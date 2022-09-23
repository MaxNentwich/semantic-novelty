
function [p_sm, p_pair, median_dist, N] = compute_stats_specificity(jaccard_dist, regions)

    median_dist = nanmedian(jaccard_dist);
    N = sum(~isnan(jaccard_dist));
    
    % https://github.com/thomaspingel/skillmack-matlab/blob/master/skillmack.m
    p_sm = skillmack(jaccard_dist);

    % Pairwise tests
    p_pair = nan(1,length(regions));
    for r = 1:length(regions)
        p_pair(r) = signrank(jaccard_dist(:,r));
    end

    p_pair = mafdr(p_pair, 'BHFDR', true);
    
end