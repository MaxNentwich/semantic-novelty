%% Estimate optical from in the videos 

function extract_optical_flow(options)

% Visualize the flow
options.visualize_motion = false;

% Read a list of the video files
vid_files = dir(options.vid_dir);
vid_files([vid_files.isdir]) = [];

% Loop over all videos
for v = 1:length(vid_files)

    [~, vid_file_name] = fileparts(vid_files(v).name);
    out_file = sprintf('%s/%s.mat', options.flow_dir, vid_file_name);
    
    if exist(out_file, 'file') ~= 0
        continue
    end
    
    % Specify the optical flow estimation method and its properties
    opticFlow = opticalFlowHS;

    % Load the video
    vid = VideoReader(sprintf('%s/%s', options.vid_dir, vid_files(v).name));
    
    % Initialize flow variable
    optic_flow = zeros(1, vid.NumFrames);
    
    % Initialize plot
    if options.visualize_motion
        h = figure;
        movegui(h);
        hViewPanel = uipanel(h,'Position',[0 0 1 1],'Title','Plot of Optical Flow Vectors');
        hPlot = axes(hViewPanel);
    end
    
    % Loop over all frames 
    n_fr = 0;
    
    while hasFrame(vid)
        
        % Count the frame
        n_fr = n_fr + 1;
        
        % Read the frame 
        frame = im2gray(readFrame(vid));
        
        % Estimate optical flow
        flow = estimateFlow(opticFlow, frame);
        
        optic_flow(n_fr) = mean2(flow.Magnitude);
        
        % Plot the flow on the frame
        if options.visualize_motion
            
            idx_x = 1:6:size(flow.Vx,1);
            idx_y = 1:6:size(flow.Vx,2);
            [X_mesh, Y_mesh] = meshgrid(idx_y, idx_x);
            
            imshow(frame)
            hold on    
            quiver(X_mesh, Y_mesh, flow.Vx(idx_x, idx_y).*flow.Magnitude(idx_x, idx_y), ...
                flow.Vy(idx_x, idx_y).*flow.Magnitude(idx_x, idx_y), 30, 'r', 'LineWidth', 3)
                        title(sprintf('mean flow = %1.2f', optic_flow(n_fr)))
            hold off
            pause(10^-3)
        end
        
    end
    
    %% Correct artifacts
    num_frames = 1:length(optic_flow); 
    
    if contains(vid_files(v).name, 'Monkey')
        
        [~, idx_art] = findpeaks(-optic_flow);
        
        optic_flow(idx_art) = interp1(setdiff(num_frames, idx_art), optic_flow(setdiff(num_frames, idx_art)), idx_art);
        
        [~, idx_art] = findpeaks(-optic_flow, 'MinPeakDistance', 10);
        
        idx_flat = (optic_flow(idx_art+2) - optic_flow(idx_art)) < 1e-5;
        
        idx_art = sort(unique([idx_art(idx_flat), idx_art(idx_flat)+1, idx_art(idx_flat)+2, ...
            idx_art(~idx_flat), idx_art(~idx_flat)-1, idx_art(~idx_flat)+1]));
        
        optic_flow(idx_art) = interp1(setdiff(num_frames, idx_art), optic_flow(setdiff(num_frames, idx_art)), idx_art);
        
        % Correct scene cuts
        [~, idx_peak] = findpeaks(optic_flow, 'MinPeakProminence', 1e-3, 'MaxPeakWidth', 4, 'MinPeakDistance', 15);
        
        idx_peak = sort([idx_peak, idx_peak-1, idx_peak-2, idx_peak-3, idx_peak+1, idx_peak+2, idx_peak+3]);

        optic_flow(idx_peak) = interp1(setdiff(num_frames, idx_peak), optic_flow(setdiff(num_frames, idx_peak)), idx_peak);
        
    elseif contains(vid_files(v).name, {'Despicable', 'Present'})
        
        [~, idx_art] = findpeaks(-optic_flow, 'MinPeakDistance', 3);

        optic_flow(idx_art) = interp1(setdiff(num_frames, idx_art), optic_flow(setdiff(num_frames, idx_art)), idx_art);

        % Correct scene cuts
        [~, idx_peak] = findpeaks(optic_flow, 'MinPeakProminence', 1e-3, 'MaxPeakWidth', 4, 'MinPeakDistance', 15);
        idx_peak = sort([idx_peak, idx_peak-1, idx_peak+1]);

        optic_flow(idx_peak) = interp1(setdiff(num_frames, idx_peak), optic_flow(setdiff(num_frames, idx_peak)), idx_peak);
    
    end
    
    % Remove the first value which is the onset
    optic_flow(1) = 0;
    
    %% Save the flow vector
    fr = vid.FrameRate;
    
    if exist(options.flow_dir, 'dir') == 0, mkdir(options.flow_dir), end  
    save(out_file, 'optic_flow', 'fr')
    
end

end