
function [saccade_idx, distance] = face_saccades_novelty(options, eye, patient, movie_file)

    % Read table with movie file names 
    file_names = readtable('file_names.xlsx');
    
    % Find the movie name
    [~, movie_file] = fileparts(movie_file);
    movie_file_name = file_names.mat_file{cellfun(@(C) strcmp(C, movie_file), file_names.mat_file)};
    [~, movie_file_name] = fileparts(movie_file_name);
    
    movie_name = file_names.video_file{cellfun(@(C) strcmp(C, movie_file), file_names.mat_file)};
    [~, movie_name] = fileparts(movie_name);
    
    % Get the frame rate
    load('vid_data.mat', 'vid_names', 'fr')
    frame_rate = fr(contains(vid_names, movie_file_name));
    
    % Load the table with saccade distance and index of the saccades
    original_table = readtable(sprintf('%s/saccade_features.csv', options.saccade_label_dir), 'Delimiter', ',');
    dist_table = readtable(sprintf('%s/saccade_features_and_distance.csv', options.saccade_label_dir), 'Delimiter', ',');

    % Check if the tables match
    id_str = cellfun(@(C) C(strfind(C, 'id_'):strfind(C, 'id_')+8), original_table.pre_saccade_file, 'UniformOutput', false);
    ids_orig = cellfun(@(C) str2double(C(regexp(C, '\d'))), id_str);
    
    id_str = cellfun(@(C) C(strfind(C, 'id_'):strfind(C, 'id_')+8), dist_table.pre_saccade_file, 'UniformOutput', false);
    ids_dist = cellfun(@(C) str2double(C(regexp(C, '\d'))), id_str);
    
    assert(sum(ids_orig - ids_dist) == 0, 'Tables do not match!\n')
   
    %% Extract data for movies
    idx_movie_data = cellfun(@(C) contains(C, sprintf('%s_%s', patient, movie_file_name)), original_table.pre_saccade_file);
    
    original_table = original_table(idx_movie_data, :);
    dist_table = dist_table(idx_movie_data, :);
   
    % Load the saccades
    saccades = detect_saccade_onset(eye, options, options.visualize_trfs);

    saccade_idx = find(saccades);

    % Check that all saccades from the table are there
    saccade_idx(~ismember(saccade_idx, original_table.saccade_sample)) = [];
    assert(sum(saccade_idx == original_table.saccade_sample) == size(original_table.saccade_sample, 1), 'Missing saccades!\n');
    
    % Remove saccades across cuts
    saccade_idx(dist_table.idx_across_cut == 1) = [];
    dist_table(dist_table.idx_across_cut == 1, :) = [];

    % Remove saccades after cuts
    frame_str = cellfun(@(C) C(strfind(C, 'fr_'):end), dist_table.pre_saccade_file, 'UniformOutput', false);
    frames = cellfun(@(C) str2double(C(regexp(C, '\d'))), frame_str);
    
    cut_data = readtable(sprintf('%s/%s_scenes.xlsx', options.cut_dir, movie_name));
    cuts = table2array(cut_data(:,1));
    
    diff_cuts = frames - cuts';
    diff_cuts(diff_cuts < 0) = NaN;
    diff_cuts = min(diff_cuts, [], 2);
    
    idx_after_cut = diff_cuts < frame_rate*options.t_after;
    
    saccade_idx(idx_after_cut) = [];
    dist_table(idx_after_cut, :) = [];
    
    distance = dist_table.distance;
                     
end