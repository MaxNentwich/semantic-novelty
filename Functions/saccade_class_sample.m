%% Classify saccades to faces on a sample patient

function saccade_class_sample(options)
    
    % Image output directory
    image_dir = sprintf('%s/sample_data/images_%s_%s', options.saccade_class, options.video_saccades_test, options.patient_saccade_test);  
    
    if exist(image_dir, 'dir') == 0
        
        % Find the first repetition of the movie
        eye_files = dir(sprintf('%s/%s/%s', options.data_dir, options.patient_saccade_test, options.eye_dir));
        eye_files = eye_files(cellfun(@(C) contains(C, options.video_saccades_test), {eye_files.name}));
        eye_files = eye_files(1);
     
        % Load the SVM model
        svm_model_file = sprintf('%s/svm_model.mat', options.saccade_class);
        load(svm_model_file, 'svm_model')

        extract_saccade_features(options, options.video_saccades_test, options.patient_saccade_test, eye_files.name, ...
            image_dir, 1, svm_model);

    end
    
end
