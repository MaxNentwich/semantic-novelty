%% Use all features of face annotations in realtion to saccade position to classify saccades to faces saccades to other objects

function train_saccade_svm(options)

    svm_model_file = sprintf('%s/svm_model.mat', options.saccade_class);
    
    if exist(svm_model_file, 'file') == 0

        % Load the features
        feature_file = sprintf('%s/training_data/features_%s_%s.mat', ...
             options.saccade_class, options.patient_saccade_class , options.video_saccades_class);
        load(feature_file, 'features')

        % Load the ground truth
        ground_truth_file = sprintf('%s/training_data/ground_truth_%s_%s.mat', ...
            options.saccade_class, options.patient_saccade_class , options.video_saccades_class);
        load(ground_truth_file, 'user_class')

        % Remove nans (no face annotations on the frame)
        idx_nan = isnan(user_class);

        features(idx_nan, :) = [];
        user_class(idx_nan) = [];

        % Train the svm model
        svm_model = fitcsvm(...
            features, ...
            user_class, ...
            'KernelFunction', 'gaussian', ...
            'PolynomialOrder', [], ...
            'KernelScale', 2.2, ...
            'BoxConstraint', 1, ...
            'Standardize', true, ...
            'ClassNames', [0; 1]);

        % Perform cross-validation
        partitioned_model = crossval(svm_model, 'KFold', 10);

        % Compute validation accuracy
        validation_accuracy = 1 - kfoldLoss(partitioned_model, 'LossFun', 'ClassifError');

        fprintf('SVM cross-validation accuracy: %1.3f\n', validation_accuracy);

        % Save model
        save(svm_model_file, 'svm_model', 'validation_accuracy')
    
    end

end