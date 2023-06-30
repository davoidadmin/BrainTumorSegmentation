% Select the input folder containing the .nii files
input_folder = uigetdir('Select the input folder');

% Define the output folder
output_folder = fullfile(input_folder, 'GaussianSmoothing_results');

% % Create the output folder if it doesn't exist
% if ~isfolder(output_folder)
%     mkdir(output_folder);
% end

% Get a list of .nii files in the input folder
nii_files = dir(fullfile(input_folder, '*.nii'));

% Set the sigma value for Gaussian smoothing
sigma = 1; % Adjust the sigma value as per your requirements

% Loop over each .nii file
for i = 1:numel(nii_files)
    % Load the .nii file
    nii_file = load_nii(fullfile(input_folder, nii_files(i).name));
    
    % Get the image data
    img = double(nii_file.img);
    
    % Apply Gaussian smoothing
    img_smoothed = imgaussfilt3(img, sigma);
    
    % Create a new .nii structure with the smoothed image data
    nii_smoothed = nii_file;
    nii_smoothed.img = img_smoothed;
    
    % Set the output file name
    [~, filename, ext] = fileparts(nii_files(i).name);
    output_filename = [filename, '_GS', ext];
    
    % Save the smoothed .nii file in the output folder
    save_nii(nii_smoothed, fullfile(output_folder, output_filename));
end

disp('Gaussian smoothing completed.');
