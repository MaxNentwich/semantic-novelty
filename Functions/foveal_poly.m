
function foveal_rect = foveal_poly(pos, r)

    x1 = pos(1) - r;
    x2 = pos(1) + r;
    y1 = pos(2) - r;
    y2 = pos(2) + r;

    foveal_rect = polyshape([x1, x1, x2, x2], [y2, y1, y1, y2]); 
    
end