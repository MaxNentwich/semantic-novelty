
function [stat, stat_shuffle] = estimate_stats_timepoints(w, w_shuffle)

    n_shuffle = size(w_shuffle, 3);
    
    % Range of the pdf
    pdf_range = 1.2*[min([min(w(:)), min(w_shuffle(:))]), ...
        max([max(w(:)), max(w_shuffle(:))])];           
    points = linspace(pdf_range(1), pdf_range(2), 10000);

    stat = zeros(size(w));
    stat_shuffle = zeros(size(w_shuffle));

    for ch = 1:size(w,1)
        for sm = 1:size(w,2)

            % Fit the pdf
            stdev = std(squeeze(w_shuffle(ch,sm,:)));
            [f,xi] = ksdensity(squeeze(w_shuffle(ch,sm,:)), points, 'Bandwidth', 0.3*stdev);

            % Estimate the p-value
            idx_pdf = round(interp1(xi, 1:length(xi), w(ch,sm)));
            stat(ch,sm) = sum(f(idx_pdf:end))*mean(diff(xi));
            stat(ch,sm) = min([stat(ch,sm), 1-stat(ch,sm)]);
            
            for s = 1:n_shuffle
                idx_pdf = round(interp1(xi, 1:length(xi), w_shuffle(ch,sm,s)));
                stat_shuffle(ch,sm,s) = sum(f(idx_pdf:end))*mean(diff(xi));
                stat_shuffle(ch,sm,s) = min([stat_shuffle(ch,sm,s), ...
                    1-stat_shuffle(ch,sm,s)]);               
            end

        end
    end
            
end