
function plot_sig_bars(p_vals, x_pos, y_pos, h_space, v_space)

    if p_vals < 0.05
        % Plot a line between the center of the bar
        star_pos = x_pos(1) + diff(x_pos)/2;
        plot(x_pos, [y_pos y_pos], 'k', 'LineWidth', 2, 'HandleVisibility','off')
        % Plot 1 star
        if p_vals >= 0.01
            plot(star_pos, y_pos+v_space, 'k*', 'HandleVisibility','off')
        end
    end

    % Plot 2 stars
    if p_vals < 0.01 && p_vals >= 0.001
        plot([star_pos - h_space, star_pos + h_space], y_pos+v_space, 'k*', 'HandleVisibility','off')
    end
    
    % Plot 3 stars
    if p_vals < 0.001
        plot([star_pos - (2*h_space), star_pos, star_pos + (2*h_space)], y_pos+v_space, 'k*', 'HandleVisibility','off')
    end
    
end