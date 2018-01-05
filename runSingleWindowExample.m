% runSingleWindowExample.m
%   This script calculates the HOG descriptor for a single image that has
%   been cropped down to the detector size. Look at this for learning about
%   the descriptor by itself (without all of the complexities added by 
%   actually searching a full image for persons). 

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
% Calculate the HOG descriptor for an example image window.

fprintf('Getting the HOG descriptor for an example image...\n');

% Read in the pre-cropped (66 x 130) image.
img = imread('./INRIAPerson/test_64x128_H96/pos/crop001501a.png');
img = imresize(img,[130 66]);

%Converting to LAB
colorTransform = makecform('srgb2lab');
img = applycform(img, colorTransform);
% Compute the HOG descriptor for this image.
HL = getHOGDescriptor(hog, img(:,:,1));
HA = getHOGDescriptor(hog, img(:,:,2));
HB = getHOGDescriptor(hog, img(:,:,3));

HL = HL';
HA = HA';
HB = HB';

H = [HL, HA, HB];
%%
% Test if this image contains a person.

% Load the pre-trained HOG model.
load('hog_model.mat');

% Evaluate the linear SVM on the descriptor.
p = H * hog.theta;

% Print whether we think it's a person or not (the SVM was trained to
% output -1 for no person and +1 for a person).
if (p > 0)
    fprintf('  This image contains a person!\n');
else
    fprintf('  This image does not contain a person!\n');
end

% Display the image
hold off;
imagesc(img)
