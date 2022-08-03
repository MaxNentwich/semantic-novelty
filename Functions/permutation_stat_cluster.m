
function [sig_pat, p_pat, n_clust_elec] = permutation_stat_cluster(w, w_shuff, ...
    labels, h, L, n_shuff, size_prctile, stats_estimate, max_clust)

    % Perform the cluster correction on each electrode in 2D
    % Find electrodes
    elec_names = cell(size(labels));

    for l = 1:length(labels)
    label_elec = strsplit(labels{l},  '-');
    label_elec = strsplit(label_elec{1}, '_');
    elec_names{l} = label_elec{end}(setdiff(1:length(label_elec{end}), ...
        regexp(label_elec{end}, '\d')));
    end

    elec_names = unique(elec_names);

    sig_pat = [];
    p_pat = [];
    
    n_clust_elec = max_clust;

    for e = 1:length(elec_names)

        fprintf('Finding clusters in electrode %s ...\n', elec_names{e});

        idx_elec = cellfun(@(C) contains(C, elec_names{e}), labels);

        % Smooth
        fprintf('Smoothing the data ...\n')
        
        w_elec = smooth_elec(w, idx_elec, h, L);
        w_shuff_elec = smooth_elec(w_shuff, idx_elec, h, L);       
        % Get the statistics for each time points
        max_stat_sum = nan(1,n_shuff);

        if stats_estimate

            [stat_elec, stat_shuff_elec] = estimate_stats_timepoints(w_elec, ...
                w_shuff_elec); 
            
            for s = 1:n_shuff   
                max_stat_sum(s) = region_stat_sum(1-stat_shuff_elec(:,:,s), ...
                    1-(size_prctile/2), false, w_shuff_elec(:,:,s));
            end

        else
            % Get the statistics for each time points
            stat_elec = mean(w_shuff_elec > w_elec, 3);
            stat_elec = min(cat(3, stat_elec, 1-stat_elec), [], 3); 

            fprintf('Computing stats for permutations ...\n')
            parfor s = 1:n_shuff   

                stat_shuff_elec = sum(w_shuff_elec > w_shuff_elec(:,:,s), 3)/(n_shuff-1);
                stat_shuff_elec = min(cat(3, stat_shuff_elec, 1-stat_shuff_elec),[],3);
                max_stat_sum(s) = region_stat_sum(1-stat_shuff_elec, 1-(size_prctile/2), ...
                    false, w_shuff_elec(:,:,s));

            end

        end

        %% Then find the clusters in the original data
        [clust_elec, p_elec, max_clust_id] = ...
            sig_clusters_p_vals(stat_elec, max_stat_sum, size_prctile, ...
            n_clust_elec, stats_estimate, n_shuff, w_elec);

       % Increase the cluster label
        n_clust_elec = n_clust_elec + max_clust_id;

        % Collect data
        sig_pat = [sig_pat; clust_elec];
        p_pat = [p_pat; p_elec];
        
    end

end