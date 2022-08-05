%% Copy necessary data to cluster, run TRF and shuffle statistics, copy results to local machine
function compute_TRF_cluster(options)

    %% Check if the results already exist on the local drive
    local_exist = check_results(options.data_dir, options);
    
    % If all files exist locally, let the user decide to recompute TRFs on cluster   
    if sum(local_exist ~= 0) == numel(local_exist)
     
        invalid_input = true;
        
        while invalid_input
            
            user_select = input('TRFs for all patients already exist on local drive. Compute them again on cluster? (y=1/n=0) \n');

            if user_select == 1
                compute_trf = true;
                invalid_input = false;
            elseif user_select == 0
                compute_trf = false;
                invalid_input = false;
            else
                fprintf('Invalid input! Please enter 1 for yes, or 0 for no \n')
            end

        end
        
    % Otherwise check if the results exist on the cluster already
    else
        compute_trf = true;
    end

    %% Check if the results already exist on the cluster
    remote_exist = check_results(options.cluster_data, options);
    
    if sum(remote_exist ~= 0) == numel(remote_exist)
        
        invalid_input = true;
        
        while invalid_input
            
            user_select = input('TRFs for all patients already exist on cluster. Compute them again on cluster? (y=1/n=0) \n');

            if user_select == 1
                compute_trf = true;
                invalid_input = false;
            elseif user_select == 0
                compute_trf = false;
                invalid_input = false;
            else
                fprintf('Invalid input! Please enter 1 for yes, or 0 for no \n')
            end

        end
        
    else
        compute_trf = true;       
    end
    
    if compute_trf
        
        % Mount edison to access as a local folder with sshfs
        if exist(options.cluster_mnt, 'dir') == 0, mkdir(options.cluster_mnt); end
        
        system(sprintf('sshfs -o idmap=user %s:%s %s', options.cluster, options.remote_home, options.cluster_mnt));

        % Copy the data to the cluster
        for pat = 1:length(options.patients)

            % Neural data
            for b = 1:length(options.band_select)
                data2cluster(options, sprintf('%s/%s/%s/%s', ...
                    options.data_dir, options.patients(pat).name, options.env_dir, options.band_select{b}))       
            end

            % Eyetracking data
            data2cluster(options, sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir))

            % Temporal Contrast
            data2cluster(options, sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.contr_dir))
            
            % Face motion
            data2cluster(options, sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.face_vel_dir))

        end

        %% Copy the scene cut annotations 
        % Timing of all scene cuts
        annot_files = dir(options.scene_annot_dir);
        annot_files = annot_files(cellfun(@(C) contains(C, '.xlsx'), {annot_files.name}));

        annot_clust_dir = sprintf('%s/edison/Annotation', options.cluster_mnt);
        if exist(annot_clust_dir, 'dir') == 0, mkdir(annot_clust_dir), end

        for f = 1:length(annot_files)
            system(sprintf('cp %s/%s %s/%s', ...
                options.scene_annot_dir, annot_files(f).name, annot_clust_dir, annot_files(f).name));
        end

        % Data for monkey movies
        monkey_annot_files = dir(options.brian_dir);
        monkey_annot_files([monkey_annot_files.isdir]) = [];

        brian_clust_dir = sprintf('%s/edison/Brians_features', options.cluster_mnt);
        if exist(brian_clust_dir, 'dir') == 0, mkdir(brian_clust_dir), end

        for f = 1:length(monkey_annot_files)
            system(sprintf('cp %s/%s %s/%s', ...
                options.brian_dir, monkey_annot_files(f).name, brian_clust_dir, monkey_annot_files(f).name));
        end

        % Salience cuts
        salience_dir = sprintf('%s/salience_cuts', options.im_data_dir);
        salience_files = dir(salience_dir);
        salience_files([salience_files.isdir]) = [];

        for f = 1:length(salience_files)

            cluster_dir = sprintf('%s/edison_itrf/Data/salience_cuts', options.cluster_mnt);
            if exist(cluster_dir, 'dir') == 0; mkdir(cluster_dir), end

            cluster_file = sprintf('%s/%s', cluster_dir, salience_files(f).name);
            if exist(cluster_file, 'file') ~= 0, continue, end

            system(sprintf('cp %s/%s %s', ...
                strrep(salience_dir, options.local_dropbox, options.bash_dropbox), salience_files(f).name, cluster_file));

        end

        %% Copy the movie name file
        sys_org_dir = strrep(sprintf('%s/Organize', options.drive_dir), options.local_dropbox, options.bash_dropbox);

        clust_org_dir = sprintf('%s/edison_itrf/Organize', options.cluster_mnt);
        if exist(clust_org_dir, 'dir') == 0, mkdir(clust_org_dir), end

        system(sprintf('cp %s/file_names.xlsx %s/file_names.xlsx', sys_org_dir, clust_org_dir));
        system(sprintf('cp %s/vid_data.mat %s/vid_data.mat', sys_org_dir, clust_org_dir));
        
        %% Copy files to determine saccades to faces
        % Saccade classification data and SVM model
        sys_saccade_class = strrep(sprintf('%s', options.saccade_class), options.local_dropbox, options.bash_dropbox);

        clust_saccade_class = sprintf('%s/edison_itrf/Data', options.cluster_mnt);
        if exist(clust_saccade_class, 'dir') == 0, mkdir(clust_saccade_class), end

        system(sprintf('cp -r %s %s', sys_saccade_class, clust_saccade_class));
        
        % Individual video frames 
        clust_frame_dir = sprintf('%s/edison/video_frames', options.cluster_mnt);
        if exist(clust_frame_dir, 'dir') == 0, mkdir(clust_frame_dir), end

        for d = 1:length(options.remote_frames)
            if exist(sprintf('%s/%s', sprintf('%s/%s', clust_frame_dir, options.remote_frames{d})), 'dir') == 0
                system(sprintf('cp -r %s/%s %s', options.frame_dir, options.remote_frames{d}, clust_frame_dir));
            end
        end
        
        % Annotation data
        clust_annot_dir = sprintf('%s/edison/Face_Annotation', options.cluster_mnt);
        
        if exist(clust_annot_dir, 'dir') == 0   
            system(sprintf('cp -r %s %s/edison', options.face_annot_dir, options.cluster_mnt));           
        end
        
        % Save the size of frames in all videos
        out_dir = sprintf('%s/video_frame_size', options.im_data_dir);
        if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
        
        vid_files = dir(options.vid_dir);
        vid_files([vid_files.isdir]) = [];
        
        for v = 1:length(vid_files)
            
            [~, vid_filename] = fileparts(vid_files(v).name);
            out_file = sprintf('%s/%s.mat', out_dir, vid_filename);
            
            if exist(out_file, 'file') == 0
                
                vid = VideoReader(sprintf('%s/%s', options.vid_dir, vid_files(v).name));
                vid_size = [vid.Width, vid.Height];

                save(out_file, 'vid_size')

            end
            
        end
        
        % Copy to cluster
        sys_out_dir = strrep(out_dir, options.local_dropbox, options.bash_dropbox);
        clust_annot_dir = sprintf('%s/edison_itrf/Data/video_frame_size', options.cluster_mnt);
        
        if exist(clust_annot_dir, 'dir') == 0   
            system(sprintf('cp -r %s %s/edison_itrf/Data', sys_out_dir, options.cluster_mnt));           
        end
        
        % Present CMI-NorthShore alignment
        system(sprintf('cp %s/align_ns_cmi_present.mat %s/align_ns_cmi_present.mat', sys_org_dir, clust_org_dir));
        
        % Size of the video frames
        vid_cmi = VideoReader(sprintf('%s/present_cmi/the_present_child_mind.mp4', options.im_data_dir));
        vid_size_cmi = [vid_cmi.Width, vid_cmi.Height];
        
        save(sprintf('%s/present_cmi/vid_size_present_cmi.mat', options.im_data_dir), 'vid_size_cmi');
        
        % Copy to cluster
        sys_present_dir = strrep(sprintf('%s/present_cmi', options.im_data_dir), options.local_dropbox, options.bash_dropbox);

        clust_present_dir = sprintf('%s/edison_itrf/Data/present_cmi', options.cluster_mnt);
        if exist(clust_present_dir, 'dir') == 0
            system(sprintf('cp -r %s %s/edison_itrf/Data', sys_present_dir, options.cluster_mnt));
        end
        
        % Copy the saccade distance by contrastive learning
        clust_distance_dir = sprintf('%s/edison_itrf/Data/ssl_dataset', options.cluster_mnt);
        if exist(clust_distance_dir, 'dir') == 0
            mkdir(clust_distance_dir)
            system(sprintf('cp %s/saccade_features.csv %s/saccade_features.csv', options.saccade_label_dir, clust_distance_dir));
            system(sprintf('cp %s/saccade_features_and_distance.csv %s/saccade_features_and_distance.csv', ...
                options.saccade_label_dir, clust_distance_dir));
        end        
        
        % Copy updated indices of scene cuts
        clust_cut_dir = sprintf('%s/edison_itrf/Data/scene_cuts_frames', options.cluster_mnt);
        if exist(clust_cut_dir, 'dir') == 0
            system(sprintf('cp -r %s %s', options.cut_dir, clust_cut_dir));
        end        

        %% Copy scripts (all functions expect the main file)
        function_dir = sprintf('%s/edison_itrf/Functions', options.cluster_mnt);
        if exist(function_dir, 'dir') == 0, mkdir(function_dir), end

        sys_w_dir = strrep(options.w_dir, options.local_dropbox, options.bash_dropbox);
        sys_master_dir = strrep(sprintf('%s/Master/Filters', options.code_dir), options.local_dropbox, options.bash_dropbox);

        system(sprintf('cp %s/Main_steps/compute_TRF.m %s/compute_TRF.m', sys_w_dir, function_dir));

        system(sprintf('cp %s/Functions/trf_file_parts.m %s/trf_file_parts.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/load_et.m %s/load_et.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/load_scenes.m %s/load_scenes.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/tplitz_pf.m %s/tplitz_pf.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/detect_saccade_onset.m %s/detect_saccade_onset.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/resample_peaks.m %s/resample_peaks.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/load_optical_flow.m %s/load_optical_flow.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/load_face_motion.m %s/load_face_motion.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/load_envelope.m %s/load_envelope.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/mTRF_filter_flow.m %s/mTRF_filter_flow.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/mtrf_multi_train.m %s/mtrf_multi_train.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/interpolateUsingLastGoodValue.m %s/interpolateUsingLastGoodValue.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/find_face_saccades.m %s/find_face_saccades.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/extract_saccade_features.m %s/extract_saccade_features.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/normal_2d.m %s/normal_2d.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/poly_circle.m %s/poly_circle.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/foveal_r.m %s/foveal_r.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/find_saccades_across_cuts.m %s/find_saccades_across_cuts.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/LpFilter.m %s/LpFilter.m', sys_master_dir, function_dir));
        system(sprintf('cp %s/Functions/check_results.m %s/check_results.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/lambda_patient.m %s/lambda_patient.m', sys_w_dir, function_dir));
        system(sprintf('cp %s/Functions/split_saccades_novelty.m %s/split_saccades_novelty.m', sys_w_dir, function_dir));

        %% Edit the settings in the remote options file 
        options.compute_trf = true;
        options.compute_stats = false;
        options.compute_chance = false;

        edit_settings_remote(options);

        %% Compute the TRF
        if options.use_compute_node
            system(sprintf('ssh -t %s ssh max@compute-0-%i matlab -r ''main_ieeg_itrf''', options.cluster, options.compute_node_id));
        else
            system(sprintf('ssh %s matlab -r ''main_ieeg_itrf''', options.cluster));
        end
        
    end

    %% Copy the results to the local drive
    [labels_str, vid_label] = trf_file_parts(options); 

    for pat = 1:length(options.patients)

        local_dir = sprintf('%s/%s/%s/%s', options.data_dir, options.patients(pat).name, options.trf_dir, labels_str(1:end-1));
        remote_dir = sprintf('%s/%s/%s/%s', options.cluster_data, options.patients(pat).name, options.trf_dir, labels_str(1:end-1));

        if exist(local_dir, 'dir') == 0, mkdir(local_dir), end

        for b = 1:length(options.band_select)

            local_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
                local_dir, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda_patient(options, b), options.n_shuff);
            remote_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
                remote_dir, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda_patient(options, b), options.n_shuff);

            if exist(local_file, 'file') ~= 0, continue, end

            fprintf('Copying %s to local drive ... \n', remote_file)

            system(sprintf('cp %s %s', remote_file, strrep(local_file, options.local_dropbox, options.bash_dropbox)));

        end

    end
    
end