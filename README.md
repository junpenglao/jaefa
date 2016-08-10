# JAEFA
Just Another Eye-movement Filtering Algorithm (JAEFA) to preprocess raw eye tracking data to fixation event.  

```
>> fixmat = JAEFA(eyex,eyey,timestamp,CondInfo,plotopt);

```
An example is shown in HOWTO.m,  

# Under the hood
You will need to update the following parameters in the JAEFA.m to suit your eye tracking setup.  
```
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
% Minimal fixation duration (remove fixation with too short duration)
minfixdur   = 0.020; 
% Minimal saccade sample (combine fixations that are too short apart)
minsaccsp   = 10;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
```
