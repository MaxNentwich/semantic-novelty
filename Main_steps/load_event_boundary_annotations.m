%% Load the event boundary annotations for all movies and save salience as well as scene cuts around events

function load_event_boundary_annotations(options)

    % Load video names
    load('vid_data.mat', 'vid_names')

    % Recreate the video used to measure response time, if not available
    % Used to corred response time
    create_response_time_test(options)

    for v = 1:length(vid_names)

        %% Load the postion of all scene cuts
        [~, video_name] = fileparts(vid_names{v});

        salience_dir = sprintf('%s/Data/salience_cuts', options.w_dir);
        if exist(salience_dir, 'dir') == 0, mkdir(salience_dir); end

        out_file = sprintf('%s/%s_salience_cuts.mat', salience_dir, video_name);
        if exist(out_file, 'file') ~= 0, continue, end

        % Load the video file for reference 
        vid = VideoReader(sprintf('%s/%s', options.vid_dir, vid_names{v}));

        % Load the annotations of semantic scenes 
        annot_file = sprintf('%s/%s_scenes.xlsx', options.scene_annot_dir, video_name);
        if exist(annot_file, 'file') == 0, continue, end

        scene_annot = xlsread(sprintf('%s/%s_scenes.xlsx', options.scene_annot_dir, video_name));

        % All scenes cuts at the video frame rate
        if contains(video_name, 'Monkey')
            scenes_all = zeros(1, vid.NumFrames/2);
        else
            scenes_all = zeros(1, vid.NumFrames);
        end
        scenes_all(scene_annot(:,1)) = 1;  

        % Create vectors of semantic and camera view scenes
        scene_idx = find(scenes_all ~= 0);

        %% Load the event boundaries
        % Define the data directory
        T = vid.NumFrames/vid.FrameRate;
        if contains(video_name, 'Monkey')
            fs = vid.FrameRate/2;
        else
            fs = vid.FrameRate;
        end

        if contains(video_name, 'Despicable_Me_Hungarian') 

            data_dir = sprintf('%s/Event_boundaries/%s_event_boundaries', options.online_dir, video_name);
            [event_boundaries, ~, n_hit, participants] = load_events_all(data_dir, fs, T);

        elseif contains(video_name, 'Despicable_Me_English')    

            data_dir_1 = sprintf('%s/Event_boundaries/%s', options.online_dir, video_name);
            [events_1, ~, n_hit_1, participants_1] = load_events_all(data_dir_1, fs, T);
            data_dir_2 = sprintf('%s/Event_boundaries/%s_event_boundaries_semantics', options.online_dir, video_name);
            [events_2, ~, n_hit_2, participants_2] = load_events_all(data_dir_2, fs, T);

            event_boundaries = [events_1; events_2];
            n_hit = [n_hit_1, n_hit_2];
            participants = [participants_1; participants_2];

        else

            data_dir = sprintf('%s/Event_boundaries/%s', options.online_dir, video_name);
            [event_boundaries, ~, n_hit, participants] = load_events_all(data_dir, fs, T);

        end

        %% Should any submissions be rejected
        idx_no_boundary = sum(event_boundaries,2) == 0;
        idx_attn_failed = n_hit' < 8;

        event_boundaries(idx_no_boundary | idx_attn_failed, :) = [];
        participants(idx_no_boundary | idx_attn_failed) = [];

        %% Shift the event boundaries by 1 second to better match the scene cuts
        if contains(video_name, 'Despicable_Me')
            t_shift = round(0.9*fs);
            event_boundaries = [event_boundaries(:, t_shift+1:end), ...
                    zeros(size(event_boundaries,1), t_shift)];
        else
            t_shift = round(0.55*fs);
            event_boundaries = [event_boundaries(:, t_shift+1:end), ...
                zeros(size(event_boundaries,1), t_shift)];
        end

        %% Create a smoothed vector or event boundaries
        events_aggregate = sum(event_boundaries);

        % Define a gaussian window 
        % The window size is determined by σ = (L – 1)/(2α) -> std = (bin_size-1)/(2*alpha);
        % In this case fs is 1 second -> resolution of the event boundaries
        sigma = options.event_window*fs;
        bin_size = options.event_bin*fs;
        alpha = (bin_size-1)/(2*sigma);

        window_fun = gausswin(bin_size, alpha);
        window_fun = window_fun/sum(window_fun);

        events_smooth = conv(events_aggregate, window_fun, 'same');

        if options.visualize_boundaries

            figure
            hold on

            if contains(video_name, 'Monkey')
                plot((0:vid.NumFrames/2-1)/fs, events_smooth)
                plot((0:vid.NumFrames/2-1)/fs, scenes_all/3)
            else
                plot((0:vid.NumFrames-1)/fs, events_smooth)
                plot((0:vid.NumFrames-1)/fs, scenes_all/3)
            end

        end

        %% Select the scenes with high and low salience
        scenes_salience = events_smooth(scene_idx);

        % Select how many cuts to select by finding the change point
        n_cuts = findchangepts(sort(scenes_salience, 'descend'));

        [~, idx_sort] = sort(scenes_salience);
        scene_idx_sort = scene_idx(idx_sort);

        scenes_high = scene_idx_sort(end-(n_cuts-1) : end);
        scenes_low = scene_idx_sort(1:n_cuts);

        if options.visualize_boundaries

            figure
            hold on 
            plot(sort(scenes_salience, 'descend'), '*-')
            plot([n_cuts n_cuts], ylim, 'r')

            xlabel('Cut')
            ylabel('Salience')

            legend({'All Cuts', 'Salience Cutoff'})

            set(gca, 'FontSize', 14)
            grid on
            grid minor

        end

        %% Match the scene cuts to the frames saved with ffmpeg
        frames = dir(sprintf('%s/%s', options.frame_dir, video_name));
        frames(1:2) = [];

        contr_dir = sprintf('%s/Data/contr_frames', options.w_dir);
        if exist(contr_dir, 'dir') == 0, mkdir(contr_dir); end

        contr_file = sprintf('%s/temp_contr_%s.mat', contr_dir, video_name);

        if exist(contr_file, 'file') == 0

            for n_fr = 1:length(frames)

                clc
                fprintf('Processing Frame %i/%i ... \n', n_fr, length(frames))

                frame_current = double(rgb2gray(imread(sprintf('%s/%s/%s', ...
                    options.frame_dir, video_name, frames(n_fr).name))));

                if n_fr == 1               
                    frame_diff = zeros(size(frame_current));
                    frame_previous = frame_current;
                else
                    frame_diff = frame_current - frame_previous;
                    frame_previous = frame_current;
                end

                temp_contr(n_fr) = mean(frame_diff(:).^2);

            end

            save(contr_file, 'temp_contr')

        else
            load(contr_file, 'temp_contr')
        end

        % Find the peaks
        [~,idx_peak] = findpeaks(temp_contr, 'MinPeakDistance', 30, 'MinPeakProminence', 1e3);

        if contains(video_name, 'Monkey')

            scenes_high_annot = scenes_high;
            scenes_low_annot = scenes_low;

            for i = 1:length(scenes_high)
                [~, idx_close] = min(abs(idx_peak - scenes_high(i)));
                scenes_high(i) = idx_peak(idx_close);
            end

            for i = 1:length(scenes_low)
                [~, idx_close] = min(abs(idx_peak - scenes_low(i)));
                scenes_low(i) = idx_peak(idx_close);
            end

        end

        %% Check of low level features are similar

        % Load the AlexNet convolutional neural network

        net = alexnet('Weights','imagenet');   
        % Pick a layer for feature extraction 
        layer = 'fc7'; 

        %% Compute changes in low level features across scene cuts
        % Based on Extended Data Table 1 in Zheng et al., 2021
        feat_dir = sprintf('%s/Data/visual_features_cuts', options.w_dir);
        if exist(feat_dir, 'dir') == 0, mkdir(feat_dir); end

        feature_high_file = sprintf('%s/%s_high_salience_features.mat', feat_dir, video_name);

        visual_changes_high = visual_changes_cuts(feature_high_file, scenes_high, options.frame_dir, video_name, net, layer);

        %% Save camera scenes
        features_low_file = sprintf('%s/%s_low_salience_features.mat', feat_dir, video_name);

        [visual_changes_low, attr_names] = visual_changes_cuts(features_low_file, scenes_low, options.frame_dir, video_name, ...
            net, layer);

        %% Compute the group level difference between semantic and camera cuts for each feature
        p = [];
        for f = 1:length(attr_names)
            p(f) = signrank(visual_changes_high(f,:), visual_changes_low(f,:));
        end

        % FDR correction
        p_fdr = mafdr(p, 'BHFDR', 'true');

        %% If the visual features are different between high and low salience cuts choose some new ones (with dumb random search)
        % Cuts with low salience
        scene_idx_low = scene_idx_sort(1:floor(length(scene_idx_sort)/2));  

        while sum(p_fdr < 0.05) ~= 0

            % Select a different set of cuts
            idx_rand = randperm(length(scene_idx_low));
            scenes_low = scene_idx_sort(idx_rand(1:n_cuts));

            if contains(video_name, 'Monkey')

                scenes_low_annot = scenes_low;

                for i = 1:length(scenes_low)
                    [~, idx_close] = min(abs(idx_peak - scenes_low(i)));
                    scenes_low(i) = idx_peak(idx_close);
                end

            end

            % Recompute the visual features
            features_low_file_sys = strrep(features_low_file, 'Dropbox (City College)', 'Dropbox\ \(City\ College\)');
            system(sprintf('rm %s', features_low_file_sys));

            [visual_changes_low, attr_names] = visual_changes_cuts(features_low_file, scenes_low, options.frame_dir, video_name, ...
                net, layer);

            p = [];
            for f = 1:length(attr_names)
                p(f) = signrank(visual_changes_high(f,:), visual_changes_low(f,:));
            end

            % FDR correction
            p_fdr = mafdr(p, 'BHFDR', 'true');

        end

        %% Save the scene cuts 
        if contains(video_name, 'Monkey')
            save(out_file, 'scenes_high_annot', 'scenes_low_annot', 'scenes_high', 'scenes_low', 'p_fdr', 'attr_names');
        else
            save(out_file, 'scenes_high', 'scenes_low', 'p_fdr', 'attr_names');
        end

    end

end