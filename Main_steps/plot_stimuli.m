%% Plot samples of stimuli and their relationship

function plot_stimuli(options)
       
    % Create the output directory
    out_dir = sprintf('%s/stimuli', options.fig_dir);
    
    sacc_dir = sprintf('%s/Data/saccade_data', options.w_dir);  
    
    if exist(out_dir, 'dir') == 0
        
        mkdir(out_dir)

        % Create empty vectors to concatentate data of all stimuli
        scenes_all = [];
        scenes_events_all = [];
        scenes_continuous_all = [];
        saccades_all = [];
        motion_all = [];

        %% Load stimuli for all patients 
        for pat = 1:length(options.patients)

            %% Check which movie files were recorded for the patient
            fprintf('Processing patient %s ...\n', options.patients(pat).name)

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
            
            % Skip the patients if selected movies were not recorded
            if isempty(eye_files), continue, end

            %% Load stimuli and neural data
            for f = 1:length(eye_files)

                %% Load the eyetracking data 
                fprintf('Loading the eyetracking data ...\n')

                load(sprintf('%s/%s', sacc_dir, eye_files(f).name), 'eye', 'saccade_onset', 'start_sample', 'end_sample')
                
                %% Load the contrast at eyetracking sampling rate 
                % To help aligning, resampling the other stimuli
                load(sprintf('%s/%s/%s/%s', options.data_dir, options.patients(pat).name, options.contr_dir, files{f}), ...
                    'contrast')

                % Cut at the triggers
                contrast = contrast(start_sample:end_sample);

                % Downsample
                contrast_ds = resample_peaks(contrast, eye.fs, eye.fs/options.fs_ana);

                % Initialize the topeliz matrix with an offset
                stim_patient = ones(length(contrast_ds),1);

                % Simulus order might change, so a new variable is created to keep track of it 
                stim_labels = {};

                %% Load the annotation of the scenes
                fprintf('Loading the scene cuts ...\n')
                scenes = load_scenes(options, files{f}, contrast, eye, options.fs_ana);

                %% Load scenes with high and low salienc
                fprintf('Loading the scene cuts with high and low salience...\n')
                [~, scenes_high, scenes_low] = load_scenes(options, files{f}, contrast, eye, options.fs_ana);

                %% Load saccades 
                fprintf('Detecting saccades ...\n')
%                 saccades = detect_saccade_onset(eye, options, options.visualize_trfs);

                % Resample to match scene cuts
%                 saccades = resample_peaks(saccades, length(saccades), length(saccades)/length(contrast_ds));
                saccades = resample_peaks(saccade_onset, length(saccade_onset), length(saccade_onset)/length(contrast_ds));
                
                %% Load the optical flow
                fprintf('Loading optical flow ...\n')
                optical_flow = load_optical_flow(files{f}, strrep(options.data_dir, '/Patients', ''), eye, ...
                    options.fs_ana);
                
                % Interpolate a longer segment of cuts
                idx_cuts = find(conv(scenes, ones(10,1), 'same') == 1);
                idx_samples = 1:length(optical_flow);
                
                optical_flow(idx_cuts) = interp1(setdiff(idx_samples, idx_cuts), optical_flow(setdiff(idx_samples, idx_cuts)), idx_cuts);

                %% Concatentate the data for all videos
                scenes_all = [scenes_all; scenes'];
                scenes_events_all = [scenes_events_all; scenes_high'];
                scenes_continuous_all = [scenes_continuous_all; scenes_low'];
                saccades_all = [saccades_all; saccades'];
                motion_all = [motion_all; optical_flow'];

            end

        end
        
        %% Get motion for all videos 
        flow_files = dir(options.flow_dir);
        flow_files([flow_files.isdir]) = [];
        flow_files(cellfun(@(C) contains(C, 'Inscapes'), {flow_files.name})) = [];
%         flow_files = flow_files(cellfun(@(C) contains(C, 'Present'), {flow_files.name}));
        
        flow_vid = [];
        scenes_vid = [];
        
        for f = 1:length(flow_files)
            
            load(sprintf('%s/%s', options.flow_dir, flow_files(f).name), 'optic_flow', 'fr')
            
            if contains(flow_files(f).name, 'Monkey')
                optic_flow = resample(optic_flow, 1, 2);
                fr = 30;
            end
                     
            [~, flow_file_name] = fileparts(flow_files(f).name);
            scenes_frame = readmatrix(sprintf('%s/%s_scenes.xlsx', options.cut_dir, flow_file_name));
            scenes_frame = scenes_frame(:,1);
            
            % Remove outliers
            if contains(flow_files(f).name, 'Present')
                scenes_frame(6:7) = [];
            end
            
            scenes_vec = zeros(size(optic_flow));
            scenes_vec(scenes_frame) = 1;
            
            % Interpolate a longer segment of cuts
            idx_cuts = find(conv(scenes_vec, ones(5,1), 'same') == 1);
            idx_samples = 1:length(optic_flow);
                
            optic_flow(idx_cuts) = interp1(setdiff(idx_samples, idx_cuts), optic_flow(setdiff(idx_samples, idx_cuts)), idx_cuts);
            
            flow_vid = [flow_vid; optic_flow'];
            scenes_vid = [scenes_vid; scenes_vec'];
            
        end
        
        idx_scenes_vid = find(scenes_vid);
        
        time_scene_vid = options.stim_fig.mot_cuts(1) : 1/fr : options.stim_fig.mot_cuts(2);

        scene_trial_idx = zeros(length(idx_scenes_vid), length(time_scene_vid));

        for i = 1:length(idx_scenes_vid)
            scene_trial_idx(i,:) = idx_scenes_vid(i) + options.stim_fig.mot_cuts(1)*fr : ...
                idx_scenes_vid(i) + options.stim_fig.mot_cuts(2)*fr;
        end

        scene_trial_idx(sum(scene_trial_idx < 1 | scene_trial_idx > length(flow_vid), 2) ~= 0, :) = [];

        flow_scenes = flow_vid(scene_trial_idx);
        
         % Plot With error
        motion_error = 1.96 * std(flow_scenes)' / sqrt(length(flow_scenes));
        
        time_flipped = [time_scene_vid'; flipud(time_scene_vid')];
        error_scenes = [mean(flow_scenes)'-motion_error; flipud(mean(flow_scenes)'+motion_error)];

        figure
        hold on
        plot(time_flipped, error_scenes, 'r')
        
        fill(time_flipped, error_scenes, 'r', 'LineStyle', 'none');
        plot(time_scene_vid, mean(flow_scenes), 'r',  'LineWidth', 2);
        alpha(0.1);
        
        y_limits = ylim;
        plot([0 0], ylim, 'g', 'LineWidth', 2)
        
        yticklabels([])
        
        grid on
        grid minor

        xlabel('Time from Film Cut [s]')
        xlim([time_scene_vid(1), time_scene_vid(end)])

        ylabel('Motion [a. u.]')
        ylim(y_limits)

        set(gca, 'FontSize', 24)
        
        saveas(gca, sprintf('%s/motion_at_cuts_average.fig', out_dir))
        saveas(gca, sprintf('%s/motion_at_cuts_average.png', out_dir))
       
        %% Plot a sample of all stimuli
        idx_sample = options.stim_fig.start_sample*options.fs_ana : ...
            (options.stim_fig.start_sample + options.stim_fig.time_sample)*options.fs_ana;
        time = options.stim_fig.start_sample : 1/options.fs_ana : options.stim_fig.start_sample + options.stim_fig.time_sample;
        time = time - time(1);

        motion_sample = motion_all(idx_sample);
        motion_sample = motion_sample / max(abs(motion_sample));
        motion_sample = motion_sample - mean(motion_sample);

        figure('Position', [267,554,1654,413])
        hold on

        plot(time, scenes_all(idx_sample) + 2.5, 'g', 'LineWidth', 2)
        plot(time, saccades_all(idx_sample) + 1, 'b', 'LineWidth', 2)
        plot(time, motion_sample, 'r', 'LineWidth', 2)

        xlabel('Time [s]')

        yticks([0, 1.5, 3])
        yticklabels({'Motion', 'Saccades', 'Film Cuts'})
        ylim([-0.75 3.75])

        set(gca, 'FontSize', 24)

        saveas(gca, sprintf('%s/stim_samples.fig', out_dir))
        saveas(gca, sprintf('%s/stim_samples.png', out_dir))
        
        %% Saccades around scene cuts
        idx_scenes = find(scenes_all);

        time_scene = options.stim_fig.sac_cuts(1) : 1/options.fs_ana : options.stim_fig.sac_cuts(2);
        time_scene(time_scene == 0) = 1e-3;

        scene_trial_idx = zeros(length(idx_scenes), length(time_scene));
        
        for i = 1:length(idx_scenes)
            scene_trial_idx(i,:) = idx_scenes(i) + options.stim_fig.sac_cuts(1)*options.fs_ana : ...
                idx_scenes(i) + options.stim_fig.sac_cuts(2)*options.fs_ana;
        end

        scene_trial_idx(sum(scene_trial_idx < 1 | scene_trial_idx > length(scenes_all), 2) ~= 0, :) = [];

        saccades_scenes = saccades_all(scene_trial_idx);

        saccade_times = saccades_scenes .* time_scene;
        saccade_times(saccade_times == 0) = [];
        saccade_times(saccade_times == 1e-3) = 0;

        figure 
        hold on

        histogram(saccade_times, length(time_scene), 'Normalization', 'probability', 'FaceColor', 'b', 'FaceAlpha', 0.8)
        plot([0 0], ylim, 'g', 'LineWidth', 2)

        grid on
        grid minor

        xlabel('Time from Film Cut [s]')
        ylabel('Saccade Probability')

        set(gca, 'FontSize', 24)
        
        saveas(gca, sprintf('%s/saccades_at_cuts_histogram.fig', out_dir))
        saveas(gca, sprintf('%s/saccades_at_cuts_histogram.png', out_dir))

        %% Motion around Saccades
        idx_saccades = find(saccades_all);

        time_saccades = options.stim_fig.mot_sac(1) : 1/options.fs_ana : options.stim_fig.mot_sac(2);

        saccade_trial_idx = zeros(length(idx_saccades), length(time_saccades));

        for i = 1:length(idx_saccades)
            saccade_trial_idx(i,:) = idx_saccades(i) + options.stim_fig.mot_sac(1)*options.fs_ana : ...
                idx_saccades(i) + options.stim_fig.mot_sac(2)*options.fs_ana;
        end

        saccade_trial_idx(sum(saccade_trial_idx < 1 | saccade_trial_idx > length(scenes_all), 2) ~= 0, :) = [];

        motion_saccades = motion_all(saccade_trial_idx);

        % Plot With error
        motion_error = 1.96 * std(motion_saccades)' / sqrt(length(motion_saccades));
        
        time_flipped = [time_saccades'; flipud(time_saccades')];
        error_saccades = [mean(motion_saccades)'-motion_error; flipud(mean(motion_saccades)'+motion_error)];

        figure
        plot(time_flipped,error_saccades,'r')
        hold on
        fill(time_flipped,error_saccades,[1 0 0],'LineStyle','none');
        plot(time_saccades, mean(motion_saccades), 'r',  'LineWidth',2);
        alpha(0.1);
        y_limits = ylim;
        plot([0 0], ylim, 'b', 'LineWidth', 2)

        grid on
        grid minor

        xlabel('Time from Saccade [s]')
        xlim([time_saccades(1), time_saccades(end)])

        ylabel('Motion [a. u.]')
        ylim(y_limits)
        
        yticklabels([])

        set(gca, 'FontSize', 24)
        
        saveas(gca, sprintf('%s/motion_at_saccades_average.fig', out_dir))
        saveas(gca, sprintf('%s/motion_at_saccades_average.png', out_dir))
        
    end

end
    