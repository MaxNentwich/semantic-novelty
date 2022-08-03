%% Find the radius of the foveal field of view on the screen
function r = foveal_r(options, eye)

    % Get the average distance of the eye to the screen
    eye_pos_left = eye.left(1:3, :);
    gaze_pos_left = eye.left(9:11, :);
    val_left = eye.left(13,:);
    dist_left = mean(sqrt(sum((eye_pos_left(:, val_left <= 0) ... 
                             - gaze_pos_left(:, val_left <= 0)).^2)));

    eye_pos_right = eye.right(1:3, :);
    gaze_pos_right = eye.right(9:11, :);
    val_right = eye.right(13,:);
    dist_right = mean(sqrt(sum((eye_pos_right(:, val_right <= 0) ... 
                              - gaze_pos_right(:, val_right <= 0)).^2)));

    dist = mean([dist_left, dist_right]);

    % Compute the radius of the foveal field in mm
    r = dist * tan(deg2rad(options.alpha_fovea)/2);

    % Convert to pixels on the screen
    pix2mm = mean(options.screen_size./options.screen_dimension);
    r = r * pix2mm;
    
end