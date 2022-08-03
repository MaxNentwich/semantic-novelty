%% Train and test mTRF model with jackknifing 
% This function uses multiple stimuli at the same time 
% Edit in the shuffling of filters of opitcal flow; dicrete times of events
% cannot be permuted, circular shuffle is used instead

function [w, r, p, w_shuffle] = mTRF_filter_flow(stim_data, neural_data, vid_idx, r_param, n_jack, n_shuff, ...
    idx_stim, stim_select, stim_labels, sparsity_th, retrain_filter, compute_r)

    % Check if there are NaNs in data or stimulus
    assert(sum(isnan(stim_data(:))) == 0, 'NaNs in stimulus data!')
    assert(sum(isnan(neural_data(:))) == 0, 'NaNs in neural data!')
    assert(length(stim_data) == length(neural_data), 'Length of stimulus and neural data don''t match')
    
    % Compute correlation with the prediction 
    if compute_r

        % Define data segments
        n_vids = unique(vid_idx);
        idx_fold = zeros(n_jack, length(n_vids));

        for v = 1:length(n_vids)
            idx_vid_n = find(vid_idx == v);
            idx_seg = round(linspace(min(idx_vid_n)-1, max(idx_vid_n), n_jack+1));
            for n = 1:n_jack
                idx_fold(n, idx_seg(n)+1:idx_seg(n+1)) = 1;
            end
        end

        for n = 1:n_jack

            %% Train 
            fprintf('Training the filter ...\n')

            if n_jack == 2
                stim_train = stim_data(idx_fold(setdiff(1:n_jack, n), :) == 1, :);
                neural_train = neural_data(idx_fold(setdiff(1:n_jack, n), :) == 1, :);            
            else
                stim_train = stim_data(sum(idx_fold(setdiff(1:n_jack, n), :)) == 1, :);
                neural_train = neural_data(sum(idx_fold(setdiff(1:n_jack, n), :)) == 1, :);
            end

            w_fold(:,:,n) = mtrf_multi_train(stim_train, neural_train, r_param);            

            %% Test
            fprintf('Testing the filter ...\n')

            stim_test = stim_data(idx_fold(n,:) == 1, :);
            neural_test = neural_data(idx_fold(n,:) == 1, :);

            % For each stimulus separately
            for s = 1:length(stim_select)   

                idx_select = find(ismember(stim_labels, stim_select{s}));

                r(:,n,idx_select) = mtrf_multi_test(stim_test(:, idx_stim == idx_select), neural_test, ...
                    w_fold(idx_stim == idx_select,:,n));

                % Shuffle statistics       
                if retrain_filter
                    r_shuff(:,:,n,idx_select) = shuffle_retrain(stim_train, stim_test, neural_train, neural_test, ...
                        r_param, idx_stim == idx_select, n_shuff);
                else
                    r_shuff(:,:,n,idx_select) = shuffle_stats(stim_test(:, idx_stim == idx_select), neural_test, ...
                        w_fold(idx_stim == idx_select,:,n), n_shuff);
                end

            end  

        end

        %% Compute the p-values

        % Average 
        r = mean(r, 2);
        r_shuff = mean(r_shuff, 3);

        % Statistics are also computed for each features separately
        for s = 1:length(stim_select)   
            idx_select = find(ismember(stim_labels, stim_select{s}));
            p(:,idx_select) = mean(r_shuff(:,:,:,idx_select)' > r(:,:,idx_select),2);       
        end
        
    else
        r = [];
        p = [];
    end
    
    % Compute the TRF on all data
    w = mtrf_multi_train(stim_data, neural_data, r_param, false); 
    
    %% Shuffle the TRFs
    w_shuffle = zeros(size(w,1), size(w,2), n_shuff);
    
    idx_shuff = randi(length(stim_data), 1, n_shuff);

    parfor i = 1:n_shuff

        fprintf('Shuffling neural data %i/%i ...\n', i, n_shuff)

        neural_shuffle = [neural_data(idx_shuff(i)+1:end, :); neural_data(1:idx_shuff(i), :)];

        % Save a little bit of time if the matrix is really sparse by using a sparse matrix representaiton in matlab
        if sum(sum(stim_data == 0)) / numel(stim_data) > sparsity_th
            sparse_compute = true;
        else
            sparse_compute = false;
        end

        w_shuffle(:,:,i) = mtrf_multi_train(stim_data, neural_shuffle, r_param, sparse_compute); 

    end
    
    w_shuffle(~ismember(idx_stim, find(ismember(stim_labels, stim_select))), :, :) = 0;

end