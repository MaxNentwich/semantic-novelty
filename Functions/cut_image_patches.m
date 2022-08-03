%% Cut image patches

function [fovea_pre, fovea_post] = cut_image_patches(pos_pre, pos_post, frame_pre, frame_post, r)

    % Find the patch cooordinates
    [patch_coord_pre, pad_pre] = patch_size(pos_pre, r, frame_pre);
    [patch_coord_post, pad_post] = patch_size(pos_post, r, frame_post);

    % Cut the patch
    fovea_pre = frame_pre(patch_coord_pre(1):patch_coord_pre(2), patch_coord_pre(3):patch_coord_pre(4), :);
    fovea_post = frame_post(patch_coord_post(1):patch_coord_post(2), patch_coord_post(3):patch_coord_post(4), :);

    % Pad the image if it is on the edges
    fovea_pre = cat(1, zeros(round(pad_pre(1)), size(fovea_pre,2), size(fovea_pre,3)), ...
        fovea_pre, zeros(round(pad_pre(2)), size(fovea_pre,2), size(fovea_pre,3)));
    fovea_pre = cat(2, zeros(size(fovea_pre,1), round(pad_pre(3)), size(fovea_pre,3)), ...
        fovea_pre, zeros(size(fovea_pre,1), round(pad_pre(4)), size(fovea_pre,3)));

    fovea_post = cat(1, zeros(round(pad_post(1)), size(fovea_post,2), size(fovea_post,3)), ...
        fovea_post, zeros(round(pad_post(2)), size(fovea_post,2), size(fovea_post,3)));
    fovea_post = cat(2, zeros(size(fovea_post,1), round(pad_post(3)), size(fovea_post,3)), ...
        fovea_post, zeros(size(fovea_post,1), round(pad_post(4)), size(fovea_post,3)));
    
end