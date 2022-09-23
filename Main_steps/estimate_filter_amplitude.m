function estimate_filter_amplitude(options, stimulus, y_label_str, smooth_band_width)

    options_main = options;
    
    for b = 1:length(options_main.band_select)

        % Check if amplitudes have been computes
        data_dir = sprintf('%s/amplitudes', options_main.im_data_dir);
        if exist(data_dir, 'dir') == 0, mkdir(data_dir), end

        data_file = sprintf('%s/%s_%s.mat', data_dir, y_label_str, options_main.band_select{b});

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

        %% Load the filters
        stats_dir = sprintf('%s/stats', options_main.im_data_dir);

        if exist(sprintf('%s/%s', stats_dir, vid_file), 'file') ~= 0

            load(sprintf('%s/%s', stats_dir, vid_file), ...
                 'w_all', 'sig_all', 'p_all', 'labels_all', 'options')

            % Convert labels
            labels_w = cell2table(cell(length(labels_all), 2), 'VariableNames', {'patient_name', 'channel_pair'});

            for l = 1:length(labels_all)

                labels_part = strsplit(labels_all{l}, {'_', '-'});

                if length(labels_part) == 4
                    labels_w.patient_name{l} = labels_part{1};
                    labels_w.channel_pair{l} = sprintf('%s-%s', labels_part{2}, labels_part{4});
                elseif length(labels_part) == 6
                    labels_w.patient_name{l} = sprintf('%s_%s', labels_part{1}, labels_part{2});
                    labels_w.channel_pair{l} = sprintf('%s-%s', labels_part{3}, labels_part{6});
                end

            end

            % Parse data for the different stimuli
            if strcmp(stimulus, 'scenes')
                idx_stim_cell = find(ismember(options_main.stim_select, stimulus));
            elseif contains(stimulus, 'saccades')
                idx_stim_cell = find(ismember(options_main.stim_select, 'saccades'));
            end

            w_stim = w_all{idx_stim_cell};

            % Correct for multiple comparisons with FDR
            [~, sig_scenes] = fdr_corr(p_all{idx_stim_cell}, sig_all{idx_stim_cell});

            w_stim(sum(sig_scenes,2) == 0, :) = [];
            labels_w(sum(sig_scenes,2) == 0, :) = [];
            labels_all(sum(sig_scenes,2) == 0, :) = [];

        end

        if exist(data_file, 'file') == 0
                
            a_condition_1_all = [];
            a_condition_2_all = [];

            patients_no_data = {};

            %% Load the scene cuts and neural data
            for pat = 1:length(options_main.patients)

                % Though filters for saccades are trained on all movies face saccades don't exist for Monkey movies
                if strcmp(stimulus, 'saccades_faces')
                    options_main.vid_names = {'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};              
                end

                %% Check which movie files were recorded for the patient
                fprintf('Processing patient %s ...\n', options_main.patients(pat).name)

                % Get a list of movies recorded for the current patient
                files = dir(sprintf('%s/%s/%s', options_main.data_dir, options_main.patients(pat).name, options_main.eye_dir));

                % Select only the files contained in stim_names
                files = files(cellfun(@(F) sum(cellfun(@(V) contains(F, V), options_main.vid_names)), {files.name}) == 1);

                % Skip the patients if selected movies were not recorded
                if isempty(files), patients_no_data = [patients_no_data; options_main.patients(pat).name]; continue, end

                % Create empty vectors to concatentate data of all stimuli
                a_condition_1 = [];
                a_condition_2 = [];

                resp_condition_1 = [];
                resp_condition_2 = [];

                %% Load stimuli and neural data
                for f = 1:length(files)

                    %% Load the eyetracking data 
                    fprintf('Loading the eyetracking data ...\n')

                    [eye, start_sample, end_sample] = load_et(options_main.data_dir, options_main.eye_dir, options_main.patients(pat).name, ...
                        files(f).name, options_main.trigger_IDs);

                    %% Load the contrast at eyetracking sampling rate 
                    % To help aligning, resampling the other stimuli
                    load(sprintf('%s/%s/%s/%s', options_main.data_dir, options_main.patients(pat).name, options_main.contr_dir, files(f).name), ...
                        'contrast')

                    % Cut at the triggers
                    contrast = contrast(start_sample:end_sample);

                    % Downsample
                    contrast_ds = resample_peaks(contrast, eye.fs, eye.fs/options_main.fs_ana);

                    %% Load the neural data   
                    [envelope, labels] = load_envelope(options_main.data_dir, options_main.env_dir, options_main.patients(pat).name, ...
                        options_main.band_select{b}, files(f).name, contrast_ds, options_main.fs_ana);

                    envelope = zscore(envelope);

                    %% Find the filters
                    labels_w_pat = labels_w(ismember(labels_w.patient_name, options_main.patients(pat).name) ...
                        & ismember(labels_w.channel_pair, labels), :);

                    %% Load the annotation of the scenes
                    if strcmp(stimulus, 'scenes')

                        fprintf('Loading the scene cuts ...\n')

                        [~, stim_condition_1, stim_condition_2] = load_scenes(options_main, files(f).name, contrast, eye, options_main.fs_ana);

                    end

                    %% Load novelty of saccades
                    if strcmp(stimulus, 'saccades_novelty')

                        fprintf('Loading the saccades with high and low novelty...\n')

                        [stim_condition_1, stim_condition_2] = split_saccades_novelty(options_main, eye, options.patients(pat).name, ...
                            files(f).name, 0);

                        % Resample to match scene cuts
                        stim_condition_1 = resample_peaks(stim_condition_1, length(stim_condition_1), ...
                            length(stim_condition_1)/length(contrast_ds));
                        stim_condition_2 = resample_peaks(stim_condition_2, length(stim_condition_2), ...
                            length(stim_condition_2)/length(contrast_ds));

                    end

                    %% Saccades to faces
                    if strcmp(stimulus, 'saccades_faces')

                        % Though filters for saccades are trained on all movies
                        % face saccades don't exist for Monkey movies

                        fprintf('Finding saccades to faces ...\n')

                        [stim_condition_1, stim_condition_2] = find_face_saccades(options_main, options_main.patients(pat).name, files(f).name, eye);

                        % Resample to match scene cuts
                        stim_condition_1 = resample_peaks(stim_condition_1, length(stim_condition_1), ...
                            length(stim_condition_1)/length(contrast_ds));
                        stim_condition_2 = resample_peaks(stim_condition_2, length(stim_condition_2), ...
                            length(stim_condition_2)/length(contrast_ds));

                    end

                    %% Fit the amplitude with a bi-linear model
                    [a_1, resp_1] = compute_filter_amplitude(options, labels_w_pat, labels_w, labels, stim_condition_1, w_stim, envelope, 0);
                    [a_2, resp_2] = compute_filter_amplitude(options, labels_w_pat, labels_w, labels, stim_condition_2, w_stim, envelope, 0);

                    a_condition_1 = [a_condition_1; a_1'];
                    a_condition_2 = [a_condition_2; a_2'];

                    resp_condition_1 = cat(1, resp_condition_1,  permute(resp_1, [2 1 3]));
                    resp_condition_2 = cat(1, resp_condition_2,  permute(resp_2, [2 1 3]));

                end

                % Average across channels
                a_condition_1_all = [a_condition_1_all; mean(a_condition_1)'];
                a_condition_2_all = [a_condition_2_all; mean(a_condition_2)'];

            end
              
            if exist(data_dir, 'dir') == 0, mkdir(data_dir), end

            save(data_file, 'a_condition_1_all', 'a_condition_2_all', 'y_label_str', 'labels_all', 'patients_no_data')

        else           
            load(data_file, 'a_condition_1_all', 'a_condition_2_all', 'y_label_str', 'labels_all', 'patients_no_data')         
        end
 
        % Output directory
        fig_dir = sprintf('%s/amplitudes', options_main.fig_dir);
        if exist(fig_dir, 'dir') == 0, mkdir(fig_dir), end
        
        out_file = sprintf('%s/%s.png', fig_dir, y_label_str);
        
        if exist(out_file, 'file') == 0
            
            %% Depending on the movies some patients are not included
            idx_no_data = cellfun(@(C) contains(C, patients_no_data), labels_all);
            labels_all(idx_no_data) = [];

            %% Violinplot per ROI
            a_diff =  a_condition_1_all - a_condition_2_all;

            idx_inf = isinf(a_diff);
            a_diff(idx_inf) = [];
            labels_all(idx_inf) = [];

            [loc, ~, pat_names] = localize_elecs_bipolar(labels_all, 'lobes');

            regions = unique(loc);

            % Count the number of electrodes in each lobe
            n_lobes = zeros(size(regions));

            regions(ismember(regions, 'Unknown')) = [];
            idx_region_sort = cellfun(@(C) find(ismember(regions, C)), options_main.regions_order);
            regions = regions(idx_region_sort);

            idx_cat = cell(size(a_diff));

            for l = 1:length(regions)

                idx_elec = sum(cellfun(@(C) contains(C, regions{l}), loc),2) >= options_main.loc_confidence; 
                idx_cat(idx_elec) = regions(l);

            end

            % Remove unlocalized electrodes
            idx_empty = cellfun(@(C) isempty(C), idx_cat);
            
            pat_names(idx_empty) = [];
            
            a_diff(idx_empty) = [];
            idx_cat(idx_empty) = [];
            
            % Check how the distribution looks like
            plot_distribution(a_diff)

            log_transform = input('Apply log transformation? (yes=1, no=0) \n');

            if log_transform 

                a_diff = log(a_diff + 1);
                plot_distribution(a_diff)

            end
            
            xlabel('Amplitude Difference')
            ylabel('Normalized Count')
            legend({'Data', 'Gaussian Fit'})
            
            dist_file = sprintf('%s/%s_distribution.png', fig_dir, y_label_str);
            saveas(gca, dist_file)
            
            %% ANOVA 
            % Anova for main effects of brain region and random effect of patient
            p_anova = anovan(a_diff, {idx_cat pat_names}, 'random',2, 'varnames', {'Region','Patient'});

            %% Average difference of amplitudes in each region and patient 
            patients = unique(pat_names);
            
            a_diff_pat = nan(length(regions), length(patients));
            
            for r = 1:length(regions)   
                idx_region = ismember(idx_cat, regions(r));
                for p = 1:length(patients)
                    idx_pat = ismember(pat_names, patients(p));
                    a_diff_pat(r,p) = mean(a_diff(idx_region & idx_pat));
                end
            end
            
            % Pairwise test for means across patients
            p_pair = zeros(1, length(regions));
            
            for r = 1:length(regions)      
                p_pair(r) = signrank(a_diff_pat(r,:));       
            end
            
            p_pair = mafdr(p_pair, 'BHFDR', 'true');
            
            % Save stats
            median_a_diff_pat = nanmedian(a_diff_pat);
            
            stat_file = strrep(data_file, '.mat', '_stats.mat');
            save(stat_file, 'p_anova', 'p_pair', 'median_a_diff_pat')
            
            %% Plot

            figure('Position', [700 300 700 550])
            hold on

            plot([0.5 6.5], [0 0], 'k--', 'Color', 0.5*ones(3,1))

            a_diff_pat = a_diff_pat';
            idx_cat_pat = repmat(regions', length(patients), 1);
            
            violinplot(a_diff_pat(:), idx_cat_pat(:), 'ShowData', false, 'ShowBox', false, 'ShowWhiskers', false, 'ShowNotches', false, ...
                'ShowMedian', false, 'BandWidth', 0.075, 'ViolinColor', options_main.region_color, 'GroupOrder', regions);

            x_tick_labels = xticklabels;
            
            %% Correct p-values for main effect of condition for multiple comparisons
            for l = 1:length(regions)
                
                if p_pair(1,l) < 0.05
                    plot(l, max(a_diff_pat(:)) + 0.2, 'k*', 'MarkerSize', 15, 'LineWidth', 1.5)
                end

                scatter(0.05*randn(1, length(patients))+l, a_diff_pat(:, l), 10, 'MarkerFaceColor', options_main.region_color(l,:), ...
                        'MarkerEdgeColor',[0 0 0])
                plot([l-0.25, l+0.25], nanmedian(a_diff_pat(:,l))*[1 1], 'k--')
            end

            xticklabels(x_tick_labels)

            xtickangle(45)
            xlim([0.5 6.5])

            title(y_label_str)
            ylabel('Amplitude Difference')

            set(gca, 'FontSize', 22)

            saveas(gca, out_file)
            
        end
        
    end
    
end