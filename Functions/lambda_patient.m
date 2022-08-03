
function lambda = lambda_patient(options, band)

    idx_band = find(ismember(options.band_names, options.band_select{band}));

    if strcmp(options.band_select{band}, 'raw')
        lambda = options.lambda_raw;
    else
        lambda = options.lambda_bands(idx_band);
    end

end