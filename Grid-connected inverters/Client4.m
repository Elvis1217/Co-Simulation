function [sys, x0, str, ts] = Client3(t, x, u, flag)
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
sizes.NumOutputs     = 6; % 6 output ports for voltage, current, and control signals
sizes.NumInputs      = 6; % 6 input ports for voltage, current, and control signals
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);
x0 = [];
str = [];
ts = [0.000001 0]; % Sample time

disp('Initializing TCP client send and receive...');

global t_client_send t_client_receive;
t_client_send = tcpip('192.168.56.1', 30001, 'NetworkRole', 'client');
set(t_client_send, 'Timeout', 10); % Timeout 10 seconds
set(t_client_send, 'OutputBufferSize', 1000000); % Increase output buffer size

t_client_receive = tcpip('192.168.56.1', 30000, 'NetworkRole', 'client');
set(t_client_receive, 'Timeout', 10); % Timeout 10 seconds
set(t_client_receive, 'InputBufferSize', 1000000); % Increase input buffer size

try
    fopen(t_client_send);
    disp('Client send initialized successfully.');
catch ME
    disp(['Failed to initialize client send: ' ME.message']);
end

try
    fopen(t_client_receive);
    disp('Client receive initialized successfully.');
catch ME
    disp(['Failed to initialize client receive: ' ME.message']);
end
end

function sys = mdlOutputs(t, x, u)
global t_client_send t_client_receive;
persistent last_valid_voltage_data last_valid_current_data;
if isempty(last_valid_voltage_data)
    last_valid_voltage_data = [0; 0; 0];
end
if isempty(last_valid_current_data)
    last_valid_current_data = [0; 0; 0];
end

% Package and send control signals
control_signals = [u(1:6)]; % Send control signals directly without identifiers
try
    fwrite(t_client_send, control_signals, 'double');
    disp(['Control signals sent to server: ' num2str(u(1:6)')]);
catch ME
    disp(['Error during sending control signals: ' ME.message']);
    % Attempt to reconnect
    try
        fclose(t_client_send);
        fopen(t_client_send);
    catch
        disp('Failed to reconnect.');
    end
end

% Receive voltage and current data
try
    while t_client_receive.BytesAvailable < 6 * 8 % Each time receiving 6 double precision numbers (voltage and current)
        pause(0.0001);
    end
    voltage_current_data = fread(t_client_receive, 6, 'double');
    voltage_data_recv = voltage_current_data(1:3);
    current_data_recv = voltage_current_data(4:6);
    last_valid_voltage_data = voltage_data_recv;
    last_valid_current_data = current_data_recv;
    disp(['Voltage data received from server: ' num2str(voltage_data_recv')]);
    disp(['Current data received from server: ' num2str(current_data_recv')]);
catch ME
    disp(['Error during receiving data: ' ME.message']);
    % Attempt to reconnect
    try
        fclose(t_client_receive);
        fopen(t_client_receive);
    catch
        disp('Failed to reconnect.');
    end
end

sys = [last_valid_voltage_data; last_valid_current_data];

if any(isnan(sys))
    sys = [0; 0; 0; 0; 0; 0];
end
end

