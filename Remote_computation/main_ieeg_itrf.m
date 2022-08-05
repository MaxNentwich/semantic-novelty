%% Main script to run TRF analysis 

%% Set flags for visualization 
options.visualize_trfs = false;                                                 % Plot stimuli for trf analysis 

%% Number of workers in parallel pool
options.parallel_workers = 20;
options.run_local = false;                                                      % Always false if running on cluster

%% Options for TRF analysis
options.band_select = {'BHA'};                                         % Frequency band {'raw', 'Theta', 'Alpha', 'Beta', 'BHA'}
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades', 'optical_flow'};                             % Stimuli in the model {'optical_flow', 'scenes', 'saccades', 'high_scenes', 'low_scenes'}
options.stim_select = {'high_scenes', 'low_scenes'};                                             % Stimuli to shuffle (selection of those in the model) 
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};                        % Videos {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'}  

options.compute_trf = true;                                                    % Compute the TRF
options.compute_stats = false;                                                   % Compute the cluster statistics
options.compute_chance = false;                                                 % Compute chance level

%% Directories 
options.cluster_dir = '/state/partition1/home/max';                                 % Path to home directory on cluster

% options.code_dir = options.local_dir;                                             % Code Directory
options.im_data_dir = sprintf('%s/edison_itrf/Data', options.cluster_dir);          % Data from intermediary analysis steps
options.w_dir = sprintf('%s/edison_itrf', options.cluster_dir);                     % Working Directory
options.data_dir = sprintf('%s/edison/Patients', options.cluster_dir);              % Data directory
options.flow_dir = sprintf('%s/edison/Optic_flow', options.cluster_dir);            % Optical flow
options.scene_annot_dir = sprintf('%s/edison/Annotation', options.cluster_dir);     % Scene annotations
options.raw_dir = 'matlab_data/raw';                                                % Raw signal
options.eye_dir = 'matlab_data/Eyetracking';                                        % Eytracking data 
options.env_dir = 'matlab_data/Envelope_phase';                                     % Envelope and phase
options.contr_dir = 'Stimuli/contr_max';                                            % Temporal contrast at eye tracking sampling rate
options.face_vel_dir = 'Stimuli/face_velocity';                                     % Face motion velocity
options.trf_dir = 'Analysis/TRF_events';                                            % Output of TRF analysis
options.stats_data = sprintf('%s/edison/Data/stats', options.cluster_dir);          % Cluster stats
options.saccade_class = sprintf('%s/Data/saccade_classification', options.w_dir);   % Classification of saccades
options.frame_dir = sprintf('%s/edison/video_frames', options.cluster_dir);         % Individual video frames 
options.face_annot_dir = sprintf('%s/edison/Face_Annotation', options.cluster_dir); % Face annotations
options.vid_dir = sprintf('%s/edison/video_files', options.cluster_dir);            % Video files
options.saccade_label_dir = sprintf('%s/Data/ssl_dataset', options.w_dir);          % Saccade novelty by contrastive learning
options.cut_dir = sprintf('%s/Data/scene_cuts_frames', options.w_dir);              % Corrected scene cut files
options.cluster_chance = sprintf('%s/Data/cluster_chance', options.w_dir);          % Chance level for significant channels in cluster stats

options.local_dropbox = 'Dropbox (City College)';                                   % Format inside matlab
options.bash_dropbox = 'Dropbox\ \(City\ College\)';                                % Format for bash commands 

% Add some necessary paths
addpath(options.w_dir)                                                              % Working directory 
addpath(genpath(sprintf('%s/Functions', options.w_dir)))                            % Functions
addpath(genpath(sprintf('%s/Organize', options.w_dir)))                             % Tables and variables for organization
addpath(genpath(sprintf('%s/edison/Data', options.cluster_dir)))                    % Stats data

%% List of patients
options.patients = dir(options.data_dir);
options.patients(1:2) = [];

% Select only Tobii/TDT data 
options.patients = options.patients(cellfun(@(C) contains(C, 'NS'), {options.patients.name}));

% Exclude subject NS141 (no movie data recorded)
options.patients = options.patients(cellfun(@(C) ~contains(C, 'NS141'), {options.patients.name}));

%% Definition of frequency bands
options.freq_bands = [4, 7; 8, 14; 15, 30; 70, 150];                            % Band limits in Hz
options.band_names = {'Theta', 'Alpha', 'Beta', 'BHA'};                         % Names
options.lambda_bands = [0.50000, 0.50000, 0.40000, 0.30000];                                    % Regression coefficients for each band      
options.lambda_raw = 0.01;                                                      % Regression coefficient for raw data       

%% Triggers in eyetracking data
options.trigger_IDs.start_ID = 11;
options.trigger_IDs.end_ID_1 = 12;
options.trigger_IDs.end_ID_2 = 13;

%% Time window for TRF analysis in seconds
options.trf_window = [-0.50000, 3];

%% Saccade detection
options.vel_th = 2.00;                             % Threshold for saccade detection (standard deviations)
options.peri_saccade_window = [0.03300, 0.12000];    % Window around saccades used to detect amplitude and speed, in seconds
options.min_diff = 0.11;                        % Minimum distance required between saccades (in seconds)
options.t_after = 1.00;                            % Time after cuts to look for saccades (in seconds)
options.t_before = 0.50;                         % Time before cuts to look for saccades (in seconds)
options.t_around = 1.00;                           % Time window around cuts to exclude from 'other' saccades
options.saccade_selection = 'first_last';       % include 'all' or the first and last ('first_last') saccade before and after cuts

%% Classification of saccades in saccades to faces and not to faces
options.video_saccades_class = 'Despicable_Me_English';     % Video used to train a classifier for saccade types
options.patient_saccade_class = 'NS127_02';                 % Patient used for training data
    
options.video_saccades_test = 'The_Present';                % Video used to train a classifier for saccade types
options.patient_saccade_test = 'NS151';                     % Patient used for training data

options.screen_size = [1920, 1080];                         % Screen size of the Tobii eyetracker [px]
options.screen_dimension = [509.2 286.4];                   % Screen size of the Tobii eyetracker [mm]
options.destrect_ext = [192, 108, 1728, 972];               % [x1, y1, x2, y2]; [x1,y1] top left, and [x2,y2] bottom right corner of the video inside a black border
options.alpha_fovea = 5;                                    % Size of the foveal visual field in DVA

options.scale_threshold = 1.0;                                % Threshold for scale to reject uncertain predictions
options.p_amplitude_similarity = 0.50;                       % Minimum p-value for kstest of saccade amplitude for face and matched saccades

%% Sampling rate at which the analysis is performed
% all signals will be resampled to this
% 10 Hz is a special case that works best with brians annotations
% Other sampling rates are first upsampled to 300 Hz. At this sampling rate
% the annotations are matched to contrast and then downsampled again
% Neural data is availabe already downsampled at different sampling rates 
% for example at 60 Hz for BHA
options.fs_ana = 60.00;

%% Statistics and training 
options.n_shuff = 2;               % Number of shuffles for stats
options.n_jack = 2;                 % Number of folds for training

options.compute_r = false;          % Compute the correlation between the predicted and original signal
options.retrain_filter = false;     % Retrain the filter when computing r

% Features that require circular shuffling
options.features_circular_shuffle = {'optical_flow', 'face_motion'}; 

% Threshold for using sparse matrices 
options.sparsity_th = 0.98500;

%% Cluster correction
options.smoothing_L = 20;           % Length of the Gaussian filter used for smoothing
options.smooting_alpha = 3.00;         % Alpha to determine width of the Gaussian filter for smoothing

options.size_prctile = 0.00100;      % Threshold for timepoints that could make up clusters  
options.stats_estimate = false;     % Estimate the distributions for low numbers of permutations

% --------------------------------------------------------------------------------------------------------------------------------
%% Analysis 

%% Start the parallel pool
pp = parpool(options.parallel_workers);

%% Compute the TRFs
if options.compute_trf
    compute_TRF(options)
end

%% Run the cluster correction
if options.compute_stats
    cluster_stats(options)
end

%% Compute chance level
if options.compute_chance
    cluster_chance_level(options)
    determine_chance_level(options)
end

%% Close the parallel pool
delete(pp);

%% Exit matlab 
exit
