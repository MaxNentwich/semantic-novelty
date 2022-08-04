
function [scene_cuts, scene_cuts_high, scene_cuts_low] = load_scenes(options, file_name, contrast, eye, fs_ana)

    % Data directory
    data_dir = strrep(options.data_dir, '/Patients', '');
    
    % Function to load the annotated scene cuts for any movie  
    [~, video_name] = fileparts(file_name);
    
    %% In the case of the monkey movies load brians annotations
    if contains(file_name, 'Monkey')
        
        monkey_idx = file_name(find(file_name == 'y') + 1);
        load(sprintf('%s/Brians_features/Movie%s_10fps_rgr2.mat', data_dir, monkey_idx), 'RGR10fps')

        idx_scenes = cellfun(@(C) strcmp(C, 'Scene Cuts'), RGR10fps.features);
        scene_cuts = RGR10fps.regressors(idx_scenes, :);
        
        % Load the annotations of semantic and camera scenes
        scene_annot = xlsread(sprintf('%s/Annotation/Monkey%s_scenes.xlsx', data_dir, monkey_idx));
            
        scene_idx_annot = scene_annot(:,1);
        
        % Resample to eyetracking sampling rate
        scene_cuts_eye = resample_peaks(scene_cuts, length(scene_cuts), length(scene_cuts)/length(contrast));

        % Find contrast corresponding to each scene change
        scene_idx = find(scene_cuts_eye ~= 0);

        % Define a search window
        search_window = 300;

        % Loop trough each window and find the peak in contrast that is closest to the scene cut, 
        % then take this sample as the corrected value of the scene cut
        for si = 1:length(scene_idx)                   
            [~, contr_idx] = max(contrast(scene_idx(si)-search_window/2 : scene_idx(si)+search_window/2)); 
            contr_idx = contr_idx - (search_window/2+1);
            scene_idx(si) = scene_idx(si) + contr_idx;
            % Correct if ther is an error
            if si == 1
                continue
            end
            if scene_idx(si) == scene_idx(si-1)
                contr_window = contrast(scene_idx(si)-search_window/2 : scene_idx(si)+search_window/2);
                [~, contr_idx] = max(contr_window); 
                contr_windw(contr_idx) = 0;
                [~, contr_idx] = max(contr_windw); 
                contr_idx = contr_idx - (search_window/2+1);
                scene_idx(si) = scene_idx(si) + contr_idx;                    
            end
        end

        % Create a vector of the length of the eyetracking data
        scene_cuts_eye = zeros(size(scene_cuts_eye));
        scene_cuts_eye(scene_idx) = 1;

        % Downsample to the desired sampling rate
        scene_cuts = resample_peaks(scene_cuts_eye, eye.fs, eye.fs/fs_ana);

    %% Otherwise load my own
    else

        if contains(file_name, 'Present')       
            scene_annot = xlsread(sprintf('%s/Annotation/The_Present_scenes.xlsx', data_dir));       
        else       
            scene_annot = xlsread(sprintf('%s/Annotation/%s_scenes.xlsx', data_dir, strrep(file_name, '.mat', '')));         
        end
        
        % Convert frame indices to a vector with zeros and ones
        scene_idx_annot = scene_annot(:,1);
       
        % Find the samples of the scenes aligned to the eyetracking data 
        scene_eye_samples = interp1(eye.time, 1:length(eye.time), eye.frame_time(scene_idx_annot));

        % Create a vector of the length of the eyetracking data
        scene_cuts_eye = zeros(1, length(eye.time));
        scene_cuts_eye(scene_eye_samples) = 1;

        % Downsample to the desired sampling rate
        scene_cuts = resample_peaks(scene_cuts_eye, eye.fs, eye.fs/fs_ana);

    end
    
    %% Find semantic and camera scenes

    % Load the indices of high and low salience cuts
    if contains(video_name, 'Monkey')
        expression = '_Rep_\d';
        load(sprintf('%s/salience_cuts/%s_salience_cuts.mat', options.im_data_dir, video_name(1:regexp(video_name, expression)-1)), ...
            'scenes_high_annot', 'scenes_low_annot');
        scenes_high = scenes_high_annot;
        scenes_low = scenes_low_annot;
    elseif contains(video_name, 'Present')
        expression = '_Rep_\d';
        load(sprintf('%s/salience_cuts/%s_salience_cuts.mat', options.im_data_dir, video_name(1:regexp(video_name, expression)-1)), ...
            'scenes_high', 'scenes_low');
    else
        load(sprintf('%s/salience_cuts/%s_salience_cuts.mat', options.im_data_dir, video_name), 'scenes_high', 'scenes_low');
    end
    
    % Find the indices of scene cuts in the resamples signal 
    scene_idx_resample = find(scene_cuts);
    
    % High Salience Scenes       
    scene_idx_high = scene_idx_resample(ismember(scene_idx_annot, scenes_high));
    scene_cuts_high = scene_cuts;
    scene_cuts_high(setdiff(1:length(scene_cuts_high), scene_idx_high)) = 0;

    % Low Salience Scenes
    scene_idx_low = scene_idx_resample(ismember(scene_idx_annot, scenes_low));
    scene_cuts_low = scene_cuts;
    scene_cuts_low(setdiff(1:length(scene_cuts_low), scene_idx_low)) = 0;
    
    %% Check if all cuts were found
    assert(length(find(scene_cuts_high)) == length(scenes_high), 'Some high salience cuts got lost!');
    assert(length(find(scene_cuts_low)) == length(scenes_low), 'Some low salience cuts got lost!');

end