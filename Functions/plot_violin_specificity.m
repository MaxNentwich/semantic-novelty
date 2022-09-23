               
function plot_violin_specificity(options_main, jaccard_dist, regions, patients, file_ratio_conditions)

    % Add number of patients to labels
    n_patients = sum(~isnan(jaccard_dist));

    region_plot_labels = cell(1, length(regions));

    for r = 1:length(regions)
        region_plot_labels{r} = sprintf('%s (N = %i)', regions{r}, n_patients(r));
    end

    % Separate insula data (all the same so violinplot makes no sense
    idx_insula = cellfun(@(C) strcmp(C, 'Insula'), regions);

    jaccard_violin = jaccard_dist;

    % Find areas with all 1's
    idx_1 = zeros(length(regions),1);
    for r = 1:length(regions)
        if sum(jaccard_dist(~isnan(jaccard_dist(:,r)), r) == 1) == sum(~isnan(jaccard_dist(:,r)))
            idx_1(r) = 1;
        end
    end
    idx_1 = idx_1 == 1;
    
    idx_remove = idx_1 | idx_insula;
    violin_pos = find(idx_remove == 0);
    
    jaccard_violin(:, idx_remove) = [];
    
    regions_violin = regions;
    regions_violin(idx_remove) = [];
    
    jaccard_violin = jaccard_violin(:);

    region_label = repmat(regions_violin', length(patients), 1);
    region_label = region_label(:);

    idx_nan = isnan(jaccard_violin);

    jaccard_violin(idx_nan) = [];
    region_label(idx_nan) = [];

    jaccard_violin = jaccard_violin + 1e-5*randn(size(jaccard_violin));

    figure 
    hold on

    violinplot(jaccard_violin, region_label, 'ShowData', false, 'ShowBox', false, 'ShowWhiskers', false, 'ShowNotches', false, ...
        'ShowMedian', false, 'BandWidth', 0.075, 'ViolinColor', options_main.region_color, 'GroupOrder', regions_violin, ...
        'GroupPos', violin_pos);

    for r = 1:length(regions)     
        scatter(0.15*randn(1, sum(~isnan(jaccard_dist(:,r)))) + r, jaccard_dist(~isnan(jaccard_dist(:,r)), r), 15, ...
            'MarkerFaceColor', options_main.region_color(r,:), 'MarkerEdgeColor', 'k')  
        plot([r-0.3, r+0.3], median(jaccard_dist(~isnan(jaccard_dist(:,r)), r)) * [1 1], 'k--')
    end

    xticks(1:length(region_plot_labels))
    xticklabels(region_plot_labels)
    xtickangle(45)

    ylim([0, 1])
    xlim([0.5 length(regions)+1])
    ylabel('Specificity')

    set(gca, 'Fontsize', 20)

    saveas(gca, file_ratio_conditions)
    
end