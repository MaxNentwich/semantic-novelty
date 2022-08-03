% Edit a cell array as a string in a cell of lines from a file 

function lines = edit_mat(lines, mat_data, var_name)

    mat_str = '[';
    for i = 1:size(mat_data,1)
        if i ~= size(mat_data,1)
            for j = 1:size(mat_data,2)
                if j ~= size(mat_data,2)
                    if mod(mat_data(i,j),1) == 0
                        mat_str = sprintf('%s%i, ', mat_str, mat_data(i,j));
                    else
                        mat_str = sprintf('%s%1.5f, ', mat_str, mat_data(i,j));
                    end
                else
                    if mod(mat_data(i,j),1) == 0
                        mat_str = sprintf('%s%i; ', mat_str, mat_data(i,j));
                    else
                        mat_str = sprintf('%s%1.5f; ', mat_str, mat_data(i,j));
                    end
                end
            end
        else
            for j = 1:size(mat_data,2)
                if j ~= size(mat_data,2)
                    if mod(mat_data(i,j),1) == 0
                        mat_str = sprintf('%s%i, ', mat_str, mat_data(i,j));
                    else
                        mat_str = sprintf('%s%1.5f, ', mat_str, mat_data(i,j));
                    end
                else
                    if mod(mat_data(i,j),1) == 0
                        mat_str = sprintf('%s%i]', mat_str, mat_data(i,j));
                    else
                        mat_str = sprintf('%s%1.5f]', mat_str, mat_data(i,j));
                    end
                end
            end
        end
    end
    
    idx_line = cellfun(@(C) contains(C, sprintf('%s = ', var_name)), lines);
    idx_command = regexp(lines{idx_line}, '];');
    lines{idx_line}(1:idx_command) = [];
    lines{idx_line} = [sprintf('options.%s = %s', var_name, mat_str), lines{idx_line}];
    
end