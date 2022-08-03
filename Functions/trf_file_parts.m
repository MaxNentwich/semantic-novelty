%% Create a file name for the TRF results

function [labels_str, vid_label] = trf_file_parts(options) 

    % Create a string for the output file containing the stimuli used
    labels_str = 'neural_shuffle_';
    for s = 1:length(options.stim_labels) 
        labels_str = sprintf('%s%s_', labels_str, options.stim_labels{s});
    end
    
    % Create a string containing the videos (they are not necessarily present for each patient)
    vid_names = options.vid_names;
    idx_present = cellfun(@(C) contains(C, 'The_Present'), options.vid_names);
    if sum(idx_present) ~= 0
        vid_names(idx_present) = [];
        vid_names = [vid_names, 'The_Present'];
    end

    vid_label = '';
    for v = 1:length(vid_names) 
        vid_label = sprintf('%s%s_', vid_label, vid_names{v});
    end   
    
end