function lines = edit_num(lines, value_str, var_name)
    
    if islogical(value_str)
        if value_str
            value_str = 'true';
        else
            value_str = 'false';
        end
    end
    
    idx_line = cellfun(@(C) contains(C, sprintf('%s = ', var_name)), lines);
    idx_command = regexp(lines{idx_line}, ';');
    lines{idx_line}(1:idx_command-1) = [];
    lines{idx_line} = [sprintf('options.%s = %s', var_name, value_str), lines{idx_line}];
    
end