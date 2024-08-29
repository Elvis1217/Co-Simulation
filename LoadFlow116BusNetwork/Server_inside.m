function [sys, x0, str, ts] = Server_inside(t, x, u, flag)
switch flag
    case 0
        [sys, x0, str, ts] = mdlInitializeSizes();
    case 3
        sys = mdlOutputs(t, x, u);
    case {1, 2, 4, 9}
        sys = [];
    otherwise
        error(['Unhandled flag = ', num2str(flag)]);
end
end

function [sys, x0, str, ts] = mdlInitializeSizes()
sizes = simsizes;
sizes.NumContStates  = 0;
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 3; % 输出
sizes.NumInputs      = 3; % 输入
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);
x0 = [];
str = [];
ts = [7.5e-5 0]; % 采样时间

% 初始化全局变量
global sharedDataFromServer sharedDataFromClient;
sharedDataFromServer = [0; 0; 0];
sharedDataFromClient = [0; 0; 0];

disp('Server initialized successfully.');
end

function sys = mdlOutputs(t, x, u)
global sharedDataFromServer sharedDataFromClient;

% 写入数据到全局变量
sharedDataFromServer = u;
disp(['Data sent to client: ' num2str(u(:)')]);

% 读取从Client发送的数据
data_recv = sharedDataFromClient;
disp(['Data received from client: ' num2str(data_recv')]);

% 输出数据
sys = data_recv;

% 检查数据有效性
if any(isnan(sys))
    sys = [0; 0; 0];
end
end
