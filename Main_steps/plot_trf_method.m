%% Plot a sample of how the TRF analysis works

function plot_trf_method(options_main, type)

    sacc_dir = sprintf('%s/saccade_data', options_main.im_data_dir); 

    % Create the output directory
    if strcmp(type, 'one_paper')
        out_dir = sprintf('%s/trf_sample_all', options_main.fig_dir);
    elseif strcmp(type, 'all_poster')
        out_dir = sprintf('%s/trf_sample_all', options_main.fig_dir);
    end
    
    if exist(out_dir, 'dir') == 0
        
        mkdir(out_dir)

        %% Load a sample file
        b = 1;

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

        sample_file = sprintf('%s/%s', options_main.stats_data, vid_file);
        load(sample_file, 'w_all', 'labels_all', 'options')

        % Parse data for different TRFs
        w_scenes = w_all{ismember(options.stim_select, 'scenes')};
        w_saccades = w_all{ismember(options.stim_select, 'saccades')};
        w_motion = w_all{ismember(options.stim_select, 'optical_flow')};

        % Select a channel 
        if strcmp(type, 'one_paper')
            ch_select = 2510;
        elseif strcmp(type, 'all_poster')
            ch_select = 4775;
        end
        
        label_select = labels_all{ch_select};
        
        trf_scenes = w_scenes(ch_select, :);
        trf_saccades = w_saccades(ch_select, :);
        trf_motion = w_motion(ch_select, :);

        % Find the patient
        label_part = strsplit(label_select, {'_', '-'});

        if length(label_part) == 6
            pat = find(ismember({options_main.patients.name}, sprintf('%s_%s', label_part{1}, label_part{2})));
            channel_label = sprintf('%s-%s', label_part{3}, label_part{6});
        elseif length(label_part) == 4
            pat = find(ismember({options_main.patients.name}, label_part{1}));
            channel_label = sprintf('%s-%s', label_part{2}, label_part{4});
        end

        %% Load a sample of the stimulus
        % Get a list of movies recorded for the current patient
        files = dir(sacc_dir);
        files([files.isdir]) = [];

        file_pat = cell(length(files),1);

        for i = 1:length(files)
            parts = strsplit(files(i).name, '_');
            if ~isnan(str2double(parts{2}))
                file_pat{i} = sprintf('%s_%s', parts{1}, parts{2});
            else
                file_pat{i} = parts{1};
            end
            file_name{i} = strrep(files(i).name, sprintf('%s_', file_pat{i}), '');
        end
        
        idx_file = cellfun(@(C) strcmp(C, options.patients(pat).name), file_pat);
        eye_files = files(idx_file);
        files = file_name(idx_file);

        % Get first video 
        eye_files = eye_files(1);
        files = files(1);

        % Load the eyetracking data 
        load(sprintf('%s/%s', sacc_dir, eye_files.name), 'eye', 'saccade_onset', 'start_sample', 'end_sample')

        % Load the contrast at eyetracking sampling rate 
        % To help aligning, resampling the other stimuli
        load(sprintf('%s/%s/%s/%s', options_main.data_dir, options_main.patients(pat).name, options_main.contr_dir, files{1}), ...
            'contrast')

        % Cut at the triggers
        contrast = contrast(start_sample:end_sample);

        % Downsample
        contrast_ds = resample_peaks(contrast, eye.fs, eye.fs/options_main.fs_ana);

        % Detect Saccades
        saccades = resample_peaks(saccade_onset, length(saccade_onset), length(saccade_onset)/length(contrast_ds));
        
        % Load Motion
        optical_flow = load_optical_flow(files{1}, strrep(options_main.data_dir, '/Patients', ''), eye, ...
            options.fs_ana);

        % Interpolate a longer segment of cuts
        scenes = load_scenes(options_main, files{1}, contrast, eye, options_main.fs_ana);

        idx_cuts = find(conv(scenes, ones(10,1), 'same') == 1);
        idx_samples = 1:length(optical_flow);

        optical_flow(idx_cuts) = interp1(setdiff(idx_samples, idx_cuts), optical_flow(setdiff(idx_samples, idx_cuts)), ...
            idx_cuts);
                    
        % Load the neural data   
        [envelope, labels] = load_envelope(options_main.data_dir, options_main.env_dir, options_main.patients(pat).name, ...
            options_main.band_select{b}, files{1}, contrast_ds, options_main.fs_ana);

        envelope = zscore(envelope);

        idx_channel = ismember(labels, channel_label);

        envelope = envelope(:, idx_channel);

        % Select a time window
        if strcmp(type, 'one_paper')
            idx_sample = 3600:4200;
        elseif strcmp(type, 'all_poster')
            idx_sample = 1:600;
        end
        
        time_sample = 0:1/options_main.fs_ana:(length(idx_sample)-1)/options_main.fs_ana;

        time_trf = options_main.trf_window(1):1/options_main.fs_ana:options_main.trf_window(2);

        %% Plot the figures
        if strcmp(type, 'one_paper')

            % Stimulus
            figure('Position', [438,742,1483,400])
            plot(time_sample, scenes(idx_sample), 'g', 'LineWidth', 2.5)

            xlim([time_sample(1), time_sample(end)])
            ylim([-0.1 1.1])

            grid on

            xlabel('Time [s]')
            yticks([0 1])

            set(gca, 'FontSize', 32)

            saveas(gca, sprintf('%s/trf_sample_stimulus.png', out_dir))

            % Envelope
            figure('Position', [438,742,1483,400])
            plot(time_sample, envelope(idx_sample), 'k', 'LineWidth', 2.5)

            xlim([time_sample(1), time_sample(end)])

            grid on

            xlabel('Time [s]')
            ylabel('norm.')

            set(gca, 'FontSize', 32)

            saveas(gca, sprintf('%s/trf_sample_response.png', out_dir))

            % TRF
            figure('Position', [438,742,650,400]) 
            hold on
            plot(time_trf, trf_scenes, 'k', 'LineWidth', 2.5)
            y_limit = ylim;
            plot([0 0], ylim, 'g', 'LineWidth', 2)
            ylim(y_limit)

            grid on

            xlim([time_trf(1), time_trf(end)])

            xlabel('Time from Stimulus [s]')
            ylabel('a.u.')

            set(gca, 'FontSize', 32)

            saveas(gca, sprintf('%s/trf_sample_filter.png', out_dir))

        elseif strcmp(type, 'all_poster')
            
            % Simuli
            figure('Position', [2500,300,670,430])
            hold on
            
            plot(time_sample, scenes(idx_sample) + 2.4, 'g', 'LineWidth', 2.5)
            plot(time_sample, saccades(idx_sample) + 1.2, 'b', 'LineWidth', 2.5)
            plot(time_sample, optical_flow(idx_sample) / max(optical_flow(idx_sample)), 'r', 'LineWidth', 2.5)
            
            yticks([0.5, 1.7, 2.9])
            
            xticks([])
            yticklabels({'Motion', 'Saccades', 'Film Cuts'})
            
            set(gca, 'FontSize', 38)
            
            saveas(gca, sprintf('%s/trf_sample_stimulus.fig', out_dir))
            saveas(gca, sprintf('%s/trf_sample_stimulus.png', out_dir))
            
            % Envelope
            figure('Position', [2621,379,522,230])
            plot(time_sample, envelope(idx_sample), 'k', 'LineWidth', 2.5)

            xlabel('Time [s]')
            yticks([])
            ylabel('BHA')

            set(gca, 'FontSize', 38)
            
            saveas(gca, sprintf('%s/trf_sample_response.fig', out_dir))
            saveas(gca, sprintf('%s/trf_sample_response.png', out_dir))
            
            % TRFs
            figure('Position', [2871,385,277,489])
            hold on
            
            plot(time_trf, trf_scenes / max(trf_scenes) + 2.4, 'g', 'LineWidth', 2.5)
            plot(time_trf, trf_saccades / max(trf_saccades) + 1.2, 'b', 'LineWidth', 2.5)
            plot(time_trf, trf_motion / max(trf_motion), 'r', 'LineWidth', 2.5)
            
            y_limit = ylim;
            plot([0 0], ylim, 'k--', 'LineWidth', 2)
            ylim(y_limit)
                        
            yticks([])
            xlabel('Time [s]')
            
            set(gca, 'FontSize', 38)
            
            saveas(gca, sprintf('%s/trf_sample_filter.fig', out_dir))
            saveas(gca, sprintf('%s/trf_sample_filter.png', out_dir))
            
        end
        
    end
    
end
