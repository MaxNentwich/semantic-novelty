
function [clusters, p_vals, max_clust_id] = ...
    sig_clusters_p_vals(stat_elec, max_stat_sum, size_prctile, max_clust, estimate, n_shuffle, varargin)

    %% Then find the clusters in the original data
    if isempty(varargin)
        [~, stat_dist, clusters] = region_stat_sum(1-stat_elec, 1-(size_prctile/2), true);
    else
        [~, stat_dist, clusters] = region_stat_sum(1-stat_elec, 1-(size_prctile/2), false, varargin{1});
    end
    
    % Increase the cluster label
    clust_id = unique(clusters);
    clust_id(clust_id == 0) = [];

    if ~isempty(max(clust_id))

        for c = length(clust_id):-1:1
            clusters(clusters == c) = max_clust + c;
        end
        
        max_clust_id = max(clust_id);

    else
        max_clust_id = 0;
    end
    
    % P-values
    if estimate
        
        if ~isempty(stat_dist)

            pdf_max = 1.2*max([max(max_stat_sum(:)), max(stat_dist(:))]);           
            points = linspace(-0.1*pdf_max, pdf_max, 10000);

            % Fit the pdf
            [f,xi] = ksdensity(max_stat_sum, points);

            % Estimate the p-value
            p_vals = zeros(size(stat_dist));

            for i = 1:length(stat_dist)           
                idx_pdf = round(interp1(xi, 1:length(xi), stat_dist(i)));
                p_vals(i) = sum(f(idx_pdf:end))*mean(diff(xi));
            end

        else 
            p_vals = [];
        end

    else
        
        if ~isempty(stat_dist)
            if size(stat_dist,1) < size(stat_dist,2), stat_dist = stat_dist'; end
            p_vals = mean(max_stat_sum > stat_dist,2);
            p_vals(p_vals < 1/n_shuffle) = 1/n_shuffle;
        else 
            p_vals = [];
        end
        
    end

    if size(p_vals,2) > size(p_vals,1)
        p_vals  = p_vals';
    end
    
end