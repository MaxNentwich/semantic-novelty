  
function plot_trf_comparison(w, idx_sig, time, h, L, amplitude_scale, n_ch_max, font_size, out_file, x_label_str, varargin)

    w_sig = smooth_elec(w, idx_sig, h, L);

    w_sig = w_sig' ./ amplitude_scale;
    c = cluster_trf_results(w_sig');

    [~, idx_sort] = sort(c.clusters);

    %% Average
    figure('Position', [700,150,250,170])
    hold on
    
    if length(varargin) == 1
        
        colors = varargin{1};
        for k = 1:length(unique(c.clusters))
            plot(time, mean(w_sig(:, c.clusters == k), 2), 'Color', colors(k,:), 'LineWidth', 2)
        end
        
    else
        for k = 1:length(unique(c.clusters))
            plot(time, mean(w_sig(:, c.clusters == k), 2), 'LineWidth', 2)
        end
    end
    
    ylim([-2 1])
    plot([0 0], ylim, 'k--', 'LineWidth', 2)
    plot(time, zeros(size(time)), '--', 'LineWidth', 1.5, 'Color', 0.5*ones(3,1))
    
    set(gca, 'FontSize', font_size)
    
    ylabel('Avg.')
    
    yticklabels([])
    
    xlabel(x_label_str)
    
    ylim([-2 1])
    set(gcf, 'Position', [700,150,250,170])
    
    avg_file = strrep(out_file, '_norm', '_cluster_avg');
    saveas(gca, avg_file)
    saveas(gca, strrep(avg_file, '.png', '.fig'))

    %% All channels
    w_sig = zscore(w_sig(:, idx_sort));
    w_sig = w_sig - mean(w_sig(0.75*ceil(size(w_sig,1)):end, :));         

    c_range = max(abs(w_sig(:)));

    figure('Position', [700,450,250,300])
    imagesc([time(1), time(end)], [1, size(w_sig,2)], w_sig')
    colormap(flipud(othercolor('RdBu10')))
    
    hold on
    plot([0 0], ylim, 'k--', 'LineWidth', 2)

    caxis([-c_range, c_range])
    
    ylabel(sprintf('%i Channels', length(idx_sig)))
    
    yticklabels([])
    
    set(gca, 'FontSize', font_size)

    inner_pos = get(gca, 'InnerPosition');
    height = (inner_pos(4) - inner_pos(2)) * (length(idx_sig) / n_ch_max);
    border = (1 - height) / 2;
    
    inner_pos(2) = border;
    inner_pos(4) = height;

    set(gca, 'InnerPosition', inner_pos)
    
    set(gcf, 'Position', [700,450,250,300])
    
    saveas(gca, out_file)

end