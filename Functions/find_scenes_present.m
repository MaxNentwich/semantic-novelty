   
function find_scenes_present(options, video)

    out_file = sprintf('%s/present_cmi/cuts_present_cmi.mat', options.im_data_dir);
    
    if exist(out_file, 'file') == 0
        
        % Compute the temporal contrast
        contr_file = sprintf('%s/present_cmi/temp_contr_the_present_cmi.mat', options.im_data_dir);

        if exist(contr_file, 'file') == 0
            
            [contrast, fr] = compute_temporal_contrast(sprintf('%s/present_cmi/the_present_child_mind.mp4', options.im_data_dir));

            save(contr_file, 'contrast', 'fr')
            
        else
            load(contr_file, 'contrast')
        end
        
        % Load the scene cuts (NorthShore version)
        scene_table = xlsread(sprintf('%s/%s_scenes.xlsx', options.scene_annot_dir, video));
        cuts_ns = scene_table(:,1);   

        % Load the video data (number of frames, frame rate)
        load(sprintf('%s/Organize/vid_data.mat', options.drive_dir), 'vid_names', 'n_frame', 'fr')
        idx_vid = cellfun(@(C) contains(C, video), vid_names);

        % Create a vector
        cuts_ns_vec = zeros(1, n_frame(idx_vid));
        cuts_ns_vec(cuts_ns) = 1;

        % Align to the cmi version
        load(sprintf('%s/Organize/align_ns_cmi_present.mat', options.drive_dir), 'resampling_ratio', 'offset')
        cuts_cmi_vec = resample_peaks(cuts_ns_vec(offset+1:end), fr(idx_vid), 1/resampling_ratio);
        cuts_cmi_vec = cuts_cmi_vec(1:length(contrast));

        % Save the data 
        cuts = find(cuts_cmi_vec);
        save(out_file, 'cuts')
        
        % Figure for verification purposes
        figure
        hold on

        plot(contrast)
        plot(0.5*mean(contrast(cuts_cmi_vec ~= 0)) * cuts_cmi_vec)

    end
    
end