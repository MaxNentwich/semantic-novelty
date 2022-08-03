
function saccade_svm(options)

    % The size of the frames from the video used for annotation and theexperiment is not the same
    match_present_frames(options)
    
    % Setup a dataset for training and label the saccades manually
    setup_saccade_dataset(options)
    
    % Train the SVM
    train_saccade_svm(options)
    
    % Visualize the classification on data from another patient
    saccade_class_sample(options)

end