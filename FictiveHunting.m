function [S, P] = FictiveHunting()
    % Settings file for Stimulus Dot Movement in MarmoView

    % Rig-specific settings
    S = MarmoViewRigSettings();

    % Protocol information
    S.protocol = 'FictiveHunting';
    S.protocol_class = ['protocols.PR_', S.protocol];
    S.protocolTitle = 'FMA Fictive Hunting';

    % Trial settings
    S.finish = 100; % Number of trials to run

    % Stimulus parameters
    P.dotSize = 10; % Dot size in pixels
    S.dotSize = 'Dot size (pixels):';

    P.dotWhite = 1;  
    S.dotWhite = 'Dot Color: White (1 = Yes, 0 = No)';
    
    P.dotBlack = 0;     % Default to black
    S.dotBlack = 'Dot Color: Black (1 = Yes, 0 = No)';
    
    P.dotRed = 0;
    S.dotRed = 'Dot Color: Red (1 = Yes, 0 = No)';

    P.embedInNoise = 1;
    S.embedInNoise = 'Embed the stimulus in the noise';
    P.dotNoiseContrast = -1; 
    S.dotNoiseContrast = 'Set the contrast between dot and noise (-1 = darker, 1 = lighter, 0 = blend)';

    P.dotSpeedX = 1; % Dot speed in pixels/frame
    S.dotSpeedX = 'Dot X speed (pixels/frame):';
    P.dotSpeedY = 1; % Dot speed in pixels/frame
    S.dotSpeedY = 'Dot Y speed (pixels/frame):';
    
    P.flashDuration = 2; % Duration of flashing period in seconds
    S.flashDuration = 'Duration of flashing before movement (s):';
    
    P.flashFrequency = 5; % Flashing frequency in Hz
    S.flashFrequency = 'Flashing frequency (Hz):';

    
    % Noise settings
    P.bgNoise = 1; % Toggle background noise
    S.bgNoise = 'Toggle background noise:';
    P.pinkNoise = 0; % Toggle pink or white noise
    S.pinkNoise = 'Noise Type (1 = pink, 0 = white)';
    P.bgNoiseContrast = 0.1;
    S.bgNoiseContrast = 'Set background noise level';

    P.noiseAmplitude = 2; % Amplitude of random noise
    S.noiseAmplitude = 'Amplitude of random noise (pixels):';

    % Boundary parameters 
    P.boundaryStartX = 150;
    P.boundaryStartY = 610;
    P.boundaryEndX = 1116; 
    P.boundaryEndY = 1068; 
    S.boundaryEndX = 'Screen width (pixels):';
    S.boundaryEndY = 'Screen height (pixels):';

    % Bounce parameter to set behavior 
    P.bounce = 1; % 1 or 0, 1 stimulus will bounce off boundary
    S.bounce = 'Stimulus behavior at boundary:';

    % Start corner selection (binary flags for each corner)
    P.startSW = 1; % Start in Southwest corner (default)
    S.startSW = 'Start in Southwest (1 = yes, 0 = no):';

    P.startSE = 0; % Start in Southeast corner
    S.startSE = 'Start in Southeast (1 = yes, 0 = no):';

    P.startNW = 0; % Start in Northwest corner
    S.startNW = 'Start in Northwest (1 = yes, 0 = no):';

    P.startNE = 0; % Start in Northeast corner
    S.startNE = 'Start in Northeast (1 = yes, 0 = no):';

    % Target corner selection (binary flags for each corner)
    P.targetSW = 0;
    S.targetSW = 'Target Southwest (1 = yes, 0 = no):';

    P.targetSE = 0;
    S.targetSE = 'Target Southeast (1 = yes, 0 = no):';

    P.targetNW = 0;
    S.targetNW = 'Target Northwest (1 = yes, 0 = no):';

    P.targetNE = 1; % Target Northeast corner (default)
    S.targetNE = 'Target Northeast (1 = yes, 0 = no):';

    % Trial duration
    P.trialDuration = 300; % Duration of each trial (seconds)
    S.trialDuration = 'Duration of each trial (seconds):';

    % Debug selection
    P.debugMode = 0; 
    S.debugMode = 'Toggle debugging features';

    P.simpleMode = 0; 
    S.simpleMode = 'Set to 1 to enable simple mode (black background + white dot)';
end
