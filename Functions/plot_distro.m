
function plot_distro(x)

    x(isnan(x)) = [];
    x(isinf(x)) = [];
    
    mu = nanmean(x);
    sigma = nanstd(x);

    x_bins = linspace(min(x), max(x), 1000);
    f = 1/(sigma*sqrt(2*pi)) * exp(-0.5 * ((x_bins-mu)/sigma).^2);

    figure
    hold on
    histogram(x, 'Normalization', 'pdf')
    plot(x_bins, f)
    
end