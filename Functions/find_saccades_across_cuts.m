%% Find saccades across scene cuts
function idx_across_cut = find_saccades_across_cuts(options, patient, eye_file, eye, start_sample, end_sample, saccade_sample, ...
    fixation_sample)

    % Load contrast for alignment
    load(sprintf('%s/%s/%s/%s', options.data_dir, patient, options.contr_dir, eye_file), 'contrast')
    % Cut at the triggers
    contrast = contrast(start_sample:end_sample);

    % Load the cuts
    scenes = load_scenes(options, eye_file, contrast, eye, eye.fs);
    cuts = find(scenes);

    idx_across_cut = false(1, length(saccade_sample));

    for s = 1:length(saccade_sample)

        if saccade_sample(s) > cuts
            continue
        end

        % Find the closest cut after saccade onset
        samples_before = saccade_sample(s) - cuts;
        if isempty(samples_before)
            cut_after = 1;
        else
            cut_after = find(samples_before == max(samples_before(samples_before < 0)));
        end

        % Find the distance to the fixation onset
        samples_fixation = fixation_sample(s) - cuts(cut_after);

        % Check if the fixation onset is after the cut
        if samples_fixation > 0
            idx_across_cut(s) = 1;
        end

    end

end