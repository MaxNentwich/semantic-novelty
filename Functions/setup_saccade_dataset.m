%% Setup a dataset to train a classifier for saccades (to faces or not)
% Extracts features saves images for visualization, label ground truth

function setup_saccade_dataset(options)

    %% Extract features from the movie
    image_dir = sprintf('%s/training_data/images', options.saccade_class);    
    feature_file = sprintf('%s/training_data/features_%s_%s.mat', ...
        options.saccade_class, options.patient_saccade_class , options.video_saccades_class);
    
    % Find the first repetition of the movie
    eye_files = dir(sprintf('%s/%s/%s', options.data_dir, options.patient_saccade_class, options.eye_dir));
    eye_files = eye_files(cellfun(@(C) contains(C, options.video_saccades_class), {eye_files.name}));
    eye_files = eye_files(1);
    
    if exist(feature_file, 'file') == 0
        features = extract_saccade_features(options, options.video_saccades_class, options.patient_saccade_class, eye_files.name, ...
            image_dir, 1);
        save(feature_file, 'features')
    end

    %% Create ground truth labels
    ground_truth_file = sprintf('%s/training_data/ground_truth_%s_%s.mat', ...
        options.saccade_class, options.patient_saccade_class , options.video_saccades_class);
    
    if exist(ground_truth_file, 'file') == 0
        
        load(feature_file, 'features')

        images = dir(image_dir);
        images([images.isdir]) = [];

        user_class = nan(length(images), 1);

        for i = 1:length(images)

            close all

            if isnan(features(i,1)), continue, end

            img = imread(sprintf('%s/%s', image_dir, images(i).name));

            figure('Position', [2200,300,1000,700])
            imagesc(img)
            axis off

            title(sprintf('i = %i; %s', i, strrep(images(i).name, '_', ' ')))

            user_class(i) = input('Does this saccade go to a face? (yes=1/no=0)\n');

            save(ground_truth_file, 'user_class')
            
        end

    end

end
