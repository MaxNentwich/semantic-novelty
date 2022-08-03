
function plot_elec_low_features(options, labels, plot_color, feature_str, band_idx)

    files = dir(options.fig_features.out_dir);
    idx_file = cellfun(@(C) contains(C, sprintf('%s_%s', options.fig_features.file_name, feature_str)), {files.name});
        
    if sum(idx_file) == 0
    
        [avg_coords, is_left, elec_names] = load_fsaverage_coords(labels);

        file_name_base = options.fig_features.file_name;
        options.fig_features.file_name = sprintf('%s_%s_%s_n_%i', ...
            file_name_base, feature_str, options.band_select{band_idx}, length(elec_names));

        close all
        plot_sig_elecs(avg_coords, is_left, elec_names, ones(size(elec_names)), ...
            options.fig_features, 1, plot_color)
    
    end

end