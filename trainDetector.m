% trainDetector.m
%   Trains a linear SVM on the ~2.2k pre-cropped windows in the 
%   /Images/Training/ folder. There is also already a pre-trained model 
%   saved in hog_model.mat, so you don't *have* to run this script in order
%   to play with the other examples.

addpath('./common/');
addpath('./svm/');
addpath('./svm/minFunc/');

%%
% Define the default HOG detector parameters (the size of the detection 
% window and the number of histogram bins).

% The number of bins to use in the histograms.
hog.numBins = 9;

% The number of cells horizontally and vertically.
hog.numHorizCells = 8;
hog.numVertCells = 16;

% Cell size in pixels (the cells are square).
hog.cellSize = 8;

% Compute the expected window size (with 1 pixel border on all sides).
hog.winSize = [(hog.numVertCells * hog.cellSize + 2), ...
               (hog.numHorizCells * hog.cellSize + 2)];

%%
% Load all training windows and get their HOG descriptors.

% Get the list of all images in the directory.
posFiles = getImagesInDir('./INRIAPerson/train_64x128_H96/pos/', true);
negFiles = getImagesInDir('./INRIAPerson/train_64x128_H96/neg/', true);

% Create the category labels.
y_train = [ones(length(posFiles), 1); zeros(length(negFiles), 1)];

% Combine the file lists to get a list of all training images.
fileList = [posFiles, negFiles];

% Build a matrix of all of the descriptors, one per row.
X_trainL = zeros(length(fileList), 3780);
X_trainA = zeros(length(fileList), 3780);
X_trainB = zeros(length(fileList), 3780);


fprintf('Computing descriptors for %d training windows: ', length(fileList));
		
% For all training window images...
for i = 1 : length(fileList)

    % Get the next filename.
    imgFile = char(fileList(i));

    % Print the current iteration (using some clever formatting to
    % overwrite).
    printIteration(i);
    
    %fprintf('%s\n', imgFile);
    % Load the image into a matrix.
    img = imread(imgFile);
    img = imresize(img,[130 66]);
    
    %Converting to LAB
    colorTransform = makecform('srgb2lab');
    img = applycform(img, colorTransform);
    
    % Calculate the HOG descriptor for the window.
    HL = getHOGDescriptor(hog, img(:,:,1));
    HA = getHOGDescriptor(hog, img(:,:,2));
    HB = getHOGDescriptor(hog, img(:,:,3));
    
    % Add the descriptor to the rest.
    X_trainL(i, :) = HL';
    X_trainA(i, :) = HA';
    X_trainB(i, :) = HB';
end

fprintf('\n');

%%
% Train the SVM.
% Store the resulting weights, theta, in the 'hog' structure.
fprintf('\nTraining linear SVM classifier...\n');
%X_train = (X_trainL+X_trainA+X_trainB)/3;
X_train = [X_trainL, X_trainA, X_trainB];
hog.theta = train_svm(X_train, y_train, 1.0);

save('hog_model.mat', 'hog');

% Evaluate the SVM over the training data.
p = X_train * hog.theta;

% Recognize as a pedestrian if the confidence is over 0.
numRight = sum((p > 0) == y_train);

fprintf('\nTraining accuracy lightness: (%d / %d) %.2f%%\n', numRight, length(y_train), numRight / length(y_train) * 100.0);

