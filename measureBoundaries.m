function measureBoundaries()

KbName('UnifyKeyNames');
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 1);  % Remove startup screens

% Open fullscreen window on your projector or arena display
[winPtr, windowRect] = Screen('OpenWindow', max(Screen('Screens')), [0, 0, 0]);

% Dot settings
dotSize = 20;
dotX = windowRect(3) / 2;
dotY = windowRect(4) / 2;

% Boundary defaults (full screen to start)
boundaryStartX = 0;
boundaryStartY = 0;
boundaryEndX = windowRect(3);
boundaryEndY = windowRect(4);

disp('Use Arrow Keys to move the dot.');
disp('Use W/A/S/D to adjust the visible boundaries.');
disp('Press Q to quit and save the boundary values.');

running = true;
stepSize = 1;

while running
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(KbName('LeftArrow'))
            dotX = max(dotX - 10, boundaryStartX);
        elseif keyCode(KbName('RightArrow'))
            dotX = min(dotX + 10, boundaryEndX);
        elseif keyCode(KbName('UpArrow'))
            dotY = max(dotY - 10, boundaryStartY);
        elseif keyCode(KbName('DownArrow'))
            dotY = min(dotY + 10, boundaryEndY);
        elseif keyCode(KbName('q'))  % Quit
            running = false;
        elseif keyCode(KbName('w'))  % Move top boundary down
            boundaryStartY = boundaryStartY + stepSize;
        elseif keyCode(KbName('s'))  % Move bottom boundary up
            boundaryEndY = boundaryEndY - stepSize;
        elseif keyCode(KbName('a'))  % Move left boundary right
            boundaryStartX = boundaryStartX + stepSize;
        elseif keyCode(KbName('d'))  % Move right boundary left
            boundaryEndX = boundaryEndX - stepSize;
        end
    end

    % Clamp the boundaries to prevent overlap
    boundaryStartX = min(max(boundaryStartX, 0), boundaryEndX - 10);
    boundaryStartY = min(max(boundaryStartY, 0), boundaryEndY - 10);
    boundaryEndX = max(min(boundaryEndX, windowRect(3)), boundaryStartX + 10);
    boundaryEndY = max(min(boundaryEndY, windowRect(4)), boundaryStartY + 10);

    % Draw visual boundary and dot
    Screen('FillRect', winPtr, [50, 50, 50]);
    Screen('FrameRect', winPtr, [255, 0, 0], [boundaryStartX, boundaryStartY, boundaryEndX, boundaryEndY], 5);
    Screen('FillOval', winPtr, [255, 255, 255], [dotX - dotSize / 2, dotY - dotSize / 2, dotX + dotSize / 2, dotY + dotSize / 2]);

    % Display text with current coordinates and boundaries
    infoText = sprintf('Dot X: %.0f, Y: %.0f\nStartX: %d, EndX: %d\nStartY: %d, EndY: %d', ...
        dotX, dotY, boundaryStartX, boundaryEndX, boundaryStartY, boundaryEndY);
    DrawFormattedText(winPtr, infoText, 20, 20, [255 255 255]);

    Screen('Flip', winPtr);
end

Screen('CloseAll');

% Save boundaries to workspace
measuredBoundaries = struct('startX', boundaryStartX, 'endX', boundaryEndX, 'startY', boundaryStartY, 'endY', boundaryEndY);
assignin('base', 'measuredBoundaries', measuredBoundaries);
disp('Measured boundaries saved to workspace as "measuredBoundaries".');
disp(measuredBoundaries);

end
