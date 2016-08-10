eyedata   = load('OneExampleTrial.mat', 'tmpmat'); 
% Infomation of this trial is represented as a number vector
sbjnum    = 4;
trialnum  = 20;
CondInfo  = [sbjnum,trialnum];
% Raw data of this trial
eyex      = eyedata.tmpmat(:,1);
eyey      = eyedata.tmpmat(:,2);
timestamp = eyedata.tmpmat(:,3);
% Set to 1 to display the output
plotopt   = 1;
% Eye-movement data classification for Human(TM)
fixmat    = JAEFA(eyex,eyey,timestamp,CondInfo,plotopt);
disp('Press any key or click your mouse to continue.')