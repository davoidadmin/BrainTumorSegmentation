% Select the first .nii file
[file1, folder1] = uigetfile('*.nii', 'Select the first .nii file');
nii1 = load_nii(fullfile(folder1, file1));

% Display the content of the first .nii file
figure;
volshow(nii1.img);
title('First .nii File');

% Option to select a second .nii file for comparison
button = questdlg('Do you want to compare with another .nii file?', 'Compare Files', 'Yes', 'No', 'No');
if strcmp(button, 'Yes')
    % Select the second .nii file
    [file2, folder2] = uigetfile('*.nii', 'Select the second .nii file');
    nii2 = load_nii(fullfile(folder2, file2));

    % Display the content of the second .nii file
    figure;
    volshow(nii2.img);
    title('Second .nii File');

    % Compare the content of the two .nii files
    figure;
    volshow(cat(4, nii1.img, nii2.img));
    title('Comparison of .nii Files');
    legend('First .nii File', 'Second .nii File');
end


