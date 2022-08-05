
function face_velocity = load_face_motion(options, patient_name, file_name, start_sample, end_sample, eye)

    load(sprintf('%s/%s/%s/%s', options.data_dir, patient_name, options.face_vel_dir, file_name), 'face_velocity')

    % Cut at the triggers
    face_velocity = face_velocity(start_sample:end_sample);

    % Downsample
    face_velocity = resample_peaks(face_velocity, eye.fs, eye.fs/options.fs_ana);

    % There may be some NaNs at the edges from previous interpolation, extrapolate here
    idx_nan = find(isnan(face_velocity)); 
    idx_no_nan = setdiff(1:length(face_velocity), idx_nan);

    face_velocity(idx_nan) = interp1(idx_no_nan, face_velocity(idx_no_nan), idx_nan, 'linear', 'extrap');
    
end