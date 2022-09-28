
function plot_sig_bars(p_vals, x_pos, y_pos, v_space)

    if p_vals < 0.05
        
        % Plot a line between the center of the bar
        plot(x_pos, [y_pos y_pos], 'k', 'LineWidth', 1.5, 'HandleVisibility','off')
        plot([x_pos(1), x_pos(1)], [y_pos y_pos-v_space], 'k', 'LineWidth', 1.5, 'HandleVisibility','off')
        plot([x_pos(2), x_pos(2)], [y_pos y_pos-v_space], 'k', 'LineWidth', 1.5, 'HandleVisibility','off')
        
    end
    
end