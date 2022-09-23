                
function plot_ratio_bar(n_stacked, n_lobes_all_sig, regions, bar_colors, legend_label, file_ratio_conditions)

    % Compute standard error of the proportion
    prop = n_stacked./sum(n_stacked,2);
    se_prop = sqrt((prop .* (1-prop)) ./ n_lobes_all_sig');

    % Add number of electrodes to labels
    region_labels = cell(1,length(regions));
    for r = 1:length(regions)
        region_labels{r} = sprintf('%s (N = %i)', regions{r}, n_lobes_all_sig(r));
    end

    fig = figure('Position', [1981,181,1540,808]);
    set(fig,'defaultAxesColorOrder',[[0 0 0]; [0 0 0]]);
    hold on

    y_ticks_man = [0 0.25 0.5 0.75 1];

    for i = 2:length(y_ticks_man)
        plot([0 length(regions)+1], y_ticks_man(i)*ones(2,1), '--', 'LineWidth', 0.1, 'Color', [0.3 0.3 0.3], 'HandleVisibility','off')
    end

    bar_condition = bar(prop, 0.5, 'stacked', 'FaceColor', 'flat');

    % Plot the errors
    eb_high = errorbar(bar_condition(1).XEndPoints, bar_condition(1).YEndPoints, 1.96*se_prop(:,1), 1.96*se_prop(:,1));    
    eb_high.Color = [0 0 0];                            
    eb_high.LineStyle = 'none'; 
    eb_high.LineWidth = 1.5;

    eb_low = errorbar(bar_condition(2).XEndPoints, bar_condition(2).YEndPoints, 1.96*se_prop(:,3), 1.96*se_prop(:,3));    
    eb_low.Color = [1 1 1];                            
    eb_low.LineStyle = 'none'; 
    eb_low.LineWidth = 1.5;

    xticks(1:size(n_stacked,1))
    xticklabels(region_labels)

    bar_condition(1).CData = bar_colors(1,:);
    bar_condition(2).CData = bar_colors(2,:);
    bar_condition(3).CData = bar_colors(3,:);

    set(gca, 'FontSize', 22)

    xtickangle(90)
    yticks([])
    y_limits = ylim;

    yyaxis right

    k = range(ylim)/range(y_limits);
    d = -y_limits(1) * k;

    yticks(y_ticks_man * k + d);                    
    yticklabels({'0', '0.25', '0.5', '0.75', '1'})
    ytickangle(135)

    legend(legend_label, 'Position', [0.025, 0.02, 0.108, 0.105])

    ylabel('Fraction of Channels')

    saveas(gca, file_ratio_conditions)
    
end
