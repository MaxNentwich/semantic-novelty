 %% Check distance of saccades with high and low novelty from scene cuts
 
 function saccade_novelty_frequency(options)
 
    % Output directory
    out_dir = sprintf('%s/saccades_novelty', options.fig_dir);
    if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
    
    sacc_dir = sprintf('%s/saccade_data', options.im_data_dir);
    
    file_timing = sprintf('%s/saccade_novelty_timing.png', out_dir);
    
    if exist(file_timing, 'file') == 0

        % Load the table with saccade distance and index of the saccades
        original_table = readtable(sprintf('%s/saccade_features.csv', options.saccade_label_dir), 'Delimiter', ',');
        dist_table = readtable(sprintf('%s/saccade_features_and_distance.csv', options.saccade_label_dir), 'Delimiter', ',');

        % Check if the tables match
        id_str = cellfun(@(C) C(strfind(C, 'id_'):strfind(C, 'id_')+8), original_table.pre_saccade_file, 'UniformOutput', false);
        ids_orig = cellfun(@(C) str2double(C(regexp(C, '\d'))), id_str);

        id_str = cellfun(@(C) C(strfind(C, 'id_'):strfind(C, 'id_')+8), dist_table.pre_saccade_file, 'UniformOutput', false);
        ids_dist = cellfun(@(C) str2double(C(regexp(C, '\d'))), id_str);

        assert(sum(ids_orig - ids_dist) == 0, 'Tables do not match!\n')

        %% Fit a regression line to control for distance
        X = [ones(length(original_table.saccade_amplitude),1), log(original_table.saccade_amplitude)];
        y = log(dist_table.distance);

        % Some distances are zero and become -Inf after the log
        y(isinf(y)) = 0;

        % Regression
        b = X\y;

        % Estimate 
        y_hat = X*b;

        % Find points above and below the regression line
        idx_above = y > y_hat;

        % Remove samples so that the two groups have the same number of saccades
        idx_above_num = find(idx_above);
        d_saccades = sum(idx_above) - sum(~idx_above);

        rng(4622)
        idx_rand = randperm(length(idx_above_num));
        idx_remove = idx_above_num(idx_rand(1:d_saccades));

        X(idx_remove, :) = [];
        y(idx_remove) = [];
        y_hat(idx_remove) = [];
        idx_above(idx_remove) = [];

        original_table(idx_remove, :) = [];
        dist_table(idx_remove, :) = [];

         %% Get eyetracking data

        for b = 1:length(options.band_select)

            time_after_cuts_high = [];
            time_after_cuts_low = [];

            %% The TRF is computed for each patient separately    
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
                end
                
                files = files(cellfun(@(C) strcmp(C, options.patients(pat).name), file_pat));

                % Select only the files contained in stim_names
                files = files(cellfun(@(F) sum(cellfun(@(V) contains(F, V), options.vid_names)), {files.name}) == 1);

                % Skip the patients if selected movies were not recorded
                if isempty(files), continue, end

                %% Load stimuli and neural data
                for f = 1:length(files)

                    % Read table with movie file names 
                    file_names = readtable('file_names.xlsx');

                    % Find the movie name
                    [~, movie_file] = fileparts(files(f).name);
                    movie_file = strrep(movie_file, sprintf('%s_', options.patients(pat).name), '');
                    movie_file_name = file_names.mat_file{cellfun(@(C) strcmp(C, movie_file), file_names.mat_file)};
                    [~, movie_file_name] = fileparts(movie_file_name);

                    load('vid_data.mat', 'vid_names', 'fr')
                    frame_rate = fr(contains(vid_names, movie_file_name));

                    idx_movie_data = cellfun(@(C) contains(C, sprintf('%s_%s', options.patients(pat).name, movie_file_name)), original_table.pre_saccade_file);

                    original_table_mov = original_table(idx_movie_data, :);
                    dist_table_mov = dist_table(idx_movie_data, :);
                    idx_above_mov = idx_above(idx_movie_data, :);

                    % Load the saccades
                    load(sprintf('%s/%s', sacc_dir, files(f).name), 'saccade_onset', 'eye')
                    saccades_all = saccade_onset;

                    saccade_idx_all = find(saccades_all);

                    % Check that all saccades from the table are there
                    saccade_idx = saccade_idx_all;
                    saccade_idx(~ismember(saccade_idx, original_table_mov.saccade_sample)) = [];
                    assert(sum(saccade_idx == original_table_mov.saccade_sample) == size(original_table_mov.saccade_sample, 1), 'Missing saccades!\n');

                    % Remove saccades across cuts
                    saccade_idx(dist_table_mov.idx_across_cut == 1) = [];
                    idx_above_mov(dist_table_mov.idx_across_cut == 1) = [];
                    dist_table_mov(dist_table_mov.idx_across_cut == 1, :) = [];

                    % Remove saccades after cuts
                    frame_str = cellfun(@(C) C(strfind(C, 'fr_'):end), dist_table_mov.pre_saccade_file, 'UniformOutput', false);
                    frames = cellfun(@(C) str2double(C(regexp(C, '\d'))), frame_str);

                    movie_name = file_names.video_file{cellfun(@(C) strcmp(C, movie_file), file_names.mat_file)};
                    [~, movie_name] = fileparts(movie_name);

                    cut_data = readtable(sprintf('%s/%s_scenes.xlsx', options.cut_dir, movie_name));
                    cuts = table2array(cut_data(:,1));

                    diff_cuts_high = frames(idx_above_mov) - cuts';
                    diff_cuts_high(diff_cuts_high < 0) = NaN;
                    diff_cuts_high = min(diff_cuts_high, [], 2);

                    diff_cuts_low = frames(~idx_above_mov) - cuts';
                    diff_cuts_low(diff_cuts_low < 0) = NaN;
                    diff_cuts_low = min(diff_cuts_low, [], 2);

                    time_after_cuts_high = [time_after_cuts_high; diff_cuts_high];
                    time_after_cuts_low = [time_after_cuts_low; diff_cuts_low];

                end

            end

            p = ranksum(time_after_cuts_high, time_after_cuts_low);

            figure
            hold on
            histogram(log(time_after_cuts_high ./ options.fs_ana), 75)
            histogram(log(time_after_cuts_low./ options.fs_ana), 75)

            xlabel('Time after Cuts [s]')
            ylabel('# of Saccades')

            legend({'High Novelty', 'Low Novelty'})

            grid on
            grid minor

            set(gca, 'FontSize', 22)
            
            % Change labels back to seconds from log(s)
            xticklabels(cellfun(@(C) round(exp(str2double(C)), 2), xticklabels))
            xtickangle(45)

            outer_pos = get(gca, 'OuterPosition');
            outer_pos(2) = 0.25;
            outer_pos(4) = 0.75;
            set(gca, 'OuterPosition', outer_pos)

            legend({'High Novelty', 'Low Novelty'}, 'Position', [0.55,0.024,0.314,0.155])

            title(sprintf('p = %1.2e (N = %i)', p, length(time_after_cuts_high)))

            saveas(gca, file_timing)

            diff_time = (nanmedian(time_after_cuts_high) - nanmedian(time_after_cuts_low)) / options.fs_ana;

        end
        
    end
        
 end