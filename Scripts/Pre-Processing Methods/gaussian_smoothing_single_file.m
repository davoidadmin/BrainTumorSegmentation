% Select the input .nii file
[input_file, input_folder] = uigetfile('*.nii', 'Select the input .nii file');

% Define the output folder
output_folder = fullfile(input_folder, 'GaussianSmoothing_results');

% Create the output folder if it doesn't exist
if ~isfolder(output_folder)
    mkdir(output_folder);
end

% Load the input .nii file
nii_file = load_nii(fullfile(input_folder, input_file));

% Set the sigma value for Gaussian smoothing
sigma = 1; % Adjust the sigma value as per your requirements

% Get the image data
img = double(nii_file.img);

% Apply Gaussian smoothing
img_smoothed = imgaussfilt3(img, sigma);

% Create a new .nii structure with the smoothed image data
nii_smoothed = nii_file;
nii_smoothed.img = img_smoothed;

% Set the output file name
[~, filename, ext] = fileparts(input_file);
output_filename = [filename, '_GS', ext];

% Save the smoothed .nii file in the output folder
save_nii(nii_smoothed, fullfile(output_folder, output_filename));

disp('Gaussian smoothing completed.');
