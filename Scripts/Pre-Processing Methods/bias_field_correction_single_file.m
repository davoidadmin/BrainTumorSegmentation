% Set up input and output directories
input_file = uigetfile('*.nii', 'Select input file'); % Select the input file
output_folder = uigetdir('Select output folder'); % Select the output folder to save the corrected image

% Read the reference image
reference_image = load_nii(input_file);
reference_data = double(reference_image.img); % Convert to double data type

% Perform intensity normalization on the reference image
normalized_reference = (reference_data - mean(reference_data(:))) / std(reference_data(:));

% Read the input image
input_image = load_nii(input_file);
input_data = double(input_image.img); % Convert to double data type

% Perform intensity normalization on the input image
normalized_input = (input_data - mean(input_data(:))) / std(input_data(:));

% Perform histogram matching
matched_data = imhistmatch(normalized_input, normalized_reference);

% Create an output image structure
output_image = input_image;
output_image.img = matched_data;

% Get the output file name
[~, filename, ~] = fileparts(input_file);
output_filename = [filename, '_BC.nii'];

% Remove special characters from the output filename
output_filename = regexprep(output_filename, '[^\w\.]', '_');

% Construct the full output path
output_path = fullfile(output_folder, output_filename);

% Save the corrected image
save_nii(output_image, output_path);

disp('Bias Field Correction completed.');
