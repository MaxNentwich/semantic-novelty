        
function plot_elecs_response_amplitude(options, w_condition, labels_condition, labels_all, loc_all, h, feature_str, band_idx, ...
    plot_type, visualize_fwhm, varargin)

    % Overwrite the base filename
    options.fig_features.file_name = sprintf('spatial_feature_comparison_%s', plot_type);
    
    files = dir(options.fig_features.out_dir);
    idx_file = cellfun(@(C) contains(C, sprintf('%s_%s', options.fig_features.file_name, feature_str)), {files.name});
        
    % Directory for counts of channels with postive or negative responses
    data_dir = sprintf('%s/feature_response_amplitude', options.im_data_dir);
    if exist(data_dir, 'dir') == 0, mkdir(data_dir), end
    
    if sum(idx_file) == 0

        %% Determine response amplitude and duration

        % Find significant responses
        w_scenes_sig = smooth_elec(w_condition,  ismember(labels_all, labels_condition), h, options.smoothing_L);
        [~, idx_max_scenes] = max(abs(w_scenes_sig), [], 2);

        %% Get the amplitude at the extremum (positive or negative)
        resp_amp = w_scenes_sig(sub2ind(size(w_scenes_sig), [1:length(idx_max_scenes)]', idx_max_scenes));

        %% Find the onset using full-with-half-max
        resp_onset = nan(length(resp_amp), 1);
        
        time = options.trf_window(1):1/options.fs_ana:options.trf_window(2);
            
        for i = 1:length(resp_amp)
            
            % Plot the response, peak and half-max threshold
            if visualize_fwhm
                figure 
                hold on
                plot(w_scenes_sig(i,:))
                plot(idx_max_scenes(i), resp_amp(i), '*')
                plot(xlim, resp_amp(i)/2*[1 1])
            end
            
            % Find samples above the half-max threshold
            idx_peak = abs(w_scenes_sig(i,:)) > abs(resp_amp(i)/2);
            
            % Morphological filling of holes to connect peaks and throughs in bimodal responses
            idx_peak = conv(idx_peak, ones(0.3*options.fs_ana,1), 'same') > 0;     
            idx_neg = conv(idx_peak == 0, ones(0.3*options.fs_ana,1), 'same') ~= 0;
            idx_neg = [0, idx_neg(1:end-1)];
            idx_peak(idx_peak & idx_neg) = 0;
                        
            % Find the cluster around the max/min
            clusters = bwlabel(idx_peak);
            cluster_peak = clusters(idx_max_scenes(i));
            clusters(clusters ~= cluster_peak) = 0;
            idx_peak(clusters == 0) = 0;
            
            % Plot the with around the maximum 
            if visualize_fwhm
                plot(idx_peak * max(w_scenes_sig(i,:)))
                pause
            end
            
            % Find onset and duration
            resp_onset(i) = time(find(idx_peak, 1, 'first'));
    
        end
        
        %% Get the ratio of positive and negative responses overall and per brain area
        % Find location for current condition 
        loc_condition = loc_all(ismember(labels_all, labels_condition), :);
        regions = unique(loc_condition);
        
        % Exclude unknown channels
        if ~options.inlude_unknown, regions(ismember(regions, 'Unknown')) = []; end
        
        % Find the number of positve and negative responses in each region
        n_pos = zeros(1, length(regions));
        n_neg = zeros(1, length(regions));
        n_all = zeros(1, length(regions));
        
        for r = 1:length(regions)
            idx_region = sum(ismember(loc_condition, regions{r}), 2) >= options.loc_confidence;
            n_pos(r) = sum(resp_amp(idx_region) > 0);
            n_neg(r) = sum(resp_amp(idx_region) <= 0);
            n_all(r) = length(resp_amp(idx_region));
        end
        
        % Save the data
        save(sprintf('%s/amplitude_%s_pos_neg.mat', data_dir, feature_str), 'n_pos', 'n_neg', 'n_all', 'regions', 'resp_amp')

        %% Make the figure

        % Get the electrode location and assing colors to individual electrodes
        if strcmp(plot_type, 'amplitude')
            [avg_coords, is_left, elec_names, resp_elec] = load_fsaverage_coords(labels_condition, resp_amp);
            if isempty(varargin)
                c_lims = [-max(abs(resp_amp)), max(abs(resp_amp))];
            else
                c_lims = varargin{1};
            end
        elseif strcmp(plot_type, 'onset')
            [avg_coords, is_left, elec_names, resp_elec] = load_fsaverage_coords(labels_condition, resp_onset);
            if isempty(varargin)
                c_lims = [-max(abs(resp_onset)), max(abs(resp_onset))];
            else
                c_lims = varargin{1};
            end
        elseif strcmp(plot_type, 'onset_positive')
            [avg_coords, is_left, elec_names, resp_elec] = load_fsaverage_coords(labels_condition(resp_amp > 0), ...
                resp_onset(resp_amp > 0));
            if isempty(varargin)
                c_lims = [-max(abs(resp_onset)), max(abs(resp_onset))];
            else
                c_lims = varargin{1};
            end
        elseif strcmp(plot_type, 'onset_negative')
            [avg_coords, is_left, elec_names, resp_elec] = load_fsaverage_coords(labels_condition(resp_amp < 0), ...
                resp_onset(resp_amp < 0));
            if isempty(varargin)
                c_lims = [-max(abs(resp_onset)), max(abs(resp_onset))];
            else
                c_lims = varargin{1};
            end
        end
        
        % Scale the color values
        color_axis = othercolor('BuDRd_18');
        col_plot_elec = resp_elec / max(abs(c_lims)) * (length(color_axis)/2) + (length(color_axis)/2);
   
        % Edit file name
        file_name_base = options.fig_features.file_name;
        options.fig_features.file_name = sprintf('%s_%s_%s_n_%i', ...
            file_name_base, feature_str, options.band_select{band_idx}, length(elec_names));
        
        % Edit electrode size
        options.fig_features.elec_size = 14;

        % Make the figure
        plot_sig_elecs(avg_coords, is_left, elec_names, col_plot_elec, options.fig_features, 1, color_axis, ...
        c_lims)
    
    end
    
end        