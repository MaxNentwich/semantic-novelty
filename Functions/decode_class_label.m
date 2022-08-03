
function [class_id_original, idx_row] = decode_class_label(class_id, n_duplicate, face_centroid)

    class_original = nan(1, n_duplicate);

    for m = 1:n_duplicate

        class_original(m) = class_id/(m+1) - 2*length(face_centroid);

        if class_original(m) < 0
            break
        end

    end
    
    class_id_original = class_original(m-1);
    idx_row = m;

end