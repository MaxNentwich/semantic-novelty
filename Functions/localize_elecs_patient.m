% Get number of electrodes in each areas split by patient

function [n_lobes_all, n_lobes_all_sig, n_lobes_cond_1, n_lobes_cond_2, n_lobes_cond_3, regions, patients, loc_all, pat_all] = ...
    localize_elecs_patient(labels_all, labels_all_sig, labels_cond_1, labels_cond_2, labels_cond_3, atlas)

    [loc_all, ~, pat_all] = localize_elecs_bipolar(labels_all, atlas); 

    [loc_all_sig, ~, pat_all_sig] = localize_elecs_bipolar(labels_all_sig, atlas);
    [loc_cond_1, ~, pat_cond_1] = localize_elecs_bipolar(labels_cond_1, atlas);
    [loc_cond_2, ~, pat_cond_2] = localize_elecs_bipolar(labels_cond_2, atlas);
    [loc_cond_3, ~, pat_shared] = localize_elecs_bipolar(labels_cond_3, atlas);

    regions = unique(loc_all_sig);
    patients = unique(pat_all);

    % Count the number of electrodes in each lobe
    n_lobes_all_sig = zeros(length(patients), length(regions));
    n_lobes_all = zeros(length(patients), length(regions));
    n_lobes_cond_1 = zeros(length(patients), length(regions));
    n_lobes_cond_2 = zeros(length(patients), length(regions));
    n_lobes_cond_3 = zeros(length(patients), length(regions));

    %% Count the number of electrodes in each region 
    for p = 1:length(patients)

        for l = 1:length(regions)
            
            idx_pat_all_sig = ismember(pat_all_sig, patients{p});
            idx_loc_pat_all_sig = [cellfun(@(C) contains(C, regions{l}), loc_all_sig(idx_pat_all_sig,1)), ...
                cellfun(@(C) contains(C, regions{l}), loc_all_sig(idx_pat_all_sig,2))];
            n_lobes_all_sig(p,l) = sum(mean(idx_loc_pat_all_sig, 2));
            
            % Find label strings in the current region and patient
            labels_pat_all_sig = labels_all_sig(idx_pat_all_sig);
            labels_pat_region_all = labels_pat_all_sig(sum(idx_loc_pat_all_sig, 2) ~= 0);
            
            % Remove outliers (only 1 electrode) is this legit???
            if length(labels_pat_region_all) == 1
                continue
            end
   
            idx_pat_all = ismember(pat_all, patients{p});           
            n_lobes_all(p,l) = sum(mean([cellfun(@(C) contains(C, regions{l}), loc_all(idx_pat_all,1)), ...
                cellfun(@(C) contains(C, regions{l}), loc_all(idx_pat_all,2))], 2));

            idx_cond_1 = ismember(pat_cond_1, patients{p});
            idx_loc_cond_1 = [cellfun(@(C) contains(C, regions{l}), loc_cond_1(idx_cond_1,1)), ...
                cellfun(@(C) contains(C, regions{l}), loc_cond_1(idx_cond_1,2))];       
            n_lobes_cond_1(p,l) = sum(mean(idx_loc_cond_1,2)); 
    
            idx_cond_2 = ismember(pat_cond_2, patients{p});
            idx_loc_cond_2 = [cellfun(@(C) contains(C, regions{l}), loc_cond_2(idx_cond_2,1)), ...
                cellfun(@(C) contains(C, regions{l}), loc_cond_2(idx_cond_2,2))];
            n_lobes_cond_2(p,l) = sum(mean(idx_loc_cond_2,2)); 

            idx_cond_3 = ismember(pat_shared, patients{p});
            n_lobes_cond_3(p,l) = sum(mean([cellfun(@(C) contains(C, regions{l}), loc_cond_3(idx_cond_3,1)), ...
                cellfun(@(C) contains(C, regions{l}), loc_cond_3(idx_cond_3,2))],2));

        end

    end
   
end