    
function [contrast, fr] = compute_temporal_contrast(video_file)

    vid = VideoReader(video_file);
    
    fr = vid.FrameRate;

    n_frames = vid.NumFrames;
    contrast = nan(n_frames, 1);

    for n_fr = 1:n_frames

        if n_fr == 1
            frame_pre = zeros(vid.Height, vid.Width);
        else
            frame_pre = frame_cur;
        end

        frame_cur = double(rgb2gray(readFrame(vid)));

        contrast(n_fr) = mean2((frame_cur - frame_pre).^2);

    end
    
end