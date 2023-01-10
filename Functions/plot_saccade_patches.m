
function plot_saccade_patches(pos_pre, pos_post, r, frame, patch_pre, patch_post)

    fov_rect_pre = foveal_poly(pos_pre, r);
    fov_rect_post = foveal_poly(pos_post, r);

    figure
    imagesc(frame)
    hold on
    plot(fov_rect_pre, 'EdgeColor', [0.85 0.9 0.05], 'FaceColor', [0.85 0.9 0.05], 'FaceAlpha', 0.3, 'LineWidth', 3)
    plot(fov_rect_post, 'EdgeColor', [0.8 0.8 0.8], 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.3, 'LineWidth', 3)

%     quiver(pos_pre(1), pos_pre(2), pos_post(1)-pos_pre(1), pos_post(2)-pos_pre(2), 0, ...
%         'LineWidth', 4, 'Color', [1 1 1], 'MaxHeadSize', 1)
    
    quiver(pos_pre(1), pos_pre(2), pos_post(1)-pos_pre(1), pos_post(2)-pos_pre(2), 0, ...
        'LineWidth', 3, 'Color', [0 0 0.3], 'MaxHeadSize', 1)
%     quiver(pos_pre(1), pos_pre(2), pos_post(1)-pos_pre(1), pos_post(2)-pos_pre(2), 0, ...
%         'LineWidth', 3, 'Color', [0, 0.3, 1], 'MaxHeadSize', 1)
%     0 0 0.3
%     0.15 0.8 1

    axis off

    figure
    imagesc(patch_pre)
    axis off
    axis square
    rectangle('Position', [1, 1, size(patch_pre,2)-1, size(patch_pre,1)-1], 'EdgeColor', [0.85 0.9 0.05], 'LineWidth', 10)

    figure
    imagesc(patch_post)
    axis off
    axis square
    rectangle('Position', [1, 1, size(patch_pre,2)-1, size(patch_pre,1)-1], 'EdgeColor', [0.8 0.8 0.8], 'LineWidth', 10)
    
    % Plot circles
    fov_circle_pre = poly_circle(pos_pre, r);
    fov_circle_post = poly_circle(pos_post, r);
    
    blue_col = [0.04 0.78 0.9];
    
    figure
    imagesc(frame)
    hold on
    plot(fov_circle_pre, 'EdgeColor', blue_col, 'FaceColor', blue_col, 'FaceAlpha', 0.2, 'LineWidth', 3)
    plot(fov_circle_post, 'EdgeColor', blue_col, 'FaceColor', blue_col, 'FaceAlpha', 0.2, 'LineWidth', 3)

    quiver(pos_pre(1), pos_pre(2), pos_post(1)-pos_pre(1), pos_post(2)-pos_pre(2), 0, ...
        'LineWidth', 4, 'Color', [1 1 1], 'MaxHeadSize', 1)
    
    quiver(pos_pre(1), pos_pre(2), pos_post(1)-pos_pre(1), pos_post(2)-pos_pre(2), 0, ...
        'LineWidth', 3, 'Color', [0, 0.3, 1], 'MaxHeadSize', 1)

    axis off
    
end