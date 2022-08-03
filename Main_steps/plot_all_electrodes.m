%% Plot the electrodes of all patients

function plot_all_electrodes(options)

    fig_files = dir(options.fig_all_elecs.out_dir);
    fig_files = fig_files(cellfun(@(C) contains(C, options.fig_all_elecs.file_name), {fig_files.name}));

    if isempty(fig_files)

        group_avg_coords = [];
        group_elec_names = [];
        group_is_left = [];

        for pat = 1:length(options.patients)

            fprintf('Working on Patient %s ...\n', options.patients(pat).name);

            % Load the fsaverage coordinates
            [avg_coords, elec_names, is_left] = load_fsaverage(options.patients(pat).name);

            for e = 1:length(elec_names)
               elec_names{e} = sprintf('%s_%s', options.patients(pat).name, elec_names{e});
            end

            if strcmp(options.patients(pat).name, 'NS131')

                for ch = 1:length(elec_names)
                    elec_names{ch} = strrep(elec_names{ch}, 'Grid1', 'GridA');
                    elec_names{ch} = strrep(elec_names{ch}, 'Grid2', 'GridB');
                end

            elseif strcmp(options.patients(pat).name, 'NS144_02')

                for ch = 1:length(elec_names)
                    elec_names{ch} = strrep(elec_names{ch}, 'LGrid', 'RGrid');
                end

            elseif strcmp(options.patients(pat).name, 'NS148_02')

                for ch = 1:length(elec_names)
                    elec_names{ch} = strrep(elec_names{ch}, 'RGridHD', 'RGrid');
                end

            end

            group_avg_coords = [group_avg_coords; avg_coords];
            group_elec_names = [group_elec_names; elec_names];
            group_is_left = [group_is_left; is_left];

        end 
        
        % Create Colorvector
        elec_color = zeros(length(group_avg_coords), 3);
        
        options.fig_all_elecs.file_name = sprintf('%s_%s_%i_patients_%i_electrodes', ...
            options.fig_all_elecs.file_name, options.fig_all_elecs.view, length(options.patients), length(group_avg_coords));

        cfg = [];

        cfg.view = options.fig_all_elecs.view;      
        
        cfg.figId = 1;
        cfg.clearFig = 0;
        cfg.figId = 1;
        cfg.axis = gca(); 
        cfg.elecColorScale = [0 255];
        cfg.showLabels = 'n';
        cfg.elecUnits = options.fig_all_elecs.elec_units;
        cfg.elecCoord = [group_avg_coords, group_is_left];
        cfg.elecNames = group_elec_names;
        cfg.elecColors = elec_color;
        cfg.ignoreDepthElec = 'n';
        cfg.showLabels = 'n';
        cfg.opaqueness = options.fig_all_elecs.opaqueness;
        cfg.elecSize = options.fig_all_elecs.elec_size;
        cfg.title = [];
        plotPialSurf('fsaverage', cfg);
        
        set(gcf, 'Units', 'normalized', 'Position', [0 0 1 1]);
        
        saveas(gcf, sprintf('%s/%s.png', options.fig_all_elecs.out_dir, options.fig_all_elecs.file_name))
    
    end

end