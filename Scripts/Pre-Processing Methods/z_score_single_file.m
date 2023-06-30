% Select the input .nii file
[input_file, input_folder] = uigetfile('*.nii', 'Select the input .nii file');

% Define the output folder
output_folder = fullfile(input_folder, 'z_score_results');

% Create the output folder if it doesn't exist
if ~isfolder(output_folder)
    mkdir(output_folder);
end

% Load the input .nii file
input_nii = load_nii(fullfile(input_folder, input_file));

% Get the image data
img = double(input_nii.img);

% Calculate mean and standard deviation
img_mean = mean(img(:));
img_std = std(img(:));

% Apply z-score normalization
img_normalized = (img - img_mean) / img_std;

% Create a new .nii structure with the normalized image data
output_nii = input_nii;
output_nii.img = img_normalized;

% Set the file name for the normalized .nii file
[~, filename, ext] = fileparts(input_file);
output_filename = [filename '_z' ext];

% Save the normalized .nii file in the output folder
save_nii(output_nii, fullfile(output_folder, output_filename));

disp('Z-score normalization completed.');
