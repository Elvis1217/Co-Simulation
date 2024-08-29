function [sys, x0, str, ts] = Client5(t, x, u, flag)
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
sizes.NumOutputs     = 3; % 三个输出端口
sizes.NumInputs      = 3; % 三个输入端口
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);
x0 = [];
str = [];
ts = [7.5E-5 0]; % 调整采样时间为0.00025

disp('Initializing TCP client send and receive...');

global t_client_send t_client_receive;
t_client_send = tcpip('192.168.56.1', 30001, 'NetworkRole', 'client');
set(t_client_send, 'Timeout', 10); % 设置超时时间为10秒
set(t_client_send, 'OutputBufferSize', 1000000); % 增加输出缓冲区大小

t_client_receive = tcpip('192.168.56.1', 30000, 'NetworkRole', 'client');
set(t_client_receive, 'Timeout', 10); % 设置超时时间为10秒
set(t_client_receive, 'InputBufferSize', 1000000); % 增加输入缓冲区大小

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
persistent last_valid_data;
if isempty(last_valid_data)
    last_valid_data = [0; 0; 0];
end

% 发送数据给主机
try
    fwrite(t_client_send, u(:), 'double');
    disp(['Data sent to server: ' num2str(u(:)')]);
catch ME
    disp(['Error during sending: ' ME.message']);
end

% 接收来自主机的数据
try
    while t_client_receive.BytesAvailable < 24
        pause(0.0001);
    end
    data_recv = fread(t_client_receive, 3, 'double');
    if length(data_recv) == 3 && all(data_recv ~= 0)
        last_valid_data = data_recv;
    end
    disp(['Data received from server: ' num2str(data_recv')]);
    sys = last_valid_data;
catch ME
    disp(['Error during receiving: ' ME.message']);
    sys = last_valid_data;
end

if any(isnan(sys))
    sys = [0; 0; 0];
end
end
