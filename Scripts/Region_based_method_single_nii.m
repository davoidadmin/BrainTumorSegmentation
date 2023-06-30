% Select the input file
[input_file, input_folder] = uigetfile('*.nii', 'Select the input file');

% Select the corresponding ground truth mask file
[mask_file, mask_folder] = uigetfile('*.nii', 'Select the ground truth mask file');

% Load the input file and the ground truth mask file
input_nii = load_nii(fullfile(input_folder, input_file));
mask_nii = load_nii(fullfile(mask_folder, mask_file));

% Check if the dimensions of the images match
if ~isequal(size(input_nii.img), size(mask_nii.img))
    % Resize the images to match the dimensions
    resized_input = imresize3(input_nii.img, size(mask_nii.img));
    resized_mask = mask_nii.img;
else
    resized_input = input_nii.img;
    resized_mask = mask_nii.img;
end

% Convert the input image to an appropriate data type
input_img = cast(resized_input, 'like', resized_mask);

% Perform region-based segmentation using k-means
num_classes = 3;
max_iterations = 10;
labeled_image = imsegkmeans(input_img, num_classes, 'NumAttempts', max_iterations);

% Clean up the segmented image using morphological operations
se = strel('disk', 3); % Create a disk-shaped structuring element
clean_mask = imopen(labeled_image == 2, se);
clean_mask = uint8(clean_mask); % Convert to uint8 data type

% Create the output folder if it doesn't exist
output_folder = fullfile(input_folder, 'RB_Segmentation_Results');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Save the segmented volume
[~, input_filename_no_ext, ~] = fileparts(input_file);
segmented_filename = sprintf('%s_segmented.nii', input_filename_no_ext);
segmented_path = fullfile(output_folder, segmented_filename);

% Create a new nifti structure with the segmented mask
nii_segmented = input_nii;
nii_segmented.img = clean_mask;

% Save the segmented mask as a nifti file
save_nii(nii_segmented, segmented_path);

