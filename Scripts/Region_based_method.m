% Select the input folder
input_folder = uigetdir('Select the input folder');

% Select the folder containing the ground truth mask files
mask_folder = uigetdir('Select the mask folder');

% Get a list of all .nii files in the input folder
file_list = dir(fullfile(input_folder, '*.nii'));

% Parameters for grid search
num_classes_range = [2, 3, 4];  % Range of values for number of classes
max_iterations_range = [5, 10, 15];  % Range of values for maximum iterations

% Loop over each file
for i = 1:numel(file_list)
    % Get the current file name
    filename = file_list(i).name;
    
    % Extract the index from the current file name
    [~, filename_no_ext, ~] = fileparts(filename);
    index = str2double(regexp(filename_no_ext, '\d+', 'match'));
    
    % Construct the corresponding ground truth mask file name
    mask_filename = sprintf('BraTS20_Training_%03d_seg.nii', index);
    
    % Check if the corresponding ground truth mask file exists
    mask_filepath = fullfile(mask_folder, mask_filename);
    if exist(mask_filepath, 'file') ~= 2
        disp(['Ground truth mask file not found for ' filename '. Skipping...']);
        continue;
    end
    
    % Load the current file and the corresponding ground truth mask file
    image_file = load_nii(fullfile(input_folder, filename));
    mask_file = load_nii(mask_filepath);
    
    % Check if the dimensions of the masks match
    if ~isequal(size(image_file.img), size(mask_file.img))
        disp(['Dimensions of ' filename ' and its ground truth mask do not match. Skipping...']);
        continue;
    end
    
    % Grid search for parameter tuning
    best_dice_coefficient = 0;
    best_num_classes = 0;
    best_max_iterations = 0;
    
    for num_classes = num_classes_range
        for max_iterations = max_iterations_range
            % Perform region-based segmentation using k-means
            labeled_image = imsegkmeans(image_file.img, num_classes, 'NumAttempts', max_iterations);

            % Clean up the segmented image using morphological operations
            se = strel('disk', 3); % Create a disk-shaped structuring element
            clean_mask = imopen(labeled_image == 2, se);
            clean_mask = uint8(clean_mask); % Convert to uint8 data type

            % Calculate Dice coefficient
            dice_coefficient = computeDiceCoefficient(mask_file.img, clean_mask);

            % Update best parameters if the current dice coefficient is higher
            if dice_coefficient > best_dice_coefficient
                best_dice_coefficient = dice_coefficient;
                best_num_classes = num_classes;
                best_max_iterations = max_iterations;
            end
        end
    end
    
    % Perform segmentation using the best parameters
    labeled_image = imsegkmeans(image_file.img, best_num_classes, 'NumAttempts', best_max_iterations);
    clean_mask = imopen(labeled_image == 2, se);
    clean_mask = uint8(clean_mask); % Convert to uint8 data type
    
    % Save the segmented volume
    segmented_filename = sprintf('%s_segmented.nii', filename_no_ext);
    segmented_path = fullfile(input_folder, 'RB_Segmentation_Results', segmented_filename);
    
    % Create a new nifti structure with the segmented mask
    nii_segmented = image_file;
    nii_segmented.img = clean_mask;
    
    % Save the segmented mask as a nifti file
    save_nii(nii_segmented, segmented_path);
end

function dice_coefficient = computeDiceCoefficient(mask1, mask2)
    intersection = sum(mask1(:) & mask2(:));
    total_voxels = sum(mask1(:)) + sum(mask2(:));
    dice_coefficient = (2 * intersection) / total_voxels;
end





