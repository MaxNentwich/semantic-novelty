% Load the foveal radius from all patients and compute the mean

function r_all = foveal_r_all(options)

    r_all = [];

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

            load(out_file, 'r')

            r_all = [r_all, r];

        end

    end
    
end