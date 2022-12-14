
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
        stats_dir = sprintf('%s/stats', options_main.im_data_dir);
        
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
            
            %% Find electrodes in each area for each patient
            labels_all_sig = unique([labels_flow; labels_scenes; labels_saccades]);
            
            [n_lobes_all, ~, n_lobes_flow, n_lobes_scenes, n_lobes_saccades, regions, patients, loc_all] = ...
                localize_elecs_patient(labels_all, labels_all_sig, labels_flow, labels_scenes, labels_saccades, options_main.atlas);

            %% Stats
            % Get the ratios of responsive channels
            ratio_scenes = n_lobes_scenes./n_lobes_all;
            ratio_saccades = n_lobes_saccades./n_lobes_all;
            ratio_flow = n_lobes_flow./n_lobes_all;
            
            % Remove 'unkown' channels  
            if ~options_main.inlude_unknown
                
                idx_unknown = cellfun(@(C) strcmp(C, 'Unknown'), regions);
                
                n_lobes_all(:, idx_unknown) = [];
                n_lobes_scenes(:, idx_unknown) = [];
                n_lobes_saccades(:, idx_unknown) = [];
                n_lobes_flow(:, idx_unknown) = [];
                
                ratio_scenes(:, idx_unknown) = [];
                ratio_saccades(:, idx_unknown) = [];
                ratio_flow(:, idx_unknown) = [];

                regions(idx_unknown) = [];

            end
            
            % Get p-values from paired tests
            for i = 1:length(regions)     
                p_sce_sac(i) = ranksum(ratio_scenes(:,i), ratio_saccades(:,i));
                p_sce_flo(i) = ranksum(ratio_scenes(:,i), ratio_flow(:,i));
                p_sac_flo(i) = ranksum(ratio_saccades(:,i), ratio_flow(:,i));           
            end
                       
            % FDR correction only for comparison between stimuli in each
            % region 
            p_fdr = mafdr([p_sce_sac, p_sce_flo, p_sac_flo], 'BHFDR', 'true');
            p_sce_sac = p_fdr(1:length(regions));
            p_sce_flo = p_fdr(length(regions)+1:2*length(regions));
            p_sac_flo = p_fdr(2*length(regions)+1:end);
            
            %% Sort by region
            if strcmp(options_main.atlas, 'lobes')
            
                idx_sort = cellfun(@(C) find(ismember(regions, C)), options_main.regions_order, 'UniformOutput', false);
                idx_sort(cellfun(@(C) isempty(C), idx_sort)) = [];
                idx_sort = cell2mat(idx_sort);
        
            elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                
                % Create a matrix with all counts 
                n_stacked = [round(sum(n_lobes_scenes)); round(sum(n_lobes_saccades)); round(sum(n_lobes_flow))]' ./ round(sum(n_lobes_all))'; 
                se_stacked = sqrt((n_stacked .* (1-n_stacked)) ./ round(sum(n_lobes_all))');

                [~, idx_sort] = sort(n_stacked(:,1), 'descend');
            
                n_stacked = n_stacked(idx_sort, :);
                se_stacked = se_stacked(idx_sort, :);
            
            end
            
            n_lobes_all = n_lobes_all(:, idx_sort);
            n_lobes_all = round(sum(n_lobes_all));

            regions = regions(idx_sort);
 
            p_sce_sac = p_sce_sac(idx_sort);
            p_sce_flo = p_sce_flo(idx_sort);
            p_sac_flo = p_sac_flo(idx_sort);
            
            ratio_scenes = ratio_scenes(:, idx_sort);
            ratio_saccades = ratio_saccades(:, idx_sort);
            ratio_flow = ratio_flow(:, idx_sort);
            
            %% Plot the ratio of responsive channels 
            file_ratio_conditions = sprintf('%s/ratio_conditions_%s_%s.png', out_dir, options_main.band_select{b}, options_main.atlas);

            if exist(file_ratio_conditions, 'file') == 0
                     
                if strcmp(options_main.atlas, 'lobes')
                    
                    condition_pos = 0.25;
                    
                    figure('Position', [600,425,1025,434])
                    hold on
                    
                    % Plot colors corresponding to brain areas
                    for r = 1:length(regions)
                        rectangle('Position', [r-0.5 0 1 1], 'FaceColor', [options_main.region_color(r, :), options_main.region_alpha], ...
                            'EdgeColor', [options_main.region_color(r, :), options_main.region_alpha])
                    end
                    
                    % Ratios for individual patients
                    for r = 1:length(regions)

                        center_pos = [-condition_pos, 0, condition_pos] + r;

                        scatter(0.033*randn(length(patients),1) + center_pos(1), ratio_scenes(:,r), 20, 'g', 'filled')
                        plot([center_pos(1)-(condition_pos/2), center_pos(1)+(condition_pos/2)], nanmedian(ratio_scenes(:,r))*[1 1], ...
                            'k', 'LineWidth', 2, 'HandleVisibility','off')

                        scatter(0.033*randn(length(patients),1) + center_pos(2), ratio_saccades(:,r), 20, 'b', 'filled')
                        plot([center_pos(2)-(condition_pos/2), center_pos(2)+(condition_pos/2)], nanmedian(ratio_saccades(:,r))*[1 1], ...
                            'k', 'LineWidth', 2, 'HandleVisibility','off')

                        scatter(0.033*randn(length(patients),1) + center_pos(3), ratio_flow(:,r), 20, 'r', 'filled')
                        plot([center_pos(3)-(condition_pos/2), center_pos(3)+(condition_pos/2)], nanmedian(ratio_flow(:,r))*[1 1], ...
                            'k', 'LineWidth', 2, 'HandleVisibility','off')

                        % Plot significant differences between stimuli
                        plot_sig_bars(p_sce_sac(r), [center_pos(1), center_pos(2)], 1.085, 0.015)
                        plot_sig_bars(p_sce_flo(r), [center_pos(1), center_pos(3)], 1.13, 0.015)
                        plot_sig_bars(p_sac_flo(r), [center_pos(2), center_pos(3)], 1.05, 0.015) 

                    end
                    
                    xtickangle(45)
                    
                    outer_pos = get(gca, 'OuterPosition');
                    outer_pos(2) = 0.15;
                    outer_pos(4) = 0.85;
                    set(gca, 'OuterPosition', outer_pos)
                    
                    legend({'Film Cuts', 'Saccades', 'Motion'}, 'Position', [0.69,0.01,0.31,0.22])
                
                    ylim([0 1.15])
                    xlim([0.5, 6.5])
                    
                    xticks(1:length(regions))
                    xticklabels(regions)
                
                elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                    
                    se_prop = se_stacked(:);
                    
                    % Add number of electrodes to labels
                    region_labels = cell(1, length(regions));
                    for r = 1:length(regions)
                        region_labels{r} = sprintf('%s (N = %i)', regions{r}, n_lobes_all(r));
                    end

                    fig = figure('units', 'normalized', 'Position', [0 0 1 1]);
                    set(fig,'defaultAxesColorOrder',[[0 0 0]; [0 0 0]]);
                    hold on
                    
                    y_ticks_man = [0 0.25 0.5 0.75 1];
                    
                    for i = 2:length(y_ticks_man)
                        plot([0 length(regions)+1.5], y_ticks_man(i)*ones(2,1), '--', 'LineWidth', 0.1, 'Color', [0.3 0.3 0.3], 'HandleVisibility','off')
                    end
                    
                    bar_condition = bar(n_stacked, 1.2, 'FaceColor', 'flat');
                    
                    % Plot the errors
                    eb = errorbar([bar_condition.XEndPoints], [bar_condition.YData], 1.96*se_prop, 1.96*se_prop);    
                    eb.Color = [0 0 0];                            
                    eb.LineStyle = 'none'; 
                    eb.LineWidth = 1.5;

                    bar_condition(1).CData = options_main.color_scenes;
                    bar_condition(2).CData = options_main.color_saccades;
                    bar_condition(3).CData = options_main.color_flow;
                    
                    ylim([-0.21 1.2])
                    
                    xtickangle(90)
                    yticks([])
                    y_limits = ylim;
                    
                    yyaxis right
                    
                    k = range(ylim)/range(y_limits);
                    d = -y_limits(1) * k;
                    
                    yticks(y_ticks_man * k + d);                    
                    yticklabels({'0', '0.25', '0.5', '0.75', '1'})
                    ytickangle(135)
                    
                    legend({'Film Cuts', 'Saccades', 'Motion'}, 'Position', [0.85, 0.079, 0.12, 0.105])
                    
                    xticks(1:size(n_stacked,1))
                    xticklabels(region_labels)
                    
                end
                
                ylabel({'Fraction of'; 'Channels'})
                set(gca, 'FontSize', 20)
                
                saveas(gca, file_ratio_conditions)
                
            end
            
        end
        
        %% Spatial plot with electrodes labeled by the amplitude of responses
        % Strength of responses
        plot_elecs_response_amplitude(options_main, w_scenes, labels_scenes, labels_all, loc_all, h, 'scenes', b, 'amplitude', 0)
        plot_elecs_response_amplitude(options_main, w_saccades, labels_saccades, labels_all, loc_all, h, 'saccades', b, ...
            'amplitude')
        plot_elecs_response_amplitude(options_main, w_flow, labels_flow, labels_all, loc_all, h, 'motion', b, 'amplitude', 0)

        % Onset of responses for channels with increase in BHA
        plot_elecs_response_amplitude(options_main, w_scenes, labels_scenes, labels_all, loc_all, h, 'scenes', b, ...
            'onset_positive', 0, [-3, 3])
        plot_elecs_response_amplitude(options_main, w_saccades, labels_saccades, labels_all, loc_all, h, 'saccades', b, ...
            'onset_positive', 0, [-3, 3])
        plot_elecs_response_amplitude(options_main, w_flow, labels_flow, labels_all, loc_all, h, 'motion', b, ...
            'onset_positive', 0, [-3, 3])
        
        % Onset of responses for channels with decrease in BHA
        plot_elecs_response_amplitude(options_main, w_scenes, labels_scenes, labels_all, loc_all, h, 'scenes', b, ...
            'onset_negative', 0, [-3, 3])
        plot_elecs_response_amplitude(options_main, w_saccades, labels_saccades, labels_all, loc_all, h, 'saccades', b, ...
            'onset_negative', 0, [-3, 3])
        plot_elecs_response_amplitude(options_main, w_flow, labels_flow, labels_all, loc_all, h, 'motion', b, ...
            'onset_negative', 0, [-3, 3])
        
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
                trf_font, sprintf('%s/%s_flow_norm.png', filt_dir, regions{i}), 'Time Lag from Motion [s]', colors_flow);
            
            %%
            amplitude_scale = max([abs(smooth_elec(w_flow, idx_sce, h, options_main.smoothing_L))'; ...
                smooth_elec(w_scenes, idx_sce, h, options_main.smoothing_L)'; ...
                smooth_elec(w_saccades, idx_sce, h, options_main.smoothing_L)']);
            
            colors_scenes = [0.25 1 0.25; 0 0.75 0];
            plot_trf_comparison(w_scenes, idx_sce, time, h, options_main.smoothing_L, amplitude_scale, n_ch_max, ...
                trf_font, sprintf('%s/%s_cuts_norm.png', filt_dir, regions{i}), 'Time from Film Cut [s]', colors_scenes);
            
            %%           
            amplitude_scale = max([abs(smooth_elec(w_flow, idx_sac, h, options_main.smoothing_L))'; ...
                smooth_elec(w_scenes, idx_sac, h, options_main.smoothing_L)'; ...
                smooth_elec(w_saccades, idx_sac, h, options_main.smoothing_L)']);
            
            colors_saccades = [0.25 0.25 1; 0 0 0.75];
            plot_trf_comparison(w_saccades, idx_sac, time, h, options_main.smoothing_L, amplitude_scale, n_ch_max, ...
                trf_font, sprintf('%s/%s_saccades_norm.png', filt_dir, regions{i}), 'Time from Saccade [s]', colors_saccades);
            
            pause(1)
            close all

        end

    end
    
end