%% Function to plot significant electrodes and corresponding r value

function plot_sig_elecs(group_avg_coords, group_is_left, group_elec_names, r_plot, fig_options, varargin)

    if ~isempty(varargin)
        RGB = varargin{1};
    end
    if length(varargin) > 1
        color_axis = varargin{2};
    end
    if length(varargin) > 2
        c_lim_rgb = varargin{3};
    else
        c_lim_rgb = [0, max(r_plot)];
    end
        
    % Define the color axis 
    if RGB
        
        % Interpolate the values
        if size(color_axis,1) == 1 && sum(r_plot == 1) == length(r_plot)
            elec_colors = repmat(color_axis, length(r_plot), 1);
        else            
            elec_colors = interp1(1:size(color_axis,1), color_axis, r_plot);
        end
        
        idx_zero = r_plot == 0;
        elec_colors(idx_zero, :) = repmat([0.75, 0.75, 0.75], sum(idx_zero), 1);
        
    end

    cfg = [];

    cfg.view = fig_options.view;      

    cfg.figId = 1;
    cfg.clearFig = 0;
    cfg.figId = 1;
    cfg.axis = gca(); 
    if RGB
        cfg.elecColorScale = [0 255];
    else
        cfg.elecColorScale = 'minmax';
    end
    cfg.showLabels = 'n';
    cfg.elecUnits = fig_options.elec_units;
    cfg.elecCoord = [group_avg_coords, group_is_left];
    cfg.elecNames = group_elec_names;
    if sum(RGB(:)) ~= 0
        cfg.elecColors = elec_colors;
    else
        cfg.elecColors = r_plot/max(r_plot);
    end
    cfg.ignoreDepthElec = 'n';
    cfg.showLabels = 'n';
    cfg.opaqueness = fig_options.opaqueness;
    cfg.elecSize = fig_options.elec_size;
    cfg.title = [];
    plotPialSurf('fsaverage', cfg);

    % Change color axis
    if RGB
        kids = get(gcf, 'Children');
        
        % Find the colorbar
        tag = cell(1, length(kids));
        for i = 1:length(kids), tag{i} = kids(i).Tag; end
        idx_cbar = find(ismember(tag, 'cbar'));
        
        favorite_kid = kids(idx_cbar);
        grandkid = get(favorite_kid, 'Children');
        
        set(favorite_kid, 'Colormap', color_axis)
        
        c_lims = c_lim_rgb;
        
        set(favorite_kid, 'XLim', c_lims)
        set(grandkid, 'XData', c_lims)

        set(favorite_kid, 'XTick', linspace(c_lims(1), c_lims(2), 5))
        set(favorite_kid, 'XTickLabel', strsplit(num2str(round(linspace(c_lims(1), c_lims(2), 5),2))))
        set(favorite_kid, 'XTickLabelRotation', 45)
        set(favorite_kid, 'FontSize', 12)
    else
        kids = get(gcf, 'Children');
        favorite_kid = kids(1);
        grandkid = get(favorite_kid, 'Children');

        c_lims = [min(r_plot), max(r_plot)];

        set(favorite_kid, 'XLim', c_lims)
        set(grandkid, 'XData', c_lims)

        set(favorite_kid, 'XTick', linspace(c_lims(1), c_lims(2), 5))
        set(favorite_kid, 'XTickLabel', strsplit(num2str(round(linspace(c_lims(1), c_lims(2), 5),2))))
        set(favorite_kid, 'FontSize', 12)
    end

    if exist(fig_options.out_dir, 'dir') == 0
        mkdir(out_dir)
    end
    
    set(gcf, 'Units', 'normalized', 'Position', [0 0 1 1]);
    
    saveas(gcf, sprintf('%s/%s.png', fig_options.out_dir, fig_options.file_name))
    pause(1)
    
end