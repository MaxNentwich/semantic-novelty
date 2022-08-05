% Main script to run TRF analysis 

%% Which level of analysis should be performed
options.process_raw_data = false;                                               % Preprocessing of raw data
options.process_trfs = false;                                                   % Compute the temporal response functions including surrogate data for statistics
options.process_stats = false;                                                  % Compute statistics
options.process_plots = true;                                                   % Plot the figures

%% Set flags for visualization and videos with eye movements or annotations
options.visualize_preproc = false;                                              % Plot spectrograms and sample channels 
options.visualize_motion = false;                                               % Plot flow vectors on each frame
options.visualize_trfs = false;                                                 % Plot stimuli for trf analysis 
options.visualize_boundaries = false;                                           % Plot the event boundary data
options.face_motion_vid = true;                                                 % Create a video with face motion annotations and motion
options.show_face_motion_frames = false;                                        % Show face motion annotations for each frame
options.visualize_face_motion = false;                                          % Plot the vector of face motions including corrections

%% Run the TRF locally or on a server 
options.run_local = true;
options.parallel_workers = 20;                                                  % Select how many cores to use on cluster

%% Options for TRF analysis
options.band_select = {'BHA'};                                                      % Frequency band {'raw', 'Theta', 'Alpha', 'Beta', 'BHA'}
options.stim_labels = {'optical_flow', 'scenes', 'saccades'};                       % Stimuli in the model {'optical_flow', 'face_motion', 'saccades', 'saccades_faces', 'saccades_matched', 'saccades_high_novelty', 'saccades_low_novelty', 'scenes', 'high_scenes', 'low_scenes'}
options.stim_select = {'optical_flow', 'scenes', 'saccades'};                       % Stimuli to shuffle (selection of those in the model) 
                
options.vid_names = {'Monkey', 'Despicable_Me_English', ...                         % Videos {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'}
    'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};    

%% Directories 
options.local_dir = '/home/max/Documents/Dropbox (City College)';                       % Path to local drive
options.drive_dir = '/media/max/9C52B2EB52B2C972/ieeg_plot';                            % Path to raw data on hard drive
options.cluster_mnt = '/home/max/edison_mnt';                                           % Local mountpoint of cluster
options.remote_home = '/state/partition1/home/max';                                     % User directory on cluster
options.cluster = 'max@134.74.28.223';                                                  % User and IP of cluster
options.use_compute_node = true;                                                        % To run on cluster compute node
options.compute_node_id = 0;                                                            % cluster compute node

options.im_data_dir = sprintf('%s/Data', options.drive_dir);                            % Data from intermediary analysis steps
options.fs_dir = sprintf('%s/Tobii/FullAnatomy', options.drive_dir);                    % Freesurfer data
options.code_dir = sprintf('%s/Code', options.local_dir);                               % Code Directory
options.w_dir = sprintf('%s/semantic_novelty', options.code_dir);                       % Working Directory
options.data_dir = sprintf('%s/Tobii/Patients', options.drive_dir);                     % Data directory
options.flow_dir = sprintf('%s/Tobii/Optic_flow', options.drive_dir);                   % Optical flow
options.online_dir = sprintf('%s/Online_experiment/Data', options.drive_dir);           % Online experiment results
options.annot_dir = sprintf('%s/Annotation_CMI', options.drive_dir);                    % CMI annotations 
options.scene_annot_dir = sprintf('%s/Tobii/Annotation', options.drive_dir);            % Scene annotations
options.brian_dir = sprintf('%s/Tobii/Brians_features', options.drive_dir);             % Annotaions for monkey movies
options.face_annot_dir = sprintf('%s/Tobii/Face_Annotation', options.drive_dir);        % Face annotations
options.mem_dir = sprintf('%s/Tobii/memory_task', options.drive_dir);                   % Memory task
options.vid_dir = sprintf('%s/Tobii/video_files', options.drive_dir);                   % Video files
options.speech_dir = sprintf('%s/Tobii/speech_files', options.drive_dir);               % Speech files
options.frame_dir = sprintf('%s/Tobii/video_frames', options.drive_dir);                % Individual video frames 
options.raw_dir = 'matlab_data/raw';                                                    % Raw signal
options.eye_dir = 'matlab_data/Eyetracking';                                            % Eytracking data 
options.neural_dir = 'matlab_data/Neural';                                              % Neural data in matlab format
options.neural_prep_dir = 'matlab_data/Neural_prep';                                    % Preprocessed neural data 
options.env_dir = 'matlab_data/Envelope_phase';                                         % Envelope and phase
options.contr_dir = 'Stimuli/contr_max';                                                % Temporal contrast at eye tracking sampling rate
options.face_vel_dir = 'Stimuli/face_velocity';                                         % Face velocity at eye tracking sampling rate
options.sacc_dir = 'Stimuli/saccades';                                                  % Saccade and Fixation onset matched to video frames
options.trf_dir = 'Analysis/TRF_events';                                                % Output of TRF analysis
options.fig_dir = sprintf('%s/Figures', options.drive_dir);                             % Figures 
options.cluster_data = sprintf('%s/edison/Patients', options.cluster_mnt);              % Data on cluster
options.stats_data = sprintf('%s/stats', options.im_data_dir);                          % Cluster stats
options.saccade_class = sprintf('%s/saccade_classification', options.im_data_dir);      % Classification of saccades
options.saccade_label_dir = sprintf('%s/ssl_dataset', options.drive_dir);               % Saccade novelty by contrastive learning
options.cut_dir = sprintf('%s/Tobii/scene_cuts_frames', options.drive_dir);             % Corrected scene cut files
options.face_novelty = sprintf('%s/faces_vs_novelty', options.im_data_dir);             % Overlap of saccades to faces and saccade novelty

options.local_dropbox = 'Dropbox (City College)';                               % Format inside matlab
options.bash_dropbox = 'Dropbox\ \(City\ College\)';                            % Format for bash commands 

global globalFsDir                                                              % Freesurfer directory for plotting
globalFsDir = options.fs_dir;

% Add some necessary paths
addpath(genpath(sprintf('%s/Main_steps', options.w_dir)))                           % Functions for main steps in the workflow
addpath(genpath(sprintf('%s/Functions', options.w_dir)))                            % Functions
addpath(genpath(sprintf('%s/Data', options.drive_dir)))                             % Data not related to patients
addpath(genpath(sprintf('%s/Organize', options.drive_dir)))                         % Tables and variables for organization
addpath(genpath(sprintf('%s/External', options.w_dir)))                             % External packages

if exist(options.im_data_dir, 'dir') == 0, mkdir(options.im_data_dir), end
if exist(options.fig_dir, 'dir') == 0, mkdir(options.fig_dir), end

%% List of patients
options.patients = dir(options.data_dir);
options.patients(1:2) = [];

%% Task (Movies, Freeviewing, Fixation, RhythmicSaccade) 
options.task = 'Movies';

%% Threshold for finding peaks in temporal contrasts (percentile)
options.th_contr_peak = 99;

%% Definition of frequency bands
options.freq_bands = [4,7; 8,14; 15,30; 70,150];                                % Band limits in Hz
options.band_names = {'Theta', 'Alpha', 'Beta', 'BHA'};                         % Names
options.lambda_bands = [0.5, 0.5, 0.4, 0.3];                                    % Regression coefficients for each band      
options.lambda_raw = 0.01;                                                      % Regression coefficient for raw data       
options.dsf = 5;                                                                % Downsampling factor for all frequency bands

%% Triggers in eyetracking data
options.trigger_IDs.start_ID = 11;
options.trigger_IDs.end_ID_1 = 12;
options.trigger_IDs.end_ID_2 = 13;

%% Time window for TRF analysis in seconds
options.trf_window = [-0.5, 3];

%% Saccade detection
options.vel_th = 2;                             % Threshold for saccade detection (standard deviations)
options.peri_saccade_window = [0.033, 0.12];    % Window around saccades used to detect amplitude and speed, in seconds
options.min_diff = 0.11;                        % Minimum distance required between saccades (in seconds)
options.t_after = 1;                            % Time after cuts to look for saccades (in seconds)
options.t_before = 0.5;                         % Time before cuts to look for saccades (in seconds)
options.t_around = 1;                           % Time window around cuts to exclude from 'other' saccades
options.saccade_selection = 'first_last';       % include 'all' or the first and last ('first_last') saccade before and after cuts

%% Face motion extraction 
options.face_motion_vids = {'The_Present', ...              % Videos with face motion annotations
    'Despicable_Me_English', 'Despicable_Me_Hungarian'};     
options.sigma_face = 0.1;                                   % Standard deviations of Gaussian filter for smooting 
options.L_face = 100;                                       % Lenght in samples for Gaussian filter
    
%% Classification of saccades in saccades to faces and not to faces
options.video_saccades_class = 'Despicable_Me_English';     % Video used to train a classifier for saccade types
options.patient_saccade_class = 'NS127_02';                 % Patient used for training data
    
options.video_saccades_test = 'The_Present';                % Video used to train a classifier for saccade types
options.patient_saccade_test = 'NS151';                     % Patient used for training data

options.screen_size = [1920, 1080];                         % Screen size of the Tobii eyetracker [px]
options.screen_dimension = [509.2 286.4];                   % Screen size of the Tobii eyetracker [mm]
options.destrect_ext = [192, 108, 1728, 972];               % [x1, y1, x2, y2]; [x1,y1] top left, and [x2,y2] bottom right corner of the video inside a black border
options.alpha_fovea = 5;                                    % Size of the foveal visual field in DVA

options.scale_threshold = 1;                                % Threshold for scale to reject uncertain predictions
options.p_amplitude_similarity = 0.5;                       % Minimum p-value for kstest of saccade amplitude for face and matched saccades

% Directorie of frames to be copied to cluster
options.remote_frames = {'Despicable_Me_English', 'Despicable_Me_Hungarian'}; 

%% Sampling rate at which the analysis is performed
% all signals will be resampled to this
% 10 Hz is a special case that works best with brians annotations
% Other sampling rates are first upsampled to 300 Hz. At this sampling rate
% the annotations are matched to contrast and then downsampled again
% Neural data is availabe already downsampled at different sampling rates 
% for example at 60 Hz for BHA
options.fs_ana = 60;

%% Statistics and training 
options.n_shuff = 1e4;              % Number of shuffles for stats
options.n_jack = 2;                 % Number of folds for training

options.compute_r = false;          % Compute the correlation between the predicted and original signal
options.retrain_filter = false;     % Retrain the filter when computing r

% Features that require circular shuffling
options.features_circular_shuffle = {'optical_flow', 'face_motion'}; 

% Threshold for using sparse matrices 
options.sparsity_th = 0.985;

%% Event boundary data
options.event_window = 0.5;         % Window for scenes in the range of event boundaries (seconds)
options.event_bin = 20;             % Bin size for Gaussian filter

%% Cluster correction
options.smoothing_L = 20;           % Length of the Gaussian filter used for smoothing
options.smooting_alpha = 3;         % Alpha to determine width of the Gaussian filter for smoothing (8 for saccades)

options.size_prctile = 0.001;       % Threshold cluster size
options.stats_estimate = false;     % Estimate the distributions for low numbers of permutations

%% Self supervised learning 
options.ssl_videos = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
options.ssl_image_plot = false;
options.ssl_patch_size = [50, 50];
options.min_fr_dist = 10;

%% Settings for figure of all electrodes
options.fig_all_elecs.out_dir = options.fig_dir;
options.fig_all_elecs.file_name = 'all_electrodes';
options.fig_all_elecs.view = 'omni';
options.fig_all_elecs.opaqueness = 0.4;
options.fig_all_elecs.elec_size = 3;
options.fig_all_elecs.elec_units = '';

%% Settings for figure comparing motion, saccades and scenes
options.stim_fig_2 = {'optical_flow', 'scenes', 'saccades'};

options.n_cluster = 3;                          % Number of clusters for filters to find saccadic spikes

options.color_flow = [1 0 0];                   % Colors for each stimulus
options.color_scenes = [0 1 0];
options.color_saccades = [0 0 1];

options.inlude_unknown = false;                 % Channels with unkown anatomical label are included in plots

options.fig_features.out_dir = sprintf('%s/feature_comparison', options.fig_dir);
options.fig_features.file_name = 'spatial_feature_comparison';
options.fig_features.view = 'omni';
options.fig_features.opaqueness = 0.4;
options.fig_features.elec_size = 8;
options.fig_features.elec_units = '';

% Set how to localize electrodes
% 2 ... both electrodes have to be labeled in a specific area (conservative, some filters will not be plotted)
% 1 ... one electrodes only can be in the ROI (liberal, some filters will be plotted more than once)
options.loc_confidence = 2;

%% Options for figures comparing scene cuts
options.regions_order = {'Occipital', 'Parietal', 'Temporal', 'MTL', 'Frontal', 'Insula'};

% Color for regions
options.region_color = [1 0.898 0; 1, 0.3294, 0; 1 0 0.8039; 1 0 0.8039; 0.3176, 0.0784, 0.9098; 0, 1, 0.5647];
options.region_alpha = 0.3;
            
options.stim_fig.start_sample = 10;         % Start of stimulus data sample in seconds
options.stim_fig.time_sample = 60;          % Time of stimulus data sample in seconds

options.stim_fig.sac_cuts = [-0.5, 1.5];    % Time window around cuts to plot saccade probability
options.stim_fig.mot_cuts = [-3, 3];    % Time window around cuts to plot motion
options.stim_fig.mot_sac = [-2, 2];    % Time window around saccades to plot motion

%% Settings for figure comparing event and continuous cuts
options.stim_fig_3 = {'high_scenes', 'low_scenes','saccades'};
options.stim_fig_S7 = {'high_scenes', 'low_scenes', 'saccades', 'optical_flow'}; 

options.vid_fig_3 = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

options.vid_fig_S8A = {'Monkey'};
options.vid_fig_S8B = {'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

%% Settings for figure comparin saccades with high and low novelty
options.stim_fig_4 =  {'saccades_high_novelty', 'saccades_low_novelty', 'scenes', 'optical_flow'};

%% Settings for figure comparing saccades to faces and matched saccades
options.stim_fig_5 = {'saccades_faces', 'saccades_matched', 'scenes'};

%% Settings for figure comparing optical flow and face motion
options.stim_fig_6 = {'optical_flow', 'face_motion', 'saccades', 'scenes'}; 

% --------------------------------------------------------------------------------------------------------------------------------
%% Analysis 

if options.process_raw_data
    
    %% A table with experiment notes, containing the order of movies, is sometimes created manually, otherwise has to be created
    match_et_iEEG(options)

    %% Check the label files 
    check_label_files(options)

    %% Load the neural and eyetracking data from original format, align and save as .mat files 
    load_data(options)

    %% Check if the labels make sense
    label_check(options)

    %% Manual bad channel rejection
    bad_channel_rejection(options)

    %% Preprocess the iEEG data
    preprocess_ieeg(options)

    %% Extract the data in different frequency bands
    extract_bandpower_phase(options)

    %% Compute the temporal contrast and align to each patient
    extract_temporal_contrast(options)

    %% Compute visual motion (optical flow)
    extract_optical_flow(options)

    %% Compute face motion
    extract_face_motion(options)

    %% Save saccade data
    save_saccade_data(options)

    %% Split scene cuts based on salience using data from online experiment
    load_event_boundary_annotations(options)

    %% Train a SVM to classify saccades to faces 
    saccade_svm(options)

    %% Setup data for defining novelty in saccades through self supervised learning
    setup_ssl_dataset(options)

    %% Overlap of saccades to faces and saccade novelty
    face_vs_novelty_saccades(options)

end

%% Compute the TRFs 
if options.process_trfs 
    
    if options.run_local
        compute_TRF(options)
    else
        compute_TRF_cluster(options)
    end

end

%% Run the cluster correction
if options.process_stats
    
    if options.run_local    
        cluster_stats(options)
    else
        cluster_stats_cluster(options)
    end
    
end

%% Plot all figures
if options.process_plots
    
    %% Time between saccade and fixation onset
    saccade_duration(options)
    
    %% Compare the timining of saccades after scene cuts (Figure S12)
    saccade_novelty_frequency(options)
    
    %% Figure of the position of all electrodes (Figure 1A)
    plot_all_electrodes(options)

    %% Figure of stimuli and their relationship (Figures 1C-F)
    plot_stimuli(options)

    %% Figure of the TRF method (Figure S3A)
    plot_trf_method(options, 'one_paper')

    %% Figure of event boundary annotation (Figure S5)
    plot_event_boundary_annotations(options)

    %% Plot the comparison of motion, saccades, and scenes (Figure 2, Figure 3A, Figure4A, Figure 5A, Figure S4, Figure S18)
    if sum(ismember(options.stim_labels, options.stim_fig_2)) == length(options.stim_fig_2) ...
            && length(options.stim_labels) == length(options.stim_fig_2)

        options.atlas = 'lobes';                                                                % Figure 2, Figure S18
        plot_motion_saccades_cuts(options)                                                 
        
        options.atlas = 'AparcAseg_Atlas';                                                      % Figure S4C
        plot_motion_saccades_cuts(options)
        
        estimate_filter_amplitude(options, 'scenes', 'Event - Continuous', 0.1)                 % Figure 3A
        estimate_filter_amplitude(options, 'saccades_novelty', 'High - Low Novelty', 0.03)      % Figure 4A
        estimate_filter_amplitude(options, 'saccades_faces', 'Faces - Non-Faces', 0.05)         % Figure 5A

    end

    %% Plot comparison of event and continuous cuts (Figure 3C&D, Figure S7, Figure S9)
    if sum(ismember(options.stim_labels, options.stim_fig_3)) == length(options.stim_fig_3) ...
            && length(options.stim_labels) == length(options.stim_fig_3)

        % Check which movies are selected
        if sum(ismember(options.vid_names, options.vid_fig_3)) == length(options.vid_fig_3) ...
            && length(options.vid_names) == length(options.vid_fig_3)

            options.atlas = 'lobes';                                                                % Figure 3C&D, Figure S7A, Figure S9
            plot_events_cuts(options, 'event_continuous_cuts', 1)

            options.atlas = 'AparcAseg_Atlas';                                                      % Figure S10
            plot_events_cuts(options, 'event_continuous_cuts', 0)
            
        elseif sum(ismember(options.vid_names, options.vid_fig_S8A)) == length(options.vid_fig_S8A) ...
            && length(options.vid_names) == length(options.vid_fig_S8A)
        
            options.atlas = 'lobes';                                                                % Figure S8A
            plot_events_cuts(options, 'event_continuous_cuts_monkey', 0)
            
        elseif sum(ismember(options.vid_names, options.vid_fig_S8B)) == length(options.vid_fig_S8B) ...
            && length(options.vid_names) == length(options.vid_fig_S8B)

            options.atlas = 'lobes';                                                                % Figure S8B
            plot_events_cuts(options, 'event_continuous_cuts_comics', 0)
            
        end
        
    end
    
    % Saccades and motion as regressors
    if sum(ismember(options.stim_labels, options.stim_fig_S7)) == length(options.stim_fig_S7) ...
            && length(options.stim_labels) == length(options.stim_fig_S7)

        options.atlas = 'lobes';                                                                    % Figure S7B
        plot_events_cuts(options, 'event_continuous_cuts_saccades_motion', 0)
        
    end
    
    %% Plot the comparison of saccades with high and low novelty (Figure 4C&D, Figure S13, Figure S14)
    if sum(ismember(options.stim_labels, options.stim_fig_4)) == length(options.stim_fig_4) ...
            && length(options.stim_labels) == length(options.stim_fig_4)

        options.atlas = 'lobes';                                                                    % Figure 4C&D, Figure S13
        plot_saccades_novelty(options)
        
        options.atlas = 'AparcAseg_Atlas';                                                          % Figure S14
        plot_saccades_novelty(options)

    end

    %% Plot the comparison of saccades to faces and matched saccades (Figure 5C&D, Figure S16)
    if sum(ismember(options.stim_labels, options.stim_fig_5)) == length(options.stim_fig_5) ...
            && length(options.stim_labels) == length(options.stim_fig_5)

        options.atlas = 'lobes';                                                                    % Figure 5C&D
        plot_saccades_faces(options)
        
        options.atlas = 'AparcAseg_Atlas';                                                          % Figure S16
        plot_saccades_faces(options)

    end

    %% Plot the comparison of average optical flow and face motion (Figure 6B&C, Figure S17)
    if sum(ismember(options.stim_labels, options.stim_fig_6)) == length(options.stim_fig_6) ...
            && length(options.stim_labels) == length(options.stim_fig_6)

        options.atlas = 'lobes';                                                                    % Figure 6B&C
        plot_flow_face_motion(options)
        
        options.atlas = 'AparcAseg_Atlas';                                                          % Figure S17
        plot_flow_face_motion(options)

    end
    
end