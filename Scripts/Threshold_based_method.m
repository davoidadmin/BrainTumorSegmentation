% Select the input folder
input_folder = uigetdir('Select the input folder');

% Select the folder containing the ground truth mask files
mask_folder = uigetdir('Select the mask folder');

% Get a list of all .nii files in the input folder
file_list = dir(fullfile(input_folder, '*.nii'));

% Loop over each file
for i = 1:numel(file_list)
    % Get the current file name
    filename = file_list(i).name;
    
    % Load the current file and the corresponding ground truth mask file
    image_file = load_nii(fullfile(input_folder, filename));
    mask_filename = sprintf('BraTS20_Training_%03d_seg.nii', i);
    mask_file = load_nii(fullfile(mask_folder, mask_filename));
    
    % Normalize the image
    image = double(image_file.img) / max(double(image_file.img(:)));
    
    % Create binary mask using a range of threshold values
    thresholds = 0.01:0.01:0.99;
    jaccard_index = zeros(size(thresholds));
    for j = 1:length(thresholds)
        tumor_mask = image > thresholds(j);
        
        % Remove small objects
        tumor_mask = bwareaopen(tumor_mask, 50);
        
        % Calculate Jaccard index
        intersection = sum(mask_file.img(:) & tumor_mask(:));
        union = sum(mask_file.img(:) | tumor_mask(:));
        jaccard_index(j) = intersection / union;
    end
    
    % Find the threshold with the highest Jaccard index
    [best_jaccard_index, best_index] = max(jaccard_index);
    best_threshold = thresholds(best_index);
    
    % Segment tumor using the best threshold value
    tumor_mask = image > best_threshold;
    tumor_mask = bwareaopen(tumor_mask, 50);
    
    % Clean up mask using morphological operations
    se = strel('disk', 3); % Create a disk-shaped structuring element
    clean_mask = zeros(size(tumor_mask)); % Initialize clean_mask
    for slice = 1:size(tumor_mask, 3)
        % Apply morphological operations to segment tumor region
        tumor_slice = tumor_mask(:, :, slice);
        clean_slice = imopen(imclose(imfill(tumor_slice, 'holes'), se), se);
        clean_mask(:, :, slice) = clean_slice;
    end
    
    % Save the segmented volume
    [~, filename_no_ext, ~] = fileparts(filename);
    segmented_filename = sprintf('%s_segmented.nii', filename_no_ext);
    segmented_path = fullfile(input_folder, 'TB_Segmentation_Results', segmented_filename);
    save_nii(make_nii(clean_mask), segmented_path);
end






