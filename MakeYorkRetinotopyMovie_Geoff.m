%YorkRetinotopy

clear all
clear MEX

place='Geoff';
if strcmp(place, 'Ione')
    homedir =[ 'C:' filesep 'Users' filesep 'Ione Fine' filesep 'Documents' filesep ...
        'Work' filesep 'Science' filesep 'Projects' filesep 'Ione Fine' filesep 'York_retinotopy' filesep ...
        'Programs_stimulus'];
elseif strcmp(place, 'Geoff');
    homedir='C:\Users\Geoff Boynton\Documents\MATLAB\YorkRetinotopy';
end
addpath(genpath(homedir));
cd(homedir); 

rng('default')
rng(sum(100*clock));
stim.seed=rng; % saves the random seed in case you want to recreate the scan

subjID='JMD1';
stimID='bar';
scanID='1'

filename=[subjID, '_', stimID, '_', scanID];


%% screen variables and trigger key
display.dist = 36.5;     %distance from screen (cm)
display.width = 27.5;  %width of screen (cm)
display.screenNum = 0;
display.skipChecks = 1;
display.bkColor = [0 0 0];
display.gamma = 0:255;% York monitor is linear

%% open and close the display and collect some parameters
%display.rect = Screen('Rect', display.windowPtr);
display.rect = [0 0 1920 1080];
display.resolution = display.rect([3,4]);
display.screenAngle = pix2angle( display, display.resolution(1));
display.blankImg = 128*ones(display.rect(4), display.rect(3));
display.frameRate = 8;  %Hz;


%% stimulus parameters
% To alter other aspects of the stimuli go into MakeStimulus

stim.dur =  10; % 288+9;  %duration of scan (seconds)
stim.type='mf'; %'mf' or 'bar'

if strcmp(stim.type, 'bar')
    stim.hz=4; % the rate at which bar stimulus updates
else
    stim.hz=1/3; % the rate at which mf stimulus updates
end
stim.nFrames=stim.dur*ceil(display.frameRate*2)+1; % guess at how many frames will be required
stim.switchtime=[0:1/stim.hz:stim.dur stim.dur+1];
stim.npos = length(stim.switchtime); % number of positions the bar/mf stimulus takes
% need one extra one, just in case 

%% background parameters
stim.background.hz=4; % the rate at which the background updates;
stim.background.switchtime=0:1/[stim.background.hz*2]:stim.dur; %on and off presented in the hz

%% scotoma parameters

stim.scotoma.on =0; % 0: no scotoma, 1: scotoma,  2 is York JMD1
if stim.scotoma.on>0
    % scotoma is registered to the center of the stimulus
    if stim.scotoma.on==1 % default scotoma
        stim.scotoma.center = [0 0]; % x, y in degrees
        % for -  x y values the fix spot moves to the left or to the upper part of the screen
        stim.scotoma.rad = [1];
    elseif stim.scotoma.on==2 % personalized scotoma
        stim.scotoma.center=[0 0];
        stim.scotoma.rad=[7.5];
    end
end
stim=MakeStimulus(display, stim); % details of the scotoma, background, mf and bar can be changed inside this

%% fixation parameters

fix.offset=[-5 10]; %location of the fixation spot in the display, x y degrees
% for -  x y values the fix spot moves to the left or to the upper part of the screen
s.scFac=8; % size of the fix spot, 1 is the default
fix.offsetP=angle2pix(display, fix.offset);
% for -  x y values the fix spot moves to the left or to the upper part of the screen

%%  eye-movement parameters
% modeling two types of eye-movements, slow drift and jitter
% % for a patient you want everything fixed
% eye.jitter.move=0;
% eye.drift.move=0; s

eye.jitter.move=0; % this jitters the stimulus while keeping fix fixed, good for mimicking small rapid movements
eye.drift.move=0; % this moves the fixation spot, good for big slow movements
if eye.jitter.move==0;
    eye.jitter.pos=zeros(stim.nFrames, 2);
elseif eye.jitter.move==1 % estimated instability based on
    % Bethlehem, Dumoulin, Dalmaijer, et al.
    % Decreased Fixation Stability of the Preferred Retinal Location
    % in Juvenile Macular Degeneration. Baker CI, ed. PLoS ONE. 2014;9(6)
    eye.jitter.pos(:, 1)=linspace(0, .5,stim.nFrames)+.25.*(randn(1, stim.nFrames)); % in degrees
    eye.jitter.pos(:, 2)=linspace(0, -.5,stim.nFrames)+.25.*(randn(1, stim.nFrames));
end
if eye.drift.move==0
    eye.drift.pos=zeros(stim.nFrames, 2);
elseif eye.drift.move==1
    eye.drift.pos(:, 1)=4*sin(linspace(0, 6*pi,stim.nFrames)+.25); % in degrees
    eye.drift.pos(:, 2)=5*sin(linspace(0, 6*pi,stim.nFrames)+.25); % in degrees
end

eye.jitter.posP=angle2pix(display, eye.jitter.pos);
eye.drift.posP=angle2pix(display, eye.drift.pos);


%% start running it
try
    %HideCursor;
    
    
    writerObj = VideoWriter([filename,'.avi'],'Grayscale AVI')
    writerObj.FrameRate = display.frameRate*2;
    open(writerObj);
    
    flipNum=1; % keeps track of stimulus flips
    backflipNum=1; on=1;% keeps track of background flips and sign
    
    h = waitbar(0,'Generating AVI movie');
    
    t = stim.background.switchtime;
    frame.colormap = [];
    
    for fN=1:length(t)
        
        if mod(fN,10) == 0
            waitbar(fN/length(t),h);
        end
        
        curTime = t(fN);
               
        if curTime>stim.switchtime(1) % this decides whether to update the stimulus
            stim.switchtime=stim.switchtime(2:end);
            flipNum=mod(flipNum,size(stim.img, 3)-1)+1;
        end
        
        % if curTime>stim.background.switchtime(1) % this decides whether to update the flickering background
        stim.background.switchtime=stim.background.switchtime(2:end);
        if on
            backimg=stim.background.img(:,:,mod(backflipNum, size(stim.background.img, 3))+1).*255; on=0;
        else
            backimg=[~stim.background.img(:,:,mod(backflipNum, size(stim.background.img, 3))+1)].*255; on=1;
        end
        %end
        % decide what part of the stimulus/scotoma to sample from, given the eye-position of the subject,
        % includes jitter but not drift, this is for the stimulus and
        % background
        rect(1,:)=stim.rect-[eye.jitter.posP(fN,1) eye.jitter.posP(fN,2) eye.jitter.posP(fN,1) eye.jitter.posP(fN,2)];
        % includes drift but not jitter, this is for the scotoma
        rect(2,:)=stim.rect-[eye.drift.posP(fN,1) eye.drift.posP(fN,2) eye.drift.posP(fN,1) eye.drift.posP(fN,2)];
        
        img=squeeze(double(stim.img(rect(1, 2):rect(1, 4), rect(1, 1):rect(1, 3), flipNum))) .* ...
            squeeze(backimg(rect(1, 2):rect(1, 4), rect(1, 1):rect(1, 3))) .* ...
            squeeze(stim.scotoma.img(rect(2, 2):rect(2, 4), rect(2, 1):rect(2, 3)));
        
        img = img(1:end-1,1:end-1);
        %textureIndex=Screen('MakeTexture', display.windowPtr, img);
        %Screen('DrawTexture', display.windowPtr, textureIndex, display.rect);
        
        s.fixoffset=fix.offsetP+eye.drift.posP(fN,:);
        frame.cdata = img/256;
        writeVideo(writerObj,frame);
%        boolMovie(:,:,fN) = img>0;
    end
    close(writerObj);
    dur = stim.dur;
    
    save filename dur t eye display fix s
    delete(h)
catch ME
    save(filename);
    %   Screen('CloseAll');
    %   ListenChar(0);
    rethrow(ME);
    ShowCursor;
    delete(h)
    
end










