function [sys, x0, str, ts] = Server3(t, x, u, flag)
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
sizes.NumOutputs     = 6; % 6 output ports for control signals
sizes.NumInputs      = 6; % 6 input ports for voltage and current signals
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);
x0 = [];
str = [];
ts = [0.00001 0]; % Sample time

disp('Initializing TCP server...');

global t_server_receive t_server_send;
t_server_receive = tcpip('0.0.0.0', 30001, 'NetworkRole', 'server');
t_server_send = tcpip('0.0.0.0', 30000, 'NetworkRole', 'server');

set(t_server_receive, 'InputBufferSize', 1000000); % Buffer size
set(t_server_send, 'OutputBufferSize', 1000000);

set(t_server_receive, 'Timeout', 10); % Timeout 10 seconds
set(t_server_send, 'Timeout', 10);

fopen(t_server_receive);
fopen(t_server_send);
disp('Server initialized successfully.');
end

function sys = mdlOutputs(t, x, u)
global t_server_receive t_server_send;
persistent last_valid_control_signals;
if isempty(last_valid_control_signals)
    last_valid_control_signals = [0; 0; 0; 0; 0; 0]; % Initial control signals
end

% Package and send voltage and current data
voltage_current_data = [u(1:6)]; % Send voltage and current directly without identifiers
try
    fwrite(t_server_send, voltage_current_data, 'double');
    disp(['Voltage and current data sent to client: ' num2str(u(1:6)')]);
catch ME
    disp(['Error during sending data: ' ME.message']);
    % Attempt to reconnect
    try
        fclose(t_server_send);
        fopen(t_server_send);
    catch
        disp('Failed to reconnect.');
    end
end

% Receive control signals
try
    while t_server_receive.BytesAvailable < 6 * 8 % Each time receiving 6 double precision numbers (control signals)
        pause(0.0001);
    end
    control_signals = fread(t_server_receive, 6, 'double');
    last_valid_control_signals = control_signals;
    disp(['Control signals received from client: ' num2str(control_signals')]);
catch ME
    disp(['Error during receiving data: ' ME.message']);
    % Attempt to reconnect
    try
        fclose(t_server_receive);
        fopen(t_server_receive);
    catch
        disp('Failed to reconnect.');
    end
end

sys = last_valid_control_signals;

if any(isnan(sys))
    sys = [0; 0; 0; 0; 0; 0];
end
end
