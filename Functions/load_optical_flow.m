
function optic_flow = load_optical_flow(file_name, data_dir, eye, fs_ana)

    % Read table to look up correspondence of different file names
    [~, file_table] = xlsread('file_names.xlsx');
    vid_file = file_table{contains(file_table(:, 2), strrep(file_name, '.mat', '')), 3};
    
    [~, vid_name] = fileparts(vid_file);
    
    load(sprintf('%s/Optic_flow/%s.mat', data_dir, vid_name), 'optic_flow', 'fr');  
    
    % Fix time axis
    if length(eye.frame_time) ~= length(unique(eye.frame_time)) 
        idx_dup = find(diff(eye.frame_time) == 0) + 1;
        eye.frame_time(idx_dup) = eye.frame_time(idx_dup) + 1e-3;
    end
    
    % Resample to 10Hz
    if fs_ana == 10   

        optic_flow = resample_peaks(optic_flow, fr, fr/10.002);       

    else

        % Cut to the number of frames recorded 
        optic_flow = optic_flow(1:length(eye.frame_sample));
        
        % Find the samples of the optic flow aligned to the eyetracking data 
        optic_flow = interp1(eye.frame_time, optic_flow, eye.time);

        % Downsample to the desired sampling rate
        optic_flow = resample_peaks(optic_flow, eye.fs, eye.fs/fs_ana);

    end  
    
    % Correct possible NaNs
    samples = 1:length(optic_flow);
    idx_nan = find(isnan(optic_flow));

    vals_interp = interp1(setdiff(samples, idx_nan), optic_flow(setdiff(samples, idx_nan)), idx_nan, ...
        'linear', 'extrap');

    optic_flow(idx_nan) = vals_interp;

end