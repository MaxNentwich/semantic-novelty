
function idx_sort = plot_trf_cluster(w_1, w_2, time, line_style, color_1, color_2, trf_font, ...
    filt_dir, region, condition_1, condition_2, condition_sig)

    c = cluster_trf_results(w_1);
    [~, idx_sort] = sort(c.clusters);

    figure('Position', [700,150,250,170])
    hold on
    for k = 1:length(unique(c.clusters))
        plot(time, mean(w_1(c.clusters == k, :)), 'LineWidth', 2, 'LineStyle', line_style{k}, 'Color', color_1)
    end

    y_lims = ylim;

    plot([0 0], ylim, 'k--', 'LineWidth', 2)
    plot(time, zeros(size(time)), '--', 'LineWidth', 1.5, 'Color', 0.5*ones(3,1))

    set(gca, 'FontSize', trf_font)
    ylabel('Avg.')
    yticklabels([])
    xlabel('Time [s]')

    ylim(y_lims)
    set(gcf, 'Position', [700,150,250,170])
    
    saveas(gca, sprintf('%s/%s_cluster_trf_%s_sig_%s.fig', filt_dir, region, condition_1, condition_sig))
    saveas(gca, sprintf('%s/%s_cluster_trf_%s_sig_%s.png', filt_dir, region, condition_1, condition_sig))
    

    figure('Position', [700,150,250,170])
    hold on
    for k = 1:length(unique(c.clusters))
        plot(time, mean(w_2(c.clusters == k, :)), 'LineWidth', 2, 'LineStyle', line_style{k}, 'Color', color_2)
    end

    ylim(y_lims)
    plot([0 0], ylim, 'k--', 'LineWidth', 2)
    plot(time, zeros(size(time)), '--', 'LineWidth', 1.5, 'Color', 0.5*ones(3,1))

    set(gca, 'FontSize', trf_font)
    ylabel('Avg.')
    yticklabels([])
    xlabel('Time [s]')

    ylim(y_lims)
    
    set(gcf, 'Position', [700,150,250,170])

    saveas(gca, sprintf('%s/%s_cluster_trf_%s_sig_%s.fig', filt_dir, region, condition_2, condition_sig))
    saveas(gca, sprintf('%s/%s_cluster_trf_%s_sig_%s.png', filt_dir, region, condition_2, condition_sig))
                
end