function [sys, x0, str, ts] = Server5(t, x, u, flag)
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
ts = [7.5E-5 0]; % 采样时间 %1e-6

disp('Initializing TCP server...');

global t_server_receive t_server_send;
t_server_receive = tcpip('0.0.0.0', 30001, 'NetworkRole', 'server');
t_server_send = tcpip('0.0.0.0', 30000, 'NetworkRole', 'server');

set(t_server_receive, 'InputBufferSize', 1000000); % 缓冲区
set(t_server_send, 'OutputBufferSize', 1000000);
set(t_server_receive, 'Timeout', 10); % 超时10秒
set(t_server_send, 'Timeout', 10); 

fopen(t_server_receive);
fopen(t_server_send);
disp('Server initialized successfully.');
end

function sys = mdlOutputs(t, x, u)
global t_server_receive t_server_send;
persistent last_valid_data;
if isempty(last_valid_data)
    last_valid_data = [0; 0; 0];
end

% 发送输入数据 u 给模型 B
try
    fwrite(t_server_send, u(:), 'double');
    disp(['Data sent to client: ' num2str(u(:)')]);
catch ME
    disp(['Error during sending: ' ME.message']);
end

% 接收从模型 B 发送的数据
try
    while t_server_receive.BytesAvailable < 24
        pause(0.0001);
    end
    data_recv = fread(t_server_receive, 3, 'double');
    if length(data_recv) == 3 && all(data_recv ~= 0)
        last_valid_data = data_recv;
    end
    disp(['Data received from client: ' num2str(data_recv')]);

    sys = data_recv;
catch ME
    disp(['Error during receiving: ' ME.message']);
    sys = last_valid_data;
end

if any(isnan(sys))
    sys = [0; 0; 0];
end
end
