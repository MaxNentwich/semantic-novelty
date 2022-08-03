%% Compute changes in visual attributes across scene cuts 

function [visual_changes, attribute_names] = visual_attribute_changes(frame_before, frame_after, ...
    net, layer)

    % Get the size of the input layer
    sz = net.Layers(1).InputSize;  

    % Load the frames before and after the scene cut
    fr_before = imread(frame_before);
    fr_after = imread(frame_after);
    
    % Convert to grayscale 
    fr_before_gr = double(rgb2gray(fr_before));
    fr_after_gr = double(rgb2gray(fr_after));
    
    % Convert to CIE 1976 L*a*b color space
    fr_before_lab = rgb2lab(fr_before);
    fr_after_lab = rgb2lab(fr_after);
    
    % Convert to the size of the input layer to AlexNet
    fr_before_net = imresize(fr_before, sz(1:2)); 
    fr_after_net = imresize(fr_after, sz(1:2));
    
    % Luminance difference 
    visual_changes(1) = mean(fr_after_gr(:)) - mean(fr_before_gr(:));
    
    % Contrast 
    visual_changes(2) = std(fr_after_gr(:)) - std(fr_before_gr(:));
    
    % Complexity
    visual_changes(3) = jpeg_compression(fr_after) - jpeg_compression(fr_before);
    
    % Entropy
    visual_changes(4) = image_entropy(fr_after_gr) - image_entropy(fr_before_gr);
    
    % Color differencs 
    visual_changes(5) = mean2(fr_after_lab(:,:,1)) - mean2(fr_before_lab(:,:,1));
    visual_changes(6) = mean2(fr_after_lab(:,:,2)) - mean2(fr_before_lab(:,:,2));
    visual_changes(7) = mean2(fr_after_lab(:,:,3)) - mean2(fr_before_lab(:,:,3));
    
    % Difference between AlexNet features from fc7
    visual_changes(8) = norm(activations(net,fr_after_net,layer,'OutputAs','rows')...
        - activations(net,fr_before_net,layer,'OutputAs','rows'));
    
    % Temporal contrast
    visual_changes(9) = mean2((fr_after_gr - fr_before_gr).^2);
    
    attribute_names = {'luminance', 'contrast', 'complexity', 'entropy', 'lab_l', 'lab_a', 'lab_b', ...
        'alexnet_fc7', 'temporal_contrast'};
    
end