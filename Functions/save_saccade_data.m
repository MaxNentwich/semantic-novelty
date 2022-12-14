%% Load eye tracking data for sharing purposes

function save_saccade_data(options)

    %% Compute the TRF for each frequency band selected
    for b = 1:length(options.band_select)

        if strcmp(options.band_select{b}, 'raw')
            options.env_dir = options.raw_dir;
        end

        %% The TRF is computed for each patient separately    
        for pat = 1:length(options.patients)

            %% Create the file name and check if the file is already there
            % Create output directory if necessary            
            out_dir = sprintf('%s/saccade_data', options.im_data_dir);            
            if exist(out_dir, 'dir') == 0, mkdir(out_dir), end        

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
                
                out_file = sprintf('%s/%s_%s', out_dir, options.patients(pat).name, files(f).name);
                if exist(out_file, 'file'), continue, end
                
                %% Load the eyetracking data 
                fprintf('Loading the eyetracking data ...\n')

                eye = load_et(options.data_dir, options.eye_dir, options.patients(pat).name, ...
                    files(f).name, options.trigger_IDs);
                
                % Trigger samples
                start_sample = eye.triggers.trigger_sample(eye.triggers.trigger_ID == options.trigger_IDs.start_ID);

                end_sample = eye.triggers.trigger_sample(eye.triggers.trigger_ID == options.trigger_IDs.end_ID_1);
                if isempty(end_sample) 
                    end_sample = eye.triggers.trigger_sample(eye.triggers.trigger_ID == options.trigger_IDs.end_ID_2);
                end

                %% Load saccades 
                fprintf('Detecting saccades ...\n')

                [saccade_onset, ~, saccade_amplitude, saccade_speed, ~, fixation_onset, pos_pre, pos_post, distance_screen] = ...
                    detect_saccade_onset(eye, options, options.visualize_trfs);
                              
                eye.left = [];
                eye.right = [];
                save(out_file, 'eye', 'saccade_onset', 'fixation_onset', 'saccade_amplitude', 'saccade_speed', 'pos_pre', 'pos_post', ...
                    'distance_screen', 'start_sample', 'end_sample')
                
            end

        end

    end

end
    