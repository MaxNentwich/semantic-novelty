%% Load all filters and test if any time points are significant compared to the filters trained 
% on shuffled time points

function cluster_stats(options)

    % Copy options from main file
    options_main = options;
    
    if exist(options_main.stats_data, 'dir') == 0, mkdir(options_main.stats_data), end
    
    for b = 1:length(options.band_select)
        
        % Define the Gaussian for smoothing
        h = gausswin(options_main.smoothing_L, options_main.smooting_alpha);
        h = h/sum(h);

        % Regularization parameter
        lambda = lambda_patient(options, b);

        % Define the data file 
        [labels_str, vid_label] = trf_file_parts(options); 

        vid_file = sprintf('%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
            vid_label, labels_str, options.band_select{b}, options.fs_ana, lambda, options.n_shuff);

        %% Load the data
        if exist(sprintf('%s/%s', options.stats_data, vid_file), 'file') == 0
        
            labels_all = [];
            w_all = cell(1, length(options.stim_select));
            sig_all = cell(1, length(options.stim_select));
            p_all = cell(1, length(options.stim_select));
            n_clust = zeros(1, length(options.stim_select));
            
            idx_pat = 1;
            
        else

            load(sprintf('%s/%s', options.stats_data, vid_file), 'w_all', 'sig_all', 'p_all', 'labels_all',  'n_clust', 'options')
            
            str_last = strsplit(labels_all{end}, '_');
            if length(str_last) == 3
                patient_last = str_last{1};
            elseif length(str_last) == 5
                patient_last = sprintf('%s_%s', str_last{1}, str_last{2});
            end
            
            idx_pat = find(ismember({options.patients.name}, patient_last)) + 1;
            
        end

        if idx_pat <= length(options.patients)

            for pat = idx_pat:length(options.patients)

                fprintf('Loading Patient %s ...\n', options.patients(pat).name);

                result_dir = sprintf('%s/%s/%s/%s', options.data_dir, options.patients(pat).name, options.trf_dir, labels_str(1:end-1));

                result_file = sprintf('%s/%s', result_dir, vid_file);
                if exist(result_file, 'file') == 0, continue, end

                load(result_file, 'labels', 'options') 

                % Reorganize the labels (add the patient ID because several patients have the same electrode names)
                for l = 1:length(labels)
                   label_parts = strsplit(labels{l}, '-');
                   labels{l} = sprintf('%s_%s-%s_%s', options.patients(pat).name, label_parts{1}, options.patients(pat).name, label_parts{2});
                end

               for s = 1:length(options.stim_select)

                    load(result_file, 'w', 'w_shuffle', 'idx_stim')  

                    % Find the right stimulus
                    idx_stim_select = idx_stim == find(ismember(options.stim_labels, options.stim_select{s}));

                    % Find significant time points and perform cluster correction
                    w_pat = w(idx_stim_select, :)';
                    w_shuff_pat = permute(w_shuffle(idx_stim_select, :, :), [2,1,3]);

                    clearvars w_shuffle

                    tic
                    [sig_pat, p_pat, n_clust_elec] = permutation_stat_cluster(w_pat, w_shuff_pat, labels, ...
                        h, options_main.smoothing_L, options.n_shuff, options_main.size_prctile, ...
                        options_main.stats_estimate, n_clust(s));
                    toc

                    clearvars w_shuff_pat

                    n_clust(s) = n_clust_elec;

                    % Concatenate data
                    w_all{s} = [w_all{s}; w_pat];
                    sig_all{s} = [sig_all{s}; sig_pat];
                    p_all{s} = [p_all{s}; p_pat];

                end

                labels_all = [labels_all; labels];

                save(sprintf('%s/%s', options.stats_data, vid_file), 'w_all', 'sig_all', 'p_all', 'labels_all',  'n_clust', 'options')

            end

        end
        
    end
    
end