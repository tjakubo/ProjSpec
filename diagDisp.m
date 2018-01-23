function diagDisp(channelNum)

close all;
% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following three parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
%deviceDescription = 'DemoDevice,BID#0'; 
deviceDescription = 'PCI-1747U,BID#0'; 
startChannel = int32(0);
channelCount = int32(32);

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
    
    figure(1);
    ax = axes();
    h = animatedline;
    title(sprintf('Channel %d', channelNum));
    %test = uidropdown(f, 'Items',{'1', '2', '3', '4', '5', '6'});
    %ax = cell(1,channelCountNum);
%     for h_i = 1:channelCountNum
%         ax{h_i} = subplot(8,4,h_i);
%         h{h_i} = animatedline;
%         grid minor;
%     end
%     handles = struct('h', h, 'ax', ax);
    time = 0;

    
    % Step 3: Read samples and do post-process, we show data here.
    errorCode = Automation.BDaq.ErrorCode();
    t = timer('TimerFcn', {@TimerCallback, instantAiCtrl, startChannel, ...
        channelCount, data}, 'period', 0.01, 'executionmode', 'fixedrate');
%drawTimer = timer('TimerFcn', {@DrawSignal, instantAiCtrl, startChannel, ...
    %channelCount, data}, 'period', 0.05, 'executionmode', 'fixedrate');
    %dataStruct = struct('h', handles, 'time', time, 'period', 1/2, 'count', 1);
    dataStruct = struct('h', h, 'time', time, 'period', 0.01, 'ax', ax, 'channelNum', channelNum);
%drawTimer.UserData = dataStruct;
    t.UserData = dataStruct;
    start(t);
    waitforbuttonpress();
    %start(t);
    %start(drawTimer);
    
    %pause(setTime*2);
    %stop(t);
    %stop(drawTimer);
    %delete(drawTimer);
    delete(t);
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
newUserData = obj.UserData;

errorCode = instantAiCtrl.Read(startChannel, channelCount, data); 
if BioFailed(errorCode)
    throw Exception();
end
%fprintf('READ\n');
addpoints(newUserData.h, newUserData.time, data.Get(newUserData.channelNum-1));
set(newUserData.ax, 'XLim', [newUserData.time-2 newUserData.time+1]);
newUserData.time = newUserData.time + newUserData.period;
drawnow;
obj.UserData = newUserData;

end

function DrawSignal(obj, event, instantAiCtrl, startChannel, ...
    channelCount, data)
%errorCode = instantAiCtrl.Read(startChannel, channelCount, data); 
%if BioFailed(errorCode)
%    throw Exception();
%end
%pomiar = [pomiar; data.Get(1)];
global pomiar;
disp('UPDATE');
newUserData = obj.UserData;
ostPomiar = pomiar(:, newUserData.count);
newUserData.time = newUserData.time + newUserData.period;
for j=1:channelCount
    %axes(newUserData.h(j).ax);
    addpoints(newUserData.h(j).h, newUserData.time, ostPomiar(j));
    set(newUserData.h(j).ax, 'XLim', [newUserData.time-2 newUserData.time+1]);
    %xlim([newUserData.time-2 newUserData.time+1]);
    %fprintf('channel %d : %10f ', j, data.Get(j));
end
%axis([aa.time-2 aa.time+1 -5 5]);
obj.UserData = newUserData;
drawnow;
end