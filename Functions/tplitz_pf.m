function [T, time] = tplitz_pf(X, k_past, k_future, fs)

    % Check size 
    if size(X,2) > size(X,1)
        X = X';
        warning('Transposing input vector')
    elseif size(X,1) > size(X,2)
    elseif size(X,1) == size(X,2)
        error('Scalar or square matrix entered')
    end
    
    k_past = round(k_past);
    k_future = round(k_future);
    
    % first column
    C = [X(k_future+1:end); zeros(k_future,1)];
    
    % first row
    R = [flip(X(1:k_future+1))', zeros(1, k_past)];

    T = toeplitz(C, R);

    % add zero-degree coefficient
%     T = [Xtmp, ones(size(Xtmp,1),1)];
    
    % time vector
    time = (-(k_future):k_past)/fs;
    
end