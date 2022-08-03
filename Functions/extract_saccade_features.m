%% Extract features from the saccade and face annotations used to clasify saccades 
function [features, prediction, score_face, saccade_sample, fixation_sample, saccade_amplitude] = extract_saccade_features(...
    options, video, patient, eye_file, image_dir, save_images, varargin)

    %% SVM model for prediction can be passed as varargin
    if length(varargin) == 1
        svm_model = varargin{1};
        predict_saccade = true;
    else
        predict_saccade = false;
    end
    
    %% Load the face annotations     
    if strcmp(video, 'The_Present')

        files = dir(sprintf('%s/present_all_frames_edited', options.face_annot_dir));
        files([files.isdir]) = [];

        frames = files(cellfun(@(C) contains(C, '.jpg'), {files.name}));
        annotation = files(cellfun(@(C) contains(C, '.json'), {files.name}));
        
    else
        
        frames = dir(sprintf('%s/%s', options.frame_dir, video));
        frames([frames.isdir]) = [];
        
        % Load the face annotation table
        filename = sprintf('%s/%s_labelled_frames_corrected.csv', options.face_annot_dir, video);
        bbox = readtable(filename, detectImportOptions(filename));
        
    end
    
    % Load the frame size
    vid_files = dir(sprintf('%s/Data/video_frame_size', options.w_dir));
    vid_files = vid_files(cellfun(@(C) contains(C, video), {vid_files.name}));

    [~, vid_filename] = fileparts(vid_files.name);
    out_file = sprintf('%s/Data/video_frame_size/%s.mat', options.w_dir, vid_filename);
    load(out_file, 'vid_size')
    
    %% Load et data
    [eye, start_sample, end_sample] = load_et(options.data_dir, options.eye_dir, patient, eye_file, options.trigger_IDs);

    % Detect saccades
    [saccade_onset, ~, saccade_amplitude, ~, ~, fixation_onset, pos_pre, pos_post] = detect_saccade_onset(eye, options, 0);
    
    %% Process eyetracking data   
    % Find the radius of the foveal field of view on the screen
    r = foveal_r(options, eye);

    %% Correct the samples
    % eye data has been cut and eye.frame_sample has to be corrected 
    eye.frame_sample = interp1(eye.time, 1:length(eye.time), eye.frame_time);

    % Find the frame corresponding to each saccade and fixation onset
    saccade_sample = find(saccade_onset);
    fixation_sample = find(fixation_onset);

    %% Remove saccades across scene cuts
    idx_across_cut = find_saccades_across_cuts(options, patient, eye_file, eye, ...
        start_sample, end_sample, saccade_sample, fixation_sample);
    
    % Remove the saccades across cuts
    saccade_sample(idx_across_cut) = [];
    fixation_sample(idx_across_cut) = [];
    
    pos_pre(idx_across_cut, :) = [];
    pos_post(idx_across_cut, :) = [];
    
    saccade_amplitude(idx_across_cut) = [];
    
    %% Find the eye position and saccade and fixation onset
    % Correct duplicate frames
    [~, idx_unique] = unique(eye.frame_sample, 'first');
    idx_frames = 1:length(eye.frame_sample);
    idx_frames(idx_unique) = [];
    
    if ~isempty(idx_frames)
        idx_duplicate = find(eye.frame_sample(idx_frames) == eye.frame_sample, 1, 'last');
        eye.frame_sample(idx_duplicate) = eye.frame_sample(idx_duplicate) + 1;
    end
    
    saccade_frame = round(interp1(eye.frame_sample, 1:length(eye.frame_sample), saccade_sample));
    fixation_frame = round(interp1(eye.frame_sample, 1:length(eye.frame_sample), fixation_sample));
    
    % Some saccades happen before movie onset
    idx_nan = isnan(saccade_frame) | isnan(fixation_frame);

    fixation_frame(idx_nan) = [];
    pos_pre(idx_nan, :) = [];
    pos_post(idx_nan, :) = [];
    saccade_sample(idx_nan) = [];
    fixation_sample(idx_nan) = [];
    saccade_amplitude(idx_nan) = [];

    % Scale the position to the screen size
    pos_pre = pos_pre.*options.screen_size;
    pos_post = pos_post.*options.screen_size;

    % Cut saccades outside the video
    idx_out = pos_pre(:,1) < options.destrect_ext(1) | pos_pre(:,1) > options.destrect_ext(3) ...
            | pos_pre(:,2) < options.destrect_ext(2) | pos_pre(:,2) > options.destrect_ext(4) ...
            | pos_post(:,1) < options.destrect_ext(1) | pos_post(:,1) > options.destrect_ext(3) ...
            | pos_post(:,2) < options.destrect_ext(2) | pos_post(:,2) > options.destrect_ext(4);

    fixation_frame(idx_out) = [];
    pos_pre(idx_out, :) = [];
    pos_post(idx_out, :) = [];
    saccade_sample(idx_out) = [];
    fixation_sample(idx_out) = [];
    saccade_amplitude(idx_out) = [];

    % Adjust for the border
    pos_pre = pos_pre - options.destrect_ext([1,2]);
    pos_post = pos_post - options.destrect_ext([1,2]);

    % Adjust for the scaling of the video
    vid_size_screen = options.destrect_ext([3,4]) - options.destrect_ext([1,2]);
    rs_factor = vid_size./vid_size_screen;

    pos_pre = pos_pre.*rs_factor;
    pos_post = pos_post.*rs_factor;

    % Exlude saccades with same onset and offset position
    idx_same = sum(pos_pre == pos_post,2) ~= 0;
    fixation_frame(idx_same) = [];
    pos_pre(idx_same, :) = [];
    pos_post(idx_same, :) = [];
    saccade_sample(idx_same) = [];
    fixation_sample(idx_same) = [];
    saccade_amplitude(idx_same) = [];
    
    %% For the present the fixation frames have to be converted to the CMI version of the video
    if strcmp(video, 'The_Present')
    
        load(sprintf('%s/Organize/align_ns_cmi_present.mat', options.w_dir), 'resampling_ratio', 'offset')
        fixation_frame = round((fixation_frame - offset)*resampling_ratio);
        
        % The CMI verison is shorter thus some fixations can't be matched to annotations 
        idx_no_annot = fixation_frame < 0 | fixation_frame > length(annotation); 
        fixation_frame(idx_no_annot) = [];
        pos_pre(idx_no_annot, :) = [];
        pos_post(idx_no_annot, :) = [];
        saccade_sample(idx_no_annot) = [];
        fixation_sample(idx_no_annot) = [];
        saccade_amplitude(idx_no_annot) = [];
        
        %% Transform the eye position 
        % Load the variables for transformation
        load(sprintf('%s/Data/present_cmi/frame_transformation.mat', options.w_dir), 'pix_border', 'scale')
        % Load the CMI video
        load(sprintf('%s/Data/present_cmi/vid_size_present_cmi.mat', options.w_dir), 'vid_size_cmi');
        
        % Adjust for the border
        pos_pre(:,2) = pos_pre(:,2) - pix_border(1);
        pos_post(:,2) = pos_post(:,2) - pix_border(1);
        
        % Adjust for the scaling of the video
        pos_pre = pos_pre.*scale;
        pos_post = pos_post.*scale;
        
        % Cut saccades outside the video
        idx_out_cmi = pos_pre(:,1) < 0 | pos_pre(:,1) > vid_size_cmi(1) ...
                    | pos_pre(:,2) < 0 | pos_pre(:,2) > vid_size_cmi(2) ...
                    | pos_post(:,1) < 0 | pos_post(:,1) > vid_size_cmi(1) ...
                    | pos_post(:,2) < 0 | pos_post(:,2) > vid_size_cmi(2);
                
        fixation_frame(idx_out_cmi) = [];
        pos_pre(idx_out_cmi, :) = [];
        pos_post(idx_out_cmi, :) = [];
        saccade_sample(idx_out_cmi) = [];
        fixation_sample(idx_out_cmi) = [];
        saccade_amplitude(idx_out_cmi) = [];

    end
    
    % Fixation frame could have been interpolated to 0
    idx_zero = fixation_frame == 0;
    
    fixation_frame(idx_zero) = [];
    pos_pre(idx_zero, :) = [];
    pos_post(idx_zero, :) = [];
    saccade_sample(idx_zero) = [];
    fixation_sample(idx_zero) = [];
    saccade_amplitude(idx_zero) = [];
    
    assert(length(pos_pre) == length(pos_post), 'Position before and after saccades does not match!')
    assert(length(fixation_frame) == length(pos_post), 'Number of frames and saccades does not match!')
    
    %% Load the face annotations and extract features
    if save_images
        if exist(image_dir, 'dir') == 0, mkdir(image_dir), end
    end
    
    % Initialize arrays for features
    face_saccade = cell(size(fixation_frame));

    towards_face = nan(length(fixation_frame),1);
    face_area = nan(length(fixation_frame),1);
    saccade_angle = nan(length(fixation_frame),1);
    centroid_angle = nan(length(fixation_frame),1);
    min_distance = nan(length(fixation_frame),1);
    features = nan(length(fixation_frame),5);
    prediction = nan(length(fixation_frame),1);
    score_face = nan(length(fixation_frame),1);

    for f = 1:length(fixation_frame)

        % Load the frame 
        if strcmp(video, 'The_Present')
            frame = imread(sprintf('%s/present_all_frames_edited/%s', options.face_annot_dir, frames(fixation_frame(f)).name));
        else
            frame = imread(sprintf('%s/%s/%s', options.frame_dir, video, frames(fixation_frame(f)).name));
        end
        
        % Add the fixation onset
        frame = insertMarker(frame, pos_post(f,:), 'o', 'Size', 5, 'Color', 'red');

        % Plot
        if save_images
            close all
            figure('Position', [2500,350,650,450])
            imagesc(frame)
            axis off
        end

        %% Load the face annotations
        if strcmp(video, 'The_Present')
            
            annot_data = jsondecode(fileread(sprintf('%s/present_all_frames_edited/%s', ...
                options.face_annot_dir, annotation(fixation_frame(f)).name)));

            if iscell(annot_data.shapes)
                idx_face = find(cellfun(@(C) contains(C, 'Face', 'IgnoreCase', true), ...
                    cellfun(@(C) C.label, annot_data.shapes, 'UniformOutput', false)));
            else
                idx_face = find(cellfun(@(C) contains(C, 'Face', 'IgnoreCase', true), {annot_data.shapes.label}));
            end
            
            if isempty(idx_face)
                if save_images
                    saveas(gca, sprintf('%s/fixation_%05d.png', image_dir, f));
                end
                continue
            end

            % Create a class column
            bounding_boxes = cell(1, length(idx_face));

            % Create a bounding box column
            for i = 1:length(idx_face)

                if iscell(annot_data.shapes)
                    bounding_boxes{i} = annot_data.shapes{idx_face(i)}.points;
                else
                    bounding_boxes{i} = annot_data.shapes(idx_face(i)).points;
                end

            end
            
        else
            
            bounding_boxes = strsplit(bbox.BBox_coordinates{fixation_frame(f)}, '\n');
            bb_coord = cell(length(bounding_boxes),1);
            
            % Skip if no annotations on this frame
            if strcmp(bounding_boxes{1}, '[]')
                if save_images
                    saveas(gca, sprintf('%s/fixation_%05d.png', image_dir, f));
                end
                continue
            end
            
        end
        
        %% Find the centroid of the bounding box and normal distance to the saccade
        face_rect = cell(length(bounding_boxes), 1);
        centroid_rect = nan(2, length(bounding_boxes));
        intersection = nan(2, length(bounding_boxes));
        normal_distance = nan(1, length(bounding_boxes));

        for b = 1:length(bounding_boxes)

            if strcmp(video, 'The_Present')
                
                face_rect{b} = polyshape(bounding_boxes{b}(:,1), bounding_boxes{b}(:,2));
                
            else
                
                bb_part = strsplit(bounding_boxes{b}, ' ');
                bb_coord{b} = cellfun(@(C) str2double(strrep(strrep(C, '[', ''), ']', '')), bb_part);
                bb_coord{b}(isnan(bb_coord{b})) = [];

                % Convert to matlab format
                h = bb_coord{b}(4) - bb_coord{b}(2);

                if h < 0
                    bb_coord{b}([2,4]) = bb_coord{b}([4,2]);
                end

                face_rect{b} = polyshape([bb_coord{b}(1), bb_coord{b}(1), bb_coord{b}(3), bb_coord{b}(3)], ...
                                      [bb_coord{b}(4), bb_coord{b}(2), bb_coord{b}(2), bb_coord{b}(4)]); 

            end
            
            % Find the centroid 
            [centroid_rect(1,b), centroid_rect(2,b)] = centroid(face_rect{b});

            % Find the normal distance to the gaze vector
            [normal_distance(b), intersection(:,b)] = normal_2d(pos_pre(f,:), pos_post(f,:), centroid_rect(:,b));

        end

        % Remove empty entries
        if ~strcmp(video, 'The_Present')
            bb_coord(cellfun(@(C) isempty(C), bb_coord)) = [];
        end
        
        % Check if the fixation onset is on a face
        face_saccade{f} = false(length(face_rect),1);
        for b = 1:length(face_rect)
             face_saccade{f}(b) = inpolygon(pos_post(f,1), pos_post(f,2), face_rect{b}.Vertices(:,1), face_rect{b}.Vertices(:,2));
        end

        %% Total area of intersection between faces and the foveal field of view
        foveal_field = poly_circle(pos_post(f,:), r);

        face_fovea_area = nan(1, length(face_rect));
        for b = 1:length(face_rect)
            face_fovea_area(b) = area(intersect(face_rect{b}, foveal_field));
        end

        pix2mm = mean(options.screen_size./options.screen_dimension);
        face_fovea_area = face_fovea_area * ((1/pix2mm)^2);

        % Area of all faces in the foveal field of view
        face_area(f) = sum(face_fovea_area);

        % Add to plot
        if save_images
            hold on
            plot(foveal_field)
        end

        %% Find the closes face (out of all faces that overlap with the foveal field of view)
        if sum(face_fovea_area) ~= 0

            idx_overlap = find(face_fovea_area ~= 0);

            [~, idx_close] = min(abs(normal_distance(idx_overlap)));
            face_min = idx_overlap(idx_close);

        else
            [~, face_min] = min(abs(normal_distance));
        end

        % The smallest normal distance might be on a face behind the saccade even if the saccade lands on a face
        if face_min ~= find(face_saccade{f})
            face_min = find(face_saccade{f});
        end

        %% Find distance to the closest bounding box
        distance = sqrt(sum((centroid_rect' - pos_post(f,:)).^2, 2));    
        [~, idx_close] = min(distance);

        % If the saccade is long and close to another face consider this the closest
        saccade_length = norm(pos_post(f,:) - pos_pre(f,:));

        if saccade_length > min(distance) && sum(idx_close ~= face_min) ~= 0
            face_min = idx_close;
        end

        if ~isempty(idx_close)
            min_distance(f) = abs(distance(idx_close));
        end

        %% Plot all bounding boxes and calculate features depending on the closest face
        for b = 1:length(face_rect)

            % Plot the bounding box
            if save_images
                plot(face_rect{b})
            end
            
            if b == face_min

                % Plot the normal distance
                l_normal = [intersection(:,face_min), centroid_rect(:,face_min)];
                if save_images
                    line(l_normal(1,:), l_normal(2,:), 'Color', 'r', 'LineWidth', 2)
                end

                % Plot a line from saccade onset to face centroid
                l_centr = [centroid_rect(:, face_min), pos_pre(f,:)'];
                if save_images
                    line(l_centr(1,:), l_centr(2,:), 'Color', 'y', 'LineWidth', 2)
                end

                % Compute the angle beteen the saccade vector and the line from onset to centroid
                v1 = pos_post(f,:) - pos_pre(f,:);
                v2 = centroid_rect(:,face_min) - pos_pre(f,:)';
                saccade_angle(f) = rad2deg(acos(v1 * v2 / (norm(v1) * norm(v2))));

                % Compute the angle between the lines from the centroid to saccade onset and fixation onset
                v3 = pos_post(f,:) - centroid_rect(:,face_min)';
                centroid_angle(f) = rad2deg(acos(v3 * -v2 / (norm(v3) * norm(-v2))));

                % Compute a label for saccade direciton towards or away from the face
                v4 = intersection(:,face_min) - pos_post(f,:)';
                post_to_normal = norm(v1' + v4) / norm(v1); 

                if post_to_normal > 1
                    towards_face(f) = 1;
                elseif post_to_normal < 1
                    towards_face(f) = -1;
                end

            end

            % Plot a line from fixation onset to the centroid of the closest face
            if b == idx_close
                l_close = [pos_post(f,:)', centroid_rect(:,idx_close)];
                if save_images
                    line(l_close(1,:), l_close(2,:), 'Color', 'b', 'LineWidth', 2)
                end
            end

        end
        
        %% Organize all features
        features(f,:) = [towards_face(f), face_area(f), min_distance(f), saccade_angle(f), centroid_angle(f)];
        
        %% Classify the saccades
        if predict_saccade
            [prediction(f), score] = predict(svm_model, features(f,:));
            score_face(f) = score(2);
        end
        
        %% Plot the saccade vector and add title with features
        if save_images

            quiver(pos_pre(f,1), pos_pre(f,2), pos_post(f,1)-pos_pre(f,1), pos_post(f,2)-pos_pre(f,2), 0, ...
                'LineWidth', 1.5, 'Color', 'green')

            if predict_saccade
                title(sprintf(['SVM label: %i; SVM score: %1.2f; Towards face: %i; Area: %1.0fmm^{2}, Distance: %1.0fmm;\n', ...
                               'Sacc Angle: %1.0f%s; Centr Angle: %1.0f%s'], ...
                               prediction(f), score_face(f), towards_face(f), face_area(f), min_distance(f), ...
                               saccade_angle(f), char(176), centroid_angle(f), char(176)))
            else
                title(sprintf(['Towards face: %i; Area: %1.0fmm^{2}, Distance: %1.0fmm;\n', ...
                               'Sacc Angle: %1.0f%s; Centr Angle: %1.0f%s'], ...
                               towards_face(f), face_area(f), min_distance(f), saccade_angle(f), char(176), ...
                               centroid_angle(f), char(176)))
            end
            
            saveas(gca, sprintf('%s/fixation_%05d.png', image_dir, f));

        end

    end

end