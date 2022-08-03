  
function plot_filters_2_conditions(w_1, w_2, time, idx_sig, h, L, n_ch_max, line_style, color_high, color_low, trf_font, ...
    filt_dir, region, condition_1, condition_2, condition_sig)
                
    % Smooth the filters
    w_1_sig = smooth_elec(w_1, idx_sig, h, L);
    w_2_sig = smooth_elec(w_2, idx_sig, h, L);

    % Cluster and plot the average
    idx_sort_sig = plot_trf_cluster(w_1_sig, w_2_sig, time, line_style, color_high, color_low, trf_font, filt_dir, ...
        region, condition_1, condition_2, condition_sig);

    % Normalize channels 
    std_high = std(w_1_sig,0,2)';
    w_1_sig = bsxfun(@minus, w_1_sig', mean(w_1_sig,2)'); 
    w_1_sig = bsxfun(@rdivide, w_1_sig, std_high);

    w_2_sig = bsxfun(@minus, w_2_sig', mean(w_2_sig,2)'); 
    w_2_sig = bsxfun(@rdivide, w_2_sig, std_high);

    % Plot all responses 
    w_all = [w_1_sig, w_2_sig];
    c_range = max(abs(w_all(:)));
    plot_trf_image(w_1_sig(:,idx_sort_sig), time, c_range, sum(idx_sig), n_ch_max, trf_font, filt_dir, region, condition_1, condition_sig)
    plot_trf_image(w_2_sig(:,idx_sort_sig), time, c_range, sum(idx_sig), n_ch_max, trf_font, filt_dir, region, condition_2, condition_sig)
    
end             