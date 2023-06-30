% Set up input and output directories
input_folder = uigetdir('Select input folder'); % Select the input folder containing the images
output_folder = fullfile(input_folder, 'BiasCorrection_results'); % Output folder to save the corrected images
% if ~exist(output_folder, 'dir')
%     mkdir(output_folder);
% end

% Get a list of all files with the pattern '*.nii' in the input folder
file_list = dir(fullfile(input_folder, '*.nii'));

% Read the reference image (first image in the folder)
reference_path = fullfile(input_folder, file_list(1).name);
reference_image = load_nii(reference_path);
reference_data = double(reference_image.img); % Convert to double data type

% Loop over each file
for i = 1:numel(file_list)
    % Read the input image
    input_path = fullfile(input_folder, file_list(i).name);
    input_image = load_nii(input_path);
    input_data = double(input_image.img); % Convert to double data type
    
    % Perform intensity normalization
    normalized_data = (input_data - mean(input_data(:))) / std(input_data(:));
    
    % Perform histogram matching
    matched_data = imhistmatch(normalized_data, reference_data);
    
    % Create an output image structure
    output_image = input_image;
    output_image.img = matched_data;
    
    % Get the output file name
    [~, filename, ~] = fileparts(input_path);
    output_filename = [filename, '_BC.nii'];
    
    % Remove special characters from the output filename
    output_filename = regexprep(output_filename, '[^\w\.]', '_');
    
    % Construct the full output path
    output_path = fullfile(output_folder, output_filename);
    
    % Save the corrected image
    save_nii(output_image, output_path);
end

disp('Bias Field Correction completed.');


