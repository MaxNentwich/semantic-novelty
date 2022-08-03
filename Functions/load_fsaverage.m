
function [avg_coords, elec_names, is_left, lobe] = load_fsaverage(sub_name)

    load('movie_subs_table.mat', 'movie_subs_table')
    
    idx_sub = cellfun(@(C) strcmp(C, sub_name), movie_subs_table.SubID);
    fprintf('%i electrodes found \n', sum(idx_sub))
    
    is_left = cellfun(@(C) strcmp(C, 'L'), movie_subs_table.Hem(idx_sub));
    
    elec_names = movie_subs_table.Contact(idx_sub);
    
    avg_coords = movie_subs_table.FSAverage(idx_sub, :);
    
    % Get the location 
    lobe = movie_subs_table.DK_Lobe(idx_sub, :);
    aparc_aseg = movie_subs_table.AparcAseg_Atlas(idx_sub, :);
    
    idx_mtl = cellfun(@(C) contains(C, {'Amygdala', 'Hippocampus', 'entorhinal', 'parahippocampal'}), aparc_aseg) ~= 0;
    aparc_aseg(~idx_mtl) = repmat({'Unknown'}, sum(~idx_mtl), 1);

    lobe(~cellfun(@(C) contains(C, 'Unknown', 'IgnoreCase', true), aparc_aseg)) = {'MTL'};
    
end