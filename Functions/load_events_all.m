%% function to load event boundaries

function [boundaries_vector, reaction_time, n_hit, participants] = load_events_all(data_dir, fs, T)

    data_files = dir(data_dir);
    data_files([data_files.isdir]) = [];
    data_files(cellfun(@(C) ~contains(C, '.csv'), {data_files.name})) = [];
    data_files(cellfun(@(C) ~contains(C, 'Database_AllParticipants'), {data_files.name})) = [];
    data_files(cellfun(@(C) contains(C, '.~lock.'), {data_files.name})) = [];

    event_results = readtable(sprintf('%s/%s', data_files.folder, data_files.name));

    % Create a time axis
    time = 0:1/fs:T-(1/fs);

    %% Extract the data for each participant

    % Find the unique participants 
    participants = unique(event_results.participant);

    % Exclude myself 
    participants(cellfun(@(C) strcmp(C, '607dbe86d7f905ecfbff3f14'), participants)) = [];

    for p = 1:length(participants)
        
        idx_participant = cellfun(@(C) strcmp(C, participants{p}), event_results.participant);

        %% Load the control task if available 
        load('response_time_vid.mat', 't_flash')

        if ismember('resp_time_key_rt', event_results.Properties.VariableNames)
           
            resp_time_str = event_results.resp_time_key_rt(idx_participant);
            resp_time_str(cellfun(@(C) isempty(C), resp_time_str)) = [];

            if isempty(resp_time_str)
                
                reaction_time(p) = 0;
                n_hit(p) = 0;
                
            else
                
                % Convert the string to double
                resp_time_str = strsplit(resp_time_str{1}, ',');
                resp_time_str = cellfun(@(C) strrep(C, '[', ''), resp_time_str, 'UniformOutput', false);
                resp_time_str = cellfun(@(C) strrep(C, ']', ''), resp_time_str, 'UniformOutput', false);

                resp_time = cellfun(@(C) str2double(C), resp_time_str);

                % Exclude double clics
                idx_double = diff(resp_time) < 0.5;
                resp_time(find(idx_double)+1) = [];

                rt = [];

                for i = 1:length(resp_time)
                    delays = resp_time(i) - t_flash;
                    delays(delays < 0) = [];
                    rt(i) = min(delays);
                end

                %% Delete more missing double clicks or clicks that don't match scenes
                rt(rt > mean(rt)+2*std(rt)) = [];

                reaction_time(p) = mean(rt);
                n_hit(p) = length(rt);
                
            end
            
        else
            reaction_time(p) = NaN;
            n_hit(p) = NaN;
            
        end

        %% Process the event boundaries
        if contains(data_dir, 'Despicable_Me')
            event_str = event_results.event_boundaries_rt(idx_participant);
            event_str(cellfun(@(C) isempty(C), event_str)) = [];
        else
            event_str = event_results.events_movies_rt(idx_participant);
            event_str(cellfun(@(C) isempty(C), event_str)) = [];
        end
        
        if ~isempty(event_str)

            % Convert the string to double
            event_str = strsplit(event_str{1}, ',');
            event_str = cellfun(@(C) strrep(C, '[', ''), event_str, 'UniformOutput', false);
            event_str = cellfun(@(C) strrep(C, ']', ''), event_str, 'UniformOutput', false);

            event_time = cellfun(@(C) str2double(C), event_str);

            % Interpolate the time axis
            event_idx = round(interp1(time, 1:length(time), event_time));
            event_idx(isnan(event_idx)) = [];
            
            % Exclude double clics
            idx_double = diff(event_idx/fs) < 0.5;
            event_idx(find(idx_double)+1) = [];
            
            % Adjust for reaction time
            if ~isnan(reaction_time(p))
                event_idx = round((event_idx/fs - reaction_time(p))*fs);
            end
            
            % Create a 0/1 vector
            event_boundaries = zeros(size(time));
            event_boundaries(event_idx) = 1;

            % Collect data
            boundaries_vector(p,:) = event_boundaries;
            
        else
            boundaries_vector(p,:) = zeros(size(time));
        end
       
    end
    
end