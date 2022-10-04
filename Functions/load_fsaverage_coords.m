function [avg_coords, is_left, elec_names, elec_val] = load_fsaverage_coords(labels, labels_val)

    % Load the fsaverage coordinates
    load('movie_subs_table.mat', 'movie_subs_table')

    is_left = [];
    avg_coords = [];
    elec_names = {};
    elec_val = [];

    for l = 1:length(labels)

        labels_contacts = strsplit(labels{l}, '-');

        for c = 1:length(labels_contacts)

            label_parts = strsplit(labels_contacts{c}, '_');

            if length(label_parts) == 3
                patient = [label_parts{1}, '_' , label_parts{2}];
                electrode = label_parts{3};
            else
                patient = label_parts{1};
                electrode = label_parts{2};
            end
            
            if strcmp(patient, 'NS134') && contains(electrode, 'RIa')
                electrode = strrep(electrode, 'RIa', 'Ria');
            elseif strcmp(patient, 'NS134') && contains(electrode, 'RFl')
                electrode = strrep(electrode, 'RFl', 'RFL');
            elseif strcmp(patient, 'NS138') && contains(electrode, 'LIa')
                electrode = strrep(electrode, 'LIa', 'Lia');
            elseif strcmp(patient, 'NS144_02') && contains(electrode, 'RGrid')
                electrode = strrep(electrode, 'RGrid', 'LGrid');
            elseif strcmp(patient, 'NS148_02') && contains(electrode, 'RGrid')
                electrode = strrep(electrode, 'RGrid', 'RGridHD');
            end

            idx_sub = cellfun(@(C) strcmp(C, patient), movie_subs_table.SubID) & ...
                cellfun(@(C) strcmp(C, electrode), movie_subs_table.Contact);
            
            if sum(idx_sub) == 0
                warning('Electrode %s %s not found!', patient, electrode)
                continue
            end
            
            if ismember([patient, '_', electrode], elec_names)
                continue
            end

            is_left = [is_left; cellfun(@(C) strcmp(C, 'L'), movie_subs_table.Hem(idx_sub))];
            avg_coords = [avg_coords; movie_subs_table.FSAverage(idx_sub, :)];
            elec_names = [elec_names; [patient, '_', electrode]];
            elec_val = [elec_val; labels_val(l)];
            
        end

    end

end