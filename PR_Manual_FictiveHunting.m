classdef PR_Manual_FictiveHunting < protocols.protocol
    % Fully manual control protocol for user-directed simulus positioning.
    % This protocol removes automated movement, relying on user input.
    % Controls:
    % 'B' - Begin trial
    % 'Q' - End trial 
    % 'F' - Toggle flashing stimulus
    % 'O' - Toggle visible stimulus
    % 'C' - Toggle black or white stimulus
    % 'J'/'K' - +/- Stumulus opacity
    % 'T'/'Y' - +/- Background noise level
    % Arrow Keys - Manual control of stimulus
    % 'A'/'D' - +/- Dot X speed
    % 'W'/'S' - +/- Dot  Y speed
    % '=+'/'-_' - +/- Dot size

    
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
        boundaryStartX double = 150;
        boundaryStartY double = 610;
        boundaryEndX double = 1116;
        boundaryEndY double = 1068;
        noiseAmplitude double = 2;
        trialDuration double = 10;
        moving logical = false;
        bgNoise logical = true;
        pinkNoise logical = true; % Default to 1/f (pink) noise
        bgColor = [128, 128, 128]; % Default to mid grey
        bgNoiseContrast double = 0.1;

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

        endZones double % Stores predefined end zone positions (4x3 matrix)

        paused logical = false;
        pausePressed logical = false; % Prevents multiple pause toggles
        resumePressed logical = false; % Prevents multiple resume toggles
        showObjectPressed logical = false;  % Tracks if 'O' key was pressed to toggle stimulus visibility
        flashPressed logical = false;       % Tracks if 'F' key was pressed to toggle flashing mode
        stimulusVisible logical = true;  % Controls whether the stimulus is drawn when paused
        flashingMode logical = false;    % Determines if stimulus should flash
        flashTime double = 0;            % Tracks the last time flash was toggled
        flashInterval double = 0.5;      % Time between flashes (adjust as needed)

        rewardTimes double = [];

        xSpeedPressed logical = false; % Prevents rapid changes to X speed
        ySpeedPressed logical = false; % Prevents rapid changes to Y speed
        sizePressed logical = false; % Prevents rapid size changes

        manualStart logical = false;       % Tracks if 'B' was pressed to start trial
        manualMode logical = false;        % Tracks if manual mode is enabled
        manualModePressed logical = false; % Prevents multiple toggles per key press
        manualEnd logical = false;         % Tracks if 'Q' was pressed to end the trial

        trialEnded logical = false; % Prevents duplicate end messages
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
        function o = PR_Manual_FictiveHunting(winPtr)
            o = o@protocols.protocol(winPtr);
        end
        
        function initFunc(o, S, P)
            fprintf('Initializing PR_StimulusDotMove_MarmoView...\n');
            o.combinedTrials = struct();  % Empty struct to hold all trial data
            o.stimTrace
            KbName('UnifyKeyNames');

            % Debugging
            o.manualTrials = true; % Hard code to enable manual trials

            o.dotSize = P.dotSize;
            o.dotSpeedX = P.dotSpeedX;
            o.dotSpeedY = P.dotSpeedY;

            % Initialize stimulus trace data storage
            o.stimTraceTime = [];
            o.stimTraceX = [];
            o.stimTraceY = [];

            o.trialDuration = P.trialDuration;
            o.noiseAmplitude = P.noiseAmplitude;
            o.bgNoise = logical(P.bgNoise);
            o.bgNoiseContrast = P.bgNoiseContrast;

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
            o.boundaryStartX = 0;
            o.boundaryStartY = 168;
            o.boundaryEndX = 1920;
            o.boundaryEndY = 1080;

            % Set start position
            o.startSW = P.startSW;
            o.startSE = P.startSE;
            o.startNW = P.startNW;
            o.startNE = P.startNE;
            
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
            o.rewardTimes = [];
        
        
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
                    fprintf(' C - Toogle black or white dot\n');
                    fprintf(' F - Toggle flashing stimulus\n');
                    fprintf(' O - Toggle visible stimulus\n');
                    fprintf(' W/S - Increase/Decrease dot Y speed\n');
                    fprintf(' A/D - Decrease/Increase dot X speed\n');
                    fprintf(' J/K - Decrease/Increase dot opacity\n');
                    fprintf(' T/Y - Decrease/Increase background noise level\n');
                    fprintf(' Arrow Keys - Move stimulus manually\n');
                    fprintf('======================\n\n');
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

                    % Save reward time with R
                    if keyCode(KbName('r'))
                        rewardTime = GetSecs() - o.startTime; % Record relative to trial start
                        o.rewardTimes = [o.rewardTimes, rewardTime];  % Append time
                        fprintf('Reward delivered at %.3f seconds.\n', rewardTime);
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
                    if mod(frameCounter, 2) == 0  
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

                    % Generate stimulus rectangle
                    rect = [o.dotX - o.dotSize / 2, o.dotY - o.dotSize / 2, ...
                            o.dotX + o.dotSize / 2, o.dotY + o.dotSize / 2];

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
        end

        %% Pass parameters through for next trial
        function P = next_trial(o, S, P)
        end

        %% Eye tracing dummy data to avoid plot error
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

        end

        %% Run closeFunc
        function closeFunc(o) 
        end
    end
end