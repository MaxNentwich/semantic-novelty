%% Function to find the test statistic in selected clusters
% Edited to work on the test statistic (here just the difference between filters) 

function [max_stat_sum, stat_dist, labeled_x] = region_stat_sum(stat_values, stat_thr, use_num, varargin)

    % Find all connected clusters 
    [labeled_x, num_regions] = bwlabel(abs(stat_values) > stat_thr);
    props = regionprops(labeled_x, 'Area', 'PixelList');

    % To test for the size of clusters in pixels (smaller clusters with
    % large responses might not survive)
    if use_num
        stat_dist = [props.Area];
        
    % Otherwise sum the test statistic in each cluster
    else
        if isempty(varargin)
            error('Filter weights are needed as function argument!')
        end
        stat_dist = zeros(1,num_regions);
        for j = 1:num_regions
%             stat_dist(j) = sum(sum(abs(varargin{1}).*(labeled_x == j)));
            stat_dist(j) = sum(sum((varargin{1}.^2).*(labeled_x == j)));
        end
    end

    % Find the largest sum of the test statistic (or number of pixels) across all clusters
    if isempty(stat_dist)
        max_stat_sum =  0;
    else
        max_stat_sum = max(stat_dist);
    end
    
    if isempty(max_stat_sum)
        max_stat_sum = NaN;
    end

end