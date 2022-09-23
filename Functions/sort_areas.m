
function [regions, jaccard_dist, n_lobes_all, n_lobes_all_sig, n_stacked] = ...
    sort_areas(options_main, regions, jaccard_dist, n_lobes_c1, n_lobes_c2, n_lobes_c3, n_lobes_all, n_lobes_all_sig)

    if strcmp(options_main.atlas, 'lobes')

        idx_sort = cellfun(@(C) find(ismember(regions, C)), options_main.regions_order, 'UniformOutput', false);
        idx_sort(cellfun(@(C) isempty(C), idx_sort)) = [];
        idx_sort = cell2mat(idx_sort);
        
        n_stacked = [];

    elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')

        % Create a matrix with all counts 
        n_stacked = [round(sum(n_lobes_c1)); round(sum(n_lobes_c2)); round(sum(n_lobes_c3))]' ./ round(sum(n_lobes_all))'; 

        [~, idx_sort] = sort(round(sum(n_lobes_all_sig))./round(sum(n_lobes_all)), 'descend');

        n_stacked = n_stacked(idx_sort, :);

    end

    regions = regions(idx_sort);
    jaccard_dist = jaccard_dist(:, idx_sort);

    n_lobes_all_sig = n_lobes_all_sig(:, idx_sort);
    n_lobes_all_sig = round(sum(n_lobes_all_sig));

    n_lobes_all = n_lobes_all(:, idx_sort);
    n_lobes_all = round(sum(n_lobes_all));
    
end