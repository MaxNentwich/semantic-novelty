    
function jaccard_shuff_median = specificity_permutation(labels_all_sig, atlas, n_shuff)

    [loc_all_sig, ~, pat_all_sig] = localize_elecs_bipolar(labels_all_sig, atlas);

    regions = unique(loc_all_sig);
    patients = unique(pat_all_sig); % Might need to be pat_all for some conditions!
    
    %% Shuffle the electrode labels
    n_lobes_shared_shuff = zeros(length(patients), length(regions), n_shuff);
    n_lobes_cond_1_shuff = zeros(length(patients), length(regions), n_shuff);
    n_lobes_cond_2_shuff = zeros(length(patients), length(regions), n_shuff);    
    jaccard_shuff = nan(length(patients), length(regions), n_shuff);
    jaccard_shuff_median = nan(n_shuff, length(regions));
    
    for n = 1:n_shuff
        
        fprintf('Shuffling electrode labels %i/%i \n', n, n_shuff)
        
        for p = 1:length(patients)

            for l = 1:length(regions)

                idx_pat_all_sig = ismember(pat_all_sig, patients{p});           
                idx_loc_all = [cellfun(@(C) contains(C, regions{l}), loc_all_sig(idx_pat_all_sig,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_all_sig(idx_pat_all_sig,2))];   

                % Find label strings in the current region and patient
                labels_pat_all_sig = labels_all_sig(idx_pat_all_sig);
                labels_pat_region_all = labels_pat_all_sig(sum(idx_loc_all, 2) ~= 0);
                
                % Remove outliers (only 1 electrode) is this legit???
                if length(labels_pat_region_all) == 1
                    labels_pat_region_all = labels_pat_region_all(false);
                end
                
                % Shuffle the conditon 
                label_cond = nan(1, length(labels_pat_region_all));
                for i = 1:length(labels_pat_region_all)
                    label_cond(i) = randperm(3,1);
                end
          
                labels_cond_1_shuff = labels_pat_region_all(label_cond == 1);
                labels_cond_2_shuff = labels_pat_region_all(label_cond == 2);
                labels_shared_shuff = labels_pat_region_all(label_cond == 3);
                
                % Find shared electrodes
                idx_loc_shared_shuff = idx_loc_all(ismember(labels_pat_all_sig, labels_shared_shuff), :);
                n_lobes_shared_shuff(p,l,n) = sum(mean(idx_loc_shared_shuff,2));

                idx_loc_cond_1_shuff = idx_loc_all(ismember(labels_pat_all_sig, labels_cond_1_shuff), :);
                n_lobes_cond_1_shuff(p,l,n) = sum(mean(idx_loc_cond_1_shuff,2));

                idx_loc_cond_2_shuff = idx_loc_all(ismember(labels_pat_all_sig, labels_cond_2_shuff), :);
                n_lobes_cond_2_shuff(p,l,n) = sum(mean(idx_loc_cond_2_shuff,2));

            end

        end
        
        jaccard_shuff(:,:,n) = 1 - (n_lobes_shared_shuff(:,:,n) ./ ...
            sum(cat(3, n_lobes_cond_1_shuff(:,:,n), n_lobes_cond_2_shuff(:,:,n), n_lobes_shared_shuff(:,:,n)), 3));

        for r = 1:length(regions)     
            jaccard_shuff_median(n,r) = median(jaccard_shuff(~isnan(jaccard_shuff(:,r,n)), r, n));
        end
    
    end

end