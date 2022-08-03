
function face_centroid = sort_annotations(face_centroid, n_duplicate, class_duplicate, f)

    for d = 1:n_duplicate
        centroid_pre(d,:) = face_centroid{d,class_duplicate+1}(f-1,:); 
        centroid_cur(d,:) = face_centroid{d,class_duplicate+1}(f,:); 
    end

    idx_pre = find(~isnan(centroid_pre(:,1)));
    idx_cur = find(~isnan(centroid_cur(:,1)));

    if ~isempty(idx_pre)

        dist_mat = pdist2(centroid_pre(idx_pre,:), centroid_cur(idx_cur,:));

        % Increase of duplicate annotations from one on previous frame
        if length(idx_pre) == 1           
            idx_ref = idx_cur;            
            [~, idx_sort] = sort(dist_mat);
        else        
            idx_ref = idx_pre; 
            [~, idx_sort] = min(dist_mat);
        end
        
        % There may be errors if the frames cannot be matched
        if length(unique(idx_sort)) < length(idx_sort)
            [~, idx_sort] = sort(dist_mat(unique(idx_sort),:));
        end

        for i = 1:length(idx_sort)
            face_centroid{idx_ref(idx_sort(i)), class_duplicate+1}(f,:) = centroid_cur(idx_cur(i),:);
        end

        idx_empty = setdiff(1:max(idx_ref(idx_sort)), idx_ref(idx_sort));
        if ~isempty(idx_empty)
            for e = 1:length(idx_empty)
                face_centroid{idx_empty(e),class_duplicate+1}(f,:) = nan(1,2);
            end
        end

    end

end
            