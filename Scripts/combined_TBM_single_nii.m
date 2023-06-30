% Select the T1 scan file
[t1_filename, t1_filepath] = uigetfile('*.nii', 'Select the T1 scan file');
t1_nii = load_nii(fullfile(t1_filepath, t1_filename));

% Select the T1CE scan file
[t1ce_filename, t1ce_filepath] = uigetfile('*.nii', 'Select the T1CE scan file');
t1ce_nii = load_nii(fullfile(t1ce_filepath, t1ce_filename));

% Select the T2 scan file
[t2_filename, t2_filepath] = uigetfile('*.nii', 'Select the T2 scan file');
t2_nii = load_nii(fullfile(t2_filepath, t2_filename));

% Select the FLAIR scan file
[flair_filename, flair_filepath] = uigetfile('*.nii', 'Select the FLAIR scan file');
flair_nii = load_nii(fullfile(flair_filepath, flair_filename));

% Select the ground truth mask file
[mask_filename, mask_filepath] = uigetfile('*.nii', 'Select the ground truth mask file');
mask_nii = load_nii(fullfile(mask_filepath, mask_filename));

% Perform tumor segmentation using the combined information from the scans
segmented_mask = performTumorSegmentation(t1_nii.img, t1ce_nii.img, t2_nii.img, flair_nii.img);

% Calculate evaluation metrics
dice_coefficient = computeDiceCoefficient(mask_nii.img, segmented_mask);
jaccard_index = computeJaccardIndex(mask_nii.img, segmented_mask);
volume_similarity_index = computeVolumeSimilarityIndex(mask_nii.img, segmented_mask);

% Display the segmented mask and ground truth mask
figure;
subplot(1, 2, 1);
volshow(segmented_mask);
title('Segmented Mask');
subplot(1, 2, 2);
volshow(mask_nii.img);
title('Ground Truth Mask');

% Display the evaluation metrics
disp(['Dice Coefficient: ', num2str(dice_coefficient)]);
disp(['Jaccard Index: ', num2str(jaccard_index)]);
disp(['Volume Similarity Index: ', num2str(volume_similarity_index)]);

function segmented_mask = performTumorSegmentation(t1, t1ce, t2, flair)
    % Apply thresholding-based tumor segmentation using intensity values
    t1_threshold = 100; % Adjust the threshold values according to your data
    t1ce_threshold = 150;
    t2_threshold = 50;
    flair_threshold = 200;
    
    segmented_mask = (t1 > t1_threshold) & (t1ce > t1ce_threshold) & (t2 > t2_threshold) & (flair > flair_threshold);
end

function dice_coefficient = computeDiceCoefficient(mask1, mask2)
    intersection = sum(mask1(:) & mask2(:));
    total_voxels = sum(mask1(:)) + sum(mask2(:));
    dice_coefficient = (2 * intersection) / total_voxels;
end

function jaccard_index = computeJaccardIndex(mask1, mask2)
    intersection = sum(mask1(:) & mask2(:));
    union = sum(mask1(:) | mask2(:));
    jaccard_index = intersection / union;
end

function volume_similarity_index = computeVolumeSimilarityIndex(mask1, mask2)
    numerator = sum(mask1(:) & mask2(:));
    denominator = sum(mask1(:) | mask2(:));
    volume_similarity_index = numerator / denominator;
end

