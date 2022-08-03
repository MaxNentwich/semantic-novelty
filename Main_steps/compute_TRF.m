%% TRF analysis comparing the response to saccades after scenes with other saccades 
% The model includes multiple regressors and removes the influence on each other

function compute_TRF(options)
       
    [labels_str, vid_label] = trf_file_parts(options); 

    %% Compute the TRF for each frequency band selected
    for b = 1:length(options.band_select)

        lambda = lambda_patient(options, b);

        if strcmp(options.band_select{b}, 'raw')
            options.env_dir = options.raw_dir;
        end

        n_stim = length(options.stim_labels);

        %% The TRF is computed for each patient separately    
        for pat = 1:length(options.patients)

            %% Create the file name and check if the file is already there
            % Create output directory if necessary            
            out_dir = sprintf('%s/%s/%s/%s', options.data_dir, options.patients(pat).name, options.trf_dir, labels_str(1:end-1));
            if exist(out_dir, 'dir') == 0, mkdir(out_dir), end        

            out_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
                out_dir, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda, options.n_shuff);

            if exist(out_file, 'file'), continue, end
            
            %% Check which movie files were recorded for the patient
            fprintf('Processing patient %s ...\n', options.patients(pat).name)

            % Get a list of movies recorded for the current patient
            files = dir(sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir));

            % Select only the files contained in stim_names
            files = files(cellfun(@(F) sum(cellfun(@(V) contains(F, V), options.vid_names)), {files.name}) == 1);

            % Skip the patients if selected movies were not recorded
            if isempty(files), continue, end

            % Create empty vectors to concatentate data of all stimuli
            stim = [];
            neural = [];
            vid_idx = [];

            %% Load stimuli and neural data
            for f = 1:length(files)

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

                % Initialize the topeliz matrix with an offset
                stim_patient = ones(length(contrast_ds),1);

                % Simulus order might change, so a new variable is created to keep track of it 
                stim_labels = {};

                %% Load the annotation of the scenes
                if ismember('scenes', options.stim_labels)

                    fprintf('Loading the scene cuts ...\n')

                    scenes = load_scenes(options, files(f).name, contrast, eye, options.fs_ana);

                    % Add to the stimulus matrix
                    stim_patient = [stim_patient, ...
                                    tplitz_pf(scenes', options.trf_window(2)*options.fs_ana, ...
                                                      -options.trf_window(1)*options.fs_ana, options.fs_ana)];  

                    stim_labels = [stim_labels, 'scenes'];

                end

                %% Load scenes with high and low salienc
                if ismember('high_scenes', options.stim_labels) && ismember('low_scenes', options.stim_labels)

                    fprintf('Loading the scene cuts with high and low salience...\n')

                    [~, scenes_high, scenes_low] = load_scenes(options, files(f).name, contrast, eye, options.fs_ana);

                    % Add to the stimulus matrix
                    stim_patient = [stim_patient, ...
                                    tplitz_pf(scenes_high', options.trf_window(2)*options.fs_ana, ...
                                                           -options.trf_window(1)*options.fs_ana, options.fs_ana), ...
                                    tplitz_pf(scenes_low', options.trf_window(2)*options.fs_ana, ...
                                                          -options.trf_window(1)*options.fs_ana, options.fs_ana)];  

                    stim_labels = [stim_labels, 'high_scenes', 'low_scenes'];

                end

                %% Load saccades 
                if ismember('saccades', options.stim_labels)

                    fprintf('Detecting saccades ...\n')

                    saccades = detect_saccade_onset(eye, options, options.visualize_trfs);

                    % Resample to match scene cuts
                    saccades = resample_peaks(saccades, length(saccades), length(saccades)/length(contrast_ds));

                    % Add to the stimulus matrix
                    stim_patient = [stim_patient, ...
                                    tplitz_pf(saccades', options.trf_window(2)*options.fs_ana, ...
                                                        -options.trf_window(1)*options.fs_ana, options.fs_ana)];  

                    stim_labels = [stim_labels, 'saccades'];

                end
                
                %% Find saccades to faces and matched saccades
                if ismember('saccades_faces', options.stim_labels) && ismember('saccades_matched', options.stim_labels)
                   
                    fprintf('Finding saccades to faces ...\n')
                    
                    [saccades_faces, saccades_matched] = find_face_saccades(options, options.patients(pat).name, files(f).name, eye);
                    
                    % Resample to match scene cuts
                    saccades_faces = resample_peaks(saccades_faces, length(saccades_faces), length(saccades_faces)/length(contrast_ds));
                    saccades_matched = resample_peaks(saccades_matched, length(saccades_matched), length(saccades_matched)/length(contrast_ds));
                    
                    % Add to the stimulus matrix
                    stim_patient = [stim_patient, ...
                                    tplitz_pf(saccades_faces', options.trf_window(2)*options.fs_ana, ...
                                                             -options.trf_window(1)*options.fs_ana, options.fs_ana), ...
                                    tplitz_pf(saccades_matched', options.trf_window(2)*options.fs_ana, ...
                                                               -options.trf_window(1)*options.fs_ana, options.fs_ana)];  

                    stim_labels = [stim_labels, 'saccades_faces', 'saccades_matched'];
                    
                end

                %% Load the optical flow
                if ismember('optical_flow', options.stim_labels)

                    fprintf('Loading optical flow ...\n')

                    optical_flow = load_optical_flow(files(f).name, strrep(options.data_dir, '/Patients', ''), eye, ...
                        options.fs_ana);
                    
                    % Interpolate a longer segment of cuts
                    scenes = load_scenes(options, files(f).name, contrast, eye, options.fs_ana);
                    
                    idx_cuts = find(conv(scenes, ones(10,1), 'same') == 1);
                    idx_samples = 1:length(optical_flow);
                    
                    optical_flow(idx_cuts) = interp1(setdiff(idx_samples, idx_cuts), optical_flow(setdiff(idx_samples, idx_cuts)), ...
                        idx_cuts);

                    % Add to the stimulus matrix
                    stim_patient = [stim_patient, ...
                                    tplitz_pf(optical_flow', options.trf_window(2)*options.fs_ana, ...
                                                            -options.trf_window(1)*options.fs_ana, options.fs_ana)];  

                    stim_labels = [stim_labels, 'optical_flow'];

                end
                
                %% Load the face motion velocity
                if ismember('face_motion', options.stim_labels)

                    fprintf('Loading face motion ...\n')
                    
                    face_velocity = load_face_motion(options, options.patients(pat).name, files(f).name, start_sample, end_sample, eye);
                    
                    % Add to the stimulus matrix
                    stim_patient = [stim_patient, ...
                                    tplitz_pf(face_velocity', options.trf_window(2)*options.fs_ana, ...
                                                             -options.trf_window(1)*options.fs_ana, options.fs_ana)];  

                    stim_labels = [stim_labels, 'face_motion'];

                end
                
                %% Split saccades by amplitude and novelty
                if ismember('saccades_high_novelty', options.stim_labels) && ismember('saccades_low_novelty', options.stim_labels)
                    
                    fprintf('Loading the saccades with high and low novelty...\n')
                    
                    [saccades_high_novelty, saccades_low_novelty] = split_saccades_novelty(options, eye, options.patients(pat).name, ...
                        files(f).name, 0);
                    
                    % Resample to match scene cuts
                    saccades_high_novelty = resample_peaks(saccades_high_novelty, length(saccades_high_novelty), ...
                        length(saccades_high_novelty)/length(contrast_ds));
                    saccades_low_novelty = resample_peaks(saccades_low_novelty, length(saccades_low_novelty), ...
                        length(saccades_low_novelty)/length(contrast_ds));
                    
                    % Add to the stimulus matrix
                    stim_patient = [stim_patient, ...
                                    tplitz_pf(saccades_high_novelty', options.trf_window(2)*options.fs_ana, ...
                                                                     -options.trf_window(1)*options.fs_ana, options.fs_ana), ...
                                    tplitz_pf(saccades_low_novelty', options.trf_window(2)*options.fs_ana, ...
                                                                    -options.trf_window(1)*options.fs_ana, options.fs_ana)];  

                    stim_labels = [stim_labels, 'saccades_high_novelty', 'saccades_low_novelty'];
                               
                end

                %% Load the neural data   
                [envelope, labels] = load_envelope(options.data_dir, options.env_dir, options.patients(pat).name, ...
                    options.band_select{b}, files(f).name, contrast_ds, options.fs_ana);

                envelope = zscore(envelope);

                %% Concatentate the data for all videos
                stim = [stim; stim_patient];
                neural = [neural; envelope];

                % Keep track of movies
                vid_idx = [vid_idx; f*ones(length(stim_patient),1)];

            end

            options.stim_labels = stim_labels;

            %% Some help to organize the concatenated stimulus
            % Create a vector of time delays for each sample 
            [~, time] = tplitz_pf(contrast', options.trf_window(2)*options.fs_ana, ...
                                            -options.trf_window(1)*options.fs_ana, options.fs_ana);
            time = [NaN, repmat(time, 1, n_stim)];

            % Create a vector of indices for each column 
            idx_stim = [1:n_stim]' .* ones(n_stim, (size(stim_patient, 2)-1)/n_stim);
            idx_stim = idx_stim';
            idx_stim = idx_stim(:)';
            idx_stim = [0, idx_stim];

            %% Compute the TRF
            % The correlation between predicted signal and original neural signal
            [w, r, p, w_shuffle] = mTRF_filter_flow(stim, neural, vid_idx, lambda, options.n_jack, options.n_shuff, ...
                idx_stim, options.stim_select, options.stim_labels, options.sparsity_th, options.retrain_filter, options.compute_r);

            %% Save the data
            band = options.band_select{b};           
            save(out_file, 'r', 'p', 'w', 'w_shuffle', 'time', 'labels', 'idx_stim', 'lambda', 'band', 'options', '-v7.3')

            if options.run_local
                !sudo reswap
            end

        end

    end

end
    