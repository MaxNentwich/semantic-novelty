%% Setup a dataset for self-supervised representation learning of foveal images across saccades

function setup_ssl_dataset(options)
    
    % Load file name table
    file_names = readtable(sprintf('%s/Organize/file_names.xlsx', options.w_dir));
     
    for pat = 1:length(options.patients)

        % Directory to save aligned data
        out_dir = sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.sacc_dir);
        if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
            
        % Get a list of movies recorded for the current patient
        files = dir(sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir));
        
        % Select only the files contained in stim_names
        files = files(cellfun(@(F) sum(cellfun(@(V) contains(F, V), options.ssl_videos)), {files.name}) == 1);

        % Skip the patients if selected movies were not recorded
        if isempty(files), continue, end

        for f = 1:length(files)
            
            % Directory to save aligned data
            out_file = sprintf('%s/%s', out_dir, files(f).name);
            
            if exist(out_file, 'file') == 0
                
                %% Load et data
                [eye, start_sample, end_sample] = load_et(options.data_dir, options.eye_dir, options.patients(pat).name, ...
                    files(f).name, options.trigger_IDs);

                % Detect saccades
                [saccade_onset, ~, saccade_amplitude, saccade_speed, ~, fixation_onset, pos_pre, pos_post, distance_screen] = ...
                    detect_saccade_onset(eye, options, 0);
    
                %% Process eyetracking data   
                % Find the radius of the foveal field of view on the screen
                r = foveal_r(options, eye);

                %% Correct the samples
                % eye data has been cut and eye.frame_sample has to be corrected 
                eye.frame_sample = interp1(eye.time, 1:length(eye.time), eye.frame_time);

                % Find the frame corresponding to each saccade and fixation onset
                saccade_sample = find(saccade_onset);
                fixation_sample = find(fixation_onset);

                %% Label saccades that go across scene cuts
                idx_across_cut = find_saccades_across_cuts(options, options.patients(pat).name, files(f).name, eye, ...
                    start_sample, end_sample, saccade_sample, fixation_sample);

                %% Find the eye position and saccade and fixation onset
                % Correct duplicate frames
                [~, idx_unique] = unique(eye.frame_sample, 'first');
                idx_frames = 1:length(eye.frame_sample);
                idx_frames(idx_unique) = [];

                if ~isempty(idx_frames)
                    idx_duplicate = find(eye.frame_sample(idx_frames) == eye.frame_sample, 1, 'last');
                    eye.frame_sample(idx_duplicate) = eye.frame_sample(idx_duplicate) + 1;
                end

                % Find the frames corresponding to saccade and fixaition onset
                saccade_frame = round(interp1(eye.frame_sample, 1:length(eye.frame_sample), saccade_sample));
                fixation_frame = round(interp1(eye.frame_sample, 1:length(eye.frame_sample), fixation_sample));

                % Some saccades happen before movie onset
                idx_nan = isnan(saccade_frame) | isnan(fixation_frame);

                % Scale the position to the screen size
                pos_pre = pos_pre.*options.screen_size;
                pos_post = pos_post.*options.screen_size;

                % Cut saccades outside the video
                idx_out = pos_pre(:,1) < options.destrect_ext(1) | pos_pre(:,1) > options.destrect_ext(3) ...
                        | pos_pre(:,2) < options.destrect_ext(2) | pos_pre(:,2) > options.destrect_ext(4) ...
                        | pos_post(:,1) < options.destrect_ext(1) | pos_post(:,1) > options.destrect_ext(3) ...
                        | pos_post(:,2) < options.destrect_ext(2) | pos_post(:,2) > options.destrect_ext(4);

                % Adjust for the border
                pos_pre = pos_pre - options.destrect_ext([1,2]);
                pos_post = pos_post - options.destrect_ext([1,2]);

                % Adjust for the scaling of the video
                [~, mat_file] = fileparts(files(f).name);
                [~, video_file] = fileparts(file_names.video_file{ismember(file_names.mat_file, mat_file)});

                load(sprintf('%s/Data/video_frame_size/%s.mat', options.w_dir, video_file), 'vid_size')

                vid_size_screen = options.destrect_ext([3,4]) - options.destrect_ext([1,2]);
                rs_factor = vid_size./vid_size_screen;

                pos_pre = pos_pre.*rs_factor;
                pos_post = pos_post.*rs_factor;

                % Exlude saccades with same onset and offset position
                idx_same = sum(pos_pre == pos_post,2) ~= 0;

                % All saccades to remove
                idx_remove = idx_nan | idx_out | idx_same;

                saccade_frame(idx_remove) = [];
                fixation_frame(idx_remove) = [];
                pos_pre(idx_remove, :) = [];
                pos_post(idx_remove, :) = [];
                saccade_amplitude(idx_remove) = [];
                saccade_speed(idx_remove) = [];
                idx_across_cut(idx_remove) = [];
                saccade_sample(idx_remove) = [];
                fixation_sample(idx_remove) = [];
                
                % Save the data 
                save(out_file, 'saccade_frame', 'fixation_frame', 'pos_pre', 'pos_post', 'saccade_amplitude', 'saccade_speed', ...
                    'saccade_sample', 'fixation_sample', 'idx_across_cut', 'r', 'distance_screen')
                
            end
      
        end
    
    end
    
    % Find the mean foveal radius
    r_file = sprintf('%s/Organize/foveal_r.mat', options.w_dir);
    
    if exist(r_file, 'file') == 0
        r = foveal_r_all(options);
        r_mean = mean(r);
        save(r_file, 'r_mean', 'r')
    else
        load(r_file, 'r_mean')
    end
    
    r_mean = round(r_mean,-1);
    
    %% Save the images cropped around saccade and fixation onset
    frame_dir = sprintf('%s/ssl_dataset', options.drive_dir);
    patch_sacc_dir = sprintf('%s/natural_saccades', frame_dir);
    patch_rand_dir = sprintf('%s/random_patches', frame_dir);
    patch_match_dir = sprintf('%s/matched_patches', frame_dir);
    
    if exist(patch_sacc_dir, 'dir') == 0, mkdir(patch_sacc_dir), end
    if exist(patch_rand_dir, 'dir') == 0, mkdir(patch_rand_dir), end
    if exist(patch_match_dir, 'dir') == 0, mkdir(patch_match_dir), end
    
    if exist(patch_sacc_dir, 'dir') == 0 && exist(patch_rand_dir, 'dir') == 0 && exist(patch_match_dir, 'dir') == 0 
        
        % Create a table to collect saccade attributes
        saccade_features = cell2table(cell(0,7), 'VariableNames', {'pre_saccade_file', 'post_saccade_file', 'saccade_amplitude', ...
            'saccade_speed', 'idx_across_cut', 'saccade_sample', 'fixation_sample'});

        random_features = cell2table(cell(0,4), 'VariableNames', {'pre_saccade_file', 'post_saccade_file', 'saccade_amplitude', ...
            'idx_across_cut'});

        matched_features = cell2table(cell(0,4), 'VariableNames', {'pre_saccade_file', 'post_saccade_file', 'saccade_amplitude', ...
            'idx_across_cut'});

        % Counter for total images
        img_id = 0;

        for pat = 1:length(options.patients)

            % Directory to save aligned data
            out_dir = sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.sacc_dir);
            if exist(out_dir, 'dir') == 0, mkdir(out_dir), end

            % Get a list of movies recorded for the current patient
            files = dir(sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir));

            % Select only the files contained in stim_names
            files = files(cellfun(@(F) sum(cellfun(@(V) contains(F, V), options.ssl_videos)), {files.name}) == 1);

            % Skip the patients if selected movies were not recorded
            if isempty(files), continue, end

            for f = 1:length(files)

                % File to load aligned saccade data
                saccade_file = sprintf('%s/%s', out_dir, files(f).name);

                % Load the saccade data
                load(saccade_file, 'saccade_frame', 'fixation_frame', 'pos_pre', 'pos_post', 'saccade_amplitude', 'saccade_speed', ...
                    'idx_across_cut', 'saccade_sample', 'fixation_sample', 'distance_screen')

                % Monkey movies are played at 60Hz but frames are at 30Hz
                if contains(files(f).name, 'Monkey')
                    saccade_frame = round(saccade_frame / 2);
                    fixation_frame = round(fixation_frame / 2);
                end

                % Video name
                [~, mat_file] = fileparts(files(f).name);
                [~, video_file] = fileparts(file_names.video_file{ismember(file_names.mat_file, mat_file)});

                frames = dir(sprintf('%s/%s', options.frame_dir, video_file));
                frames([frames.isdir]) = [];

                saccade_pre_file = cell(length(saccade_frame),1);
                saccade_post_file = cell(length(saccade_frame),1);

                rand_pre_file = cell(length(saccade_frame),1);
                rand_post_file = cell(length(saccade_frame),1);

                random_amplitude = nan(length(saccade_frame),1);

                for n_fr = 1:length(saccade_frame)

                    % Load the frames
                    frame_sac = imread(sprintf('%s/%s/%s', options.frame_dir, video_file, frames(saccade_frame(n_fr)).name));
                    if saccade_frame(n_fr) == fixation_frame(n_fr)
                        frame_fix = frame_sac;
                    else
                        frame_fix = imread(sprintf('%s/%s/%s', options.frame_dir, video_file, frames(fixation_frame(n_fr)).name));
                    end

                    %% Load a random frame at a different time in the movie
                    idx_frame = 1:length(frames);

                    % Frame should not be too close to the real one
                    load('vid_data.mat', 'vid_names', 'fr')
                    fr = fr(cellfun(@(C) contains(C, video_file), vid_names));

                    idx_min = saccade_frame(n_fr) - options.min_fr_dist*fr;
                    idx_max = saccade_frame(n_fr) + options.min_fr_dist*fr;

                    if idx_min < 1, idx_min = 1; end
                    if idx_max > length(frames), idx_max = length(frames); end

                    idx_frame(idx_min:idx_max) = [];

                    n_rand_fr = idx_frame(randi(length(idx_frame), 1));

                    frame_rand = imread(sprintf('%s/%s/%s', options.frame_dir, video_file, frames(n_rand_fr).name));

                    %% Cut image patches for saccades
                    [saccade_pre, saccade_post] = cut_image_patches(round(pos_pre(n_fr,:)), round(pos_post(n_fr,:)), frame_sac, frame_fix, ...
                        r_mean);

                    %% Cut a completely random patch 
                    rand_pos_pre = [randi(size(frame_sac,2), 1), randi(size(frame_sac,1), 1)];
                    rand_pos_post = [randi(size(frame_sac,2), 1), randi(size(frame_sac,1), 1)];

                    % Amplitude of the random saccade
                    random_amplitude(n_fr) = sqrt(sum((rand_pos_post - rand_pos_pre).^2));

                    % Convert to mm
                    mm_per_pix = mean(options.screen_dimension ./ options.screen_size);
                    random_amplitude(n_fr) = random_amplitude(n_fr) * mm_per_pix;

                    % Convert to DVA
                    random_amplitude(n_fr) = rad2deg(atan(random_amplitude(n_fr) / distance_screen));

                    [random_pre, random_post] = cut_image_patches(rand_pos_pre, rand_pos_post, frame_sac, frame_fix, r_mean);

                    %% Cut a patch with the same amplitude and orientation as the saccade on a random frame
                    [match_pre, match_post] = cut_image_patches(round(pos_pre(n_fr,:)), round(pos_post(n_fr,:)), frame_rand, frame_rand, r_mean);

                    %% Plot saccade patch
                    if options.ssl_image_plot

                        close all

                        plot_saccade_patches(pos_pre(n_fr, :), pos_post(n_fr, :), r_mean, frame_fix, saccade_pre, saccade_post)
                        pause
                        plot_saccade_patches(rand_pos_pre, rand_pos_post, r_mean, frame_fix, random_pre, random_post)
                        pause
                        plot_saccade_patches(pos_pre(n_fr, :), pos_post(n_fr, :), r_mean, frame_rand, match_pre, match_post)
                        pause

                    end

                    %% Save the patches
                    % File to save saccade patches
                    img_id = img_id +1;

                    if img_id == 97
                        pause
                    end

                    if img_id == 181
                        pause
                    end

                    % Saccades
                    saccade_pre_file{n_fr} = sprintf('id_%06d_pre_%s_%s_sac_%05d_fr_%05d.jpg', img_id, options.patients(pat).name, mat_file, ...
                        n_fr, saccade_frame(n_fr));
                    saccade_post_file{n_fr} = sprintf('id_%06d_post_%s_%s_sac_%05d_fr_%05d.jpg', img_id, options.patients(pat).name, mat_file, ...
                        n_fr, fixation_frame(n_fr));

                    imwrite(saccade_pre, sprintf('%s/%s', patch_sacc_dir, saccade_pre_file{n_fr}))
                    imwrite(saccade_post, sprintf('%s/%s', patch_sacc_dir, saccade_post_file{n_fr}))

                    % Random patches
                    rand_pre_file{n_fr} = sprintf('id_%06d_pre_%s_sac_%05d_fr_%05d.jpg', img_id, mat_file, n_fr, saccade_frame(n_fr));
                    rand_post_file{n_fr} = sprintf('id_%06d_post_%s_sac_%05d_fr_%05d.jpg', img_id, mat_file, n_fr, fixation_frame(n_fr));

                    imwrite(random_pre, sprintf('%s/%s', patch_rand_dir, rand_pre_file{n_fr}))
                    imwrite(random_post, sprintf('%s/%s', patch_rand_dir, rand_post_file{n_fr}))

                    % Matched patches
                    imwrite(match_pre, sprintf('%s/%s', patch_match_dir, saccade_pre_file{n_fr}))
                    imwrite(match_post, sprintf('%s/%s', patch_match_dir, saccade_post_file{n_fr}))

                end

                %% Feature tables
                % Saccades
                saccade_features_video = table(saccade_pre_file, saccade_post_file, saccade_amplitude, saccade_speed, idx_across_cut', ...
                    saccade_sample, fixation_sample, ...
                    'VariableNames', {'pre_saccade_file', 'post_saccade_file', 'saccade_amplitude', 'saccade_speed', 'idx_across_cut', ...
                    'saccade_sample', 'fixation_sample'});

                saccade_features = [saccade_features; saccade_features_video];

                % Random patches
                random_features_video = table(rand_pre_file, rand_post_file, random_amplitude, idx_across_cut', ...
                    'VariableNames', {'pre_saccade_file', 'post_saccade_file', 'saccade_amplitude', 'idx_across_cut'});

                random_features = [random_features; random_features_video];

                % Matched patches
                matched_features_video = table(saccade_pre_file, saccade_post_file, saccade_amplitude, idx_across_cut', ...
                    'VariableNames', {'pre_saccade_file', 'post_saccade_file', 'saccade_amplitude', 'idx_across_cut'});

                matched_features = [matched_features; matched_features_video];

            end

        end

        % Save the saccade features
        writetable(saccade_features, sprintf('%s/saccade_features.csv', frame_dir))
        writetable(random_features, sprintf('%s/random_features.csv', frame_dir))
        writetable(matched_features, sprintf('%s/matched_features.csv', frame_dir))
        
    end
    
end