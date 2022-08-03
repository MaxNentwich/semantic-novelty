
function [envelope, labels] = load_envelope(data_dir, env_dir, patient_name, band, file_name, scene_cuts, fs_ana)

    fprintf('Loading the neural data ...\n')

    if fs_ana == 10

        load(sprintf('%s/%s/%s/%s/%s', data_dir, patient_name, env_dir, band, file_name), ...
            'envelope_10Hz', 'labels');

        % Some movies were played sligthly less than 10 mins and thus neural data is padded with zeros 
        % to match stimulus 
        if length(envelope_10Hz) < length(scene_cuts) && ~contains(file_name, 'Monkey')
            envelope_10Hz = [envelope_10Hz; ...
                zeros(length(scene_cuts)-length(envelope_10Hz), size(envelope_10Hz,2))];
        end

        % Other movies have an extra sample in the neural data,
        if length(envelope_10Hz) > length(scene_cuts) && ~contains(file_name, 'Monkey')
            envelope_10Hz = envelope_10Hz(1:length(scene_cuts), :);
        end
        
        envelope = envelope_10Hz;

    else
        
        if strcmp(band, 'raw')
            
            load(sprintf('%s/%s/%s/%s', data_dir, patient_name, env_dir, file_name), 'ieeg');
            
            % Resample the envelopes
            envelope_ds = resample(ieeg.data, 1,  ieeg.fs/fs_ana);
            envelope_ds = [envelope_ds(2:end,:); zeros(1, size(envelope_ds,2))];  
            
            % Electrode labels
            labels = ieeg.label;
            
        else

            load(sprintf('%s/%s/%s/%s/%s', data_dir, patient_name, env_dir, band, file_name), ...
                'envelope_ds', 'fs_ds', 'labels');

            if fs_ds ~= fs_ana
                
                load(sprintf('%s/%s/%s/%s/%s', data_dir, patient_name, env_dir, band, file_name), 'ieeg');

                % Resample the envelopes
                envelope_ds = resample(ieeg.envelope, 1,  ieeg.fs/fs_ana);
                envelope_ds = [envelope_ds(2:end,:); zeros(1, size(envelope_ds,2))];      

            end
        
        end
        
        envelope = envelope_ds;
        
        if length(envelope) > length(scene_cuts)
            envelope = envelope(1:length(scene_cuts), :);
        end

    end

end