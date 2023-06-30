% Set the parameters
max_iterations = 500; % Maximum number of iterations
alpha = 1.0; % Weight for the internal energy term
beta = 1.0; % Weight for the image term
gamma = 1.0; % Weight for the balloon term

% Prompt the user to select the input folder
input_folder = uigetdir('Select the folder containing NIfTI files');

% Create the output folder
output_folder = fullfile(input_folder, 'LS_Segmentation_Results');
%mkdir(output_folder);

% Get a list of all NIfTI files in the input folder
file_list = dir(fullfile(input_folder, '*.nii'));

% Iterate over each NIfTI file
for i = 1:numel(file_list)
    % Load the NIfTI file
    nii = load_nii(fullfile(input_folder, file_list(i).name));
    image = nii.img;
    
    % Perform level set segmentation
    segmented_mask = region_seg(image, max_iterations, alpha, beta, gamma, 'average');
    
    % Save the segmented mask as a NIfTI file
    segmented_nii = nii;
    segmented_nii.img = segmented_mask;
    segmented_nii.hdr.dime.datatype = 2; % Set the datatype to uint8
    segmented_nii.hdr.dime.bitpix = 8; % Set the bit depth to 8-bit
    segmented_filename = fullfile(output_folder, ['segmented_' file_list(i).name]);
    save_nii(segmented_nii, segmented_filename);
end

disp('Segmentation complete.');

% Function to perform level set segmentation
function segmented_mask = region_seg(image, max_iterations, alpha, beta, gamma, method)
    % Initialize phi as a signed distance function
    phi = initialize_phi(image);
    
    % Compute the gradient of the image
    grad = compute_gradient(image);
    
    for iter = 1:max_iterations
        % Calculate curvature term
        curvature = calculate_curvature(phi, grad.gradient_x, grad.gradient_y, grad.gradient_z);
        
        % Update phi
        phi = phi + delta_t(length, alpha, curvature, beta, gamma) .* curvature;
        
        % Ensure the level set function remains a signed distance function
        phi = sussman_reinit(phi, 0.5);
        
        % Display intermediate result
        if mod(iter, 10) == 0
            imshow(image, [])
            hold on
            contour(phi, [0 0], 'r', 'LineWidth', 2)
            hold off
            drawnow
        end
    end
    
    % Convert phi to a binary mask
    segmented_mask = phi <= 0;
end

% Function to initialize the level set function
function phi = initialize_phi(image)
    phi = double(image > 0);
end

% Function to compute the gradient of an image
function grad = compute_gradient(image)
    grad.gradient_x = gradient_x(image);
    grad.gradient_y = gradient_y(image);
    grad.gradient_z = gradient_z(image);
end

% Function to calculate the gradient of an image along the x-axis
function gradient = gradient_x(phi)
    gradient = cat(2, diff(phi, 1, 2), zeros(size(phi, 1), 1, size(phi, 3)));
end

% Function to calculate the gradient of an image along the y-axis
function gradient = gradient_y(phi)
    gradient = cat(1, diff(phi, 1, 1), zeros(1, size(phi, 2), size(phi, 3)));
end

% Function to calculate the gradient of an image along the z-axis
function gradient = gradient_z(phi)
    gradient = cat(3, diff(phi, 1, 3), zeros(size(phi, 1), size(phi, 2), 1));
end

% Function to calculate curvature terms
function curvature = calculate_curvature(phi, grad_x, grad_y, grad_z)
    curvature_x = gradient_x(grad_x) ./ (eps + sqrt(eps^2 + double(gradient_magnitude_squared(grad_x))));
    curvature_y = gradient_y(grad_y) ./ (eps + sqrt(eps^2 + double(gradient_magnitude_squared(grad_y))));
    curvature_z = gradient_z(grad_z) ./ (eps + sqrt(eps^2 + double(gradient_magnitude_squared(grad_z))));
    
    % Handle integer division by casting back to the original class
    curvature_x = cast(curvature_x, 'like', grad_x);
    curvature_y = cast(curvature_y, 'like', grad_y);
    curvature_z = cast(curvature_z, 'like', grad_z);
    
    curvature = divergence(curvature_x, curvature_y, curvature_z);
end




% Function to calculate the divergence term in the level set equation
function div = divergence(grad_x, grad_y, grad_z, curvature_x, curvature_y, curvature_z)
    div = zeros(size(grad_x));
    
    if ~isempty(grad_x)
        div = div + grad_x .* curvature_x;
    end
    if ~isempty(grad_y)
        div = div + grad_y .* curvature_y;
    end
    if ~isempty(grad_z)
        div = div + grad_z .* curvature_z;
    end
end

% Function to calculate the time step size
function dt = delta_t(length, alpha, curvature, beta, gamma)
    dt = 0.45 / (max(length(:))^2);
    dt = dt + alpha * curvature;
    dt = dt + beta * max(curvature(:));
    dt = dt + gamma;
end

% Function to reinitialize the level set function to ensure it remains a signed distance function
function phi = sussman_reinit(phi, dt)
    phi = phi ./ sqrt(phi.^2 + eps^2);
    phi_plus = max(phi, 0);
    phi_minus = min(phi, 0);
    phi_plus_shift = circshift(phi_plus, [0 1]);
    phi_minus_shift = circshift(phi_minus, [0 -1]);
    phi_plus_gradient = phi_plus - phi_plus_shift;
    phi_minus_gradient = phi_minus - phi_minus_shift;
    phi_plus_gradient_plus = circshift(phi_plus_gradient, [0 1]);
    phi_minus_gradient_minus = circshift(phi_minus_gradient, [0 -1]);
    phi_plus_gradient_plus(end, :) = phi_plus_gradient(end, :);
    phi_minus_gradient_minus(1, :) = phi_minus_gradient(1, :);
    phi_plus_gradient_minus = circshift(phi_plus_gradient, [0 -1]);
    phi_minus_gradient_plus = circshift(phi_minus_gradient, [0 1]);
    phi_plus_gradient_minus(:, end) = phi_plus_gradient(:, end);
    phi_minus_gradient_plus(:, 1) = phi_minus_gradient(:, 1);
    pos_idx = phi > 0;
    neg_idx = phi < 0;
    phi(pos_idx) = phi(pos_idx) - dt * ...
        max(0, min(phi_plus_gradient_minus(pos_idx), phi_minus_gradient_plus(pos_idx))) + ...
        dt * max(0, min(phi_plus_gradient_plus(pos_idx), phi_minus_gradient_minus(pos_idx)));
    phi(neg_idx) = phi(neg_idx) + dt * ...
        max(0, min(phi_plus_gradient_minus(neg_idx), phi_minus_gradient_plus(neg_idx))) - ...
        dt * max(0, min(phi_plus_gradient_plus(neg_idx), phi_minus_gradient_minus(neg_idx)));
end

%Function to calculate the gradient magnitude squared
function magnitude_squared = gradient_magnitude_squared(gradient)
    magnitude_squared = sum(gradient.^2, 4);
end

% Function to load a NIfTI file
function nii = load_nii(filename)
    nii = load_untouch_nii(filename);
end

% Function to save a NIfTI file
function save_nii(nii, filename)
    save_untouch_nii(nii, filename);
end




