% Prompt the user to select the folder containing the segmented masks
segmented_folder = uigetdir('Select the folder containing the segmented masks');

% Prompt the user to select the folder containing the ground truth masks
ground_truth_folder = uigetdir('Select the folder containing the ground truth masks');

% Get a list of all segmented mask files in the segmented folder
segmented_files = dir(fullfile(segmented_folder, '*.nii'));

% Initialize arrays to store the metrics for each file
dice_similarity = zeros(1, numel(segmented_files));
jaccard_similarity = zeros(1, numel(segmented_files));
volume_similarity = zeros(1, numel(segmented_files));

% Regular expression pattern to extract the file number
file_number_pattern = '(\d+)';

% Loop over each segmented mask file
for i = 1:numel(segmented_files)
    % Get the filename for the current segmented mask
    segmented_filename = segmented_files(i).name;

    % Extract the file number from the filename
    file_number_match = regexp(segmented_filename, file_number_pattern, 'match');
    file_number = str2double(file_number_match{1});

    % Load the segmented mask and the corresponding ground truth mask
    segmented_mask = niftiread(fullfile(segmented_folder, segmented_filename));
    segmented_mask = cast(segmented_mask, 'logical'); % Convert to logical for binary operations

    ground_truth_mask = niftiread(fullfile(ground_truth_folder, sprintf('BraTS20_Training_%03d_seg.nii', file_number)));
    ground_truth_mask = cast(ground_truth_mask, 'logical'); % Convert to logical for binary operations

    % Calculate metrics for the current file
    dice_similarity(i) = 2 * sum(ground_truth_mask(:) & segmented_mask(:)) / (sum(ground_truth_mask(:)) + sum(segmented_mask(:)));
    jaccard_similarity(i) = sum(ground_truth_mask(:) & segmented_mask(:)) / sum(ground_truth_mask(:) | segmented_mask(:));
    volume_similarity(i) = sum(segmented_mask(:)) / sum(ground_truth_mask(:));
end

% Calculate average metrics
average_dice_similarity = mean(dice_similarity);
average_jaccard_similarity = mean(jaccard_similarity);
average_volume_similarity = mean(volume_similarity);

% Save metrics to a file
metrics_filename = fullfile(segmented_folder, 'metrics.txt');
fid = fopen(metrics_filename, 'w');
fprintf(fid, 'Average Dice Similarity: %.4f\n', average_dice_similarity);
fprintf(fid, 'Average Jaccard Similarity: %.4f\n', average_jaccard_similarity);
fprintf(fid, 'Average Volume Similarity: %.4f\n', average_volume_similarity);
fclose(fid);




