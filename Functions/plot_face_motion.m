
function plot_face_motion(options)

    % Save options from the main file 
    options_main = options;
    
    % Output directory
    out_dir = sprintf('%s/flow_face_motion', options.fig_dir);
    if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
    
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
        stats_dir = sprintf('%s/Data/stats', options_main.w_dir);

        if exist(sprintf('%s/%s', stats_dir, vid_file), 'file') ~= 0

            load(sprintf('%s/%s', options_main.stats_data, vid_file), 'w_all', 'sig_all', 'p_all', 'labels_all',  'n_clust', 'options')

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
            labels_flow = labels_flow(~ismember(labels_flow, labels_shared));
            labels_face = labels_face(~ismember(labels_face, labels_shared));

            % Localize electrodes
            loc_all = localize_elecs_bipolar(labels_all, options_main.atlas); 
            
            loc_all_sig = localize_elecs_bipolar(labels_all_sig, options_main.atlas);
            loc_flow = localize_elecs_bipolar(labels_flow, options_main.atlas);
            loc_face = localize_elecs_bipolar(labels_face, options_main.atlas);
            loc_shared = localize_elecs_bipolar(labels_shared, options_main.atlas);
            
            if ~strcmp(options_main.atlas, 'lobes')
                
                loc_all = combine_locs(loc_all, 1:length(loc_all));

                loc_all_sig = combine_locs(loc_all_sig, 1:length(loc_all_sig));
                loc_flow = combine_locs(loc_flow, 1:length(loc_flow));
                loc_face = combine_locs(loc_face, 1:length(loc_face));
                loc_shared = combine_locs(loc_shared, 1:length(loc_shared));

            end
            
            regions = unique(loc_all_sig);

            % Count the number of electrodes in each lobe
            n_lobes_all_sig = zeros(size(regions));
            n_lobes_all = zeros(size(regions));
            n_lobes_flow = zeros(size(regions));
            n_lobes_face = zeros(size(regions));
            n_lobes_shared = zeros(size(regions));

            for l = 1:length(regions)

                n_lobes_all_sig(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_all_sig(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_all_sig(:,2))],2)));
                n_lobes_all(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_all(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_all(:,2))],2)));
                n_lobes_flow(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_flow(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_flow(:,2))],2)));    
                n_lobes_face(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_face(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_face(:,2))],2)));    
                n_lobes_shared(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_shared(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_shared(:,2))],2)));

            end

            %% Figures 
            [~, idx_sort] = sort(n_lobes_all_sig./n_lobes_all, 'descend');

            n_lobes_all_sig = n_lobes_all_sig(idx_sort);
            n_lobes_all = n_lobes_all(idx_sort);

            n_lobes_flow = n_lobes_flow(idx_sort);
            n_lobes_face = n_lobes_face(idx_sort);
            n_lobes_shared = n_lobes_shared(idx_sort);

            regions = regions(idx_sort);

            n_stacked = [n_lobes_flow, n_lobes_shared, n_lobes_face]./n_lobes_all;

            % Remove 'unkown' channels  
            if ~ options_main.inlude_unknown
                
                idx_unknown = cellfun(@(C) strcmp(C, 'Unknown'), regions);
                
                n_lobes_all_sig(idx_unknown) = [];
                n_lobes_all(idx_unknown) = [];

                regions(idx_unknown) = [];
                
                n_stacked(idx_unknown, :) = [];
            
            end
            
            %% Sum of electrodes in each ROI
            file_ratio_total = sprintf('%s/ratio_total_%s.png', out_dir, options.band_select{b});
            
            if exist(file_ratio_total, 'file') == 0
                
                % Add number of electrodes to labels
                for r = 1:length(regions)
                    region_labels{r} = sprintf('%s (N = %i)', regions{r}, n_lobes_all(r));
                end

                figure('Position', [675,500,700,550])

                bar(n_lobes_all_sig./n_lobes_all);

                xticks(1:size(n_stacked,1))
                xticklabels(region_labels)

                xtickangle(45)

                ylabel('Ratio of Responsive Channels')

                grid on
                grid minor

                set(gca, 'FontSize', 16)

                saveas(gca, file_ratio_total)
                
            end

            %% Ratio of different groups 
            file_ratio_conditions = sprintf('%s/ratio_conditions_%s.png', out_dir, options.band_select{b});
            
            if exist(file_ratio_conditions, 'file') == 0
                
                figure('Position', [675,483,665,479])

                bar_condition = bar(n_stacked./sum(n_stacked,2), 'stacked', 'FaceColor', 'flat');

                bar_condition(1).CData = [1 0 0];
                bar_condition(2).CData = [0.5 0.5 0];
                bar_condition(3).CData = [0 1 0];

                grid on 
                grid minor

                xticks(1:size(n_stacked,1))
                xticklabels(regions)

                xtickangle(45)

                ylabel('Ratio of Responsive Channels')

                legend({'Optical Flow', 'Any Motion', 'Face Motion'})

                set(gca, 'FontSize', 16)

                saveas(gca, file_ratio_conditions)
                
            end
            
            %% Filters
            % Define the Gaussian for smoothing
            h = gausswin(options_main.smoothing_L, options.smooting_alpha);
            h = h/sum(h);
            
            % Time axis
            time = options.trf_window(1):1/options.fs_ana:options.trf_window(2);
        
            for i = 1:length(regions)
                
                fig_filters = figure((i*3)+100);
                fig_average = figure((i*3)+101);
                fig_sig = figure((i*3)+102);
                
                roi_select = regions{i};

                % Find the indices of the region of interest in the filter matrices
                idx_elec = find(sum(cellfun(@(C) contains(C, roi_select), loc_all),2) >= options_main.loc_confidence); 

                labels_elec = labels_all(idx_elec);
                
                labels_flow_elec = labels_flow(ismember(labels_flow, labels_elec));
                labels_face_elec = labels_face(ismember(labels_face, labels_elec));
                labels_shared_elec = labels_shared(ismember(labels_shared, labels_elec));
                
                idx_flow = ismember(labels_all, labels_flow_elec);
                idx_face = ismember(labels_all, labels_face_elec);
                idx_shared = ismember(labels_all, labels_shared_elec);

                %% Filters might contain distinct responses -> separate them 
                
                w_flow = smooth_elec(w_flow, 1:size(w_flow,1), h, options_main.smoothing_L);
                w_face = smooth_elec(w_face, 1:size(w_face,1), h, options_main.smoothing_L);
                
                % Responses to face saccades
                plot_filters(w_flow, w_face, sig_flow, sig_face, idx_flow, time, fig_average, fig_filters, fig_sig, ...
                    [3, 2, 1; 3, 2, 2])
                
                % Responses to any saccade
                plot_filters(w_flow, w_face, sig_flow, sig_face, idx_shared, time, fig_average, fig_filters, fig_sig, ...
                    [3, 2, 3; 3, 2, 4])
                
                % Responses to matched saccades
                plot_filters(w_face, w_flow, sig_face, sig_flow, idx_face, time, fig_average, fig_filters, fig_sig, ...
                    [3, 2, 6; 3, 2, 5])
               
            end
            
        end
        
    end

end