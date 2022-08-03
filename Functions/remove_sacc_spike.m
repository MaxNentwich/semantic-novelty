
function [idx_spike, color_spike] = remove_sacc_spike(options, w, idx_sig, spike_dir, spike_file)

    % Define the data file 
    [labels_str, vid_label] = trf_file_parts(options); 
        
    if exist(spike_file, 'file') == 0

        % Compute a correlation matrix between all filters of all channels
        w_faces_sig = w(idx_sig, :);
        corr_w = corr(w_faces_sig');

        % Perform the clustering 
        c = direcClus_fix_bessel_bsxfun(corr_w, options.n_cluster, size(corr_w, 2)-1, 1e3, 500, 0, 0, 1e-4, 1, 1e3, 1);
        [~, idx_clust] = sort(c.clusters);

        % Plot the sorted correlation matrix
        color_options = othercolor('Cat_12');
        color_select = color_options(round(linspace(1, length(color_options), options.n_cluster)), :);
        
        c_sort = c.clusters(idx_clust);        
        cluster_boundary = find(diff(c_sort) ~= 0);
        cluster_boundary = [0; cluster_boundary; size(corr_w,1)];
        
        figure
        imagesc(corr_w(idx_clust, idx_clust))
        axis square

        xlabel('Channel')
        ylabel('Channel')
        cb = colorbar;
        ylabel(cb, 'Correlation Coefficient')
        set(gca, 'FontSize', 22)
        
        for i = 1:length(cluster_boundary)-1
            rectangle('Position', [cluster_boundary(i)+3 cluster_boundary(i)+3 ...
                cluster_boundary(i+1)-cluster_boundary(i)-3 cluster_boundary(i+1)-cluster_boundary(i)-3], ...
                'LineWidth', 3, 'EdgeColor', color_select(i,:))
        end
        
        saveas(gca, sprintf('%s/corr_w_%s%s.png', spike_dir, labels_str, vid_label))

        % Plot the mean of all channels in each cluster
        time = options.trf_window(1):1/options.fs_ana:options.trf_window(2);

        for k = 1:options.n_cluster
            figure('Position', [2250 600 600 225])
            plot(time, 10*mean(w_faces_sig(c.clusters == k, :)), 'LineWidth', 2, 'Color', color_select(k,:))
            grid on 
            grid minor
            xlabel('Time [s]')
            ylabel('Amplitude')
            xlim(options.trf_window)
            set(gca, 'FontSize', 22)
            title(sprintf('Cluster %i Average', k))
            saveas(gca, sprintf('%s/cluster_%i_%s%s.png', spike_dir, k, labels_str, vid_label))
        end

        k_spikes = input('Select the cluster of saccadic spikes:\n');
        
        color_spike = color_select(k_spikes,:);
        
        % Index of channels with saccadic spike
        idx_spike = c.clusters == k_spikes;

        save(spike_file, 'idx_spike', 'color_spike')

    else
        load(spike_file, 'idx_spike', 'color_spike')
    end