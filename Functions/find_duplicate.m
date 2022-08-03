function idx_duplicate = find_duplicate(input) 
    [~, idx_unique] = unique(input);
    idx_duplicate = setdiff(1:length(input), idx_unique);    
end