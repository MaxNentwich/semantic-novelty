               
function plot_trf_image(w, time, c_range, n_sig, n_ch_max, font_size, filt_dir, region, condition, condition_sig)

    w = bsxfun(@minus, w, mean(w(0.75*ceil(size(w,1)):end, :))); 

    figure('Position', [700,450,250,300])
    imagesc([time(1), time(end)], [1, n_sig], w')
    colormap(flipud(othercolor('RdBu10')))

    hold on
    plot([0 0], ylim, 'k--', 'LineWidth', 2)

    caxis([-c_range, c_range])

    ylabel(sprintf('N=%i', n_sig))

    yticklabels([])

    set(gca, 'FontSize', font_size)

    inner_pos = get(gca, 'InnerPosition');
    height = (inner_pos(4) - inner_pos(2)) * (n_sig / n_ch_max);
    border = (1 - height) / 2;

    inner_pos(2) = border;
    inner_pos(4) = height;

    set(gca, 'InnerPosition', inner_pos)

    set(gcf, 'Position', [700,450,250,300])
    
    saveas(gca, sprintf('%s/%s_filters_trf_%s_sig_%s.fig', filt_dir, region, condition, condition_sig))
    saveas(gca, sprintf('%s/%s_filters_trf_%s_sig_%s.png', filt_dir, region, condition, condition_sig))
    
end