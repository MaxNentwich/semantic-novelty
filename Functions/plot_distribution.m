% Plot distibution and Gaussian fit        

function [x, log_transform] = plot_distribution(x, dist_file)

    plot_distro(x)

    log_transform = input('Apply log transformation? (yes=1, no=0) \n');

    if log_transform 

        x = log(x + 1);
        plot_distro(x)

    end

    xlabel('Amplitude Difference')
    ylabel('Normalized Count')
    legend({'Data', 'Gaussian Fit'})

    saveas(gca, dist_file)

end