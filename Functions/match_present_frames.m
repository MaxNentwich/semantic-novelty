%% Find the transformation for the size of the video frames from the CMI and NorthShore version of the present

function match_present_frames(options)

    % Define the file name
    out_file = sprintf('%s/present_cmi/frame_transformation.mat', options.im_data_dir);
    
    if exist(out_file, 'file') == 0

        % Create a array of all frames in the NorthShore version
        vid_ns = VideoReader(sprintf('/%s/The_Present.mp4', options.vid_dir));
        frames_ns = 1:vid_ns.NumFrames;

        % Load the resampling ratio and offset to match frames to CMI verison
        load(sprintf('%s/Organize/align_ns_cmi_present.mat', options.drive_dir), 'resampling_ratio', 'offset')

        % Frames in CMI version corresponding to frames in NorthShore version
        frames_ns = round((frames_ns - offset)*resampling_ratio);

        % Select a frame that is not black to find the border
        frame_select_ns = 314;
        frame_select_cmi = frames_ns(frame_select_ns);

        % Load the frames in both versions of the video
        img_ns = imread(sprintf('%s/The_Present/frame%05d.jpg', options.frame_dir, frame_select_ns));
        img_cmi = imread(sprintf('%s/present_all_frames_edited/present_%04d.jpg', options.face_annot_dir, frame_select_cmi));

        % Find the black border at the top and bottom
        [~, pix_border] = findpeaks(abs(diff(sum(img_ns(:,1),3) == 0)));

        % Remove the black border
        img_ns = img_ns(pix_border(1)+1:pix_border(2), :, :);

        % Find the scale for both dimensions
        img_ns = rgb2gray(img_ns);
        img_cmi = rgb2gray(img_cmi);

        scale = size(img_cmi) ./ size(img_ns);
        
        if scale(1) == scale(2)
            scale = scale(1);
        else
            error('Scale for x and y are different!')
        end

        % Rescale the frame of the NorthShore version
        img_ns = imresize(img_ns, scale);

        % Plot both frames to check
        figure
        imagesc(img_ns)
        colormap gray

        figure
        imagesc(img_cmi)
        colormap gray
        
        % Save the variables for transformation 
        save(out_file, 'pix_border', 'scale')
        
    end

end