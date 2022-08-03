
function [p, sig] = fdr_corr(p, sig)

    % Correct the indices of the significant clusters
    clust_idx = unique(sig);
    clust_idx(clust_idx == 0) = [];
    
    for i = 1:length(clust_idx)
        sig(sig == clust_idx(i)) = i;
    end
    
    % FDR correction of p values
    p_corr = mafdr(p, 'BHFDR', true);

    % Remove non-significant clusters and p-values
    idx_nsig = find(p_corr > 0.05);
    for c = 1:length(idx_nsig), sig(sig == idx_nsig(c)) = 0; end
    p(idx_nsig) = [];
    
    % Set all clusters to 1
    sig(sig ~= 0) = 1;
    
end