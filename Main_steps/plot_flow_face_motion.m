
function plot_flow_face_motion(options)

    % Save options from the main file 
    options_main = options;
    
    % Output directory
    out_dir = sprintf('%s/optical_flow_face_motion', options.fig_dir);
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
            idx_flow = find(ismember(options.stim_select, 'optical_flow'));
            idx_face = find(ismember(options.stim_select, 'face_motion'));

            w_flow = w_all{idx_flow};
            w_face = w_all{idx_face};

            %% Correct for multiple comparisons with FDR
            [~, sig_flow] = fdr_corr(p_all{idx_flow}, sig_all{idx_flow});
            [~, sig_face] = fdr_corr(p_all{idx_face}, sig_all{idx_face});
 
            %% Bar plot to summarize ratio of responsive electrodes per area
            labels_flow = labels_all(sum(sig_flow,2) ~= 0);
            labels_face = labels_all(sum(sig_face,2) ~= 0);
            
            % Find shared an unique electrodes
            labels_all_sig = unique([labels_flow; labels_face]);

            labels_shared = labels_flow(ismember(labels_flow, labels_face));
            labels_face = labels_face(~ismember(labels_face, labels_shared));
            labels_flow = labels_flow(~ismember(labels_flow, labels_shared));

            % Localize electrodes
            [n_lobes_all, n_lobes_all_sig, n_lobes_face, n_lobes_flow, n_lobes_shared, regions, patients, loc_all] = ...
                localize_elecs_patient(labels_all, labels_all_sig, labels_face, labels_flow, labels_shared, options_main.atlas);
                     
            %% Stats
            jaccard_dist = 1 - (n_lobes_shared ./ sum(cat(3, n_lobes_face, n_lobes_flow, n_lobes_shared), 3));
            
            if strcmp(options_main.atlas, 'lobes')
                
                shuffle_file = sprintf('%s/face_total_motion_shuffle.mat', data_dir);
                
                if exist(shuffle_file, 'file') == 0
                    jaccard_shuff_median = specificity_permutation(labels_all_sig, options_main.atlas, 1e3);
                    save(shuffle_file, 'jaccard_shuff_median')
                else
                    load(shuffle_file, 'jaccard_shuff_median')
                end
                
            else
                jaccard_shuff_median = zeros(size(jaccard_dist));
            end  
            
            [regions, jaccard_dist, jaccard_shuff_median, n_lobes_all_sig, n_lobes_face, n_lobes_shared, n_lobes_flow, n_lobes_all] = ...
                remove_areas(options_main, regions, jaccard_dist, jaccard_shuff_median, ...
                n_lobes_all_sig, n_lobes_face, n_lobes_shared, n_lobes_flow, n_lobes_all);

            % Sort areas 
            [regions, jaccard_dist, jaccard_shuff_median, n_lobes_all, n_lobes_all_sig, n_stacked] = ...
                sort_areas(options_main, regions, jaccard_dist, jaccard_shuff_median, ...
                n_lobes_face, n_lobes_shared, n_lobes_flow, n_lobes_all, n_lobes_all_sig);
            
            if strcmp(options_main.atlas, 'lobes')

                [p_sm, p_pair, median_dist, N] = compute_stats_specificity(jaccard_dist, jaccard_shuff_median);
                
                save(sprintf('%s/face_total_motion_stats.mat', data_dir), 'p_sm', 'p_pair', 'median_dist', 'N', 'regions')
            
            end

            %% Plots
            file_ratio_conditions = sprintf('%s/ratio_conditions_%s_%s.png', out_dir, options_main.band_select{b}, options_main.atlas);

            if strcmp(options_main.atlas, 'lobes')
                
                plot_specificity(options_main, jaccard_dist, p_pair, regions, file_ratio_conditions)
                
            elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                
                %% Ratio of responsive channels for each condtion 
                plot_ratio_bar(n_stacked, n_lobes_all_sig, regions, options_main.bar_colors, {'Total Motion', 'Both', 'Face Motion'}, file_ratio_conditions)
                
                %% Total number of responsive channels
                file_ratio_total = sprintf('%s/ratio_total_%s_%s.png', out_dir, options.band_select{b}, options_main.atlas);
                plot_total_bar(n_lobes_all_sig, n_lobes_all, regions, file_ratio_total)

            end         

            %% Plot resonsive electrodes in each condition
            out_name = 'flow_face_motion_electrode_location';
            if exist(sprintf('%s/%s.png', out_dir, out_name), 'file') ~= 0, continue, end
            
            [coords_all, is_left_all, elec_names_all] = load_fsaverage_coords(labels_all_sig);

            % Create labels for face, non-face and shared electrodes
            idx_flow = zeros(length(elec_names_all), 1);
            idx_face = zeros(length(elec_names_all), 1);
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

                idx_flow(e) = sum(contains(labels_flow, elec_names_all{e})) ~= 0;
                idx_face(e) = sum(contains(labels_face, elec_names_all{e})) ~= 0;
                idx_shared(e) = sum(contains(labels_shared, elec_names_all{e})) ~= 0;

            end

            idx_shared(idx_flow & idx_face) = 1;
            idx_flow(idx_flow & idx_face) = 0;
            idx_face(idx_flow & idx_face) = 0;

            idx_flow(idx_flow & idx_shared) = 0;
            idx_face(idx_face & idx_shared) = 0;

            idx_condition(idx_flow == 1) = 1;
            idx_condition(idx_shared == 1) = 2;
            idx_condition(idx_face == 1) = 3;

            close all
            color_map = options_main.bar_colors; 

            % Spatial plot settings 
            options.fig_features.out_dir = out_dir;
            options.fig_features.file_name = out_name;
            options.fig_features.view = 'omni';
            options.fig_features.opaqueness = 0.4;
            options.fig_features.elec_size = 8;
            options.fig_features.elec_units = '';

            plot_sig_elecs(coords_all, is_left_all, elec_names_all, idx_condition, ...
                options.fig_features, 1, color_map, [-1, 1])
            
        end

    end

end