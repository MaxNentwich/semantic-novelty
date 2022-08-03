%% Make a movie to test delay in responses response and movie time
% Whitle flashes

function create_response_time_test(options)

vid_file = sprintf('%s/Online_experiment/response_time_movie.avi', options.drive_dir);

if exist(strrep(vid_file, '.avi', '.mp4'), 'file') == 0

    vid = VideoWriter(vid_file);
    vid.FrameRate = 30;

    open(vid);

    % Time in seconds
    T = 60;

    % Number of frames
    n_frame = T*vid.FrameRate;

    % Create frames 
    frame_width = 720;
    frame_height = 480;

    black = zeros(frame_height, frame_width);

    % Frame with a white squere
    square_width = 100;
    white = zeros(frame_height, frame_width);
    white(frame_height/2-(square_width/2):frame_height/2+(square_width/2), ...
        frame_width/2-(square_width/2):frame_width/2+(square_width/2)) = 1;

    % Define the timepoints of flashes
    n_flash = 10;     % number
    len_flash = 0.2;  % seconds
    len_flash = len_flash*vid.FrameRate;

    rng(12);
    fr_flash = sort(randi(n_frame, 1, n_flash));

    % Save the frame position
    t_flash = fr_flash/vid.FrameRate';
    fr = vid.FrameRate;
    save(sprintf('%s/Data/response_time_vid.mat', options.w_dir), 't_flash', 'fr')

    % Extend for 3 frames 
    fr_flash = repmat(fr_flash, len_flash, 1) + [0:len_flash-1]';
    fr_flash = sort(fr_flash(:));

    vid_frames = zeros(1,n_frame);
    vid_frames(fr_flash) = 1;
    plot(vid_frames)

    for i = 1:n_frame

        if ismember(i, fr_flash)
            writeVideo(vid, white);
        else
            writeVideo(vid, black);
        end

    end

    close(vid);

    % Transcribe with ffmpeg
    vid_file_sys = strrep(vid_file, 'Dropbox (City College)', 'Dropbox\ \(City\ College\)');

    system(sprintf('ffmpeg -i %s -c:v libx264 -preset veryslow -crf 18 -tune animation -c:a libmp3lame %s', ...
        vid_file_sys, strrep(vid_file_sys, '.avi', '.mp4')));

    system(sprintf('rm %s', vid_file_sys));
    
end

end