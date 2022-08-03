%% Cluster level statistics on computational cluster

function cluster_stats_cluster(options)

    %% Check if the results already exist on the local drive
    % Define the data file 
    [labels_str, vid_label] = trf_file_parts(options); 
    
    for b = 1:length(options.band_select)
        
        vid_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
            options.stats_data, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda_patient(options, b), options.n_shuff);

        local_exist(b) = exist(vid_file, 'file');

    end

    % If all files exist locally, let the user decide to recompute TRFs on cluster   
    if sum(local_exist ~= 0) == numel(local_exist)
     
        invalid_input = true;
        
        while invalid_input
            
            user_select = input('Stats for all frequency bands already exist on local drive. Compute them again on cluster? (y=1/n=0) \n');

            if user_select == 1
                compute_stats = true;
                invalid_input = false;
            elseif user_select == 0
                compute_stats = false;
                invalid_input = false;
            else
                fprintf('Invalid input! Please enter 1 for yes, or 0 for no \n')
            end

        end
        
    % Otherwise check if the results exist on the cluster already
    else
        compute_stats = true;
    end

    %% Check if the results already exist on the cluster
    remote_stats_dir = sprintf('%s/edison/Data/stats', options.cluster_mnt); 

    for b = 1:length(options.band_select)
        
        vid_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
            remote_stats_dir, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda_patient(options, b), options.n_shuff);

        remote_exist(b) = exist(vid_file, 'file');

    end
    
    if sum(remote_exist ~= 0) == numel(remote_exist)
        
        invalid_input = true;
        
        while invalid_input
            
            user_select = input('Stats for all frequency bands already exist on cluster. Compute them again on cluster? (y=1/n=0) \n');

            if user_select == 1
                compute_stats = true;
                invalid_input = false;
            elseif user_select == 0
                compute_stats = false;
                invalid_input = false;
            else
                fprintf('Invalid input! Please enter 1 for yes, or 0 for no \n')
            end

        end
        
    else
        compute_stats = true;
    end

    if compute_stats

        %% Copy scripts (all functions expect the main file)
        function_dir = sprintf('%s/edison_itrf/Functions', options.cluster_mnt);
        if exist(function_dir, 'dir') == 0, mkdir(function_dir), end

        sys_w_dir = strrep(options.w_dir, options.local_dropbox, options.bash_dropbox);

        system(sprintf('cp %s/Main_steps/cluster_stats.m %s/cluster_stats.m', sys_w_dir, function_dir));

        system(sprintf('cp %s/Functions/lambda_patient.m %s/lambda_patient.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/trf_file_parts.m %s/trf_file_parts.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/permutation_stat_cluster.m %s/permutation_stat_cluster.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/smooth_elec.m %s/smooth_elec.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/estimate_stats_timepoints.m %s/estimate_stats_timepoints.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/region_stat_sum.m %s/region_stat_sum.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/sig_clusters_p_vals.m %s/sig_clusters_p_vals.m', sys_w_dir, function_dir));

        %% Edit the settings in the remote options file 
        options.compute_trf = false;
        options.compute_stats = true;
        options.compute_chance = false;

        edit_settings_remote(options);

        %% Compute the TRF
        if options.use_compute_node
            system(sprintf('ssh -t %s ssh max@compute-0-%i matlab -r ''main_ieeg_itrf''', options.cluster, options.compute_node_id));
        else
            system(sprintf('ssh %s matlab -r ''main_ieeg_itrf''', options.cluster));
        end

    end

    %% Copy the results 
    for b = 1:length(options.band_select)
        
        local_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
            options.stats_data, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda_patient(options, b), options.n_shuff);
        remote_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
            remote_stats_dir, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda_patient(options, b), options.n_shuff);

        if exist(local_file, 'file') ~= 0, continue, end
        
        local_file = strrep(local_file, options.local_dropbox, options.bash_dropbox);

        fprintf('Copying %s to local drive ... \n', remote_file)
        system(sprintf('cp %s %s', remote_file, local_file));

    end

end