
function plot_total_bar(n_lobes_all_sig, n_lobes_all, regions, file_ratio_total)

    % Compute standard error of the proportions
    prop_total = n_lobes_all_sig./n_lobes_all;
    se_prop = sqrt((prop_total .* (1-prop_total)) ./ n_lobes_all);

    % Add number of electrodes to labels
    region_labels = cell(1,length(regions));
    for r = 1:length(regions)
        region_labels{r} = sprintf('N = %i', n_lobes_all(r));
    end

    fig = figure('Position', [1981,181,1540,400]);
    set(fig,'defaultAxesColorOrder',[[0 0 0]; [0 0 0]]);
    hold on

    y_ticks_man = [0 0.25 0.5 0.75 1];

    for i = 2:length(y_ticks_man)
        plot([0 length(regions)+1], y_ticks_man(i)*ones(2,1), '--', 'LineWidth', 0.1, 'Color', [0.3 0.3 0.3], 'HandleVisibility','off')
    end

    bar_total = bar(prop_total, 0.5, 'FaceColor', [0.5 0.5 0.5]);

    % Plot the errors
    eb_high = errorbar(bar_total.XEndPoints, bar_total.YEndPoints, 1.96*se_prop, 1.96*se_prop);    
    eb_high.Color = [0 0 0];                            
    eb_high.LineStyle = 'none'; 
    eb_high.LineWidth = 1.5;

    xticks(1:length(region_labels))
    xticklabels(region_labels)

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

    ylabel('Fraction of Channels')

    saveas(gca, file_ratio_total)
                
end