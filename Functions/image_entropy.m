% Function to compute entropy of an image, a measure of image compexity

function img_entropy = image_entropy(img)

    N = histcounts(img, 0:256);
    p = N/sum(N);
    
    img_entropy = -nansum(p .* log2(p));
    
end