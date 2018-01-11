
function measure(period,NumberOfChannels)

close all;
% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following three parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'PCI-1747U,BID#0'; 
startChannel = int32(0);
channelCount = int32(NumberOfChannels);

% Step 1: Create a 'InstantAiCtrl' for Instant AI function.
instantAiCtrl = Automation.BDaq.InstantAiCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    instantAiCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    data = NET.createArray('System.Double', channelCount);
    
    h = animatedline;
    time = 0;
    grid minor;
    
    % Step 3: Read samples and do post-process, we show data here.
    errorCode = Automation.BDaq.ErrorCode();
    t = timer('TimerFcn', {@TimerCallback, instantAiCtrl, startChannel, ...
        channelCount, data}, 'period', period, 'executionmode', 'fixedrate', ...
        'StartDelay', 1);
    drawTimer = timer('TimerFcn', {@DrawSignal, instantAiCtrl, startChannel, ...
        channelCount, data}, 'period', 1/30, 'executionmode', 'fixedrate', ...
        'StartDelay', 1);
    dataStruct = struct('h', h, 'time', time, 'period', 1/30);
    %drawTimer.UserData.handle = h;
    %drawTimer.UserData.time = time;
    %drawTimer.UserData.period = period;
    drawTimer.UserData = dataStruct;
    
    %start(t);
    start(drawTimer);
    
    input('InstantAI is in progress...Press Enter key to quit!');
    %stop(t);
    stop(drawTimer);
    delete(drawTimer);
    %delete(t);
catch e
    disp(e);
    % Something is wrong.
    if BioFailed(errorCode)    
        errStr = 'Some error occurred. And the last error code is ' ... 
            + errorCode.ToString();
    else
        errStr = e.message;
    end
    disp(errStr); 
end

% Step 4: Close device and release any allocated resource.
instantAiCtrl.Dispose();

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

%global pomiar;
%pomiar = [];
function TimerCallback(obj, event, instantAiCtrl, startChannel, ...
    channelCount, data)
%persistent pomiar;
%global pomiar;
%if isempty(pomiar)
%    pomiar = [];```
%end
errorCode = instantAiCtrl.Read(startChannel, channelCount, data); 
if BioFailed(errorCode)
    throw Exception();
end
%pomiar = [pomiar; data.Get(1)];
fprintf('\n');
for j=0:(channelCount - 1)
    fprintf('channel %d : %10f ', j, data.Get(j));
end
end

function DrawSignal(obj, event, instantAiCtrl, startChannel, ...
    channelCount, data)
%persistent pomiar;
%global pomiar;
%if isempty(pomiar)
%    pomiar = [];```
%end
errorCode = instantAiCtrl.Read(startChannel, channelCount, data); 
if BioFailed(errorCode)
    throw Exception();
end
%pomiar = [pomiar; data.Get(1)];
disp('UPDATE');
aa = obj.UserData;
aa.time = aa.time + aa.period;
axis([aa.time-2 aa.time+1 -1 1]);
addpoints(aa.h,aa.time, data.Get(0) );
obj.UserData = aa;
drawnow;
end