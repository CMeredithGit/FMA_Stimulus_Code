classdef PR_StimulusDotMove_MarmoView < protocols.protocol
    % Protocol for a stimulus that can be used for testing behavior of
    % marmosets in the freely moving arena. Paired with
    % StimulusDotMove_MarmoView.m settings file. 
    % Controls:
    % 'B' - Begin trial
    % 'P' - Pause trial
    % 'R' - Resume trial
    % 'Q' - End trial 
    % 'Space' - Switch to manual control
    % Arrow Keys - Manual control of stimulus
    % 'A'/'D' - +/- Dot X speed
    % 'W'/'S' - +/- Dot  Y speed
    % '=+'/'-_' - +/- Dot size

    % Paused Controls:
    % 'F' - Toggle flashing stimulus
    % 'O' - Toggle visible stimulus
    % 'R' - Resume trial
    
    % Debug Mode (if enabled):
    %   - Displays screen boundaries in white
    %   - Displays target end zone in red
    
    % Simple Mode (make sure to disable embedInNoise)
    %   - Displays a black background
    %   - Generates a white dot for stimulus

%% Set properties
    properties (Access = public)
        combinedTrials struct
        stimTrace table
        stimTraceTime = [];
        stimTraceX = [];
        stimTraceY = [];
        subjectName char = 'UnknownSubject';

        dotX double = 0;
        dotY double = 0;
        dotSize double = 10;
        dotSpeedX double = 1;
        dotSpeedY double = 1;
        dotColor = [0, 0, 0]; % Default to black
        targetX double = 0;
        targetY double = 0;
        targetSize double = 100;
        boundaryStartX double = 96;
        boundaryStartY double = 218;
        boundaryEndX double = 1100;
        boundaryEndY double = 710;
        noiseAmplitude double = 2;
        trialDuration double = 10;
        moving logical = false;
        bgNoise logical = true;
        pinkNoise logical = true; % Default to 1/f (pink) noise
        bgColor = [128, 128, 128]; % Default to mid grey
        bgNoiseContrast double = 0.1;
        embedInNoise logical = false; % Determines if the stimulus is embedded in noise
        dotNoiseContrast double = 0; % Controls dot contrast relative to background (-1 = darker, 1 = lighter, 0 = blend)

        vbl double = 0;   % Stores the last vertical blank timestamp
        ifi double = 0;   % Stores the inter-frame interval (screen refresh rate)

        % Flashing properties
        flashDuration double = 1; % Duration of flashing before movement
        flashFrequency double = 5; % Frequency of flashing (Hz)
        flashing logical = true;
        flashVisible logical = true;
        lastFlashTime double = 0;

        trialData;
        trialNumber double = 0;

        startSW logical = false;
        startSE logical = false;
        startNW logical = false;
        startNE logical = false;

        targetSW logical = false;
        targetSE logical = false;
        targetNW logical = false;
        targetNE logical = false;

        endZones double % Stores predefined end zone positions (4x3 matrix)

        bounce logical = false;

        paused logical = false;
        pausePressed logical = false; % Prevents multiple pause toggles
        resumePressed logical = false; % Prevents multiple resume toggles
        showObjectPressed logical = false;  % Tracks if 'O' key was pressed to toggle stimulus visibility
        flashPressed logical = false;       % Tracks if 'F' key was pressed to toggle flashing mode
        stimulusVisible logical = true;  % Controls whether the stimulus is drawn when paused
        flashingMode logical = false;    % Determines if stimulus should flash
        flashTime double = 0;            % Tracks the last time flash was toggled
        flashInterval double = 0.5;      % Time between flashes (adjust as needed)


        xSpeedPressed logical = false; % Prevents rapid changes to X speed
        ySpeedPressed logical = false; % Prevents rapid changes to Y speed
        sizePressed logical = false; % Prevents rapid size changes

        manualStart logical = false;       % Tracks if 'B' was pressed to start trial
        manualMode logical = false;        % Tracks if manual mode is enabled
        manualModePressed logical = false; % Prevents multiple toggles per key press
        manualEnd logical = false;         % Tracks if 'Q' was pressed to end the trial

        trialEnded logical = false; % Prevents duplicate end messages

        debugMode logical = false; % Enables drawing of boundaries for debugging
        simpleMode logical = false; % If true, overrides everything and just draws a white dot on black background
        controlsPrinted logical = false; % Prevents re-printing controls

        % Manual trials mode
        manualTrials logical = false; % Enables fully manual trial mode
        dotColorToggle logical = false; % Tracks black/white toggle status
        manualDotColorToggle logical = false;
        manualDotColorTogglePressed logical = false;
        dotAlpha double = 100;  % Default to fully visible (100%)
        contrastIncreasePressed logical = false;
        contrastDecreasePressed logical = false;
        bgNoiseTogglePressed logical = false;
        bgContrastIncreasePressed logical = false;
        bgContrastDecreasePressed logical = false;
        % Jitter properties
        jitteredDotX double = 0;
        jitteredDotY double = 0;


    end

    %% Set the methods and run initFunc
    methods (Access = public)
        function o = PR_StimulusDotMove_MarmoView(winPtr)
            o = o@protocols.protocol(winPtr);
        end
        
        function initFunc(o, S, P)
            fprintf('Initializing PR_StimulusDotMove_MarmoView...\n');
            o.combinedTrials = struct();  % Empty struct to hold all trial data
            o.stimTrace
            KbName('UnifyKeyNames');

            % Debugging
            o.debugMode = logical(P.debugMode); % Enable/disable debug visuals 
            o.simpleMode = logical(P.simpleMode); % White stimulus on black background
            o.manualTrials = logical(P.manualTrials); % Enable manual trial mode if selected

            o.dotSize = P.dotSize;
            o.dotSpeedX = P.dotSpeedX;
            o.dotSpeedY = P.dotSpeedY;
            o.embedInNoise = logical(P.embedInNoise);
            o.dotNoiseContrast = P.dotNoiseContrast;

            % Initialize stimulus trace data storage
            o.stimTraceTime = [];
            o.stimTraceX = [];
            o.stimTraceY = [];

            o.trialDuration = P.trialDuration;
            o.noiseAmplitude = P.noiseAmplitude;
            o.bgNoise = logical(P.bgNoise);
            o.bgNoiseContrast = P.bgNoiseContrast;

            % Set up endzones (X, Y, width, height)
            o.endZones = [
                114, 336, 50, 50;   % SW corner
                1086, 336, 50, 50;  % SE corner
                114, 336, 50, 50;   % NW corner
                1086, 336, 50, 50;]; % NE corner
            fprintf('End zones assigned.\n');

            if P.dotWhite == 1
                o.dotColor = [255, 255, 255];
            elseif P.dotBlack == 1
                o.dotColor = [0, 0, 0];
            elseif P.dotRed == 1
                o.dotColor = [255, 0, 0];
            else
                warning('No dot color selected; defaulting to white.');
                o.dotColor = [255, 255, 255];
            end

            % Flashing stimulus parameters
            o.flashDuration = P.flashDuration;
            o.flashFrequency = P.flashFrequency;

            [o.winPtr, windowRect] = PsychImaging('OpenWindow', max(Screen('Screens')), o.bgColor);
            Screen('BlendFunction', o.winPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

            % Get screen refresh interval (ifi) and initial vertical blank time (vbl)
            o.ifi = Screen('GetFlipInterval', o.winPtr);
            o.vbl = Screen('Flip', o.winPtr); % Initial flip
            
            % Set up boundaries (Adjust as needed)
            [screenXpixels, screenYpixels] = Screen('WindowSize', o.winPtr);
            o.boundaryStartX = 90;
            o.boundaryStartY = 216;
            o.boundaryEndX = 1100;
            o.boundaryEndY = 712;

            % Set start position
            o.startSW = P.startSW;
            o.startSE = P.startSE;
            o.startNW = P.startNW;
            o.startNE = P.startNE;
            

            % Set stimulus behavior when encountering a boundary
            o.bounce = logical(P.bounce);

            % Define target corner
            o.targetSW = logical(P.targetSW);
            o.targetSE = logical(P.targetSE);
            o.targetNW = logical(P.targetNW);
            o.targetNE = logical(P.targetNE);

            fprintf('Target selection loaded: SW=%d, SE=%d, NW=%d, NE=%d\n', ...
            o.targetSW, o.targetSE, o.targetNW, o.targetNE);

            if o.targetSW
                o.targetX = o.endZones(1, 1); 
                o.targetY = o.endZones(1, 2);
                o.targetSize = o.endZones(1, 3);
            elseif o.targetSE
                o.targetX = o.endZones(2, 1); 
                o.targetY = o.endZones(2, 2);
                o.targetSize = o.endZones(2, 3);
            elseif o.targetNW
                o.targetX = o.endZones(3, 1); 
                o.targetY = o.endZones(3, 2);
                o.targetSize = o.endZones(3, 3);
            elseif o.targetNE
                o.targetX = o.endZones(4, 1); 
                o.targetY = o.endZones(4, 2);
                o.targetSize = o.endZones(4, 3);
            else
                fprintf('ERROR: No valid target corner selected.\n');
                error('No valid target corner selected.'); % Catch case where no target is set
            end
            fprintf('Target set to (X=%.2f, Y=%.2f)\n', o.targetX, o.targetY);

            % Create struct to save trial data
            o.trialData = struct('seed', {}, 'trace', {}, 'noiseSeed', {});
        end

        function pinkNoise = filter1f(o, whiteNoise)
            % Convert white noise to frequency domain
            noiseFFT = fft2(whiteNoise);
    
            % Get frequency grid
            [rows, cols] = size(whiteNoise);
            [X, Y] = meshgrid(1:cols, 1:rows);
            freqGrid = sqrt((X - cols/2).^2 + (Y - rows/2).^2);
            freqGrid(freqGrid == 0) = 1; % Prevent division by zero
    
            % Apply 1/f scaling
            scaling = 1 ./ freqGrid;
            noiseFFT = noiseFFT .* scaling;
    
            % Convert back to spatial domain
            pinkNoise = real(ifft2(noiseFFT));
    
            % Normalize to [-1, 1] range
            pinkNoise = pinkNoise ./ max(abs(pinkNoise(:)));
    
            % If input is 1D or very small, return a single value for movement
            if numel(whiteNoise) == 1
                pinkNoise = pinkNoise(1,1); % Return a single noise value
            end
        end
        
%% Run prep_run_trial
        function [FP, TS] = prep_run_trial(o)
            FP = struct(); 
            FP(1).states = 1;
            FP(1).col = 'b';
            TS = 1;
        
            frameCounter = 0; % Reset frame counter at the start of each trial
        
            % Reset trial flags
            o.manualStart = false; % Ensure new trials wait for 'B'
            o.manualEnd = false;   % Prevent all trials from ending after pressing 'Q'
            o.trialEnded = false;  % Reset trial end flag
        
            o.trialNumber = o.trialNumber + 1;
            o.moving = false;
            o.flashing = true;
            o.flashVisible = true;
            o.lastFlashTime = GetSecs();
        
            o.startTime = GetSecs();
        
        
            % Wait for 'B' key before starting
            if ~o.controlsPrinted
                fprintf('\n=== Trial Controls ===\n');
                fprintf(' B - Begin trial\n');
                fprintf(' P - Pause trial\n');
                fprintf(' R - Resume trial\n');
                fprintf(' Q - End trial\n');
                fprintf(' Space - Toggle manual control mode\n');
                fprintf(' Arrow Keys - Move stimulus manually (manual mode only)\n');
                fprintf(' W/S - Increase/Decrease dot X speed\n');
                fprintf(' A/D - Decrease/Increase dot Y speed\n');
                fprintf(' -/+ - Decrease/Increase dot size\n');
                fprintf(' Paused Controls\n');
                fprintf(' F - Toggle flashing stimulus\n');
                fprintf(' O - Toggle visible stimulus\n');
                fprintf(' R - Resume trial\n');
                fprintf('======================\n\n');
                o.controlsPrinted = true; % Prevents duplicate printing
            end
        
            % If manualTrials is enabled, allow the user to select the start position
            if o.manualTrials
                if o.trialNumber == 1
                    fprintf('\n=== Manual Trial Controls ===\n');
                    fprintf(' B - Begin trial\n');
                    fprintf(' Q - End trial\n');
                    fprintf(' C - Toogle Black or white dot\n');
                    fprintf(' F - Toggle flashing stimulus\n');
                    fprintf(' O - Toggle visible stimulus\n');
                    fprintf(' j/k - Decrease/Increase dot opacity\n');
                    fprintf(' Arrow Keys - Move stimulus manually (manual mode only)\n');
                else
                end

                fprintf('\n=== Manual Trials Mode: Select Start Corner ===\n');
                fprintf('1. NW\n2. NE\n3. SW\n4. SE\n');
        
                validInput = false;
                while ~validInput
                    startChoice = input('Enter the number corresponding to the START corner: ', 's');
                    switch startChoice
                        case '1'
                            o.startNW = true; o.startNE = false; o.startSW = false; o.startSE = false;
                            validInput = true;
                        case '2'
                            o.startNW = false; o.startNE = true; o.startSW = false; o.startSE = false;
                            validInput = true;
                        case '3'
                            o.startNW = false; o.startNE = false; o.startSW = true; o.startSE = false;
                            validInput = true;
                        case '4'
                            o.startNW = false; o.startNE = false; o.startSW = false; o.startSE = true;
                            validInput = true;
                        otherwise
                            fprintf('Invalid choice. Please enter 1, 2, 3, or 4.\n');
                    end
                end
                fprintf('\nStart corner selected. Press "B" to begin the trial.\n');
            end
        
            while ~o.manualStart
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown && keyCode(KbName('b'))
                    o.manualStart = true; % Start trial
                    fprintf('Trial started by user.\n');
                end
            end
        
            % Start time AFTER 'B' is pressed
            o.startTime = GetSecs();
        
            % Define where the stimulus starts
            if o.startSW
                o.dotX = o.boundaryStartX + o.dotSize / 2;
                o.dotY = randi([o.boundaryStartY + (o.boundaryEndY - o.boundaryStartY) / 2, o.boundaryEndY - o.dotSize / 2]);
            elseif o.startSE
                o.dotX = o.boundaryEndX - o.dotSize / 2;
                o.dotY = randi([o.boundaryStartY + (o.boundaryEndY - o.boundaryStartY) / 2, o.boundaryEndY - o.dotSize / 2]);
            elseif o.startNW
                o.dotX = o.boundaryStartX + o.dotSize / 2;
                o.dotY = randi([o.boundaryStartY + o.dotSize / 2, o.boundaryStartY + (o.boundaryEndY - o.boundaryStartY) / 2]);
            elseif o.startNE
                o.dotX = o.boundaryEndX - o.dotSize / 2;
                o.dotY = randi([o.boundaryStartY + o.dotSize / 2, o.boundaryStartY + (o.boundaryEndY - o.boundaryStartY) / 2]);
            else
                o.dotX = (o.boundaryEndX - o.boundaryStartX) / 2;
                o.dotY = (o.boundaryEndY - o.boundaryStartY) / 2;
            end
        
            % If manualTrials is enabled, skip automatic movement direction setup
            if ~o.manualTrials
                % Set initial movement direction toward target
                if o.targetX < o.dotX
                    o.dotSpeedX = -abs(o.dotSpeedX); % Move left if target is to the left
                else
                    o.dotSpeedX = abs(o.dotSpeedX);  % Move right if target is to the right
                end
        
                if o.targetY < o.dotY
                    o.dotSpeedY = -abs(o.dotSpeedY); % Move up if target is above
                else
                    o.dotSpeedY = abs(o.dotSpeedY);  % Move down if target is below
                end
            end
        
            o.trialEnded = false; % Reset flag at the start of each trial
        
            % Saving the seeds and traces for stimulus traces
            rng('shuffle');
            o.trialData(o.trialNumber).seed = rng;
            o.trialData(o.trialNumber).noiseSeed = randi(1e9);
            o.trialData(o.trialNumber).trace = [];
        end

%% Run continue_run_trial
        function keepgoing = continue_run_trial(o, varargin)
            % If manualTrials is enabled, trial runs indefinitely until 'Q' is pressed
            if o.manualTrials
                keepgoing = ~o.manualEnd; % Runs until user presses 'Q'
                return;
            end
        
            % Standard end zone logic for normal trials
            if o.targetNE
                % NE: Top half of screen
                yMin = o.boundaryStartY;
                yMax = (o.boundaryStartY + o.boundaryEndY) / 2;
                xMin = o.targetX - 10;  
                xMax = o.targetX + 10;
            
            elseif o.targetSE
                % SE: Bottom half of screen
                yMin = (o.boundaryStartY + o.boundaryEndY) / 2;
                yMax = o.boundaryEndY;
                xMin = o.targetX - 10;
                xMax = o.targetX + 10;
            
            elseif o.targetNW
                % NW: Bottom half of screen (mirrored from NE)
                yMin = (o.boundaryStartY + o.boundaryEndY) / 2;
                yMax = o.boundaryEndY;
                xMin = o.targetX - 10;  
                xMax = o.targetX + 10;
            
            elseif o.targetSW
                % SW: Top half of screen (mirrored from SE)
                yMin = o.boundaryStartY;
                yMax = (o.boundaryStartY + o.boundaryEndY) / 2;
                xMin = o.targetX - 5;
                xMax = o.targetX + 5;
            
            else
                % Default case
                yMin = o.targetY - 50;  
                yMax = o.targetY + 50;
                xMin = o.targetX - 50;
                xMax = o.targetX + 50;
            end
        
            % Check if the dot has entered the expanded end zone
            inEndZone = (o.dotX >= xMin && o.dotX <= xMax) && (o.dotY >= yMin && o.dotY <= yMax);
        
            % Stop the trial if manually ended with 'Q'
            if o.manualEnd
                fprintf('Trial manually ended.\n');
                keepgoing = false;
                return;
            end
        
            % Stop the trial when the dot reaches the target end zone
            if inEndZone
                keepgoing = false;
                return;
            end
        
            % Continue running indefinitely if in manual mode
            if o.manualMode
                keepgoing = true;
                return;
            end
        
            % Continue if stimulus is still moving
            keepgoing = o.moving || o.flashing;
        end

%% Run state_and_screen_update
        function drop = state_and_screen_update(o, currentTime, x, y, inputs)
            drop = 0;
             
            persistent frameCounter noiseY;
            if isempty(frameCounter)
                frameCounter = 0;
                noiseY = 0; % Initialize noiseY to 0
            end

            % **Manual Trials Mode: Full Manual Control**
            if o.manualTrials
                [keyIsDown, ~, keyCode] = KbCheck;
        
                if keyIsDown
                    % Manually end trial with 'Q'
                    if keyCode(KbName('q'))
                        o.manualEnd = true;
                        fprintf('Trial manually ended.\n');
                        return;
                    end

                    % Toggle black or white stimulus
                     if keyCode(KbName('c')) && ~o.manualDotColorTogglePressed
                        if all(o.dotColor == [0, 0, 0])
                            o.dotColor = [255, 255, 255];
                        else 
                            o.dotColor = [0, 0, 0];
                        end
                        o.manualDotColorToggle = ~o.manualDotColorToggle; % Flip between black and white
                        o.manualDotColorTogglePressed = true; % Prevent repeated toggling while holding key
                     end

                     % Increase Opacity with 'K' Key
                    if keyCode(KbName('l')) && ~o.contrastIncreasePressed
                        o.dotAlpha = min(o.dotAlpha + 10, 100); % Prevent exceeding 100%
                        o.contrastIncreasePressed = true;
                    end
            
                    % Decrease Opacity with 'J' Key
                    if keyCode(KbName('k')) && ~o.contrastDecreasePressed
                        o.dotAlpha = max(o.dotAlpha - 10, 0); % Prevent full disappearance
                        o.contrastDecreasePressed = true;
                    end
        
                    % Manual movement with arrow keys
                    if keyCode(KbName('LeftArrow'))
                        o.dotY = min(o.boundaryEndY, o.dotY + o.dotSpeedY);
                    elseif keyCode(KbName('RightArrow'))
                        o.dotY = max(o.boundaryStartY, o.dotY - o.dotSpeedY);
                           
                    elseif keyCode(KbName('UpArrow'))
                        o.dotX = max(o.boundaryStartX, o.dotX - o.dotSpeedX); 
                    elseif keyCode(KbName('DownArrow'))
                        o.dotX = min(o.boundaryEndX, o.dotX + o.dotSpeedX);
                          
                    end
    
                    % Toggle stimulus ON/OFF with 'O'
                    if keyCode(KbName('o')) && ~o.showObjectPressed
                        o.stimulusVisible = ~o.stimulusVisible;
                        o.showObjectPressed = true;
                    end
        
                    % Toggle background noise
                    if keyCode(KbName('n')) && ~o.bgNoiseTogglePressed
                        o.bgNoise = ~o.bgNoise; % Toggle noise on/off
                        fprintf('Background noise toggled.\n');
                        o.bgNoiseTogglePressed = true;
                    end
                    if ~keyCode(KbName('n'))
                        o.bgNoiseTogglePressed = false; % Reset toggle flag
                    end

                    % Increase noise contrast with 'Y'
                    if keyCode(KbName('y')) && ~o.bgContrastIncreasePressed
                        o.bgNoiseContrast = min(o.bgNoiseContrast + 0.05, 1); % Max contrast = 1
                        o.bgContrastIncreasePressed = true;
                    end
                    
                    % Decrease noise contrast with 'T'
                    if keyCode(KbName('t')) && ~o.bgContrastDecreasePressed
                        o.bgNoiseContrast = max(o.bgNoiseContrast - 0.05, 0); % Min contrast = 0
                        o.bgContrastDecreasePressed = true;
                    end


                    % Enable/Disable flashing mode with 'F'
                    if keyCode(KbName('f')) && ~o.flashPressed
                        o.flashingMode = ~o.flashingMode;
                        o.flashTime = GetSecs();
                        o.flashPressed = true;
                    end
        
                    % Adjust X speed with A/D while maintaining direction
                    if keyCode(KbName('d')) && ~o.xSpeedPressed
                        o.dotSpeedX = min(o.dotSpeedX + 1, 20);
                        fprintf('Increased X speed: %.1f\n', o.dotSpeedX);
                        o.xSpeedPressed = true;
                    elseif keyCode(KbName('a')) && ~o.xSpeedPressed
                        o.dotSpeedX = max(o.dotSpeedX - 1, 1);
                        fprintf('Decreased X speed: %.1f\n', o.dotSpeedX);
                        o.xSpeedPressed = true;
                    end
        
                    % Adjust Y speed with W/S while maintaining direction
                    if keyCode(KbName('w')) && ~o.ySpeedPressed
                        o.dotSpeedY = min(o.dotSpeedY + 1, 20);
                        fprintf('Increased Y speed: %.1f\n', o.dotSpeedY);
                        o.ySpeedPressed = true;
                    elseif keyCode(KbName('s')) && ~o.ySpeedPressed
                        o.dotSpeedY = max(o.dotSpeedY - 1, 1);
                        fprintf('Decreased Y speed: %.1f\n', o.dotSpeedY);
                        o.ySpeedPressed = true;
                    end
        
                    % Adjust dot size with +/- keys
                    if keyCode(KbName('=+')) && ~o.sizePressed
                        o.dotSize = min(o.dotSize + 2, 100);
                        fprintf('Increased dot size: %.1f\n', o.dotSize);
                        o.sizePressed = true;
                    elseif keyCode(KbName('-_')) && ~o.sizePressed
                        o.dotSize = max(o.dotSize - 2, 5);
                        fprintf('Decreased dot size: %.1f\n', o.dotSize);
                        o.sizePressed = true;
                    end
                end
        
                % Reset key toggles when keys are released
                if ~keyCode(KbName('o'))
                    o.showObjectPressed = false;
                end
                if ~keyCode(KbName('f'))
                    o.flashPressed = false;
                end
                if ~keyCode(KbName('a')) && ~keyCode(KbName('d'))
                    o.xSpeedPressed = false;
                end
                if ~keyCode(KbName('w')) && ~keyCode(KbName('s'))
                    o.ySpeedPressed = false;
                end
                if ~keyCode(KbName('=+')) && ~keyCode(KbName('-_'))
                    o.sizePressed = false;
                end
                if ~keyCode(KbName('c'))
                    o.manualDotColorTogglePressed = false;
                end
                if ~keyCode(KbName('l'))
                    o.contrastIncreasePressed = false;
                end
                if ~keyCode(KbName('k'))
                    o.contrastDecreasePressed = false;
                end
                if ~keyCode(KbName('t'))
                    o.bgContrastDecreasePressed = false;
                end
                if ~keyCode(KbName('y'))
                    o.bgContrastIncreasePressed = false;
                end
        
                % Generate background noise
                if o.bgNoise
                    % Get full screen dimensions
                    [screenXpixels, screenYpixels] = Screen('WindowSize', o.winPtr);
                
                    % Generate full-screen Gaussian noise
                    grayLevel = double(o.bgColor(1));
                    noiseAmplitude = 128 * o.bgNoiseContrast;  % Scale amplitude
                    noiseImage = grayLevel + noiseAmplitude .* randn(screenYpixels, screenXpixels);
                    noiseImage = uint8(min(max(noiseImage, 0), 255)); % Clamp values
                
                    % Create and draw noise texture over the entire screen
                    noiseTexture = Screen('MakeTexture', o.winPtr, noiseImage);
                    Screen('DrawTexture', o.winPtr, noiseTexture, [], []);
                    Screen('Close', noiseTexture);
                    else
                        Screen('FillRect', o.winPtr, o.bgColor);
                end

                % Flashing logic
                if o.flashingMode
                    if GetSecs() - o.flashTime >= 1 / o.flashFrequency
                        o.stimulusVisible = ~o.stimulusVisible;
                        o.flashTime = GetSecs();
                    end
                end
        
                % Draw only if stimulus is visible
                if o.stimulusVisible
                    if mod(o.frameCounter, 2) == 0  
                        jitterRange = o.dotSize * 0.05;  % 5% of dot size
                        jitterX = randn * jitterRange;   % Random jitter
                        jitterY = randn * jitterRange;
                    
                        % Apply jitter ON TOP of manual movement
                        o.jitteredDotX = o.dotX + jitterX;
                        o.jitteredDotY = o.dotY + jitterY;
                    
                        % Ensure jitter stays within boundaries
                        o.jitteredDotX = max(o.boundaryStartX, min(o.boundaryEndX, o.jitteredDotX));
                        o.jitteredDotY = max(o.boundaryStartY, min(o.boundaryEndY, o.jitteredDotY));
                    else
                        % Keep the previous jittered position when not updating
                        o.jitteredDotX = o.dotX;
                        o.jitteredDotY = o.dotY;
                    end
        
                    alphaValue = round((o.dotAlpha / 100) * 255);

                    % Create color with alpha channel
                    dotColorWithAlpha = [o.dotColor, alphaValue];
                    Screen('FillOval', o.winPtr, dotColorWithAlpha, rect);
                end
                
                % Store stimulus position and timestamp
                o.stimTraceTime = [o.stimTraceTime; currentTime - o.startTime];  % Relative time
                o.stimTraceX = [o.stimTraceX; o.dotX];
                o.stimTraceY = [o.stimTraceY; o.dotY];

                % Flip screen to update drawing
                waitframes = 1;
                o.vbl = Screen('Flip', o.winPtr, o.vbl + (waitframes - 0.5) * o.ifi);
        
                return;
            end
            % Determine whether the target is on the East or West side
            if o.targetX > (o.boundaryStartX + o.boundaryEndX) / 2
                % Target is on the East → Set attraction zone at 60%
                attractionZoneX = o.boundaryStartX + 0.6 * (o.boundaryEndX - o.boundaryStartX);
            else
                % Target is on the West → Set attraction zone at 30%
                attractionZoneX = o.boundaryStartX + 0.3 * (o.boundaryEndX - o.boundaryStartX);
            end

            % Check if paused
            if o.paused
                [keyIsDown, ~, keyCode] = KbCheck;
            
                if keyIsDown
                    % Resume trial with 'R'
                    if keyCode(KbName('r')) && ~o.resumePressed
                        o.paused = false; % Unpause
                        o.resumePressed = true;
                        fprintf('Trial resumed.\n');
                    end
            
                    % Toggle stimulus ON/OFF with 'O'
                    if keyCode(KbName('o')) && ~o.showObjectPressed  % Ensures proper toggling
                        o.stimulusVisible = ~o.stimulusVisible;
                        fprintf('Stimulus toggled: %s\n', string(o.stimulusVisible));
                        o.showObjectPressed = true; % Prevents rapid toggling
                    end
            
                    % Enable/Disable flashing mode with 'F'
                    if keyCode(KbName('f')) && ~o.flashPressed  % Ensures proper toggling
                        o.flashingMode = ~o.flashingMode;
                        o.flashTime = GetSecs(); % Reset flash timer
                        fprintf('Flashing mode: %s\n', string(o.flashingMode));
                        o.flashPressed = true; % Prevents rapid toggling
                    end
                end
            
                % Reset key toggles when keys are released
                if ~keyCode(KbName('r'))
                    o.resumePressed = false;
                end
                if ~keyCode(KbName('o'))
                    o.showObjectPressed = false;
                end
                if ~keyCode(KbName('f'))
                    o.flashPressed = false;
                end
            
                % Flashing logic (if enabled)
                if o.flashingMode
                    if GetSecs() - o.flashTime >= 1 / o.flashFrequency  % Same as trial start
                        o.stimulusVisible = ~o.stimulusVisible; % Toggle visibility
                        o.flashTime = GetSecs(); % Update last toggle time
                    end
                end
            
                % Draw only if stimulus is visible
                if o.stimulusVisible
                    % Define stimulus rectangle 
                    rect = [o.dotX - o.dotSize / 2, o.dotY - o.dotSize / 2, ...
                            o.dotX + o.dotSize / 2, o.dotY + o.dotSize / 2];
            
                    if o.simpleMode
                        % Simple mode: White dot on black background
                        Screen('FillRect', o.winPtr, [0, 0, 0]); % Black background
                        if o.stimulusVisible  % Ensure stimulus disappears when flashing
                            Screen('FillOval', o.winPtr, [255, 255, 255], rect);
                        end
                    else
                        % Full stimulus mode (handles noise-based or solid dot)
                        if o.embedInNoise
                            % Regenerate noise texture if needed
                            baseNoise = 128 + (randn(o.dotSize, o.dotSize) * o.bgNoiseContrast * 255);
                            dotNoise = baseNoise + (o.dotNoiseContrast * 128);
                            dotNoise = uint8(min(max(dotNoise, 0), 255));
            
                            % Create circular alpha mask dynamically based on dotSize
                            [x, y] = meshgrid(1:o.dotSize, 1:o.dotSize);
                            center = o.dotSize / 2;
                            mask = uint8(((x - center).^2 + (y - center).^2) <= (center^2)) * 255; % Circle mask
            
                            % Convert to 4-channel (RGBA) texture dynamically
                            dotNoiseTexture = uint8(cat(3, dotNoise, dotNoise, dotNoise, mask));
            
                            % Create and draw the noise texture with an alpha mask
                            dotTexture = Screen('MakeTexture', o.winPtr, dotNoiseTexture);
                            Screen('DrawTexture', o.winPtr, dotTexture, [], rect);
                            Screen('Close', dotTexture);
                        else
                            % If not embedding in noise, draw a normal solid stimulus
                            Screen('FillOval', o.winPtr, o.dotColor, rect);
                        end
                    end
                end
            
                % Flip screen to update drawing
                waitframes = 1;
                o.vbl = Screen('Flip', o.winPtr, o.vbl + (waitframes - 0.5) * o.ifi);
            
                return; % Exit early to stay paused
            end

            % Check for key press
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                % Pause trial with 'P'
                if keyCode(KbName('p')) && ~o.pausePressed
                    o.paused = true; % Set paused state
                    o.pausePressed = true; % Prevent multiple toggles
                    fprintf('Trial paused.\n');
                end
                
                % Resume trial with 'R'
                if keyCode(KbName('r')) && ~o.resumePressed
                    fprintf('R key detected.\n');
                    o.paused = false; % Unpause trial
                    o.resumePressed = true; % Prevent multiple toggles
                    fprintf('Trial resumed.\n');
                end
                
                % Reset toggle flags when keys are released
                if ~keyCode(KbName('p'))
                    o.pausePressed = false;
                end
                if ~keyCode(KbName('r'))
                    o.resumePressed = false;
                end

            
                % Toggle manual mode with 'space'
                if keyCode(KbName('space')) && ~o.manualModePressed
                    o.manualMode = ~o.manualMode; % Toggle manual mode
                    o.manualModePressed = true; % Prevent multiple toggles from one press
            
                    if o.manualMode
                        fprintf('Manual control activated. Trial duration extended.\n');
                    else
                        fprintf('Manual control deactivated. Resuming trial timing.\n');
                    end
                elseif ~keyCode(KbName('space'))
                    o.manualModePressed = false; % Reset toggle when key is released
                end
            
                % Manually end trial with 'q'
                if keyCode(KbName('q')) && ~o.manualEnd
                    o.manualEnd = true; % Set flag to end trial
                    fprintf('Trial manually ended by user.\n');
                end

                % Manual movement with arrow keys
                if o.manualMode
                    if keyCode(KbName('DownArrow'))
                        o.dotX = o.dotX - o.dotSpeedX;
                    elseif keyCode(KbName('UpArrow'))
                        o.dotX = o.dotX + o.dotSpeedX;
                    elseif keyCode(KbName('LeftArrow'))
                        o.dotY = o.dotY - o.dotSpeedY;
                    elseif keyCode(KbName('RightArrow'))
                        o.dotY = o.dotY + o.dotSpeedY;
                    end
                end
                
                % Adjust X speed with A/D while maintaining direction
                if keyCode(KbName('d')) && ~o.xSpeedPressed
                    speedSign = sign(o.dotSpeedX); % Preserve current direction (+1 or -1)
                    o.dotSpeedX = speedSign * min(abs(o.dotSpeedX) + 1, 20);
                    fprintf('Increased X speed: %.1f\n', o.dotSpeedX);
                    o.xSpeedPressed = true;
                elseif keyCode(KbName('a')) && ~o.xSpeedPressed
                    speedSign = sign(o.dotSpeedX); % Preserve current direction
                    o.dotSpeedX = speedSign * max(abs(o.dotSpeedX) - 1, 1);
                    fprintf('Decreased X speed: %.1f\n', o.dotSpeedX);
                    o.xSpeedPressed = true;
                end
   
                % Adjust Y speed with W/S while maintaining direction
                if keyCode(KbName('w')) && ~o.ySpeedPressed
                    speedSign = sign(o.dotSpeedY); % Preserve current direction (+1 or -1)
                    o.dotSpeedY = speedSign * min(abs(o.dotSpeedY) + 1, 20);
                    fprintf('Increased Y speed: %.1f\n', o.dotSpeedY);
                    o.ySpeedPressed = true;
                elseif keyCode(KbName('s')) && ~o.ySpeedPressed
                    speedSign = sign(o.dotSpeedY); % Preserve current direction
                    o.dotSpeedY = speedSign * max(abs(o.dotSpeedY) - 1, 1);
                    fprintf('Decreased Y speed: %.1f\n', o.dotSpeedY);
                    o.ySpeedPressed = true;
                end

                % Adjust dot size with +/- keys (independent flag)
                if keyCode(KbName('=+')) && ~o.sizePressed  % '+' key
                    o.dotSize = min(o.dotSize + 2, 100);
                    fprintf('Increased dot size: %.1f\n', o.dotSize);
                    o.sizePressed = true;
                elseif keyCode(KbName('-_')) && ~o.sizePressed  % '-' key
                    o.dotSize = max(o.dotSize - 2, 5);
                    fprintf('Decreased dot size: %.1f\n', o.dotSize);
                    o.sizePressed = true;
                end
                
                % Reset flags when keys are released
                if ~keyCode(KbName('a')) && ~keyCode(KbName('d'))
                    o.xSpeedPressed = false;
                end
                if ~keyCode(KbName('w')) && ~keyCode(KbName('s'))
                    o.ySpeedPressed = false;
                end
                if ~keyCode(KbName('=+')) && ~keyCode(KbName('-_'))
                    o.sizePressed = false;
                end
            end

            if o.simpleMode
                % SIMPLE MODE: Black background + White dot              
                % Draw black background
                Screen('FillRect', o.winPtr, [0, 0, 0]);  
            
                % Draw white dot at its current position
                Screen('FillOval', o.winPtr, [255, 255, 255], ...
                    [o.dotX - o.dotSize / 2, o.dotY - o.dotSize / 2, ...
                     o.dotX + o.dotSize / 2, o.dotY + o.dotSize / 2]);
            else
                % FULL STIMULUS MODE
                % Generate background noise
                if o.bgNoise
                % Get full screen dimensions
                [screenXpixels, screenYpixels] = Screen('WindowSize', o.winPtr);
            
                % Generate full-screen Gaussian noise
                grayLevel = double(o.bgColor(1));
                noiseAmplitude = 128 * o.bgNoiseContrast;  % Scale amplitude
                noiseImage = grayLevel + noiseAmplitude .* randn(screenYpixels, screenXpixels);
                noiseImage = uint8(min(max(noiseImage, 0), 255)); % Clamp values
            
                % Create and draw noise texture over the entire screen
                noiseTexture = Screen('MakeTexture', o.winPtr, noiseImage);
                Screen('DrawTexture', o.winPtr, noiseTexture, [], []);
                Screen('Close', noiseTexture);
                else
                    Screen('FillRect', o.winPtr, o.bgColor);
                end
            end

            % Flashing and movement logic
            if o.flashing
                if currentTime - o.startTime >= o.flashDuration
                    o.flashing = false;
                    o.moving = true;
                    o.startTime = GetSecs();
                end
        
                if currentTime - o.lastFlashTime >= 1 / o.flashFrequency
                    o.flashVisible = ~o.flashVisible;
                    o.lastFlashTime = currentTime;
                end

            elseif o.moving
                if currentTime >= o.startTime + o.trialDuration
                    o.moving = false;
                end
        
                if o.manualMode
                    % Manual movement: Only allow movement from arrow keys
                    if keyCode(KbName('LeftArrow'))
                        o.dotX = o.dotX - o.dotSpeedX;
                    elseif keyCode(KbName('RightArrow'))
                        o.dotX = o.dotX + o.dotSpeedX;
                    elseif keyCode(KbName('UpArrow'))
                        o.dotY = o.dotY - o.dotSpeedY;
                    elseif keyCode(KbName('DownArrow'))
                        o.dotY = o.dotY + o.dotSpeedY;
                    end
                else
                    % Increment frame counter
                    frameCounter = frameCounter + 1;

                    % Dot movement generation
                    % Continuous movement in X direction
                    o.dotX = o.dotX + o.dotSpeedX;
                    
                    if o.pinkNoise
                        % Generate pink noise for movement
                        whiteNoise = randn(1,1); % Single-value noise
                        if mod(frameCounter, 2) == 0
                            noiseY = o.filter1f(whiteNoise); % Get pink noise value
                        end
                    else
                        % Use standard Gaussian white noise
                        if mod(frameCounter, 2) == 0  % Apply noise every 2 frames
                            noiseY = randn() * o.noiseAmplitude;
                        end
                    end
                    
                    % Apply pink noise to movement
                    if o.dotX >= attractionZoneX
                        % Apply a small drift toward targetY after crossing 60%
                        driftFactorY = max(0.005, min(0.02, abs(o.targetY - o.dotY) / 2000)); % Scale drift
                        o.dotY = o.dotY + (o.targetY - o.dotY) * driftFactorY + noiseY * o.noiseAmplitude;
                    else
                        % Normal noise-driven movement before 60% of the screen
                        o.dotY = o.dotY + o.dotSpeedY + noiseY * o.noiseAmplitude;
                    end
                    
                    % Invert the Y direction if stimulus touches boundary
                    if o.bounce
                        if o.dotY <= o.boundaryStartY + o.dotSize / 2 || o.dotY >= o.boundaryEndY - o.dotSize / 2
                            o.dotSpeedY = -o.dotSpeedY; % Reverse Y direction
                            noiseY = -noiseY; % Reverse noise effect to prevent immediate re-exit
                
                            % Prevent dot from getting stuck outside the boundary
                            o.dotY = max(min(o.dotY, o.boundaryEndY - o.dotSize / 2), o.boundaryStartY + o.dotSize / 2);
                        end
                    end
                end
            end

            % Draw dot if visible
            % Adjust dot color based on embedInNoise
            if o.embedInNoise
                % Blend stimulus into noise by setting a color close to the background
                noiseVariation = randn(1,3) * o.bgNoiseContrast * 255;
                o.dotColor = max(0, min(255, [128, 128, 128] + noiseVariation)); % Clamp values
            else
                % Standard stimulus drawing on top of noise
                o.dotColor = [0, 0, 0]; % Black dot
            end
            
            % Draw dot if visible
            if (o.flashing && o.flashVisible) || o.moving
                rect = [o.dotX - o.dotSize / 2, o.dotY - o.dotSize / 2, o.dotX + o.dotSize / 2, o.dotY + o.dotSize / 2];
            
                if ~o.simpleMode  % <-- Prevent any noise dot drawing if simpleMode is enabled
                    if o.embedInNoise
                        % Generate dot noise based on dotNoiseContrast
                        baseNoise = 128 + (randn(o.dotSize, o.dotSize) * o.bgNoiseContrast * 255);
                        
                        % Adjust contrast: -1 makes it darker, 1 makes it lighter, 0 keeps it the same
                        dotNoise = baseNoise + (o.dotNoiseContrast * 128);
                        
                        % Ensure values stay within valid range
                        dotNoise = uint8(min(max(dotNoise, 0), 255));
                        
                        % Create a circular alpha mask dynamically based on dotSize
                        [x, y] = meshgrid(1:o.dotSize, 1:o.dotSize);
                        center = o.dotSize / 2;
                        mask = uint8(((x - center).^2 + (y - center).^2) <= (center^2)) * 255; % Circle mask
                        
                        % Convert to 4-channel (RGBA) texture dynamically
                        dotNoiseTexture = uint8(cat(3, dotNoise, dotNoise, dotNoise, mask));
                        
                        % Create and draw the noise texture with an alpha mask
                        dotTexture = Screen('MakeTexture', o.winPtr, dotNoiseTexture);
                        Screen('DrawTexture', o.winPtr, dotTexture, [], rect);
                        Screen('Close', dotTexture); % Free memory
                    else
                        % Draw a solid black dot when not embedding in noise
                        Screen('FillOval', o.winPtr, [0, 0, 0], rect);
                    end
                end

            end
        
            % Draw boundaries for debugging
            if o.debugMode
                % Draw screen boundaries in white
                Screen('FrameRect', o.winPtr, [255, 255, 255], ...
                    [o.boundaryStartX, o.boundaryStartY, o.boundaryEndX, o.boundaryEndY], 2);
                
                % Draw the selected end zone in red
                xMin = o.targetX - o.targetSize / 2;
                xMax = o.targetX + o.targetSize / 2;
                yMin = o.targetY - o.targetSize / 2;
                yMax = o.targetY + o.targetSize / 2;
                
                Screen('FrameRect', o.winPtr, [255, 0, 0], [xMin, yMin, xMax, yMax], 3);
            end

            waitframes = 1; % Flip every frame
            o.vbl = Screen('Flip', o.winPtr, o.vbl + (waitframes - 0.5) * o.ifi);

            % Store stimulus position and timestamp
            o.stimTraceTime = [o.stimTraceTime; currentTime - o.startTime];  % Relative time
            o.stimTraceX = [o.stimTraceX; o.dotX];
            o.stimTraceY = [o.stimTraceY; o.dotY];

        end

        % Pass parameters through for next trial
        function P = next_trial(o, S, P)
        end

        % Eye tracing dummy data to avoid plot error
        function plot_trace(~, ~)
        end

%% Run end_run_trial
        function Iti = end_run_trial(o)
            Iti = 1;
            fprintf('Trial %d Ended - Final Speeds:\n', o.trialNumber);
            fprintf('  X Speed: %.1f\n', o.dotSpeedX);
            fprintf('  Y Speed: %.1f\n', o.dotSpeedY);

            % Create a table containing stimulus trace data
            stimTrace = table(o.stimTraceTime, o.stimTraceX, o.stimTraceY, ...
                  'VariableNames', {'Time', 'X', 'Y'});
            
            % Store it in combinedTrials
            o.combinedTrials(o.trialNumber).stimTrace = stimTrace;

            
            if ~isempty(o.trialData)
                trialData = o.trialData(o.trialNumber);
                save(fullFilePath, 'trialData');
            else
                warning('No trial data available to save.');
            end
        end

%% Run closeFunc
        function closeFunc(o) 
        end
    end
end
