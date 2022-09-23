
function [regions, jaccard_dist, n_lobes_all_sig, n_lobes_c1, n_lobes_c2, n_lobes_c3, n_lobes_all] = ...
    remove_areas(options, regions, jaccard_dist, n_lobes_all_sig, n_lobes_c1, n_lobes_c2, n_lobes_c3, n_lobes_all)

    if ~options.inlude_unknown  

        idx_remove = cellfun(@(C) strcmp(C, 'Unknown'), regions);
        jaccard_dist(:, idx_remove) = [];
        regions(idx_remove) = [];
        n_lobes_all_sig(:, idx_remove) = [];

        n_lobes_c1(:, idx_remove) = [];
        n_lobes_c2(:, idx_remove) = [];
        n_lobes_c3(:, idx_remove) = [];
        n_lobes_all(:, idx_remove) = [];

    end

    if ~options.include_insula             
        idx_remove = cellfun(@(C) strcmp(C, 'Insula'), regions);
        jaccard_dist(:, idx_remove) = [];
        regions(idx_remove) = [];
        n_lobes_all_sig(:, idx_remove) = [];
    end
    
end