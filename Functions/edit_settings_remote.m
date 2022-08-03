%% Edit the settings in a file on a remote cluster

function edit_settings_remote(options)

    file_name = sprintf('%s/main_ieeg_itrf.m', options.cluster_mnt);
    
    %% Read the file contents
    file_id = fopen(file_name);
    
    c = 1;
    line = fgetl(file_id);
    lines{c} = line;
    
    while ischar(line)
        c = c + 1;
        line = fgetl(file_id);
        lines{c} = line;
    end
    
    fclose(file_id);
    
    % remove -1 entry at the end
    lines(cellfun(@(C) ~ischar(C), lines)) = [];
    
    %% Edit the contents
  
    % Visualize TRFs
    lines = edit_num(lines, options.visualize_trfs, 'visualize_trfs');
    
    % Number of parallel workers
    lines = edit_num(lines, sprintf('%i', options.parallel_workers), 'parallel_workers');
    
    % Names of selected frequency bands
    lines = edit_cell(lines, options.band_select, 'band_select');

    % Stimuli included in analysis
    lines = edit_cell(lines, options.stim_labels, 'stim_labels');
    
    % Stimuli selected for analysis 
    lines = edit_cell(lines, options.stim_select, 'stim_select');
    
    % Videos selected
    lines = edit_cell(lines, options.vid_names, 'vid_names');
    
    % Frequency bands
    lines = edit_mat(lines, options.freq_bands, 'freq_bands');
    lines = edit_cell(lines, options.band_names, 'band_names');
    lines = edit_mat(lines, options.lambda_bands, 'lambda_bands');
    lines = edit_num(lines, sprintf('%1.2f', options.lambda_raw), 'lambda_raw');
    
    % Eyetracking triggers
    lines = edit_num(lines, sprintf('%i', options.trigger_IDs.start_ID), 'trigger_IDs.start_ID');
    lines = edit_num(lines, sprintf('%i', options.trigger_IDs.end_ID_1), 'trigger_IDs.end_ID_1');
    lines = edit_num(lines, sprintf('%i', options.trigger_IDs.end_ID_2), 'trigger_IDs.end_ID_2');
    
    % Time window for TRF analysis
    lines = edit_mat(lines, options.trf_window, 'trf_window');
    
    % Saccade detection
    lines = edit_num(lines, sprintf('%1.2f', options.vel_th), 'vel_th');
    lines = edit_mat(lines, options.peri_saccade_window, 'peri_saccade_window');
    lines = edit_num(lines, sprintf('%1.2f', options.min_diff), 'min_diff');
    lines = edit_num(lines, sprintf('%1.2f', options.t_after), 't_after');
    lines = edit_num(lines, sprintf('%1.2f', options.t_before), 't_before');
    lines = edit_num(lines, sprintf('%1.2f', options.t_around), 't_around');
    lines = edit_num(lines, sprintf('''%s''', options.saccade_selection), 'saccade_selection');
    
    % Sampling rate
    lines = edit_num(lines, sprintf('%1.2f', options.fs_ana), 'fs_ana');
    
    % Statistics and training 
    lines = edit_num(lines, sprintf('%i', options.n_shuff), 'n_shuff');
    lines = edit_num(lines, sprintf('%i', options.n_jack), 'n_jack');
    lines = edit_num(lines, options.compute_r, 'compute_r');
    lines = edit_num(lines, options.retrain_filter, 'retrain_filter');
    lines = edit_cell(lines, options.features_circular_shuffle, 'features_circular_shuffle');
    lines = edit_num(lines, sprintf('%1.5f', options.sparsity_th), 'sparsity_th');
    
    % Cluster correction
    lines = edit_num(lines, sprintf('%i', options.smoothing_L), 'smoothing_L');
    lines = edit_num(lines, sprintf('%1.2f', options.smooting_alpha), 'smooting_alpha');
    lines = edit_num(lines, sprintf('%1.5f', options.size_prctile), 'size_prctile');
    lines = edit_num(lines, options.stats_estimate, 'stats_estimate');
    
    % Compute the TRF or statistics
    lines = edit_num(lines, options.compute_trf, 'compute_trf');
    lines = edit_num(lines, options.compute_stats, 'compute_stats');
    lines = edit_num(lines, options.compute_chance, 'compute_chance');
    
    % Saccade classification   
    lines = edit_num(lines, sprintf('%1.1f', options.scale_threshold), 'scale_threshold');
    lines = edit_num(lines, sprintf('%1.2f', options.p_amplitude_similarity), 'p_amplitude_similarity');

    %% Wrtie the edited file
    file_out = fopen(file_name, 'w');
    
    for l = 1:length(lines)
        fprintf(file_out, '%s\n', lines{l});
    end
    
    fclose(file_out);
    
end