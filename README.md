# Semantic novelty modulates neural responses to visual change across the human brain
Code to reproduce results in https://www.biorxiv.org/content/10.1101/2022.06.20.496467v1.full

Associated data to reproduce figures and statistics is available at: https://osf.io/n6vpc/

Analysis and figures can be reproduced by running [main_ieeg_itrf](main_ieeg_itrf.m).

Set `options.local_dir` to the path containing all scripts.

Set `options.drive_dir` to the path containing the data. 

## Settings for different parts of the analysis
Analysis can be computed for different features of the videos and subsets of videos. For analysis described in the manuscript the following options were used: 

Figure 2: 
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'optical_flow', 'scenes', 'saccades'};                      
options.stim_select = {'optical_flow', 'scenes', 'saccades'};                       
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
```

Figure 3: 
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
```

Figure 4: 
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'saccades_high_novelty', 'saccades_low_novelty', 'scenes', 'optical_flow'}; 
options.stim_select = {'saccades_high_novelty', 'saccades_low_novelty'};          
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
```

Figure 5: 
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'saccades_faces', 'saccades_matched', 'scenes'}; 
options.stim_select = {'saccades_faces', 'saccades_matched'};   
options.vid_names = {'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
```

Comparison in Figure S9:

Panel A (same as Figure 3):
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
```

Panel B:
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades', 'optical_flow'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Monkey', 'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
```

Comparison in Figure S10:

Panel A:
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Monkey'};
```

Panel B:
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'high_scenes', 'low_scenes', 'saccades'};   
options.stim_select = {'high_scenes', 'low_scenes'};                
options.vid_names = {'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
```

Figure S19:
```
options.band_select = {'BHA'};                                               
options.stim_labels = {'optical_flow', 'face_motion', 'saccades', 'scenes'}; 
options.stim_select = {'optical_flow', 'face_motion'};
options.vid_names = {'Despicable_Me_English', 'Despicable_Me_Hungarian', 'The_Present_Rep_1', 'The_Present_Rep_2'};
```

## Setting up computation on a server
A server can be set up to perform computation (about 128GB of memory are necessary). The script is set up to mount the server on a local 
folder, copy necessary scripts and run analysis. Connection is established with SSH. Use `options.run_local = false` to compute on a server.
The [main_ieeg_itrf](Remote_computation/main_ieeg_itrf.m) script in the 'Remote_computation' folder needs to be copied onto the server or the mounted local folder. 

Scripts for remote computation have been tested on Linux only. 

`options.cluster = 'user@xxx.xx.xx.xxx` is the username and IP adress to adress to the server. 
`options.remote_home` defines the home directory on the server. Data and scripts will be copied there. 
`options.parallel_workers` sets the number of cores used as workers for parallel processing. 
`options.use_compute_node` uses a compute node on the server that is accessed with SSH from the master node. This option is specific to our 
setup and will likely need to be set `false`. 
`options.run_local = true` runs analysis on the local machine. 


## External packages used 
Relevant scripts from external packages are included in 'External'. The full packages are available at:

- SDK to open data from Tucker-Davis Technolobies electrophysiology acquisition system. Download [here](https://www.tdt.com/docs/sdk/offline-data-analysis/offline-data-matlab/getting-started/) (accessed 08/04/2022) 

- Chebfun for image compression. Download [here](https://www.chebfun.org/download/) (accessed 08/04/2022) 

- iELVis for electrode visualization Download [here](http://ielvis.pbworks.com/w/page/117734730/Installing%20iELVis) (accessed 08/04/2022) 

- Package for violinplots. Download [here](https://github.com/bastibe/Violinplot-Matlab) (accessed 08/04/2022) 

- Computational Brain Imaging Group (CBIG) repository for clustering. Download [here](https://github.com/ThomasYeoLab/CBIG) (accessed 08/04/2022)

- Skillings-Mack test, a nonparametric Two-way ANOVA with unbalanced observations. Download [here](https://github.com/thomaspingel/mackskill-matlab) (accessed 09/28/2022)

The system identification is based on the mTRF Toolbox. Download [here](https://github.com/mickcrosse/mTRF-Toolbox) (accessed 08/04/2022) 