# semantic-novelty
Code to reproduce results in https://www.biorxiv.org/content/10.1101/2022.06.20.496467v1.full

Analysis and figures can be reproduced with main_ieeg_itrf.m.

The following packages are required:

SDK to open data from Tucker-Davis Technolobies electrophysiology acquisition system: 
https://www.tdt.com/docs/sdk/offline-data-analysis/offline-data-matlab/getting-started/

Chebfun for image compression
https://www.chebfun.org/download/

iELVis for electrode visualization
http://ielvis.pbworks.com/w/page/117734730/Installing%20iELVis

Package for violinplots
https://github.com/bastibe/Violinplot-Matlab

Computational Brain Imaging Group (CBIG) repository for clustering 
https://github.com/ThomasYeoLab/CBIG

A server can be set up to perform computation (about 128GB of memory are necessary). The script is set up to mount the server on a local 
folder, copy necessary scripts and run analysis. Connection is established with SSH. Use 'options.run_local = false' to compute on a server.
The 'main_ieeg_itrf.m' script in the 'Remote_computation' folder needs to be copied onto the server or the mounted local folder. Scripts for
remote computation have been tested on Linux only. 
'options.cluster = 'user@xxx.xx.xx.xxx' is the username and IP adress to adress to the server. 'options.remote_home' defined the home directory
on the server. Data and scripts will be copied there. 
'options.parallel_workers' sets the number of cores used as workers for parallel processing. 
'options.use_compute_node' uses a compute node on the server that is accessed with SSH from the master node. This option is specific to our 
setup and will likely need to be set 'false'. 
'options.run_local = true' runs analysis on the local machine. 

Analysis can be computed for different features of the videos and subsets of videos. For analysis described in the manuscript the following options were used: 

Figure 2: 
options.band_select = {'BHA'};                                               
options.stim_labels = {'optical_flow', 'scenes', 'saccades'};                      
options.stim_select = {'optical_flow', 'scenes', 'saccades'};                       
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

Figure 3: 
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

Figure 4: 
options.band_select = {'BHA'};                                               
options.stim_labels = {'saccades_high_novelty', 'saccades_low_novelty', 'scenes', 'optical_flow'}; 
options.stim_select = {'saccades_high_novelty', 'saccades_low_novelty'};          
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

Figure 5: 
options.band_select = {'BHA'};                                               
options.stim_labels = {'saccades_faces', 'saccades_matched', 'scenes'}; 
options.stim_select = {'saccades_faces', 'saccades_matched'};   
options.vid_names = {'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

Figure 6:
options.band_select = {'BHA'};                                               
options.stim_labels = {'optical_flow', 'face_motion', 'saccades', 'scenes'}; 
options.stim_select = {'optical_flow', 'face_motion'};
options.vid_names = {'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

Comparison in Figure S7:

Panel A (same as Figure 3):
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

Panel B:
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades', 'optical_flow'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};

Comparison in Figure S8:

Panel A:
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Monkey'};

Panel B:
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};


