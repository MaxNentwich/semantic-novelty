
function align_present_cmi_ns(options)

    out_file = sprintf('%s/Organize/align_ns_cmi_present.mat', options.drive_dir);
    
    if exist(out_file, 'file') == 0

        % Compute the temporal contrast of the CMI version
        contr_file = sprintf('%s/present_cmi/temp_contr_the_present_cmi.mat', options.im_data_dir);

        if exist(contr_file, 'file') == 0

            [contrast, fr] = compute_temporal_contrast(sprintf('%s/present_cmi/the_present_child_mind.mp4', options.im_data_dir));

            save(contr_file, 'contrast', 'fr')

        else
            load(contr_file, 'contrast', 'fr')
        end

        contrast_cmi = contrast;

        % Load the temporal contrast of the NorthShore version
        load(sprintf('%s/temporal_contrast.mat', options.im_data_dir), 'contrast_vid', 'vid_names')
        idx_vid = cellfun(@(C) contains(C, 'The_Present'), vid_names);

        contrast_ns = contrast_vid{idx_vid};

        % Find the peaks in the contrast
        [~, peaks_cmi] = findpeaks(contrast_cmi, 'MinPeakHeight', prctile(contrast_cmi, options.th_contr_peak));
        [~, peaks_ns] = findpeaks(contrast_ns, 'MinPeakHeight', prctile(contrast_ns, options.th_contr_peak));

        % Last peak of the contrast in the NorthShore video is not in the CMI video
        peaks_ns(end) = [];

        % Compute the resampling ratio, comparing the samples between the first and last peak of the temporal contrast (cut)
        resampling_ratio = range(peaks_cmi)/range(peaks_ns);

        % Resample the contrast of the CMI version
        contrast_cmi_rs = resample_peaks(contrast_cmi, fr, resampling_ratio);

        % Find the offset
        [xc, lag] = xcorr(contrast_ns, contrast_cmi_rs);
        [~, idx_max_xc] = max(xc);

        offset = lag(idx_max_xc);

        % Save the data
        save(out_file, 'resampling_ratio', 'offset')
        
    end

end