%% extract temporal contrast from each video file and align to subject data based on psychtoolbox frame timing 

function extract_temporal_contrast(options)

    [~, file_names] = xlsread('file_names.xlsx');

    mat_col = strcmp(file_names(1,:), 'mat_file');
    vid_col = find(strcmp(file_names(1,:), 'video_file'));

    if exist('./Data/temporal_contrast.mat', 'file') == 0

        vid_names = unique(file_names(2:end, vid_col));

        contrast_vid = cell(size(vid_names));

        % Read optical flow from all frames and store
        for v = 1:length(vid_names)

            vid = VideoReader(sprintf('%s/%s', options.vid_dir, vid_names{v}));

            n_fr = 0;

            while hasFrame(vid)

                clc
                fprintf('Processing Frame %i/%i ... \n', n_fr + 1, round(vid.Duration*vid.FrameRate))

                frame_current = double(rgb2gray(readFrame(vid)));

                n_fr = n_fr + 1;

                if n_fr == 1               
                    frame_diff = zeros(size(frame_current));
                    frame_previous = frame_current;
                else
                    frame_diff = frame_current - frame_previous;
                    frame_previous = frame_current;
                end

                contrast_vid{v}(n_fr) = mean(frame_diff(:).^2);

            end

            %% Correct artifacts
            frames = 1:length(contrast_vid{v}); 

            plot(contrast_vid{v})

            if contains(vid_names{v}, 'Monkey')

                [~, idx_art] = findpeaks(-contrast_vid{v});

                contrast_vid{v}(idx_art) = interp1(setdiff(frames, idx_art), ...
                    contrast_vid{v}(setdiff(frames, idx_art)), idx_art);

                [~, idx_art] = findpeaks(-contrast_vid{v}, 'MinPeakDistance', 10);

                idx_flat = contrast_vid{v}(idx_art) == contrast_vid{v}(idx_art+2);

                idx_art = sort([idx_art(idx_flat), idx_art(idx_flat)+1, idx_art(idx_flat)+2, ...
                    idx_art(~idx_flat), idx_art(~idx_flat)-1, idx_art(~idx_flat)+1]);

                contrast_vid{v}(idx_art) = interp1(setdiff(frames, idx_art), ...
                    contrast_vid{v}(setdiff(frames, idx_art)), idx_art);

            else   

                [~, idx_art] = findpeaks(-contrast_vid{v}, 'MinPeakDistance', 3);

                contrast_vid{v}(idx_art) = interp1(setdiff(frames, idx_art), ...
                    contrast_vid{v}(setdiff(frames, idx_art)), idx_art);
            end

            hold on
            plot(contrast_vid{v})

        end

        % Save contrast data
        save('./Data/temporal_contrast.mat', 'contrast_vid', 'vid_names')

        clearvars contrast

    else
        load('./Data/temporal_contrast.mat', 'contrast_vid', 'vid_names')
    end

    % Assign the values to the right timestamps based on psychtoolbox timing
    for pat = 1:length(options.patients)

        data_files = dir(sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir));
        data_files([data_files.isdir]) = [];

        for f = 1:length(data_files)

            out_dir = sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.contr_dir);
            out_file = data_files(f).name;

            if exist(sprintf('%s/%s', out_dir, out_file), 'file') ~= 0
                continue
            end

            fprintf('Align contrast to patient %s %s ...\n', options.patients(pat).name, data_files(f).name)

            load(sprintf('%s/%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir, data_files(f).name), 'eye')

            name_idx = contains(file_names(:,mat_col), strrep(data_files(f).name, '.mat', ''));
            vid_idx = contains(vid_names, file_names(name_idx, vid_col));

            if length(unique(eye.frame_time)) ~= length(eye.frame_time)
                idx_same = find(diff(eye.frame_time) == 0);
                eye.frame_time(idx_same) = eye.frame_time(idx_same) - 1e-10;
            end

            contrast = interp1(eye.frame_time, contrast_vid{vid_idx}(1:length(eye.frame_time)), eye.time);

            % Save the data
            if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
            save(sprintf('%s/%s', out_dir, out_file), 'contrast')

            clearvars contrast

        end

    end

end