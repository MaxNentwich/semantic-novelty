%% Match recordings when no experiment notes are availavble 

function match_et_iEEG(options)

for p = 1:length(options.patients)
    
    % Define the output file name 
    out_file = sprintf('%s/%s/file_correspondance.mat', options.data_dir, options.patients(p).name);
    out_table = sprintf('%s/%s/%s_ExperimentNotes.xlsx', options.data_dir, options.patients(p).name, options.patients(p).name);
    
    if exist(out_table, 'file') ~= 0
        continue
    end
    
    n_files = dir(sprintf('%s/%s/Neural/Movies', options.data_dir, options.patients(p).name));
    n_files(1:2) = [];

    et_files = dir(sprintf('%s/%s/Eyetracking/Movies', options.data_dir, options.patients(p).name));
    et_files(1:2) = [];

    % Load iEEG triggers
    triggs_ecog = cell(1, length(n_files));

    for rec = 1:length(n_files)

        data_hdr = TDTbin2mat(sprintf('%s/%s', n_files(rec).folder, n_files(rec).name), 'HEADERS', 1);

        if isfield(data_hdr.stores, 'PtC2')
            triggs_ecog{rec} = unique([data_hdr.stores.PtC2.onset, ...
                data_hdr.stores.PtC4.onset, data_hdr.stores.PtC6.onset])';
        elseif isfield(data_hdr.stores, 'PC0_')
            triggs_ecog{rec} = unique([data_hdr.stores.PC0_.onset, ...
                data_hdr.stores.PtC4.onset, data_hdr.stores.PtC6.onset])';
        elseif isfield(data_hdr.stores, 'PC2_')
            triggs_ecog{rec} = unique([data_hdr.stores.PC2_.onset, ...
                data_hdr.stores.PC4_.onset, data_hdr.stores.PC6_.onset])';
        end

    end
    
    % Manual correction 
    % NS170_03 contains one extra trigger value in the recording for Despicable Me English
    if strcmp(options.patients(p).name, 'NS174_03')
        triggs_ecog{ismember({n_files.name}, 'B29_DespMeEng')}(22) = [];
    end
    

    % Load ET triggers
    triggs_eye = cell(1, length(et_files));

    for rec = 1:length(et_files)

        load(sprintf('%s/%s', et_files(rec).folder, et_files(rec).name), 'Eye_movie')

        triggs_eye{rec} = double([Eye_movie.timing.ET_time{:,2}])/1e6;

    end

    %% Search for closest match
    distance = nan(length(n_files), length(et_files));

    for rec_n = 1:length(n_files)

        for rec_et = 1:length(et_files)

            if length(triggs_ecog{rec_n}) == length(triggs_eye{rec_et})

                distance(rec_n, rec_et) = pdist([diff(triggs_ecog{rec_n})'; diff(triggs_eye{rec_et})]);

            end

        end

    end

    n_files(sum(isnan(distance), 2) == size(distance, 2)) = [];
    distance(sum(isnan(distance), 2) == size(distance, 2), :) = [];

    % Best match for each iEEG file
    [~, idx_et2n] = min(distance, [], 2);

    % Check
    if length(unique(idx_et2n)) ~= length(idx_et2n)
        error('Some files do not match up unambiguously!')
    end

    % Reorder ET files
    et_files = et_files(idx_et2n);

    %% Save results
    file_correspondance = [extractfield(et_files, 'name')', extractfield(n_files, 'name')'];
    save(out_file, 'file_correspondance')
    
    % Save as a table
    et_names = [{''}; {et_files.name}'];
    n_names = [{''}; {n_files.name}'];
    
    time = repmat({''}, size(et_names));
    notes = repmat({''}, size(et_names));
    
    T = table(time, et_names, n_names, notes, 'VariableNames', {'Time', 'Eyetracking file', 'EEG folder', 'Notes'});

    writetable(T, out_table);
    
end

end