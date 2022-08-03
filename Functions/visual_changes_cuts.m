
function [visual_changes, attr_names] = visual_changes_cuts(file_name, scenes_high, frame_dir, video_name, net, layer)

    if exist(file_name, 'file') == 0

        for n = 1:length(scenes_high)

            fprintf('Processing cut %i/%i ...\n', n, length(scenes_high))

            [visual_changes(:,n), attr_names] = visual_attribute_changes(...
                sprintf('%s/%s/frame%05d.jpg', frame_dir, video_name, scenes_high(n)-2), ...
                sprintf('%s/%s/frame%05d.jpg', frame_dir, video_name, scenes_high(n)+1), ...
                net, layer);

        end

        % Save the features
        save(file_name, 'visual_changes', 'attr_names')

    else   
        % Load the features
        load(file_name, 'visual_changes', 'attr_names') 
    end
    
end