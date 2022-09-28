
function plot_saccades_novelty(options)

    % Save options from the main file 
    options_main = options;
    
    % Output directory
    out_dir = sprintf('%s/saccades_novelty', options.fig_dir);
    if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
    
    % Directory for stats
    data_dir = sprintf('%s/statistics', options_main.im_data_dir);
    if exist(data_dir, 'dir') == 0, mkdir(data_dir), end
    
    for b = 1:length(options.band_select)
        
        % Find the index of the selected frequency band
        idx_band = find(ismember(options_main.band_names, options_main.band_select{b}));

        if strcmp(options_main.band_select{b}, 'raw')
            lambda = options_main.lambda_raw;
        else
            lambda = options_main.lambda_bands(idx_band);
        end

        % Define the data file 
        [labels_str, vid_label] = trf_file_parts(options_main); 

        vid_file = sprintf('%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
            vid_label, labels_str, options_main.band_select{b}, options_main.fs_ana, lambda, options_main.n_shuff);

        %% Load the data
        stats_dir = sprintf('%s/stats', options_main.im_data_dir);

        if exist(sprintf('%s/%s', stats_dir, vid_file), 'file') ~= 0

            load(sprintf('%s/%s', options_main.stats_data, vid_file), 'w_all', 'sig_all', 'p_all', 'labels_all', 'options')

            %% Parse data for the different stimuli
            idx_high = find(ismember(options.stim_select, 'saccades_high_novelty'));
            idx_low = find(ismember(options.stim_select, 'saccades_low_novelty'));

            w_high = w_all{idx_high};
            w_low = w_all{idx_low};

            %% Correct for multiple comparisons with FDR
            [~, sig_high] = fdr_corr(p_all{idx_high}, sig_all{idx_high});
            [~, sig_low] = fdr_corr(p_all{idx_low}, sig_all{idx_low});

            %% Remove the saccdic spikes from the data
            spike_dir = sprintf('%s/saccadic_spike', out_dir);
            if exist(spike_dir, 'dir') == 0, mkdir(spike_dir), end

            spike_file_high = sprintf('%s/spike_idx_faces_%s%s.mat', spike_dir, labels_str, vid_label);
            spike_file_low = sprintf('%s/spike_idx_matched_%s%s.mat', spike_dir, labels_str, vid_label);
            
            % Index of significant channels
            idx_sig_high = find(sum(sig_high,2) ~= 0);
            idx_sig_low = find(sum(sig_low,2) ~= 0);
            
            idx_spike_high = remove_sacc_spike(options_main, w_high, idx_sig_high, spike_dir, spike_file_high);
            idx_spike_low = remove_sacc_spike(options_main, w_low, idx_sig_low, spike_dir, spike_file_low);
            
            % Remove the spikes
            sig_high(idx_sig_high(idx_spike_high), :) = zeros(sum(idx_spike_high), size(sig_high,2));
            sig_low(idx_sig_low(idx_spike_low), :) = zeros(sum(idx_spike_low), size(sig_low,2));
            
            %% Bar plot to summarize ratio of responsive electrodes per area
            labels_high = labels_all(sum(sig_high,2) ~= 0);
            labels_low = labels_all(sum(sig_low,2) ~= 0);
            
            % Find shared an unique electrodes
            labels_all_sig = unique([labels_high; labels_low]);

            labels_shared = labels_high(ismember(labels_high, labels_low));
            labels_high = labels_high(~ismember(labels_high, labels_shared));
            labels_low = labels_low(~ismember(labels_low, labels_shared));

            % Localize electrodes
            [n_lobes_all, n_lobes_all_sig, n_lobes_high, n_lobes_low, n_lobes_shared, regions, patients, loc_all] = ...
                localize_elecs_patient(labels_all, labels_all_sig, labels_high, labels_low, labels_shared, options_main.atlas);
                     
            %% Stats
            jaccard_dist = 1 - (n_lobes_shared ./ sum(cat(3, n_lobes_high, n_lobes_low, n_lobes_shared), 3));

            if strcmp(options_main.atlas, 'lobes')
                
                shuffle_file = sprintf('%s/saccade_novelty_shuffle.mat', data_dir);
                
                if exist(shuffle_file, 'file') == 0
                    jaccard_shuff_median = specificity_permutation(labels_all_sig, options_main.atlas, 1e3);
                    save(shuffle_file, 'jaccard_shuff_median')
                else
                    load(shuffle_file, 'jaccard_shuff_median')
                end
                
            else
                jaccard_shuff_median = zeros(size(jaccard_dist));
            end
            
            [regions, jaccard_dist, jaccard_shuff_median, n_lobes_all_sig, n_lobes_high, n_lobes_shared, n_lobes_low, n_lobes_all] = ...
                remove_areas(options_main, regions, jaccard_dist, jaccard_shuff_median, ...
                n_lobes_all_sig, n_lobes_high, n_lobes_shared, n_lobes_low, n_lobes_all);
            
            % Sort areas 
            [regions, jaccard_dist, jaccard_shuff_median, n_lobes_all, n_lobes_all_sig, n_stacked] = ...
                sort_areas(options_main, regions, jaccard_dist, jaccard_shuff_median, ...
                n_lobes_high, n_lobes_shared, n_lobes_low, n_lobes_all, n_lobes_all_sig);

            if strcmp(options_main.atlas, 'lobes')

                [p_sm, p_pair, median_dist, N] = compute_stats_specificity(jaccard_dist, jaccard_shuff_median);
                
                save(sprintf('%s/saccade_novelty_stats.mat', data_dir), 'p_sm', 'p_pair', 'median_dist', 'N', 'regions')
            
            end

            %% Plots
            file_ratio_conditions = sprintf('%s/ratio_conditions_%s_%s.png', out_dir, options_main.band_select{b}, options_main.atlas);

            if strcmp(options_main.atlas, 'lobes')
                
                plot_specificity(options_main, jaccard_dist, p_pair, regions, file_ratio_conditions)

            elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                
                %% Ratio of responsive channels for each condtion 
                plot_ratio_bar(n_stacked, n_lobes_all_sig, regions, options_main.bar_colors, {'High Novelty', 'Both', 'Low Novelty'}, file_ratio_conditions)
                
                %% Total number of responsive channels
                file_ratio_total = sprintf('%s/ratio_total_%s_%s.png', out_dir, options.band_select{b}, options_main.atlas);
                plot_total_bar(n_lobes_all_sig, n_lobes_all, regions, file_ratio_total)

            end
            
            %% Filters
            % Define the Gaussian for smoothing
            h = gausswin(options_main.smoothing_L, options_main.smooting_alpha);
            h = h/sum(h);
            
            % Time axis
            time = options_main.trf_window(1):1/options_main.fs_ana:options_main.trf_window(2);
        
            % Font size
            trf_font = 22;
            
            % Colors
            color_high = options_main.bar_colors(1,:);
            color_low = options_main.bar_colors(3,:);
            color_shared = options_main.bar_colors(2,:);
            
            % Line styles
            line_style = {'-', ':', '-.', '--'};
            
            filt_dir = sprintf('%s/filters', out_dir);
            if exist(filt_dir, 'dir') == 0, mkdir(filt_dir), else, continue, end
    
            for i = 1:length(regions)
                
                roi_select = regions{i};

                % Find the indices of the region of interest in the filter matrices
                idx_elec = find(sum(cellfun(@(C) contains(C, roi_select), loc_all),2) >= options_main.loc_confidence); 

                labels_elec = labels_all(idx_elec);
                
                labels_high_elec = labels_high(ismember(labels_high, labels_elec));
                labels_low_elec = labels_low(ismember(labels_low, labels_elec));
                labels_shared_elec = labels_shared(ismember(labels_shared, labels_elec));
                
                idx_high = ismember(labels_all, labels_high_elec);
                idx_low = ismember(labels_all, labels_low_elec);
                idx_shared = ismember(labels_all, labels_shared_elec);
                
                n_ch_max = max([sum(idx_high), sum(idx_low), sum(idx_shared)]);

                %% Filters 
                if sum(idx_high) ~= 0
                    plot_filters_2_conditions(w_high, w_low, time, idx_high, h, options_main.smoothing_L, n_ch_max, line_style, ...
                        color_high, color_low, trf_font, filt_dir, roi_select, 'high_novelty', 'low_novelty', 'high_novelty')
                end
                
                if sum(idx_shared) ~= 0
                    plot_filters_2_conditions(w_high, w_low, time, idx_shared, h, options_main.smoothing_L, n_ch_max, line_style, ...
                        color_shared, color_shared, trf_font, filt_dir, roi_select, 'high_novelty', 'low_novelty', 'both')
                end
                
                if sum(idx_low) ~= 0
                    plot_filters_2_conditions(w_low, w_high, time, idx_low, h, options_main.smoothing_L, n_ch_max, line_style, ...
                        color_low, color_high, trf_font, filt_dir, roi_select, 'low_novelty', 'high_novelty', 'low_novelty')
                end
                
            end

            %% Plot resonsive electrodes in each condition
            [coords_all, is_left_all, elec_names_all] = load_fsaverage_coords(labels_all_sig);

            % Create labels for face, non-face and shared electrodes
            idx_high = zeros(length(elec_names_all), 1);
            idx_low = zeros(length(elec_names_all), 1);
            idx_shared = zeros(length(elec_names_all), 1);
            idx_condition = zeros(length(elec_names_all), 1);

            for e = 1:length(elec_names_all) 

                if contains(elec_names_all{e}, 'RGridHD')
                    elec_names_all{e} = strrep(elec_names_all{e}, 'RGridHD', 'RGrid');
                end

                if contains(elec_names_all{e}, 'NS138') && contains(elec_names_all{e}, 'Lia')
                    elec_names_all{e} = strrep(elec_names_all{e}, 'Lia', 'LIa');
                end

                if contains(elec_names_all{e}, 'NS144_02') && contains(elec_names_all{e}, 'LGrid')
                    elec_names_all{e} = strrep(elec_names_all{e}, 'LGrid', 'RGrid');
                end

                idx_high(e) = sum(contains(labels_high, elec_names_all{e})) ~= 0;
                idx_low(e) = sum(contains(labels_low, elec_names_all{e})) ~= 0;
                idx_shared(e) = sum(contains(labels_shared, elec_names_all{e})) ~= 0;

            end

            idx_shared(idx_high & idx_low) = 1;
            idx_high(idx_high & idx_low) = 0;
            idx_low(idx_high & idx_low) = 0;

            idx_high(idx_high & idx_shared) = 0;
            idx_low(idx_low & idx_shared) = 0;

            idx_condition(idx_high == 1) = 1;
            idx_condition(idx_shared == 1) = 2;
            idx_condition(idx_low == 1) = 3;

            close all
            color_map = options_main.bar_colors; 

            % Spatial plot settings 
            options_main.fig_features.out_dir = out_dir;
            options_main.fig_features.file_name = 'saccade_novelty_electrode_location';
            options_main.fig_features.view = 'omni';
            options_main.fig_features.opaqueness = 0.4;
            options_main.fig_features.elec_size = 8;
            options_main.fig_features.elec_units = '';

            plot_sig_elecs(coords_all, is_left_all, elec_names_all, idx_condition, ...
                options_main.fig_features, 1, color_map, [-1, 1])
            
        end

    end

end