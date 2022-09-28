
function [p_sm, p_pair, median_dist, N] = compute_stats_specificity(jaccard_dist, jaccard_shuff_median)

    median_dist = nanmedian(jaccard_dist);
    N = sum(~isnan(jaccard_dist));
    
    % https://github.com/thomaspingel/skillmack-matlab/blob/master/skillmack.m
    p_sm = skillmack(jaccard_dist);

    % Pairwise tests
    p_pair = mean(nanmedian(jaccard_dist) <= jaccard_shuff_median);
    p_pair(p_pair == 0) = 1/size(jaccard_shuff_median,1);
    
    p_pair = mafdr(p_pair, 'BHFDR', true);

end