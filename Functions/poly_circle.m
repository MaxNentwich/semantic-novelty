function P = poly_circle(center_coords, radius, varargin)
    
    if length(varargin) == 1
        n = varargin{1};
    else
        n = 100;
    end

    theta = (0:n-1)*(2*pi/n);
    
    x = center_coords(1) + radius*cos(theta);
    y = center_coords(2) + radius*sin(theta);
    
    P = polyshape(x,y)';

end