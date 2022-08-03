%% Create a table with the number of channels in each electrode file and the number of channels in the data
% To double check if the alignment is alright

function check_label_files(options)

    % Output file 
    out_file = sprintf('%s/Data_consistency/label_files.csv', options.w_dir);
    
    if exist(out_file, 'file') == 0
        
        n_channel_label = nan(length(options.patients),1);
        n_channels_data = nan(length(options.patients),1);
        solution = cell(length(options.patients),1);
        channel_sheet = cell(length(options.patients),1);

        for p = 1:length(options.patients)

            % Load the names of the iEEG data folders
            ieeg_names = file_corresp(options.data_dir, options.patients(p).name, options.task);

            data_folder = sprintf('%s/%s/Neural/%s/%s', options.data_dir, options.patients(p).name, options.task, ieeg_names{1});

            %% Import TDT    
            EEG1 = TDTbin2mat(data_folder, 'T1', 0, 'T2', 1, 'STORE', 'EEG1');
            EEG2 = TDTbin2mat(data_folder, 'T1', 0, 'T2', 1, 'STORE', 'EEG2');

            if isempty(EEG1.streams)
                EEG1 = TDTbin2mat(data_folder, 'T1', 0, 'T2', 1, 'STORE', 'RAWx');
                EEG1.streams.EEG1.data = EEG1.streams.RAWx.data;
                EEG1.streams.EEG1.fs = EEG1.streams.RAWx.fs;
            end

            %% Import all depth and strips/grids, based on xls sheet.
            ieeg.data = EEG1.streams.EEG1.data;         
            ieeg.fs = EEG1.streams.EEG1.fs;  

            clearvars EEG1

            % Combine first and second block
            if ~isempty(EEG2.streams)

                data2 = EEG2.streams.EEG2.data;
                fs2 = EEG2.streams.EEG2.fs;

                clearvars EEG2

                if fs2 ~= ieeg.fs
                    error('Sampling rates of EEG data blocks are different! \n')
                end

                ieeg.data = [ieeg.data; data2]; 

            end

            clearvars data1 data2

            %% Import labels
            % Excel file with channel labels and definitions (which are bad, outside brain, within soz etc.)
            label_file = sprintf('%s/%s/Anatomy/%s_Electrode_Labels_TDT.xlsx', ...
                options.data_dir, options.patients(p).name, options.patients(p).name);

            labels = import_label(label_file);

            %% 'Solution'
            if height(labels) > size(ieeg.data,1)  
                d = height(labels) - size(ieeg.data,1);
                solution{p} = sprintf('%i extra labels at the end removed', d);   
            elseif height(labels) < size(ieeg.data,1)   
                d = size(ieeg.data,1) - height(labels);
                solution{p} = sprintf('%i extra data channels at the end removed', d); 
            else
                solution{p} = '';
            end

            % Find the original channel file
            recon_files = dir(sprintf('%s/%s/elec_recon', options.fs_dir, options.patients(p).name));
            elec_files = recon_files(cellfun(@(C) contains(C, '_TDT'), {recon_files.name}));

            if length(elec_files) == 1
                channel_sheet{p} = elec_files.name;
            else
                for i = 1:length(elec_files)
                    fprintf('%i ... %s \n', i, elec_files(i).name)
                end
                selection = input('Which electrode sheet was used?');
                channel_sheet{p} = elec_files(selection).name;
            end

            %% Collect the data
            n_channel_label(p) = height(labels);
            n_channels_data(p) = size(ieeg.data,1);

        end

        T = table({options.patients.name}', channel_sheet, n_channel_label, n_channels_data, solution, ...
            'VariableNames', {'Patient', 'Label File', 'Channels in label file', 'Channels in data', 'Solution'});

        writetable(T, out_file)
        
    end

end