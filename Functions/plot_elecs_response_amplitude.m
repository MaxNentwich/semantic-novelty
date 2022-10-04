        
function plot_elecs_response_amplitude(options, w_condition, labels_condition, labels_all, h, feature_str, band_idx)

    % Overwrite the base filename
    options.fig_features.file_name = 'spatial_feature_comparison_amplitude';
    
    files = dir(options.fig_features.out_dir);
    idx_file = cellfun(@(C) contains(C, sprintf('%s_%s', options.fig_features.file_name, feature_str)), {files.name});
        
    if sum(idx_file) == 0

        %% Determine whether response amplitudes are postivie or negative 

        % Find significant responses
        w_scenes_sig = smooth_elec(w_condition,  ismember(labels_all, labels_condition), h, options.smoothing_L);
        [~, idx_max_scenes] = max(abs(w_scenes_sig), [], 2);

        % Get the amplitude at the extremum (positive or negative)
        resp_amp = w_scenes_sig(sub2ind(size(w_scenes_sig), [1:length(idx_max_scenes)]', idx_max_scenes));

        % Overwrite the filename
        options.fig_features.file_name = 'spatial_feature_comparison_amplitude';

        %% Make the figure
        
        % Get the electrode location and assing colors to individual electrodes
        [avg_coords, is_left, elec_names, resp_amp_elec] = load_fsaverage_coords(labels_condition, resp_amp);

        % Scale the color values
        color_axis = othercolor('BuDRd_18');
        col_plot_elec = resp_amp_elec / max(abs(resp_amp_elec)) * (length(color_axis)/2) + (length(color_axis)/2);
        
        % Edit file name
        file_name_base = options.fig_features.file_name;
        options.fig_features.file_name = sprintf('%s_%s_%s_n_%i', ...
            file_name_base, feature_str, options.band_select{band_idx}, length(elec_names));

        % Make the figure
        plot_sig_elecs(avg_coords, is_left, elec_names, col_plot_elec, options.fig_features, 1, color_axis, ...
        [-max(abs(resp_amp)), max(abs(resp_amp))])
    
    end
    
end        