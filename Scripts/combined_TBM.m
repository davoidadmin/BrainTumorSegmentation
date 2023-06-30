% Select input folders for each scan type
t1_folder = uigetdir('Select folder for T1 scans');
t1ce_folder = uigetdir('Select folder for T1ce scans');
t2_folder = uigetdir('Select folder for T2 scans');
flair_folder = uigetdir('Select folder for FLAIR scans');
ground_truth_folder = uigetdir('Select folder for ground truth masks');

% Get a list of all files with the pattern '*.nii' in the input folders
t1_files = dir(fullfile(t1_folder, '*.nii'));
t1ce_files = dir(fullfile(t1ce_folder, '*.nii'));
t2_files = dir(fullfile(t2_folder, '*.nii'));
flair_files = dir(fullfile(flair_folder, '*.nii'));
gt_files = dir(fullfile(ground_truth_folder, '*.nii'));

% Initialize variables for index calculation
jaccard_sum = 0;
dice_sum = 0;
volume_sum = 0;

% Loop over each file
for i = 1:numel(t1_files)
    % Read the input images
    t1_nii = load_nii(fullfile(t1_folder, t1_files(i).name));
    t1ce_nii = load_nii(fullfile(t1ce_folder, t1ce_files(i).name));
    t2_nii = load_nii(fullfile(t2_folder, t2_files(i).name));
    flair_nii = load_nii(fullfile(flair_folder, flair_files(i).name));
    gt_nii = load_nii(fullfile(ground_truth_folder, gt_files(i).name));
    
    % Perform thresholding-based segmentation
    segmented_mask = thresholdSegmentation(t1_nii.img, t1ce_nii.img, t2_nii.img, flair_nii.img);
    
    % Calculate Jaccard Similarity Index, Dice Similarity Index, and Volume Similarity Index
    jaccard_index = calculateJaccardIndex(segmented_mask, gt_nii.img);
    dice_index = calculateDiceIndex(segmented_mask, gt_nii.img);
    volume_index = calculateVolumeSimilarityIndex(segmented_mask, gt_nii.img);
    
    % Accumulate the index values
    jaccard_sum = jaccard_sum + jaccard_index;
    dice_sum = dice_sum + dice_index;
    volume_sum = volume_sum + volume_index;
end

% Calculate average index values
num_files = numel(t1_files);
average_jaccard_index = jaccard_sum / num_files;
average_dice_index = dice_sum / num_files;
average_volume_index = volume_sum / num_files;

% Display average index values
disp(['Average Jaccard Similarity Index: ', num2str(average_jaccard_index)]);
disp(['Average Dice Similarity Index: ', num2str(average_dice_index)]);
disp(['Average Volume Similarity Index: ', num2str(average_volume_index)]);

disp('Index calculation completed.');

% Function to perform thresholding-based segmentation
function segmented_mask = thresholdSegmentation(t1, t1ce, t2, flair)
    % Apply thresholding-based tumor segmentation using intensity values
    t1_threshold = 100; % Adjust the threshold values according to your data
    t1ce_threshold = 150;
    t2_threshold = 50;
    flair_threshold = 200;
    
    segmented_mask = (t1 > t1_threshold) & (t1ce > t1ce_threshold) & (t2 > t2_threshold) & (flair > flair_threshold);
end

% Function to calculate Jaccard Similarity Index
function jaccard_index = calculateJaccardIndex(segmented_mask, ground_truth_mask)
    intersection = sum(segmented_mask(:) & ground_truth_mask(:));
    union = sum(segmented_mask(:) | ground_truth_mask(:));
    
    jaccard_index = intersection / union;
end

% Function to calculate Dice Similarity Index
function dice_index = calculateDiceIndex(segmented_mask, ground_truth_mask)
    intersection = sum(segmented_mask(:) & ground_truth_mask(:));
    mask_sum = sum(segmented_mask(:)) + sum(ground_truth_mask(:));
    
    dice_index = (2 * intersection) / mask_sum;
end

% Function to calculate Volume Similarity Index
function volume_index = calculateVolumeSimilarityIndex(segmented_mask, ground_truth_mask)
    segmented_volume = sum(segmented_mask(:));
    ground_truth_volume = sum(ground_truth_mask(:));
    overlap_volume = sum(segmented_mask(:) & ground_truth_mask(:));
    
    volume_index = (2 * overlap_volume) / (segmented_volume + ground_truth_volume);
end


