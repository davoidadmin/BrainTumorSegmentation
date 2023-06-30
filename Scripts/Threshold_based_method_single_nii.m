% Load images
tumor = load_nii('C:\Users\dave9\Desktop\Università\Image Processing\BraTS20_Training_001\BraTS20_Training_001_t1.nii');
truth_mask = load_nii('BraTS20_Training_001_seg.nii');

% Normalize image
tumor_img = double(tumor.img) / max(double(tumor.img(:)));

% Create binary mask using a range of threshold values
thresholds = 0.01:0.01:0.99;
jaccard_index = zeros(size(thresholds));
for i = 1:length(thresholds)
    tumor_mask = tumor_img > thresholds(i);

    % Remove small objects
    tumor_mask = bwareaopen(tumor_mask, 50);

    % Calculate Jaccard index
    intersection = sum(truth_mask.img(:) & tumor_mask(:));
    union = sum(truth_mask.img(:) | tumor_mask(:));
    jaccard_index(i) = intersection / union;
end

% Find threshold with highest Jaccard index
[best_jaccard_index, best_index] = max(jaccard_index);
best_threshold = thresholds(best_index);

% Segment tumor using best threshold value
tumor_mask = tumor_img > best_threshold;
tumor_mask = bwareaopen(tumor_mask, 50);

% Clean up mask using morphological operations
se = strel('disk', 3); % Create a disk-shaped structuring element
clean_mask = zeros(size(tumor_mask)); % Initialize clean_mask

for slice = 1:size(tumor_mask, 3)
    % Apply morphological operations to segment tumor region
    tumor_slice = tumor_mask(:, :, slice);
    se = strel('disk', 3);
    clean_slice = imopen(imclose(imfill(tumor_slice,'holes'),se),se);
    clean_mask(:, :, slice) = clean_slice;
end

% Display the original and segmented volumes side by side
figure;
volshow(tumor.img);
title('Original Volume');

figure;
volshow(clean_mask);
title('Segmented Volume');


% Convert inputs to categorical
truth_cat = categorical(truth_mask.img(:));
clean_cat = categorical(clean_mask(:));

% Calculate confusion matrix
conf_matrix = confusionmat(truth_cat, clean_cat);

% Calculate evaluation metrics
dice_similarity = 2 * conf_matrix(2,2) / (2 * conf_matrix(2,2) + conf_matrix(1,2) + conf_matrix(2,1));
jaccard_similarity = conf_matrix(2,2) / (conf_matrix(2,2) + conf_matrix(1,2) + conf_matrix(2,1));
%hausdorff_distance = hausdorffDist(truth_mask.img, clean_mask);
%average_surface_distance = surfDist(truth_mask.img, clean_mask);
volume_similarity = (2 * sum(truth_mask.img(:) & clean_mask(:))) / (sum(truth_mask.img(:)) + sum(clean_mask(:)));
