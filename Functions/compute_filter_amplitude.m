
function [a, resp_win] = compute_filter_amplitude(options, labels_w_pat, labels_w, labels, scene_vec, w_scenes, envelope, visualize_trfs)
          
    % Get indices of scenes
    idx_scene = find(scene_vec);
    
    % Remove cuts too close to the edges
    idx_out = idx_scene + options.trf_window(1)*options.fs_ana < 1 ...
        | idx_scene + options.trf_window(2)*options.fs_ana > length(scene_vec);   
    idx_scene(idx_out) = [];
    
    % Initialize arrays
    resp_win = zeros(size(labels_w_pat,1), length(idx_scene), range(options.trf_window)*options.fs_ana + 1);
    a = zeros(size(labels_w_pat,1), length(idx_scene));
    
    for ch = 1:size(labels_w_pat,1)
        
        % Get the filter for the channel that has already been estimated
        idx_w = ismember(labels_w.patient_name, labels_w_pat.patient_name{ch}) ...
            & ismember(labels_w.channel_pair, labels_w_pat.channel_pair{ch});

        h_est = w_scenes(idx_w, :);

        % Get the response for the channel
        idx_env = ismember(labels, labels_w_pat.channel_pair{ch});
        response = envelope(:, idx_env);
        
        % Construct a matrix that adds filters to the poitions of the stimulus
        S_h = zeros(length(scene_vec), length(idx_scene));

        for i = 1:length(idx_scene)
            
            S_h(idx_scene(i)+options.trf_window(1)*options.fs_ana : idx_scene(i)+options.trf_window(2)*options.fs_ana, i) = h_est;
            
            % Also save the corresponding response
            resp_win(ch,i,:) = response(idx_scene(i)+options.trf_window(1)*options.fs_ana : ...
                idx_scene(i)+options.trf_window(2)*options.fs_ana);
                 
        end
        
        % Estimate the amplitude
        a(ch,:) = S_h\response;
        a(ch,:) = a(ch,:) / std(a(ch,:));
        
        %% Figures
        if visualize_trfs
            
            time = options.trf_window(1) : 1/options.fs_ana : options.trf_window(2);

            figure
            hold on

            plot(time, h_est, 'k', 'LineWidth', 2)
            plot([0 0], ylim, 'g')

            set(gca, 'FontSize', 22)

            xlim([options.trf_window(1), options.trf_window(2)])

            grid on
            grid minor

            xlabel('Time from Cut [s]')
            ylabel('a.u.')

            % All events
            plot_range = [min(min(squeeze(resp_win(ch,:,:)))), max(max(squeeze(resp_win(ch,:,:))))];

            for i = 1:length(idx_scene)

                figure('Position' , [500, 500, 600, 600])
                hold on

                plot(time, squeeze(resp_win(ch,i,:)), 'LineWidth', 2, 'Color', [0.7 0.7 0.7])
                plot(time, a(ch,i) * h_est, 'k', 'LineWidth', 2)
                plot([0 0], plot_range, 'g')

                set(gca, 'FontSize', 22)

                legend({'Neural Signal', 'TRF'}, 'Position', [0.7 0.05 0.2 0.1])

                xlim([options.trf_window(1), options.trf_window(2)])
                ylim(plot_range)

                grid on
                grid minor

                xlabel('Time from Cut [s]')
                ylabel('Normailzed Amplitude')

                title(sprintf('a = %1.2f', a(ch,i)))

                outer_pos = get(gca, 'OuterPosition');
                outer_pos(2) = 0.2;
                outer_pos(4) = 0.8;
                set(gca, 'OuterPosition', outer_pos)

            end
            
        end

    end
                    
end