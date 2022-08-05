%% Load the event boundary annotations for all movies and save salience as well as scene cuts around events

function plot_event_boundary_annotations(options)

    out_dir = sprintf('%s/event_annotation', options.fig_dir);
    
    if exist(out_dir, 'dir') == 0
        
        mkdir(out_dir);
    
        % Load video names
        load('vid_data.mat', 'vid_names')

        % Recreate the video used to measure response time, if not available
        % Used to corred response time
        create_response_time_test(options)

        v = find(cellfun(@(C) contains(C, 'Despicable_Me_English'), vid_names));

        %% Load the postion of all scene cuts
        [~, video_name] = fileparts(vid_names{v});

        % Load the video file for reference 
        vid = VideoReader(sprintf('%s/%s', options.vid_dir, vid_names{v}));

        scene_annot = xlsread(sprintf('%s/%s_scenes.xlsx', options.scene_annot_dir, video_name));

        % All scenes cuts at the video frame rate
        scenes_all = zeros(1, vid.NumFrames);
        scenes_all(scene_annot(:,1)) = 1;  

        %% Load the event boundaries
        % Define the data directory
        T = vid.NumFrames/vid.FrameRate;
        fs = vid.FrameRate;

        data_dir_1 = sprintf('%s/Event_boundaries/%s', options.online_dir, video_name);
        [events_1, ~, n_hit_1] = load_events_all(data_dir_1, fs, T);
        data_dir_2 = sprintf('%s/Event_boundaries/%s_event_boundaries_semantics', options.online_dir, video_name);
        [events_2, ~, n_hit_2] = load_events_all(data_dir_2, fs, T);

        event_boundaries = [events_1; events_2];
        n_hit = [n_hit_1, n_hit_2];

        %% Should any submissions be rejected
        idx_no_boundary = sum(event_boundaries,2) == 0;
        idx_attn_failed = n_hit' < 8;

        event_boundaries(idx_no_boundary | idx_attn_failed, :) = [];

        %% Shift the event boundaries by 1 second to better match the scene cuts
        t_shift = round(0.9*fs);
        event_boundaries = [event_boundaries(:, t_shift+1:end), ...
                zeros(size(event_boundaries,1), t_shift)];

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

        %% Load data from Sam
        time_vec = (0:vid.NumFrames-1)/fs;

        annot_dir = sprintf('%s/Event_boundaries_Cohen', options.im_data_dir);
        annot_files = dir(annot_dir);
        annot_files([annot_files.isdir]) = [];

        boundary_control = zeros(length(annot_files), length(time_vec));

        for f = 1:length(annot_files)       
            annot_data = readmatrix(annot_files(f).name);
            boundaries = annot_data(:,3);
            boundaries(isnan(boundaries)) = [];
            boundary_control(f, interp1(time_vec, 1:length(time_vec), boundaries)) = 1;     
        end

        %% Shift and smooth
        boundary_control = [boundary_control(:, t_shift+1:end), zeros(size(boundary_control,1), t_shift)];
        events_control_aggregate = sum(boundary_control);
        events_control_smooth = conv(events_control_aggregate, window_fun, 'same');

        % Comparison of our's and Sam's data
        t_0 = 180;
        t_1 = 365;
        time_vec = time_vec - t_0;

        rho = corr(events_smooth', events_control_smooth');

        figure('Position', [860,322,553,420])
        hold on

        plot(time_vec, events_smooth, 'LineWidth', 2)
        plot(time_vec, events_control_smooth, 'LineWidth', 2)

        title(sprintf('\\rho = %1.2f', rho))
        xlim([0 t_1-t_0])

        xlabel('Time [s]')
        ylabel('Event Salience')

        grid on
        grid minor

        set(gca, 'FontSize', 22)
        
        outer_pos = get(gca, 'OuterPosition');
        outer_pos(2) = 0.25;
        outer_pos(4) = 0.7;
        set(gca, 'OuterPosition', outer_pos)

        legend({'Our Data', 'Cohen et al.'}, 'Position', [0.35, 0.021, 0.4, 0.166])
        
        saveas(gca, sprintf('%s/dataset_compariso.png', out_dir))

        % Cross-correlation
        [xc, lag] = xcorr(events_smooth', events_control_smooth', 10*fs,  'normalized');

        figure('Position', [1413,322,322,420])
        plot(lag/fs, xc, 'k', 'LineWidth', 2)

        xlabel('Lag [s]')
        ylabel('Cross-Correlation')

        grid on
        grid minor
        
        outer_pos = get(gca, 'OuterPosition');
        outer_pos(2) = 0.25;
        outer_pos(4) = 0.7;
        set(gca, 'OuterPosition', outer_pos)

        set(gca, 'FontSize', 22)
        
        saveas(gca, sprintf('%s/xcorr.png', out_dir))

        % Smoothing of data
        load(sprintf('%s/salience_cuts/Despicable_Me_English_salience_cuts.mat', options.im_data_dir), 'scenes_high', 'scenes_low')
        scenes_high_vec = zeros(size(scenes_all));
        scenes_high_vec(scenes_high) = 1;
        
        scenes_low_vec = zeros(size(scenes_all));
        scenes_low_vec(scenes_low) = 1;
        
        figure('Position', [80,322,780,420])
        hold on

        plot(time_vec, 1.1*scenes_high_vec, 'Color', [0 1 0], 'LineWidth', 2)
        plot(time_vec, 1.1*scenes_low_vec, 'Color', [0 0.2 0], 'LineWidth', 2)
        for e = 1:size(event_boundaries,1)
            if e == 1
                plot(time_vec, event_boundaries(e,:), 'Color', [0.3 0.3 0.3, 0.3]) 
            else
                plot(time_vec, event_boundaries(e,:), 'Color', [0.3 0.3 0.3, 0.3], 'HandleVisibility', 'off') 
            end
        end
        plot(time_vec, events_smooth, 'Color', [0, 0.4470, 0.7410], 'LineWidth', 2.5)

        ylim([0 1.1])
        xlim([150 200])

        xlabel('Time [s]')
        ylabel('Event Salience')

        set(gca, 'FontSize', 22)

        outer_pos = get(gca, 'OuterPosition');
        outer_pos(2) = 0.25;
        outer_pos(3) = 0.5;
        outer_pos(4) = 0.7;
        set(gca, 'OuterPosition', outer_pos)

        legend({'Event Cut', 'Continuous Cut', 'Individual Annotations', 'Event Salience'}, 'Position', [0.52, 0.455, 0.445, 0.323])
        
        saveas(gca, sprintf('%s/smoothing.png', out_dir))
        
    end

end