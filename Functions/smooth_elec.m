function w_elec = smooth_elec(w, idx_elec, h, L)

    if sum(idx_elec) == 0
        w_elec = [];
    else
    
        if size(w,3) ~= 1

            w_elec = w(idx_elec, :, :);

            n = size(w_elec,2);

            w_elec = cat(2, fliplr(w_elec(:,1:L,:)), w_elec, fliplr(w_elec(:, end-L+1:end, :)));

            if sum(idx_elec) > 15
                for ch = 1:size(w_elec,1)
                    w_elec(ch,:,:) = filtfilt(h, 1, squeeze(w_elec(ch,:,:)));
                end
            else               
                w_elec = permute(filtfilt(h,1,permute(w_elec,[2,1,3])), [2,1,3]);                    
            end

            w_elec = w_elec(:, L+1:L+n, :);

        else

            w_elec = w(idx_elec, :);

            n = size(w_elec,2);

            w_elec = filtfilt(h,1,[fliplr(w_elec(:,1:L)), w_elec, fliplr(w_elec(:,end-L+1:end))]')';
            w_elec = w_elec(:, L+1:L+n);

        end
        
    end

end