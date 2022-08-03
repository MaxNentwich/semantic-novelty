
function [normal_distance, intersection] = normal_2d(x1, x2, p)
    
    if size(x1,2) > size(x1,1), x1 = x1'; end
    if size(x2,2) > size(x2,1), x2 = x2'; end
    if size(p,2) > size(p,1), p = p'; end
       
    % Find the vector defining the line
    v = x2 - x1;
    v = v / norm(v);
    
    % Find the normal vector 
    n = [-v(2); v(1)];
    n = n / norm(n);
     
    % Find the parameters for the lines through x1 and x2;  as well as the line defined by the vector n and p (s)
    A = [v, -n];
    b = p - x1;
    
    % Solve the system of equations
    params = A\b;
    
    % Parameters to get to the intersection on the normal vector
    s = params(2);
    
    % Compute the point where the normal vector through p intersects the line through x1 and x2
    intersection = p + s*n;
    intersection_2 = x1 + params(1)*v;
    
    % The normal vector is normalized and therefor s corresponds to the nomral distance
    normal_distance = s;
    
end