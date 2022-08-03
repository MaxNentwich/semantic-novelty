           
function c = cluster_trf_results(w)

    % Compute a correlation matrix
    w_corr = corr(w');
            
    % Plot the filters and correlation between them 
    figure
    imagesc(w_corr)
    xlabel('Channel')
    ylabel('Channel')
    title('Correlation')
    colorbar

    % Choose the number of clusters
    success = false;

    while ~ success

        K = input('How many clusters are there?\n');
        
        if K > 1
            
            c = direcClus_fix_bessel_bsxfun(w_corr, K, size(w_corr, 2)-1, 1e2, 500, 0, 0, 1e-4, 1, 1e3, 1);
            [~, idx_clust] = sort(c.clusters);

            figure
            imagesc(w_corr(idx_clust, idx_clust))
            xlabel('Channel')
            ylabel('Channel')
            title('Correlation')
            colorbar
            
        else
            c.clusters = ones(size(w,1), 1);
        end
        
        success = input('Did the clustering work? (yes=1/no=0)\n') == 1;

    end
    
end
            