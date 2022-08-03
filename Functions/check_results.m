    
function local_exist = check_results(data_dir, options)

    [labels_str, vid_label] = trf_file_parts(options); 
    
    for pat = 1:length(options.patients)
        
        out_dir = sprintf('%s/%s/%s/%s', data_dir, options.patients(pat).name, options.trf_dir, labels_str(1:end-1));

        for b = 1:length(options.band_select)

            local_file = sprintf('%s/%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
                out_dir, vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda_patient(options, b), options.n_shuff);
            
            local_exist(pat,b) = exist(local_file, 'file');
            
        end

    end
    
end