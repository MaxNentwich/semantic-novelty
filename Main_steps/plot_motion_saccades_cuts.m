
function plot_motion_saccades_cuts(options_main)

    out_dir = sprintf('%s/feature_comparison', options_main.fig_dir);
    if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
        
    h = gausswin(options_main.smoothing_L, options_main.smooting_alpha);
    h = h/sum(h);

    for b = 1:length(options_main.band_select)
        
        % Find the index of the selected frequency band
        idx_band = find(ismember(options_main.band_names, options_main.band_select{b}));

        if strcmp(options_main.band_select{b}, 'raw')
            lambda = options_main.lambda_raw;
        else
            lambda = options_main.lambda_bands(idx_band);
        end

        % Define the data file 
        [labels_str, vid_label] = trf_file_parts(options_main); 
        
        vid_file = sprintf('%s%s%s_%1.0f_Hz_lambda_%1.2f_%1.0f.mat', ...
            vid_label, labels_str, options_main.band_select{b}, options_main.fs_ana, lambda, options_main.n_shuff);
        
        %% Load the data
        stats_dir = sprintf('%s/Data/stats', options_main.w_dir);
        
        if exist(sprintf('%s/%s', stats_dir, vid_file), 'file') ~= 0

            load(sprintf('%s/%s', stats_dir, vid_file), ...
                 'w_all', 'sig_all', 'p_all', 'labels_all', 'options')
             
            %% Parse data for the different stimuli
            idx_flow_cell = find(ismember(options.stim_select, 'optical_flow'));
            idx_scenes_cell = find(ismember(options.stim_select, 'scenes'));
            idx_saccades_cell = find(ismember(options.stim_select, 'saccades'));
            
            w_flow = w_all{idx_flow_cell};
            w_scenes = w_all{idx_scenes_cell};
            w_saccades = w_all{idx_saccades_cell};
            
            %% Correct for multiple comparisons with FDR
            [~, sig_flow] = fdr_corr(p_all{idx_flow_cell}, sig_all{idx_flow_cell});
            [~, sig_scenes] = fdr_corr(p_all{idx_scenes_cell}, sig_all{idx_scenes_cell});
            [~, sig_saccades] = fdr_corr(p_all{idx_saccades_cell}, sig_all{idx_saccades_cell});
            
            %% Remove the saccdic spikes from the data
            spike_dir = sprintf('%s/saccadic_spike', out_dir);
            if exist(spike_dir, 'dir') == 0, mkdir(spike_dir), end
            
            spike_file = sprintf('%s/spike_idx_%s%s.mat', spike_dir, labels_str, vid_label);
            
            % Index of significant channels
            idx_sig = find(sum(sig_saccades,2) ~= 0);
                
            options.n_cluster = options_main.n_cluster;
            [idx_spike, color_spike] = remove_sacc_spike(options, w_saccades, idx_sig, spike_dir, spike_file);
            
            % Remove the spikes
            sig_saccades(idx_sig(idx_spike), :) = zeros(sum(idx_spike), size(sig_saccades,2));
            
            % Save channel indices to plot saccadic spike
            labels_spike = labels_all(idx_sig(idx_spike));
            
            %% Venn diagram showing number of responsive channels and overlap between groups 
            labels_flow = labels_all(sum(sig_flow,2) ~= 0);
            labels_scenes = labels_all(sum(sig_scenes,2) ~= 0);
            labels_saccades = labels_all(sum(sig_saccades,2) ~= 0);
            
            file_venn = sprintf('%s/venn_diagram_%s.png', out_dir, options_main.band_select{b});
            
            if exist(file_venn, 'file') == 0
                
                n_flow = length(labels_flow);
                n_scenes = length(labels_scenes);
                n_saccades = length(labels_saccades);
                
                l_flow_venn = labels_flow;
                l_scenes_venn = labels_scenes;
                l_saccades_venn = labels_saccades;

                % Electrodes with responses to all stimuli
                labels_shared_all = l_flow_venn(ismember(l_flow_venn, l_scenes_venn) & ismember(l_flow_venn, l_saccades_venn));
                l_flow_venn(ismember(l_flow_venn, labels_shared_all)) = [];
                l_scenes_venn(ismember(l_scenes_venn, labels_shared_all)) = [];
                l_saccades_venn(ismember(l_saccades_venn, labels_shared_all)) = [];

                % Electrodes shared between two stimuli
                labels_flow_scenes = l_flow_venn(ismember(l_flow_venn, l_scenes_venn));
                l_flow_venn(ismember(l_flow_venn, labels_flow_scenes)) = [];
                l_scenes_venn(ismember(l_scenes_venn, labels_flow_scenes)) = [];

                labels_flow_saccades = l_flow_venn(ismember(l_flow_venn, l_saccades_venn));
                l_saccades_venn(ismember(l_saccades_venn, labels_flow_saccades)) = [];

                labels_scenes_saccades = l_scenes_venn(ismember(l_scenes_venn, l_saccades_venn));

                % Count
                n_flow_scenes = length(labels_flow_scenes);
                n_flow_saccades = length(labels_flow_saccades);
                n_scenes_saccades = length(labels_scenes_saccades);
                n_shared_all = length(labels_shared_all);

                % Plot the venn diagram
                figure
                hold on
                plot(poly_circle([15 5], sqrt(length(labels_all)/pi), 1e3), 'FaceColor', [0.7 0.7 0.7])
                venn([n_flow, n_scenes, n_saccades], [n_flow_scenes, n_flow_saccades, n_scenes_saccades, n_shared_all])
                axis square
                axis off
                
                saveas(gca, file_venn)
                
            end
            
            %% Bar plot to summarize ratio of responsive electrodes per area
            % Find shared an unique electrodes
            labels_all_sig = unique([labels_flow; labels_scenes; labels_saccades]);

            loc_all = localize_elecs_bipolar(labels_all, options_main.atlas); 
            
            loc_all_sig = localize_elecs_bipolar(labels_all_sig, options_main.atlas);
            loc_flow = localize_elecs_bipolar(labels_flow, options_main.atlas);
            loc_scenes = localize_elecs_bipolar(labels_scenes, options_main.atlas);
            loc_saccades = localize_elecs_bipolar(labels_saccades, options_main.atlas);

            regions = unique(loc_all_sig);

            % Count the number of electrodes in each lobe
            n_lobes_all_sig = zeros(size(regions));
            n_lobes_all = zeros(size(regions));
            n_lobes_flow = zeros(size(regions));
            n_lobes_scenes = zeros(size(regions));
            n_lobes_saccades = zeros(size(regions));

            for l = 1:length(regions)

                n_lobes_all_sig(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_all_sig(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_all_sig(:,2))],2)));
                n_lobes_all(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_all(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_all(:,2))],2)));
                n_lobes_flow(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_flow(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_flow(:,2))],2)));    
                n_lobes_scenes(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_scenes(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_scenes(:,2))],2)));    
                n_lobes_saccades(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_saccades(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_saccades(:,2))],2)));

            end

            %% Figures 
            n_stacked = [n_lobes_scenes, n_lobes_saccades, n_lobes_flow]./n_lobes_all;

            % Remove 'unkown' channels  
            if ~options_main.inlude_unknown
                
                idx_unknown = cellfun(@(C) strcmp(C, 'Unknown'), regions);
                
                n_lobes_all(idx_unknown) = [];

                regions(idx_unknown) = [];
                
                n_stacked(idx_unknown, :) = [];
            
            end
            
            if strcmp(options_main.atlas, 'lobes')
            
                idx_sort = cellfun(@(C) find(ismember(regions, C)), options_main.regions_order, 'UniformOutput', false);
                idx_sort(cellfun(@(C) isempty(C), idx_sort)) = [];
                idx_sort = cell2mat(idx_sort);
        
            elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                
                [~, idx_sort] = sort(n_stacked(:,1), 'descend');
            
            end
            
            n_lobes_all = n_lobes_all(idx_sort);

            regions = regions(idx_sort);
            
            n_stacked = n_stacked(idx_sort, :);
            
            %% Ratio of different groups 
            file_ratio_conditions = sprintf('%s/ratio_conditions_%s_%s.png', out_dir, options_main.band_select{b}, options_main.atlas);

            % Compute the standard error of the proportions 
            se_prop = sqrt((n_stacked .* (1-n_stacked)) ./ n_lobes_all);
            se_prop = se_prop(:);
            
            if exist(file_ratio_conditions, 'file') == 0
                     
                % Add number of electrodes to labels
                for r = 1:length(regions)
                    region_labels{r} = sprintf('%s (N = %i)', regions{r}, n_lobes_all(r));
                end

                if strcmp(options_main.atlas, 'lobes')
                    
                    figure('Position', [675,483,650,650])
                    hold on
                    
                    % Plot colors corresponding to brain areas
                    for r = 1:length(regions)
                        rectangle('Position', [r-0.5 0 1 1], 'FaceColor', [options_main.region_color(r, :), options_main.region_alpha], ...
                            'EdgeColor', [options_main.region_color(r, :), options_main.region_alpha])
                    end
                    
                    bar_condition = bar(n_stacked, 'FaceColor', 'flat');
                
                elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                    
                    fig = figure('units', 'normalized', 'Position', [0 0 1 1]);
                    set(fig,'defaultAxesColorOrder',[[0 0 0]; [0 0 0]]);
                    hold on
                    
                    y_ticks_man = [0 0.25 0.5 0.75 1];
                    
                    for i = 2:length(y_ticks_man)
                        plot([0 length(regions)+1.5], y_ticks_man(i)*ones(2,1), '--', 'LineWidth', 0.1, 'Color', [0.3 0.3 0.3], 'HandleVisibility','off')
                    end
                    
                    bar_condition = bar(n_stacked, 1.2, 'FaceColor', 'flat');
                    
                end
   
                % Plot the errors
                eb = errorbar([bar_condition.XEndPoints], [bar_condition.YData], 1.96*se_prop, 1.96*se_prop);    
                eb.Color = [0 0 0];                            
                eb.LineStyle = 'none'; 
                eb.LineWidth = 1.5;
                
                bar_condition(1).CData = options_main.color_scenes;
                bar_condition(2).CData = options_main.color_saccades;
                bar_condition(3).CData = options_main.color_flow;

%                 grid on 
                
                xticks(1:size(n_stacked,1))
                xticklabels(region_labels)

                if strcmp(options_main.atlas, 'AparcAseg_Atlas')
                    ylim([-0.21 1.2])
                end
                
                set(gca, 'FontSize', 22)
                
                if strcmp(options_main.atlas, 'lobes')
                    
                    xtickangle(45)
                    
                    outer_pos = get(gca, 'OuterPosition');
                    outer_pos(2) = 0.1;
                    outer_pos(4) = 0.9;
                    set(gca, 'OuterPosition', outer_pos)
                    
                    legend({'Film Cuts', 'Saccades', 'Motion'}, 'Position', [0.64, 0.131, 0.308, 0.155])
                
%                     grid minor
                    
                elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                    
                    xtickangle(90)
                    yticks([])
                    y_limits = ylim;
                    
                    yyaxis right
                    
                    k = range(ylim)/range(y_limits);
                    d = -y_limits(1) * k;
                    
                    yticks(y_ticks_man * k + d);                    
                    yticklabels({'0', '0.25', '0.5', '0.75', '1'})
                    ytickangle(135)
                    
                    legend({'Film Cuts', 'Saccades', 'Motion'}, 'Position', [0.03, 0.079, 0.05, 0.105])

                end
                
                ylabel('Fraction of Channels')

                saveas(gca, file_ratio_conditions)
                
            end
            
        end
        
        %% Spatial plot        
        plot_elec_low_features(options_main, labels_flow, options_main.color_flow, 'motion', b)
        plot_elec_low_features(options_main, labels_scenes, options_main.color_scenes, 'scenes', b)
        plot_elec_low_features(options_main, labels_saccades, options_main.color_saccades, 'saccades', b)
        
        % Channels with saccadic spike
        plot_elec_low_features(options_main, labels_spike, color_spike, 'saccadic_spike', b)
        
        %% Plot the filters in some regions of interest
        % Time axis
        time = options.trf_window(1):1/options.fs_ana:options.trf_window(2);

        %% Filters in each ROI
        trf_font = 22;
        
        filt_dir = sprintf('%s/filters', out_dir);
        if exist(filt_dir, 'dir') == 0
            mkdir(filt_dir)
        else
            continue
        end

        for i = 1:length(regions)

            roi_select = regions{i};

            % Find the indices of the region of interest in the filter matrices
            idx_elec = find(sum(cellfun(@(C) contains(C, roi_select), loc_all),2) >= options_main.loc_confidence); 

            idx_flow = idx_elec(sum(sig_flow(idx_elec,:),2) ~= 0);
            idx_sce = idx_elec(sum(sig_scenes(idx_elec,:),2) ~= 0);
            idx_sac = idx_elec(sum(sig_saccades(idx_elec,:),2) ~= 0);
            
            n_ch_max = max([length(idx_flow), length(idx_sce), length(idx_sac)]);
            
            %% Filters might contain distinct responses -> separate them               
            amplitude_scale = max([abs(smooth_elec(w_flow, idx_flow, h, options_main.smoothing_L))'; ...
                smooth_elec(w_scenes, idx_flow, h, options_main.smoothing_L)'; ...
                smooth_elec(w_saccades, idx_flow, h, options_main.smoothing_L)']);
            
            colors_flow = [1 0.25 0.25; 0.75 0 0];
            plot_trf_comparison(w_flow, idx_flow, time, h, options_main.smoothing_L, amplitude_scale, n_ch_max, ...
                trf_font, sprintf('%s/%s_flow_norm.png', filt_dir, regions{i}), colors_flow);
            
            %%
            amplitude_scale = max([abs(smooth_elec(w_flow, idx_sce, h, options_main.smoothing_L))'; ...
                smooth_elec(w_scenes, idx_sce, h, options_main.smoothing_L)'; ...
                smooth_elec(w_saccades, idx_sce, h, options_main.smoothing_L)']);
            
            colors_scenes = [0.25 1 0.25; 0 0.75 0];
            plot_trf_comparison(w_scenes, idx_sce, time, h, options_main.smoothing_L, amplitude_scale, n_ch_max, ...
                trf_font, sprintf('%s/%s_cuts_norm.png', filt_dir, regions{i}), colors_scenes);
            
            %%           
            amplitude_scale = max([abs(smooth_elec(w_flow, idx_sac, h, options_main.smoothing_L))'; ...
                smooth_elec(w_scenes, idx_sac, h, options_main.smoothing_L)'; ...
                smooth_elec(w_saccades, idx_sac, h, options_main.smoothing_L)']);
            
            colors_saccades = [0.25 0.25 1; 0 0 0.75];
            plot_trf_comparison(w_saccades, idx_sac, time, h, options_main.smoothing_L, amplitude_scale, n_ch_max, ...
                trf_font, sprintf('%s/%s_saccades_norm.png', filt_dir, regions{i}), colors_saccades);
            
            pause(1)
            close all

        end

    end
    
end