%% Find the difference between saccade and fixation onset

function saccade_duration(options)

    saccade_duration = [];
    
    % Output directory
    out_dir = sprintf('%s/saccades_duration', options.fig_dir);
    if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
    
    file_duration = sprintf('%s/saccade_duration.png', out_dir);
    
    if exist(file_duration, 'file') == 0

        %% The TRF is computed for each patient separately    
        for pat = 1:length(options.patients)

            %% Create the file name and check if the file is already there
            % Create output directory if necessary            
            sacc_dir = sprintf('%s/Data/saccade_data', options.w_dir);            
            if exist(sacc_dir, 'dir') == 0, mkdir(sacc_dir), end        

            %% Check which movie files were recorded for the patient
            fprintf('Processing patient %s ...\n', options.patients(pat).name)

            % Get a list of movies recorded for the current patient
            files = dir(sacc_dir);
            files([files.isdir]) = [];

            file_pat = cell(length(files),1);

            for i = 1:length(files)
                parts = strsplit(files(i).name, '_');
                if str2double(parts{2}) == 2
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

                %% Load the eyetracking data 
                fprintf('Loading the saccades ...\n')

                load(sprintf('%s/%s', sacc_dir, files(f).name), 'saccade_onset', 'fixation_onset', 'eye')

                saccade_duration = [saccade_duration; (find(fixation_onset) - find(saccade_onset)) / eye.fs * 1e3];

            end

        end

        histogram(saccade_duration, 35)

        xlabel('Saccade Duration [ms]')
        ylabel('Number of Saccades')

        grid on 
        grid minor

        set(gca, 'FontSize', 22)

        saveas(gca, file_duration)
        
    end

end
    