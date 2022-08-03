%% resample scenes -> reassign peaks to the right location 

function [signal_rs, time_rs] = resample_peaks(signal, fs_original, ds_factor)

    n_ds = round(length(signal)/ds_factor);
    signal_rs = zeros(1, n_ds);

    time = (1:length(signal))/fs_original;
    time_rs = (1:n_ds)/(fs_original/ds_factor);

    idx_peak = signal ~= 0;
    time_peak = time(idx_peak);

    idx_rs = round(interp1(time_rs, 1:n_ds, time_peak));
    idx_rs(isnan(idx_rs)) = 1;
    
    signal_rs(idx_rs) = signal(idx_peak);

end