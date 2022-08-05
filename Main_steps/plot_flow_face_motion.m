
function plot_flow_face_motion(options)

    % Save options from the main file 
    options_main = options;
    
    % Output directory
    out_dir = sprintf('%s/optical_flow_face_motion', options.fig_dir);
    if exist(out_dir, 'dir') == 0, mkdir(out_dir), end
    
    for b = 1:length(options.band_select)
        
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

            load(sprintf('%s/%s', options_main.stats_data, vid_file), 'w_all', 'sig_all', 'p_all', 'labels_all', 'options')

            %% Parse data for the different stimuli
            idx_flow = find(ismember(options.stim_select, 'optical_flow'));
            idx_face = find(ismember(options.stim_select, 'face_motion'));

            w_flow = w_all{idx_flow};
            w_face = w_all{idx_face};

            %% Correct for multiple comparisons with FDR
            [~, sig_flow] = fdr_corr(p_all{idx_flow}, sig_all{idx_flow});
            [~, sig_face] = fdr_corr(p_all{idx_face}, sig_all{idx_face});
 
            %% Bar plot to summarize ratio of responsive electrodes per area
            labels_flow = labels_all(sum(sig_flow,2) ~= 0);
            labels_face = labels_all(sum(sig_face,2) ~= 0);
            
            % Find shared an unique electrodes
            labels_all_sig = unique([labels_flow; labels_face]);

            labels_shared = labels_flow(ismember(labels_flow, labels_face));
            labels_flow = labels_flow(~ismember(labels_flow, labels_shared));
            labels_face = labels_face(~ismember(labels_face, labels_shared));

            % Localize electrodes
            loc_all = localize_elecs_bipolar(labels_all, options_main.atlas); 
            
            loc_all_sig = localize_elecs_bipolar(labels_all_sig, options_main.atlas);
            loc_flow = localize_elecs_bipolar(labels_flow, options_main.atlas);
            loc_face = localize_elecs_bipolar(labels_face, options_main.atlas);
            loc_shared = localize_elecs_bipolar(labels_shared, options_main.atlas);
            
            regions = unique(loc_all_sig);

            % Count the number of electrodes in each lobe
            n_lobes_all_sig = zeros(size(regions));
            n_lobes_all = zeros(size(regions));
            n_lobes_flow = zeros(size(regions));
            n_lobes_face = zeros(size(regions));
            n_lobes_shared = zeros(size(regions));

            for l = 1:length(regions)

                n_lobes_all_sig(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_all_sig(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_all_sig(:,2))],2)));
                n_lobes_all(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_all(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_all(:,2))],2)));
                n_lobes_flow(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_flow(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_flow(:,2))],2)));    
                n_lobes_face(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_face(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_face(:,2))],2)));    
                n_lobes_shared(l) = round(sum(mean([cellfun(@(C) contains(C, regions{l}), loc_shared(:,1)), ...
                    cellfun(@(C) contains(C, regions{l}), loc_shared(:,2))],2)));

            end

            %% Figures 
            n_stacked = [n_lobes_flow, n_lobes_shared, n_lobes_face]./n_lobes_all;
            
            % Remove 'unkown' channels  
            if ~ options_main.inlude_unknown
                
                idx_unknown = cellfun(@(C) strcmp(C, 'Unknown'), regions);
                
                n_lobes_all_sig(idx_unknown) = [];
                n_lobes_all(idx_unknown) = [];

                regions(idx_unknown) = [];
                
                n_stacked(idx_unknown, :) = [];
            
            end
            
            if strcmp(options_main.atlas, 'lobes')
            
                idx_sort = cellfun(@(C) find(ismember(regions, C)), options_main.regions_order, 'UniformOutput', false);
                idx_sort(cellfun(@(C) isempty(C), idx_sort)) = [];
                idx_sort = cell2mat(idx_sort);
        
            elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                
                [~, idx_sort] = sort(n_lobes_all_sig./n_lobes_all, 'descend');
            
            end
            
            n_lobes_all_sig = n_lobes_all_sig(idx_sort);
            n_lobes_all = n_lobes_all(idx_sort);

            regions = regions(idx_sort);

            n_stacked = n_stacked(idx_sort, :);
            
            %% Colors
            options_main.region_color(~ismember(options_main.regions_order, regions), :) = [];
            
            %% Sum of electrodes in each ROI
            file_ratio_total = sprintf('%s/ratio_total_%s_%s.png', out_dir, options.band_select{b}, options_main.atlas);
            
            % Compute standard error of the proportions
            prop_total = n_lobes_all_sig./n_lobes_all;
            se_prop = sqrt((prop_total .* (1-prop_total)) ./ n_lobes_all);
            
            if exist(file_ratio_total, 'file') == 0
                
                % Add number of electrodes to labels
                for r = 1:length(regions)
                    region_labels{r} = sprintf('N = %i', n_lobes_all(r));
                end

                if strcmp(options_main.atlas, 'lobes')
                    
                    figure('Position', [406,373,587,550])
                     hold on
                
                    % Plot colors corresponding to brain areas
                    for r = 1:length(regions)
                        rectangle('Position', [r-0.5 0 1 0.6], 'FaceColor', [options_main.region_color(r, :), options_main.region_alpha], ...
                            'EdgeColor', [options_main.region_color(r, :), options_main.region_alpha])
                    end

                    ylim([0 0.6])
                    
                elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                    
                    fig = figure('Position', [1981,181,1540,400]);
                    set(fig,'defaultAxesColorOrder',[[0 0 0]; [0 0 0]]);
                    hold on
                    
                    y_ticks_man = [0 0.33 0.66 1];
                    
                    for i = 2:length(y_ticks_man)
                        plot([0 length(regions)+1], y_ticks_man(i)*ones(2,1), '--', 'LineWidth', 0.1, 'Color', [0.3 0.3 0.3], 'HandleVisibility','off')
                    end

                end
                
                bar_total = bar(prop_total, 0.5, 'FaceColor', [0.5 0.5 0.5]);

                % Plot the errors
                eb = errorbar(bar_total.XEndPoints, bar_total.YEndPoints, 1.96*se_prop(:,1), 1.96*se_prop(:,1));    
                eb.Color = [0 0 0];                            
                eb.LineStyle = 'none'; 
                eb.LineWidth = 1.5;

                xticks(1:size(n_stacked,1))
                xticklabels(region_labels)

                set(gca, 'FontSize', 22)
                
                if strcmp(options_main.atlas, 'lobes')
                    
                    xtickangle(45)

                elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')
                    
                    xtickangle(90)
                    yticks([])
                    y_limits = ylim;
                    
                    yyaxis right
                    
                    k = range(ylim)/range(y_limits);
                    d = -y_limits(1) * k;
                    
                    yticks(y_ticks_man * k + d);                    
                    yticklabels({'0', '0.33', '0.66', '1'})
                    ytickangle(135)
                    
                end
                
                ylabel('Fraction of Channels')

                saveas(gca, file_ratio_total)
                
            end

            %% Ratio of different groups 
            file_ratio_conditions = sprintf('%s/ratio_conditions_%s_%s.png', out_dir, options.band_select{b}, options_main.atlas);
            
            % Compute standard error of the proportion
            prop = n_stacked./sum(n_stacked,2);
            se_prop = sqrt((prop .* (1-prop)) ./ n_lobes_all_sig);
            
            if exist(file_ratio_conditions, 'file') == 0
                
                % Add number of electrodes to labels
                for r = 1:length(regions)
                    region_labels{r} = sprintf('%s (N = %i)', regions{r}, n_lobes_all_sig(r));
                end
                
                if strcmp(options_main.atlas, 'lobes')
                    
                    figure('Position', [993,373,656,550])
                    hold on

                    % Plot colors corresponding to brain areas
                    for r = 1:length(regions)
                        rectangle('Position', [r-0.5 0 1 1], 'FaceColor', [options_main.region_color(r, :), options_main.region_alpha], ...
                            'EdgeColor', [options_main.region_color(r, :), options_main.region_alpha])
                    end
                    
                    ylim([0 1])

                elseif strcmp(options_main.atlas, 'AparcAseg_Atlas')

                    fig = figure('Position', [1981,181,1540,808]);
                    set(fig,'defaultAxesColorOrder',[[0 0 0]; [0 0 0]]);
                    hold on
                    
                    y_ticks_man = [0 0.25 0.5 0.75 1];
                    
                    for i = 2:length(y_ticks_man)
                        plot([0 length(regions)+1], y_ticks_man(i)*ones(2,1), '--', 'LineWidth', 0.1, 'Color', [0.3 0.3 0.3], 'HandleVisibility','off')
                    end
                    
                end
                
                bar_condition = bar(prop, 0.5, 'stacked', 'FaceColor', 'flat');

                % Plot the errors
                eb_total = errorbar(bar_condition(1).XEndPoints, bar_condition(1).YEndPoints, 1.96*se_prop(:,1), 1.96*se_prop(:,1));    
                eb_total.Color = [0 0 0];                            
                eb_total.LineStyle = 'none'; 
                eb_total.LineWidth = 1.5;

                eb_face = errorbar(bar_condition(2).XEndPoints, bar_condition(2).YEndPoints, 1.96*se_prop(:,3), 1.96*se_prop(:,3));    
                eb_face.Color = [1 1 1];                            
                eb_face.LineStyle = 'none'; 
                eb_face.LineWidth = 1.5;

                xticks(1:size(n_stacked,1))
                xticklabels(region_labels)

                bar_condition(1).CData = [1 0 0];
                bar_condition(2).CData = [0.66 0 0];
                bar_condition(3).CData = [0.33 0 0];

                set(gca, 'FontSize', 22)
                
                if strcmp(options_main.atlas, 'lobes')

                    xtickangle(45)
                    
                    outer_pos = get(gca, 'OuterPosition');
                    outer_pos(2) = 0.1;
                    outer_pos(4) = 0.9;
                    set(gca, 'OuterPosition', outer_pos)
                    
                    legend({'Total Motion', 'Both', 'Face Motion'}, 'Position', [0.668,0.024,0.314,0.155])

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
                    
                    legend({'Total Motion', 'Both', 'Face Motion'}, 'Position', [0.025, 0.02, 0.108, 0.105])
                
                end
                
                ylabel('Fraction of Channels')

                saveas(gca, file_ratio_conditions)
                
            end           

            %% Plot resonsive electrodes in each condition
            out_name = 'flow_face_motion_electrode_location';
            if exist(sprintf('%s/%s.png', out_dir, out_name), 'file') ~= 0, continue, end
            
            [coords_all, is_left_all, elec_names_all] = load_fsaverage_coords(labels_all_sig);

            % Create labels for face, non-face and shared electrodes
            idx_flow = zeros(length(elec_names_all), 1);
            idx_face = zeros(length(elec_names_all), 1);
            idx_shared = zeros(length(elec_names_all), 1);
            idx_condition = zeros(length(elec_names_all), 1);

            for e = 1:length(elec_names_all) 

                if contains(elec_names_all{e}, 'RGridHD')
                    elec_names_all{e} = strrep(elec_names_all{e}, 'RGridHD', 'RGrid');
                end

                if contains(elec_names_all{e}, 'NS138') && contains(elec_names_all{e}, 'Lia')
                    elec_names_all{e} = strrep(elec_names_all{e}, 'Lia', 'LIa');
                end

                if contains(elec_names_all{e}, 'NS144_02') && contains(elec_names_all{e}, 'LGrid')
                    elec_names_all{e} = strrep(elec_names_all{e}, 'LGrid', 'RGrid');
                end

                idx_flow(e) = sum(contains(labels_flow, elec_names_all{e})) ~= 0;
                idx_face(e) = sum(contains(labels_face, elec_names_all{e})) ~= 0;
                idx_shared(e) = sum(contains(labels_shared, elec_names_all{e})) ~= 0;

            end

            idx_shared(idx_flow & idx_face) = 1;
            idx_flow(idx_flow & idx_face) = 0;
            idx_face(idx_flow & idx_face) = 0;

            idx_flow(idx_flow & idx_shared) = 0;
            idx_face(idx_face & idx_shared) = 0;

            idx_condition(idx_flow == 1) = 1;
            idx_condition(idx_shared == 1) = 2;
            idx_condition(idx_face == 1) = 3;

            close all
            color_map = [1 0 0; 0.66 0 0; 0.33 0 0]; 

            % Spatial plot settings 
            options.fig_features.out_dir = out_dir;
            options.fig_features.file_name = out_name;
            options.fig_features.view = 'omni';
            options.fig_features.opaqueness = 0.4;
            options.fig_features.elec_size = 8;
            options.fig_features.elec_units = '';

            plot_sig_elecs(coords_all, is_left_all, elec_names_all, idx_condition, ...
                options.fig_features, 1, color_map, [-1, 1])
            
        end

    end

end