%% Divide saccades in saccades to faces and control saccades

function [saccades_faces, saccades_matched, fixations_faces, fixations_matched] = find_face_saccades(options, patient, eye_file, eye)

    % Find the video name
    file_table = readtable(sprintf('%s/Organize/file_names.xlsx', options.drive_dir));
    [~, video] = fileparts(file_table.video_file{cellfun(@(C) contains(eye_file, C), file_table.mat_file)});
    
    % Load the SVM model
    svm_model_file = sprintf('%s/svm_model.mat', options.saccade_class);
    load(svm_model_file, 'svm_model')

    [~, ~, score_face, saccade_sample, fixation_sample, saccade_amplitude] = extract_saccade_features(options, ...
        video, patient, eye_file, '', 0, svm_model);
    
    % Find saccades to faces
    idx_face = score_face > options.scale_threshold;
    amplitude_face = saccade_amplitude(idx_face);
    saccade_sample_face = saccade_sample(idx_face);
    fixation_sample_face = fixation_sample(idx_face);
    
    % Find saccades away to faces or somewhere else, or saccades on frames without faces (NaNs)
    idx_matched = score_face < -options.scale_threshold | isnan(score_face);
    amplitude_matched = saccade_amplitude(idx_matched);
    saccade_sample_matched = saccade_sample(idx_matched);
    fixation_sample_matched = fixation_sample(idx_matched);
    
    %% Match the amplitude between saccades to faces and matched saccades
    n_group = min(length(amplitude_face), length(amplitude_matched));
    amplitude_matched_copy = amplitude_matched;
    
    idx_match = nan(1, n_group);
    for i = 1:n_group
        [~, idx_match(i)] = min(abs(amplitude_matched_copy - amplitude_face(i)));
        amplitude_matched_copy(idx_match(i)) = NaN;
    end
    
    amplitude_matched = amplitude_matched(idx_match);
    saccade_sample_matched = saccade_sample_matched(idx_match);
    fixation_sample_matched = fixation_sample_matched(idx_match);
    
    amplitude_face = amplitude_face(1:length(idx_match));
    saccade_sample_face = saccade_sample_face(1:length(idx_match));
    saccade_sample_matched = saccade_sample_matched(1:length(idx_match));
    
    % Check if amplitude is matched
    [~, p] = kstest2(amplitude_face, amplitude_matched);
    
    % If the amplitude is not matched, select a subset with matched amplitude
    while p < options.p_amplitude_similarity
        
        amplitude_face = amplitude_face(1:end-1);
        amplitude_matched = amplitude_matched(1:end-1);
        
        if isempty(amplitude_face)
            break
        end
        
        [~, p] = kstest2(amplitude_face, amplitude_matched);

    end
    
    saccade_sample_face = saccade_sample_face(1:length(amplitude_face));
    fixation_sample_face = fixation_sample_face(1:length(amplitude_face));

    saccade_sample_matched = saccade_sample_matched(1:length(amplitude_face));
    fixation_sample_matched = fixation_sample_matched(1:length(amplitude_face));
    
    %% Create vectors of face and matched saccades
    saccades_faces = zeros(size(eye.time));
    saccades_matched = zeros(size(eye.time));
    fixations_faces = zeros(size(eye.time));
    fixations_matched = zeros(size(eye.time));
    
    saccades_faces(saccade_sample_face) = 1;
    saccades_matched(saccade_sample_matched) = 1;

    fixations_faces(fixation_sample_face) = 1;
    fixations_matched(fixation_sample_matched) = 1;
    
end
