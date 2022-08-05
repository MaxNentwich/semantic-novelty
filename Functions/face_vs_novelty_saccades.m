%% How much do face/non-face and high/low novelty saccades overlap 

function face_vs_novelty_saccades(options)
       
    [labels_str, vid_label] = trf_file_parts(options); 

    %% Compute the TRF for each frequency band selected
    for b = 1:length(options.band_select)

        lambda = lambda_patient(options, b);

        if strcmp(options.band_select{b}, 'raw')
            options.env_dir = options.raw_dir;
        end
        
        %% Create the file name and check if the file is already there
        % Create output directory if necessary            
        if exist(options.face_novelty, 'dir') == 0, mkdir(options.face_novelty), end        

        out_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
            options.face_novelty, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda, options.n_shuff);

        if exist(out_file, 'file'), continue, end

        distance_face = [];
        distance_non_face = [];

        %% The TRF is computed for each patient separately    
        for pat = 1:length(options.patients)
            
            %% Check which movie files were recorded for the patient
            fprintf('Processing patient %s ...\n', options.patients(pat).name)

            % Get a list of movies recorded for the current patient
            files = dir(sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir));

            % Select only the files contained in stim_names
            files = files(cellfun(@(F) sum(cellfun(@(V) contains(F, V), options.vid_names)), {files.name}) == 1);

            % Skip the patients if selected movies were not recorded
            if isempty(files), continue, end

            %% Load stimuli and neural data
            for f = 1:length(files)

                if contains(files(f).name, 'Monkey'), continue, end
                
                %% Load the eyetracking data 
                fprintf('Loading the eyetracking data ...\n')

                [eye, start_sample, end_sample] = load_et(options.data_dir, options.eye_dir, options.patients(pat).name, ...
                    files(f).name, options.trigger_IDs);

                %% Load the contrast at eyetracking sampling rate 
                % To help aligning, resampling the other stimuli
                load(sprintf('%s/%s/%s/%s', options.data_dir, options.patients(pat).name, options.contr_dir, files(f).name), ...
                    'contrast')

                % Cut at the triggers
                contrast = contrast(start_sample:end_sample);

                % Downsample
                contrast_ds = resample_peaks(contrast, eye.fs, eye.fs/options.fs_ana);

                %% Find saccades to faces and matched saccades

                fprintf('Finding saccades to faces ...\n')

                [saccades_faces, saccades_matched] = find_face_saccades(options, options.patients(pat).name, files(f).name, eye);

                %% Split saccades by amplitude and novelty                    
                fprintf('Loading the saccades with high and low novelty...\n')

                [saccade_idx, distance] = face_saccades_novelty(options, eye, options.patients(pat).name, files(f).name);
                
                distance_face = [distance_face; distance(ismember(saccade_idx, find(saccades_faces)))];
                distance_non_face = [distance_non_face; distance(ismember(saccade_idx, find(saccades_matched)))];

            end

        end
        
        p = ranksum(distance_face, distance_non_face);
        
        save(out_file, 'distance_face', 'distance_non_face', 'p')

    end

end
    