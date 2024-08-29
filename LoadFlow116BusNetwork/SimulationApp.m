classdef SimulationApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        InitializeButton               matlab.ui.control.Button
        ModelListBox                   matlab.ui.control.ListBox
        PendingSimulationsListBox      matlab.ui.control.ListBox
        AddModelButton                 matlab.ui.control.Button
        RemoveModelButton              matlab.ui.control.Button
        StartSimulationButton          matlab.ui.control.Button
        ClearResultsButton             matlab.ui.control.Button
        TextArea                       matlab.ui.control.TextArea
        SimulationTimeEditFieldLabel   matlab.ui.control.Label
        SimulationTimeEditField        matlab.ui.control.EditField
        ResultsListBoxLabel            matlab.ui.control.Label
        ResultsListBox                 matlab.ui.control.ListBox
    end

    properties (Access = private)
        % 定义私有属性
        SelectedModel       % 用户选择的模型
        PendingModels       % 等待仿真的模型列表
        SimulationTime      % 仿真时间
        FutureHandles       % 并行任务的句柄
        SimulationResults   % 存储仿真结果
    end

    methods (Access = private)

        % 初始化仿真环境的函数
        function initializeSimulationEnvironment(app)
            % 初始化共享数据
            global sharedDataFromServer sharedDataFromClient;
            sharedDataFromServer = [0; 0; 0];
            sharedDataFromClient = [0; 0; 0];

            % 设置工作目录
            cd('C:\Users\dilu2\Desktop\并行仿真');

            % 更新状态
            app.TextArea.Value = "Initialization complete.";

            % 清空结果列表
            app.ResultsListBox.Items = {};
            app.PendingModels = {}; % 初始化为一个空 cell 数组
            app.PendingSimulationsListBox.Items = {};
            app.FutureHandles = {}; % 初始化任务句柄数组
            app.SimulationResults = {}; % 初始化仿真结果
        end

        % 启动仿真并获取结果
        function startSimulation(app)
            % 获取选中的模型和仿真时间
            pendingModels = app.PendingModels;
            simTime = app.SimulationTime;

            % 检查是否选择了至少一个模型
            if isempty(pendingModels)
                app.TextArea.Value = 'Please select at least one model to simulate.';
                return;
            end

            % 启动并行池（如果尚未创建）
            if isempty(gcp('nocreate'))
                disp('Starting parallel pool...');
                parpool('local', numel(pendingModels)); % 创建与模型数量相等的并行池
            end

            % 启动并行仿真
            app.FutureHandles = cell(1, numel(pendingModels)); % 存储parfeval的future对象

            % 合并所有模型名称用于状态更新
            simulatingModels = strjoin(pendingModels, ' and ');

            % 更新状态信息，显示正在仿真的所有模型
            app.TextArea.Value = sprintf('Parallel simulation %s...', simulatingModels);

            % 为每个选中的模型启动仿真
            for i = 1:numel(pendingModels)
                modelName = pendingModels{i};
                sub_file = [modelName, '.slx'];

                % 使用parfeval启动并行仿真
                app.FutureHandles{i} = parfeval(@start_simulation, 1, sub_file, simTime);
            end

            % 等待所有仿真任务完成
            disp('Waiting for simulations to complete...');
            wait([app.FutureHandles{:}]);

            % 更新状态信息
            app.TextArea.Value = 'Simulations completed.';
            drawnow; % 强制UI更新

            % 提取并存储仿真结果
            app.SimulationResults = struct();
            for i = 1:numel(pendingModels)
                modelName = pendingModels{i};
                simOut = fetchOutputs(app.FutureHandles{i});

                app.SimulationResults.(modelName).SM_speeds = simOut.get('SM_speeds');
                app.SimulationResults.(modelName).SM_terminal_voltages = simOut.get('SM_terminal_voltages');
                app.SimulationResults.(modelName).pu = simOut.get('pu');
                app.SimulationResults.(modelName).Vabc = simOut.get('Vabc');
            end

            % 更新结果文件列表
            app.updateResultsList();

            % 关闭模型
            for i = 1:numel(pendingModels)
                close_system(pendingModels{i}, 0);
            end
        end

        % 更新结果列表框
        function updateResultsList(app)
            % 获取所有结果名称
            resultNames = {};
            fields = fieldnames(app.SimulationResults);
            for i = 1:numel(fields)
                modelName = fields{i};
                resultNames = [resultNames; ...
                    {sprintf('%s - SM_speeds', modelName), ...
                    sprintf('%s - SM_terminal_voltages', modelName), ...
                    sprintf('%s - pu', modelName), ...
                    sprintf('%s - Vabc', modelName)}];
            end

            % 更新列表框
            app.ResultsListBox.Items = resultNames;
        end

        % 清理仿真结果的函数
        function clearSimulationResults(app)
            % 清理工作区中的仿真结果
            clearvars -global sharedDataFromServer sharedDataFromClient;
            clc;

            % 清空文本区域
            app.TextArea.Value = 'Results cleared.';

            % 清空结果列表
            app.ResultsListBox.Items = {};

            % 清空等待仿真列表
            app.PendingModels = {};
            app.PendingSimulationsListBox.Items = {};

            % 删除 MAT 文件
            delete('*.mat');
        end

        % 将选中的模型添加到等待仿真列表中
        function addModel(app)
            selectedModel = app.ModelListBox.Value;
            if ~isempty(selectedModel) && ~ismember(selectedModel, app.PendingModels)
                app.PendingModels{end+1} = selectedModel;
                app.PendingSimulationsListBox.Items = app.PendingModels; % 使用 cell 数组更新列表框
            end
        end

        % 从等待仿真列表中移除选中的模型
        function removeModel(app)
            selectedModel = app.PendingSimulationsListBox.Value;
            if ~isempty(selectedModel)
                app.PendingModels(strcmp(app.PendingModels, selectedModel)) = [];
                app.PendingSimulationsListBox.Items = app.PendingModels; % 使用 cell 数组更新列表框
            end
        end

        % 绘制选中的仿真结果
        function plotSelectedResult(app)
            selectedItem = app.ResultsListBox.Value;
            if isempty(selectedItem)
                return;
            end

            % 解析选中的结果名称
            parts = split(selectedItem, ' - ');
            modelName = parts{1};
            resultName = parts{2};

            % 获取仿真数据
            data = app.SimulationResults.(modelName).(resultName);

            % 绘制结果
            figure;
            time = data(:, 1);
            signals = data(:, 2:end);
            plot(time, signals);
            title(selectedItem);
            xlabel('Time');
            ylabel(resultName);
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % 初始化界面上的组件
            app.ModelListBox.Items = {'Sub1', 'Sub2', 'Sub3', 'Sub4'};
            app.PendingModels = {}; % 初始化为一个空 cell 数组
            app.SimulationTime = '4.5'; % 默认仿真时间
            app.TextArea.Value = "Simulations completed..";
        end

        % Button pushed function: InitializeButton
        function InitializeButtonPushed(app, event)
            % 调用初始化函数
            app.initializeSimulationEnvironment();
        end

        % Value changed function: ModelListBox
        function ModelListBoxValueChanged(app, event)
            % 获取选择的模型
            app.SelectedModel = app.ModelListBox.Value;
        end

        % Button pushed function: AddModelButton
        function AddModelButtonPushed(app, event)
            % 将选中的模型添加到等待仿真列表中
            app.addModel();
        end

        % Button pushed function: RemoveModelButton
        function RemoveModelButtonPushed(app, event)
            % 从等待仿真列表中移除选中的模型
            app.removeModel();
        end

        % Button pushed function: StartSimulationButton
        function StartSimulationButtonPushed(app, event)
            % 启动仿真
            app.startSimulation();
        end

        % Button pushed function: ClearResultsButton
        function ClearResultsButtonPushed(app, event)
            % 清理仿真结果
            app.clearSimulationResults();
        end

        % Value changed function: SimulationTimeEditField
        function SimulationTimeEditFieldValueChanged(app, event)
            % 更新仿真时间
            app.SimulationTime = app.SimulationTimeEditField.Value;

            % 显示更新后的仿真时间
            app.TextArea.Value = ['Simulation Time: ', app.SimulationTime];
        end

        % Value changed function: ResultsListBox
        function ResultsListBoxValueChanged(app, event)
            % 绘制选中的仿真结果
            app.plotSelectedResult();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 720 500];
            app.UIFigure.Name = 'Co-Simulation App';

            % Create InitializeButton
            app.InitializeButton = uibutton(app.UIFigure, 'push');
            app.InitializeButton.ButtonPushedFcn = createCallbackFcn(app, @InitializeButtonPushed, true);
            app.InitializeButton.Position = [50 450 120 30];
            app.InitializeButton.Text = 'Initialize';

            % Create ModelListBox
            app.ModelListBox = uilistbox(app.UIFigure);
            app.ModelListBox.Items = {'Sub1', 'Sub2', 'Sub3', 'Sub4'};
            app.ModelListBox.ValueChangedFcn = createCallbackFcn(app, @ModelListBoxValueChanged, true);
            app.ModelListBox.Position = [50 320 120 100];

            % Create AddModelButton
            app.AddModelButton = uibutton(app.UIFigure, 'push');
            app.AddModelButton.ButtonPushedFcn = createCallbackFcn(app, @AddModelButtonPushed, true);
            app.AddModelButton.Position = [185 360 120 30];
            app.AddModelButton.Text = 'Add Model';

            % Create RemoveModelButton
            app.RemoveModelButton = uibutton(app.UIFigure, 'push');
            app.RemoveModelButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveModelButtonPushed, true);
            app.RemoveModelButton.Position = [185 320 120 30];
            app.RemoveModelButton.Text = 'Remove Model';

            % Create PendingSimulationsListBox
            app.PendingSimulationsListBox = uilistbox(app.UIFigure);
            app.PendingSimulationsListBox.Position = [320 320 120 100];
            app.PendingSimulationsListBox.Items = {};

            % Create StartSimulationButton
            app.StartSimulationButton = uibutton(app.UIFigure, 'push');
            app.StartSimulationButton.ButtonPushedFcn = createCallbackFcn(app, @StartSimulationButtonPushed, true);
            app.StartSimulationButton.Position = [50 280 120 30];
            app.StartSimulationButton.Text = 'Start Simulation';

            % Create ClearResultsButton
            app.ClearResultsButton = uibutton(app.UIFigure, 'push');
            app.ClearResultsButton.ButtonPushedFcn = createCallbackFcn(app, @ClearResultsButtonPushed, true);
            app.ClearResultsButton.Position = [320 280 120 30];
            app.ClearResultsButton.Text = 'Clear Results';

            % Create SimulationTimeEditFieldLabel
            app.SimulationTimeEditFieldLabel = uilabel(app.UIFigure);
            app.SimulationTimeEditFieldLabel.HorizontalAlignment = 'right';
            app.SimulationTimeEditFieldLabel.Position = [50 245 100 22];
            app.SimulationTimeEditFieldLabel.Text = 'Simulation Time';

            % Create SimulationTimeEditField
            app.SimulationTimeEditField = uieditfield(app.UIFigure, 'text');
            app.SimulationTimeEditField.ValueChangedFcn = createCallbackFcn(app, @SimulationTimeEditFieldValueChanged, true);
            app.SimulationTimeEditField.Position = [160 245 100 22];
            app.SimulationTimeEditField.Value = '4.5';

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.Position = [50 50 390 180];
            app.TextArea.Editable = 'off'; % 禁止编辑，以显示状态信息

            % Create ResultsListBoxLabel
            app.ResultsListBoxLabel = uilabel(app.UIFigure);
            app.ResultsListBoxLabel.HorizontalAlignment = 'right';
            app.ResultsListBoxLabel.Position = [520 450 120 22];
            app.ResultsListBoxLabel.Text = 'Simulation Results';

           % Create ResultsListBox
app.ResultsListBox = uilistbox(app.UIFigure);
app.ResultsListBox.ValueChangedFcn = createCallbackFcn(app, @ResultsListBoxValueChanged, true);
app.ResultsListBox.Position = [500 50 180 380];
app.ResultsListBox.Items = {'SM_speeds1', 'SM_terminal_voltages1', 'pu1', 'Vabc1', 'SM_speeds2', 'SM_terminal_voltages2', 'pu2', 'Vabc2'};


            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SimulationApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end

% 仿真函数
function simOut = start_simulation(file, simTime)
    % 设置工作目录为模型所在目录
    cd('C:\Users\dilu2\Desktop\并行仿真');
    
    % 加载模型
    load_system(file);
    
    % 获取模型名称（不包括扩展名）
    [~, modelName, ~] = fileparts(file);
    
    % 设置仿真参数
    set_param(modelName, 'StopTime', simTime);
    
    % 启动模型的仿真
    simOut = sim(modelName, 'SimulationMode', 'normal', 'StopTime', simTime, 'SaveOutput', 'on');
end
