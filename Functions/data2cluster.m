
function data2cluster(options, local_dir)

    data_files = dir(sprintf('%s', local_dir));
    data_files([data_files.isdir]) = []; 

    for f = 1:length(data_files)

        local_file = sprintf('%s/%s', local_dir, data_files(f).name);

        remote_file = strrep(local_file, options.data_dir, options.cluster_data);    
        if exist(remote_file, 'file') ~= 0, continue, end

        remote_dir = strrep(remote_file, data_files(f).name, '');
        if exist(remote_dir, 'dir') == 0, mkdir(remote_dir), end

        fprintf('Copying %s to remote directory ... \n', local_file)
        system(sprintf('cp %s %s', local_file, remote_file));

    end

end