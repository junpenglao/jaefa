function fixmat = JAEFA(eyex,eyey,timesample,condinfo,plotopt)
% JAEFA - Just Another Eye-movement Filtering Algorithm
% input:
% eyex, eyey - in pixel space
% timesample - in second, linear increase time stream
% condinfo   - vector indicating the condtion
% plotopt    - output filtering result if plotopt=1
%
% output fixmat:
% [x_fix,y_fix,dur_fix,num_fix,time_start,time_end,sample_start,sample_end,condinfo]
% 
% IMPORTANT: double check the parameters in the function!!!
% 2016-08-10 Junpeng Lao, University of Fribourg.
%--------------------------------------------------------------------------
% MIT License 
% Copyright (c) 2016 Junpeng Lao

%%%%%%%%%%%%%%%%%% Parameters: Please update manually!!! %%%%%%%%%%%%%%%%%%
% Screen Resolution
Res         = [0 0 1920 1080];
% Screen  Screen_Size in cm
Screen_Size = [52.128 29.322];
% View distance of subjects in cm
Distance    = 70;
% velocity calculation duration
velt        = 20;
% in degrees per second
angspdthrs  = 30;
% Minimal fixation duration in ms (remove fixation with too short duration)
minfixdur   = 20; % set to 0 to include all fixations
% Minimal saccade duration in ms (combine fixations that are too short apart)
minsaccsp   = 10; % set to 0 to consider all saccades
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
samplerate  = 1000; % ideal sample rate
minfixdur   = minfixdur/samplerate;
% Degree per visual angle
DPP         = atand( (Screen_Size(1)/2) / Distance) / (Res(3)/2);
SR          = round(1/mean(diff(timesample)));

if sum(diff(timesample)<0)
    idxtmp = find(diff(timesample)<0);
    eyex(1:idxtmp(end))       = [];
    eyey(1:idxtmp(end))       = [];
    timesample(1:idxtmp(end)) = [];
end

% %%%%%%%%%%% Beta: convolution method for computing visual angle %%%%%%%%%%%
% Tail=round(velt/2); % per-saccade/post-saccade intervel, this will the only parameter.
%          % it decide the minimal temporal seperation between 2 saccades
% xt=-Tail:1:Tail;
% 
% % Unit Step Function
% yUSF=heaviside(xt)*2-1; % put minial value to -1, now it has range [-1 1]
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numsample   = length(timesample);
timesample(diff(timesample)==0) = timesample(diff(timesample)==0) - min(diff(timesample))/2;
if numsample > velt
    % replace sample outside of the screen with NaN (thus exclude the blink)
    exlIdx1t    = eyex<Res(1) | eyey<Res(2) | eyex>Res(3) | eyey>Res(4);
    eyex(exlIdx1t) = NaN;
    eyey(exlIdx1t) = NaN;
    
    endtime    = floor(timesample(end)*samplerate);
    xi1        = (1:endtime)/samplerate;
    % resample to 1ms per datapoint
    eyex1  = interp1(timesample,eyex,xi1,'nearest');
    eyey1  = interp1(timesample,eyey,xi1,'nearest');
    
%     %%%%%%%%% Beta: convolution method for computing visual angle %%%%%%%%%
%     eyedata=[eyex1;eyey1]';
%     convLayer1=zeros(size(eyedata));
%     outputLayer1tmp=zeros(size(eyedata));
%     for ichanal=1:size(eyedata,2)
%         convLayer1(:,ichanal)=conv(eyedata(:,ichanal),yUSF,'same');
%     end
%     for ieye=1:(size(eyedata,2)/2)
%         outputLayer1tmp(:,1+(ieye-1)*2)=sum(abs(convLayer1(:,[1 2]+(ieye-1)*2)),2);
%         outputLayer1tmp(:,2+(ieye-1)*2)=sqrt(convLayer1(:,1+(ieye-1)*2).^2+convLayer1(:,2+(ieye-1)*2).^2);
%     end
%     velocity1 = outputLayer1tmp(:,2);
%     velocity1(1:Tail) = 0;
%     velocity1(end-Tail:end) = 0;
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Compute angular speed and detect saccades
    % compute velocity using a forward and backward box filter
    velovect  = DPP * sqrt((eyex1(velt+1:endtime)-eyex1(1:endtime-velt)).^2 ...
        + (eyey1(velt+1:endtime)-eyey1(1:endtime-velt)).^2)./ ...
        (velt/samplerate);
    velocity1 = cat(1,zeros(velt/2,1),velovect',zeros(velt/2,1));
    
    % velocity  = interp1(xi1,velocity1,timesample,'nearest');
    fixvect   = ones(length(xi1),1);
    fixvect(velocity1>angspdthrs | isnan(velocity1)) = 0;
    if SR > 500;fixvect   = conv(fixvect,[1 1 1],'same')>0;end
    
    [sacclabel,Nsacc] = bwlabel(fixvect==0);
    for sacctmp = 1:Nsacc
        if sum(sacclabel==sacctmp)<minsaccsp
            fixvect(sacclabel==sacctmp) = 1;
        end
    end
    [fixlabel1,Nfix] = bwlabel(fixvect);
    fixlabel     = interp1(xi1,fixlabel1,timesample,'nearest');
    if Nfix>0
        fixmat        = zeros(Nfix,8+length(condinfo));
        fixmat(:,9:end) = kron(condinfo,ones(Nfix,1));
        for fixtmp = 1:Nfix
            fixind = find(fixlabel == fixtmp);
            if ~isempty(fixind)
            x_fix  = nanmean(eyex(fixind));
            y_fix  = nanmean(eyey(fixind));
            sample_start = fixind(1);
            sample_end   = fixind(end);
            time_start = timesample(sample_start);
            time_end   = timesample(sample_end);
            durfix     = time_end - time_start;
            fixmat(fixtmp,1:8) = [x_fix,y_fix,durfix,fixtmp,time_start,time_end,sample_start,sample_end];
            end
        end
        fixmat = fixmat(fixmat(:,3)>minfixdur,:);
        if isempty(fixmat) ~= 1
            fixmat(:,4) = 1:size(fixmat,1);
        end
    else
        fixmat = [];
    end
    
    % display (optional)
    if plotopt
        %%
        scrsz=get(0,'ScreenSize');
        figure('NumberTitle','off','Name','Check Trials - Press any key to continue',...
            'Position',[scrsz(1) scrsz(4)/4 scrsz(3) scrsz(4)/2]);
        title(condinfo)
        subplot(1,3,[1 2]);hold on;
        plot(timesample,eyex*DPP,timesample,eyey*DPP)
        satemp=[timesample(fixmat(:,7)),eyex(fixmat(:,7)),eyey(fixmat(:,7)),...
                timesample(fixmat(:,8)),eyex(fixmat(:,8)),eyey(fixmat(:,8))];
        scatter(satemp(:,1),satemp(:,2)*DPP,'r','filled');
        scatter(satemp(:,1),satemp(:,3)*DPP,'r','filled');
        scatter(satemp(:,4),satemp(:,5)*DPP,'k','filled');
        scatter(satemp(:,4),satemp(:,6)*DPP,'k','filled');
        
        plot(xi1,velocity1.*10./quantile(velocity1(:),.99),'k')
        % [pks1,loc1,w1,p1]=findpeaks(velocity1(:,1),'MinPeakProminence',minpp);
        % scatter(loc1,3.9*ones(1,length(loc1)),'v')
        plot(xi1,fixvect*3.9,'.')
        xlim([0,timesample(end)])
        ylabel('Visual Degree')
        xlabel('Time (s)')
        
        subplot(1,3,3);hold on;
        scatter(eyex,eyey)
        scatter(fixmat(:,1),fixmat(:,2),'fill')
        set(gca, 'YDir', 'reverse');
        axis('equal')
        title('Spatial distribution of sample (in blue) and fixation (in red)')
        w = waitforbuttonpress;
        close
    end
    
    else
        fixmat = [];
end
