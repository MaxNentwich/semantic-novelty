    
function [patch_coord, pad_size] = patch_size(pos, r, frame)

    if pos(2)-r < 1 
        patch_coord(1) = 1;
        pad_size(1) = abs(pos(2)-r) + 1;
    else
        patch_coord(1) = pos(2)-r;
        pad_size(1) = 0;
    end

    if pos(2)+r > size(frame,1)
        patch_coord(2) = size(frame,1);
        pad_size(2) = pos(2)+r - size(frame,1);
    else
        patch_coord(2) = pos(2)+r;
        pad_size(2) = 0;
    end

    if pos(1)-r < 1
        patch_coord(3) = 1;
        pad_size(3) = abs(pos(1)-r) + 1;
    else
        patch_coord(3) = pos(1)-r;
        pad_size(3) = 0;
    end

    if pos(1)+r > size(frame,2)
        patch_coord(4) = size(frame,2);
        pad_size(4) = pos(1)+r - size(frame,2);
    else
        patch_coord(4) = pos(1)+r;
        pad_size(4) = 0;
    end

end