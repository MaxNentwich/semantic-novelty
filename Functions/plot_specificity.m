               
function plot_specificity(options_main, jaccard_dist, p_pair, regions, file_ratio_conditions)

    % Add number of patients to labels
    n_patients = sum(~isnan(jaccard_dist));

    region_plot_labels = cell(1, length(regions));

    for r = 1:length(regions)
        region_plot_labels{r} = sprintf('%s (N = %i)', regions{r}, n_patients(r));
    end

    figure 
    hold on

    for r = 1:length(regions)  
        
        scatter(0.1*randn(1, sum(~isnan(jaccard_dist(:,r)))) + r, jaccard_dist(~isnan(jaccard_dist(:,r)), r), 25, ...
            'MarkerFaceColor', options_main.region_color(r,:), 'MarkerEdgeColor', 'k')  
        plot([r-0.3, r+0.3], median(jaccard_dist(~isnan(jaccard_dist(:,r)), r)) * [1 1], 'k--', 'LineWidth', 2)
        
        if p_pair(r) < 0.05
            plot(r, 1.2, 'k*', 'MarkerSize', 15, 'LineWidth', 1.5)
        end
        
    end

    xticks(1:length(region_plot_labels))
    xticklabels(region_plot_labels)
    xtickangle(45)

    ylim([0, 1.3])
    xlim([0.5 length(regions)+1])
    ylabel('Specificity')

    set(gca, 'Fontsize', 20)

    saveas(gca, file_ratio_conditions)
    
end