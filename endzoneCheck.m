function endzoneCoords = endzoneCheck()
    % Clear everything
    sca; % Close any open Psychtoolbox screens
    clear;
    clc;

    % Initialize Psychtoolbox
    PsychDefaultSetup(2);
    screenNumber = max(Screen('Screens'));
    [winPtr, windowRect] = PsychImaging('OpenWindow', screenNumber, [0 0 0]); % Black background

    % Screen dimensions
    [screenXpixels, screenYpixels] = Screen('WindowSize', winPtr);

    % Initial box settings
    boxWidth = 100; % Default width
    boxHeight = 100; % Default height
    moveSpeed = 10; % Movement speed
    resizeSpeed = 1; % Resize step size

    % Box colors and names
    boxColors = {[255 0 0], [0 0 255], [0 255 0], [255 255 0]}; % Red, Blue, Green, Yellow
    boxNames = {'Red', 'Blue', 'Green', 'Yellow'};

    % Starting positions (each centered at different quadrants)
    boxPositions = [
        screenXpixels * 0.3, screenYpixels * 0.3; % Red
        screenXpixels * 0.7, screenYpixels * 0.3; % Blue
        screenXpixels * 0.3, screenYpixels * 0.7; % Green
        screenXpixels * 0.7, screenYpixels * 0.7  % Yellow
    ];

    % Storage for final positions
    endzoneCoords = zeros(4, 4); % [X, Y, Width, Height] for each box

    % Unify key names
    KbName('UnifyKeyNames');

    % Skip start screen → Immediately start setting the first box
    lastKeyPressTime = GetSecs(); % Prevents immediate multi-presses

    % Loop through all 4 boxes
    for i = 1:4
        currentX = boxPositions(i, 1);
        currentY = boxPositions(i, 2);
        currentWidth = boxWidth;
        currentHeight = boxHeight;
        currentColor = boxColors{i};

        fprintf('Setting %s Box: Move with WASD, Resize Width with Left/Right Arrows, Resize Height with Up/Down Arrows, Press N to Set\n', boxNames{i});

        boxSet = false;
        while ~boxSet
            % Check for key press
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                % Move box with WASD
                if keyCode(KbName('a'))
                    currentX = max(currentX - moveSpeed, currentWidth / 2);
                elseif keyCode(KbName('d'))
                    currentX = min(currentX + moveSpeed, screenXpixels - currentWidth / 2);
                elseif keyCode(KbName('w'))
                    currentY = max(currentY - moveSpeed, currentHeight / 2);
                elseif keyCode(KbName('s'))
                    currentY = min(currentY + moveSpeed, screenYpixels - currentHeight / 2);
                end

                % Resize width with Left/Right Arrow Keys
                if keyCode(KbName('RightArrow'))
                    currentWidth = min(currentWidth + resizeSpeed, screenXpixels);
                elseif keyCode(KbName('LeftArrow'))
                    currentWidth = max(currentWidth - resizeSpeed, 20);
                end

                % Resize height with Up/Down Arrow Keys
                if keyCode(KbName('UpArrow'))
                    currentHeight = min(currentHeight + resizeSpeed, screenYpixels);
                elseif keyCode(KbName('DownArrow'))
                    currentHeight = max(currentHeight - resizeSpeed, 20);
                end

                % Prevent multiple presses on 'N' (0.5s timeout)
                if keyCode(KbName('n')) && (GetSecs() - lastKeyPressTime > 0.5)
                    boxSet = true;
                    lastKeyPressTime = GetSecs(); % Reset timeout
                    fprintf('%s Box Set at X=%.2f, Y=%.2f, Width=%.2f, Height=%.2f\n', boxNames{i}, currentX, currentY, currentWidth, currentHeight);
                    endzoneCoords(i, :) = [currentX, currentY, currentWidth, currentHeight];
                end

                % Exit the script early with 'Q'
                if keyCode(KbName('q'))
                    fprintf('Exiting early. Any unset boxes will remain at defaults.\n');
                    sca;
                    return;
                end
            end

            % Define the box rectangle
            boxRect = CenterRectOnPointd([0, 0, currentWidth, currentHeight], currentX, currentY);

            % Draw the box
            Screen('FillRect', winPtr, currentColor, boxRect);
            Screen('Flip', winPtr);
        end
    end

    % Close screen and return final positions
    sca;
    fprintf('Final Endzone Coordinates:\n');
    for i = 1:4
        fprintf('%s Box: X=%.2f, Y=%.2f, Width=%.2f, Height=%.2f\n', boxNames{i}, endzoneCoords(i, 1), endzoneCoords(i, 2), endzoneCoords(i, 3), endzoneCoords(i, 4));
    end
end
