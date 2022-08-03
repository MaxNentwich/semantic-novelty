%% Construct a face velocity stimulus from the face annotations for The Present and Despicable Me

function extract_face_motion(options)

    for video = 1:length(options.face_motion_vids)

        % Directory for videos and results
        out_dir = sprintf('%s/Data/Face_motion/', options.w_dir);
        if exist(out_dir, 'dir') == 0, mkdir(out_dir), end

        %% Load all the data if it hasn't already been loaded
        if exist(sprintf('%s/%s_face_velocity.mat', out_dir, options.face_motion_vids{video}), 'file') == 0

            % For the CMI version of the present scene cuts need to be found
            if strcmp(options.face_motion_vids{video}, 'The_Present')
                find_scenes_present(options, options.face_motion_vids{video})
            end

            % Load the frame rate 
            if strcmp(options.face_motion_vids{video}, 'The_Present')
                vid_file = sprintf('%s/Data/present_cmi/the_present_child_mind.mp4', options.w_dir);
                vid = VideoReader(vid_file);
                frame_rate = vid.FrameRate;
            else
                load(sprintf('%s/Organize/vid_data.mat', options.w_dir), 'fr', 'vid_names')
                frame_rate = fr(cellfun(@(C) contains(C, options.face_motion_vids{video}), vid_names));
            end
            T = 1/frame_rate;

            % Load the list of frames
            if strcmp(options.face_motion_vids{video}, 'The_Present')

                files = dir(sprintf('%s/present_all_frames_edited', options.face_annot_dir));
                files([files.isdir]) = [];

                frames = files(cellfun(@(C) contains(C, '.jpg'), {files.name}));
                annotation = files(cellfun(@(C) contains(C, '.json'), {files.name}));

            else
                frames = dir(sprintf('%s/%s', options.frame_dir, options.face_motion_vids{video}));
                frames([frames.isdir]) = [];
            end

            %% Load all annotations 
            if strcmp(options.face_motion_vids{video}, 'The_Present')

                Predicted_Classes = cell(length(frames), 1);
                BBox_coordinates = cell(length(frames), 1);
                bbox = table(Predicted_Classes, BBox_coordinates);

                for f = 1:length(frames)

                    annot_data = jsondecode(fileread(sprintf('%s/present_all_frames_edited/%s', ...
                        options.face_annot_dir, annotation(f).name)));

                    if iscell(annot_data.shapes)
                        idx_face = find(cellfun(@(C) contains(C, 'Face', 'IgnoreCase', true), ...
                            cellfun(@(C) C.label, annot_data.shapes, 'UniformOutput', false)));
                    else
                        idx_face = find(cellfun(@(C) contains(C, 'Face', 'IgnoreCase', true), {annot_data.shapes.label}));
                    end

                    if isempty(idx_face)
                        continue
                    end

                    n_face(f) = length(idx_face);

                    % Create a class column
                    bbox.Predicted_Classes{f} = zeros(1, length(idx_face));

                    % Create a bounding box column
                    for i = 1:length(idx_face)

                        if iscell(annot_data.shapes)
                            bbox.BBox_coordinates{f}{i} = annot_data.shapes{idx_face(i)}.points;
                        else
                            bbox.BBox_coordinates{f}{i} = annot_data.shapes(idx_face(i)).points;
                        end

                    end

                end

                % Only one class exists for the present
                class_id = 0;
                n_duplicate = max(n_face);

                % Colors for bounding boxes 
                class_color = [1, 0, 0];
                color_table = table(class_id, class_color);

            else

                % Load the bounding box coordinates
                bbox = readtable(sprintf('%s/%s_labelled_frames_corrected.csv', ...
                    options.face_annot_dir, options.face_motion_vids{video}));

                % Sort the frames
                idx_frame = cellfun(@(C) str2double(C(regexp(C, '\d'))), bbox.Image_Name);
                [~, idx_sort] = sort(idx_frame);

                bbox = bbox(idx_sort, :);

                % Find number of classes and create color table
                all_classes = cellfun(@(K) cellfun(@(C) str2double(C(regexp(C, '\d'))), strsplit(K, ' ')), ...
                    bbox.Predicted_Classes, 'UniformOutput', false);
                class_id = [0:max(cellfun(@(C) max(C), all_classes))]';

                % Maximum number of duplicate faces from one class
                n_duplicate = max(cellfun(@(K) length(K), cellfun(@(C) find_duplicate(C), all_classes, 'UniformOutput', false))) + 1;

                %% Colors for bounding boxes 
                cbar = othercolor('Accent8');
                class_color = cbar(round(linspace(1, length(cbar), length(class_id))), :);

                color_table = table(class_id, class_color);

            end

            if exist(sprintf('%s/%s_face_centroid.mat', out_dir, options.face_motion_vids{video}), 'file') == 0

                % Create a video file to check data
                if options.face_motion_vid
                    vid_out = VideoWriter(sprintf('%s/face_centroid_%s', out_dir, options.face_motion_vids{video}));
                    vid_out.FrameRate = frame_rate;
                    open(vid_out)
                end

                % Initialize face centroid array
                face_centroid = cell(n_duplicate, length(class_id));

                % Extra colums for duplicates from the same class
                for c = 1:length(class_id)
                    for n = 1:n_duplicate
                        face_centroid{n, c} = nan(length(frames), 2);
                    end
                end

                class_duplicate = cell(length(frames),1);
                duplicate = false(length(frames),1);

                %% Loop over the frames and extract the centroid of the bounding boxes
                for f = 1:length(frames)

                    fprintf('Frame %i/%i ... \n', f, length(frames))

                    if strcmp(options.face_motion_vids{video}, 'The_Present')
                        frame = imread(sprintf('%s/present_all_frames_edited/%s', options.face_annot_dir, frames(f).name));
                    else
                        frame = imread(sprintf('%s/%s/%s', options.frame_dir, options.face_motion_vids{video}, frames(f).name));
                    end

                    % Load the classes for annotations of the current frame
                    if strcmp(options.face_motion_vids{video}, 'The_Present')
                        classes = bbox.Predicted_Classes{f};
                    else
                        classes = strsplit(bbox.Predicted_Classes{f}, ' ');
                        classes = cellfun(@(C) str2double(C(regexp(C, '\d'))), classes);
                        classes(isnan(classes)) = [];
                    end

                    % Load the string of bounding boxes
                    if strcmp(options.face_motion_vids{video}, 'The_Present')
                        bounding_boxes = bbox.BBox_coordinates{f};
                    else
                        bounding_boxes = strsplit(bbox.BBox_coordinates{f}, '\n');
                    end

                    % Delete labels of statues (create artefacts and are not salient)
                    if strcmp(options.face_motion_vids{video}, 'Despicable_Me_Hungarian')
                        bounding_boxes(ismember(classes, 2)) = [];
                        classes(ismember(classes, 2)) = [];
                    end

                    % No bounding box
                    if length(bounding_boxes) <= 1  
                        
                        if isempty(bounding_boxes)
                            if options.face_motion_vid, writeVideo(vid_out, frame), end
                            continue
                        end
                        
                        if ~strcmp(options.face_motion_vids{video}, 'The_Present')
                            if strcmp(bounding_boxes{1}, '[]') 
                                if options.face_motion_vid, writeVideo(vid_out, frame), end
                                continue
                            end
                        end
                        
                    end

                    % Catch frames with a missmatch of class labels and bounding boxes
                    if length(classes) < length(bounding_boxes)
                        error('frame %i: Coordinates without matching class label\n', f)
                        bounding_boxes =  bounding_boxes(1:length(classes));
                    end

                    % If there are duplicate entries in classes create a new class 
                    % Occurs when there are several characters with a single label (e.g. two minions)
                    if length(unique(classes)) < length(classes)

                        idx_duplicate = find_duplicate(classes);

                        class_duplicate{f} = unique(classes(idx_duplicate));

                        % Multiply the class id of duplicate entries to distingish them; 
                        % add length of the face_centroid array so they don't overlap with others
                        for c = 1:length(class_duplicate{f})
                            idx_class = find(ismember(classes, class_duplicate{f}(c)));
                            for i = 2:length(idx_class)
                                classes(idx_class(i)) = i*(classes(idx_class(i)) + 2*length(face_centroid));
                            end
                        end

                        duplicate(f) = true;

                    end

                    %% Extract the centroids of each face
                    bb_coord = cell(length(bounding_boxes),1);

                    for b = 1:length(bounding_boxes)

                        if strcmp(options.face_motion_vids{video}, 'The_Present')

                            % Find the centroid
                            if classes(b) > length(face_centroid)

                                % Duplicate annoatations are stored in rows -> find the correct row and class 
                                [class_id_original, idx_row] = decode_class_label(classes(b), n_duplicate, face_centroid);

                                [x,y] = centroid(polyshape(bounding_boxes{b}(:,1), bounding_boxes{b}(:,2)));
                                face_centroid{idx_row, class_id_original+1}(f,:) = [x,y];

                            else 
                                [x,y] = centroid(polyshape(bounding_boxes{b}(:,1), bounding_boxes{b}(:,2)));
                                face_centroid{1, classes(b)+1}(f,:) = [x,y];
                            end

                        else

                            % Convert string to double
                            bb_part = strsplit(bounding_boxes{b}, ' ');
                            bb_coord{b} = cellfun(@(C) str2double(strrep(strrep(C, '[', ''), ']', '')), bb_part);
                            bb_coord{b}(isnan(bb_coord{b})) = [];

                            % Continue if empty
                            if isempty(bb_coord{b})
                                if options.face_motion_vid, writeVideo(vid_out, frame), end
                                continue
                            end

                            if b > 1 && sum(bb_coord{b} - bb_coord{b-1}) == 0
                                if options.face_motion_vid, writeVideo(vid_out, frame), end
                                warning('frame %i: Duplicate annotation\n', f)
                                continue
                            end

                            % Height of the bounding box
                            h = bb_coord{b}(4) - bb_coord{b}(2);

                            % Somtimes the order of y coordinates in the annotations are inverted and have to be switched
                            if h < 0
                                warning('frame %i: y coordinates switched\n', f)
                                bb_coord{b}([2,4]) = bb_coord{b}([4,2]);
                                h = bb_coord{b}(4) - bb_coord{b}(2);
                            end

                            % Find the centroid
                            if classes(b) > length(face_centroid)

                                % Duplicate annoatations are stored in rows -> find the correct row and class 
                                [class_id_original, idx_row] = decode_class_label(classes(b), n_duplicate, face_centroid);

                                face_centroid{idx_row, class_id_original+1}(f,1) = ...
                                    bb_coord{b}(1) + ((bb_coord{b}(3) - bb_coord{b}(1))/2);
                                face_centroid{idx_row, class_id_original+1}(f,2) = ...
                                    bb_coord{b}(2) + ((bb_coord{b}(4) - bb_coord{b}(2))/2);
                            else 
                                face_centroid{1, classes(b)+1}(f,1) = bb_coord{b}(1) + ((bb_coord{b}(3) - bb_coord{b}(1))/2);
                                face_centroid{1, classes(b)+1}(f,2) = bb_coord{b}(2) + ((bb_coord{b}(4) - bb_coord{b}(2))/2);
                            end

                        end

                    end

                    % Sort the order of duplicate annotations
                    if duplicate(f)
                        for c = 1:length(class_duplicate{f})
                            face_centroid = sort_annotations(face_centroid, n_duplicate, class_duplicate{f}(c), f);  
                        end
                    end

                    if f > 1
                        if duplicate(f-1) 
                            if sum(ismember(classes, class_duplicate{f-1})) ~= 0
                                for c = 1:length(class_duplicate{f-1})
                                    face_centroid = sort_annotations(face_centroid, n_duplicate, class_duplicate{f-1}(c), f);
                                end
                            end
                        end
                    end

                    %% Create an image with the face centroid on each frame
                    if options.show_face_motion_frames || options.face_motion_vid

                        frame_marker = frame;

                        for p = 1:length(classes)

                            if classes(p) > length(face_centroid)
                                [class_idx, row_idx] = decode_class_label(classes(p), n_duplicate, face_centroid);
                            else
                                class_idx = classes(p);
                                row_idx = 1;
                            end

                            c_cur = face_centroid{row_idx,class_idx+1}(f,:);

                            if f > 1
                                c_pre = face_centroid{row_idx,class_idx+1}(f-1,:);
                            else
                                c_pre = nan(1,2);
                            end

                            col_marker = 255*color_table.class_color(ismember(color_table.class_id, class_idx), :);

                            if sum(isnan(c_cur)) == 0
                                frame_marker = insertMarker(frame_marker, [c_cur(1), c_cur(2)], 'o', 'Size', 5, 'Color', col_marker); 
                            end   

                            if sum(isnan(c_cur)) == 0 && sum(isnan(c_pre)) == 0
                                frame_marker = insertShape(frame_marker, 'Line', ...
                                    [c_pre(1), c_pre(2), c_cur(1), c_cur(2)], 'Color', col_marker);
                            end

                        end

                    end

                    % Plot the frame
                    if options.show_face_motion_frames
                        clf
                        imagesc(frame_marker)
                        title(frames(f).name)
                        xticks([])
                        yticks([])
                        pause
                    end

                    % Add to video
                    if options.face_motion_vid
                        writeVideo(vid_out, frame_marker) 
                    end

                end

                % Close the video file
                if options.face_motion_vid
                    close(vid_out)
                end

                % Save the data
                save(sprintf('%s/%s_face_centroid.mat', out_dir, options.face_motion_vids{video}), 'face_centroid', 'frame_rate')

            else
                load(sprintf('%s/%s_face_centroid.mat', out_dir, options.face_motion_vids{video}), 'face_centroid', 'frame_rate')
            end

            % Reorganize array
            face_centroid(cellfun(@(C) sum(nansum(C)) == 0, face_centroid)) = [];

            %% Plot the face centroid for each character over time
            if options.visualize_face_motion      
                figure
                hold on
                for i = 1:length(face_centroid)
                    plot(face_centroid{i})
                end 
            end

            %% Compute velocity
            v_class = zeros(length(face_centroid{1})-1, length(face_centroid));
            
            for i = 1:length(face_centroid)
                v_class(:,i) = sqrt(sum(((face_centroid{i}(2:end,:) - face_centroid{i}(1:end-1,:))/T).^2, 2));
            end

            v = nansum(v_class, 2);

            if options.visualize_face_motion    
                figure
                hold on
                plot(v)
            end

            %% Load the scene cuts
            if strcmp(options.face_motion_vids{video}, 'The_Present')
                load(sprintf('%s/Data/present_cmi/cuts_present_cmi.mat', options.w_dir), 'cuts')
            else
                scene_table = xlsread(sprintf('%s/%s_scenes.xlsx', options.scene_annot_dir, options.face_motion_vids{video}));
                cuts = scene_table(:,1);        
            end

            % Correct the offset in the cuts
            cuts = cuts - 1;
            if strcmp(options.face_motion_vids{video}, 'Despicable_Me_English'), cuts = sort([cuts; 4961]); end

            % Interpolate at scene cuts
            idx_no_cut = setdiff(1:length(v), cuts);
            v(cuts) = interp1(idx_no_cut, v(idx_no_cut), cuts);

            if options.visualize_face_motion    
                plot(v)
            end
            
            % Add an offset for the first frame
            v = [0; v];

            % Smooth with a gaussian window
            alpha = (options.L_face-1)/(2*options.sigma_face*frame_rate);

            h = gausswin(options.L_face, alpha);
            h = h/sum(h);

            v = conv(v, h, 'same');

            if options.visualize_face_motion  

                plot(v, 'k')

                xlabel('Frame')
                ylabel('Face motion velocity')
                legend({'Motion with Cuts', 'Motion (Cuts corrected)', 'Filtered signal'})
                set(gca, 'FontSize', 16)
                grid on, grid minor

            end

            if options.visualize_face_motion    
                figure
                plot((1:options.L_face)/frame_rate, h)
                grid on 
            end

            %% Resample The Present to match the NorthShore stimulus
            if strcmp(options.face_motion_vids{video}, 'The_Present')

                % Load the temporal contrast of the NorthShore version
                load(sprintf('%s/Data/temporal_contrast.mat', options.w_dir), 'contrast_vid', 'vid_names')
                idx_vid = cellfun(@(C) contains(C, 'The_Present'), vid_names);

                contrast_ns = contrast_vid{idx_vid};

                % Align the two verions of the present
                align_present_cmi_ns(options)

                % Load the resampling factor and offset for alignment
                load(sprintf('%s/Organize/align_ns_cmi_present.mat', options.w_dir), 'resampling_ratio', 'offset')

                v = resample(v, 1e3, 1e3*resampling_ratio);

                v = [zeros(offset, 1); v];
                v = [v; zeros(length(contrast_ns)-length(v), 1)];

                % Check if resampling makes sense
                if options.visualize_face_motion   

                    % Load the temporal contrast of the CMI version
                    contr_file = sprintf('%s/Data/present_cmi/temp_contr_the_present_cmi.mat', options.w_dir);
                    load(contr_file, 'contrast')

                    contrast_cmi = contrast;

                    contrast_cmi = resample(contrast_cmi, 1e3, 1e3*resampling_ratio);

                    contrast_cmi = [zeros(offset, 1); contrast_cmi];
                    contrast_cmi = [contrast_cmi; zeros(length(contrast_ns)-length(contrast_cmi), 1)];

                    figure
                    hold on

                    plot(contrast_ns)
                    plot(contrast_cmi)

                end

            end

            %% Save the face velocity
            if strcmp(options.face_motion_vids{video}, 'The_Present')
                frame_rate = frame_rate/resampling_ratio;
            end

            save(sprintf('%s/%s_face_velocity.mat', out_dir, options.face_motion_vids{video}), 'v', 'frame_rate')

        else
            load(sprintf('%s/%s_face_velocity.mat', out_dir, options.face_motion_vids{video}), 'v')
        end
        
        %% Align the motion vector to the patient data using eyetracking time stamps
        for pat = 1:length(options.patients)
            
            vel_pat_dir = sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.face_vel_dir);
            if exist(vel_pat_dir, 'dir') == 0, mkdir(vel_pat_dir), end
            
            % Find all eyetracking files for this video
            eye_files = dir(sprintf('%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir));
            eye_files([eye_files.isdir]) = [];
            eye_files = eye_files(cellfun(@(C) contains(C, options.face_motion_vids{video}), {eye_files.name}));
            
            for file = 1:length(eye_files)
            
                % Filename
                vel_pat_file = sprintf('%s/%s', vel_pat_dir, eye_files(file).name);
                if exist(vel_pat_file, 'file') ~= 0, continue, end
                
                % Load the eyetracking data
                load(sprintf('%s/%s/%s/%s', options.data_dir, options.patients(pat).name, options.eye_dir, eye_files(file).name), ...
                    'eye')
        
                % The timing of two frames sometimes overlaps and has to be corrected
                if length(unique(eye.frame_time)) ~= length(eye.frame_time)
                    idx_same = find(diff(eye.frame_time) == 0);
                    eye.frame_time(idx_same) = eye.frame_time(idx_same) - 1e-10;
                end
            
                % Interpolate the velocity vector
                face_velocity = interp1(eye.frame_time, v(1:length(eye.frame_time)), eye.time);

                % Save the data                
                save(vel_pat_file, 'face_velocity')

                clearvars face_velocity
            
            end
            
        end
        
    end
    
end