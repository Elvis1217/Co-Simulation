function [sys, x0, str, ts] = Server_inside_2023(t, x, u, flag)
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
sizes.NumOutputs     = 3; 
sizes.NumInputs      = 3; 
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);
x0 = [];
str = [];
ts = [7.5e-5 0];

global sharedDataFromServer sharedDataFromClient;
sharedDataFromServer = [0; 0; 0];
sharedDataFromClient = [0; 0; 0];

disp('Server initialized successfully.');
end

function sys = mdlOutputs(t, x, u)
global sharedDataFromServer sharedDataFromClient;

sharedDataFromServer = u;
disp(['Data sent to client: ' num2str(u(:)')]);

data_recv = sharedDataFromClient;
disp(['Data received from client: ' num2str(data_recv')]);

sys = data_recv;

if any(isnan(sys))
    sys = [0; 0; 0];
end
end
