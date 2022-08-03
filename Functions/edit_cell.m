% Edit a cell array as a string in a cell of lines from a file 

function lines = edit_cell(lines, cell_data, var_name)

    cell_str = '{';
    for i = 1:length(cell_data)
        if i ~= length(cell_data)
            cell_str = sprintf('%s''%s'', ', cell_str, cell_data{i});
        else
            cell_str = sprintf('%s''%s''}', cell_str, cell_data{i});
        end
    end
    
    idx_line = cellfun(@(C) contains(C, sprintf('%s = ', var_name)), lines);
    idx_command = regexp(lines{idx_line}, ';');
    lines{idx_line}(1:idx_command-1) = [];
    lines{idx_line} = [sprintf('options.%s = %s', var_name, cell_str), lines{idx_line}];
    
end