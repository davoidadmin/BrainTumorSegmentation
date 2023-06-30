% Select the input folder using a file dialog
input_folder = uigetdir('Select the input folder');

% Define the output folder
output_folder = fullfile(input_folder, 'z_score_results');

% % Create the output folder if it doesn't exist
% if ~isfolder(output_folder)
%     mkdir(output_folder);
% end

% Get a list of .nii files ending with "t1" in the input folder
t1_files = dir(fullfile(input_folder, '*t1.nii'));

% Loop over each t1 file
for i = 1:numel(t1_files)
    % Load the t1 file
    t1_file = load_nii(fullfile(input_folder, t1_files(i).name));
    
    % Get the image data
    img = double(t1_file.img);
    
    % Calculate mean and standard deviation
    img_mean = mean(img(:));
    img_std = std(img(:));
    
    % Apply z-score normalization
    img_normalized = (img - img_mean) / img_std;
    
    % Create a new .nii structure with the normalized image data
    nii_normalized = t1_file;
    nii_normalized.img = img_normalized;
    
    % Set the file name for the normalized .nii file
    [~, filename, ext] = fileparts(t1_files(i).name);
    output_filename = sprintf('%03d_z.nii', i);
    
    % Save the normalized .nii file in the output folder
    save_nii(nii_normalized, fullfile(output_folder, output_filename));
end

disp('Z-score normalization completed.');
