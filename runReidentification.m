%runReidentification.m
%   Calculates the color histograms from the detected people boxes got by
%   runExampleSearch.m. Then, calculates the similaritys from the original
%   image and the image searched.

%% Load data
% Read the image searched.
img = imread('./Images/Validation/IMG_9997.jpg');

% Read the original image.
imgOriginal = imread('./INRIAPerson/test_64x128_H96/pos/crop001501g.png');

%Converting to LAB
colorTransform = makecform('srgb2lab');
img = applycform(img, colorTransform);
imgOriginal = applycform(imgOriginal, colorTransform);

% Load the pre-configured and pre-trained HOG detector.
load('hog_model.mat');

%% Calculates the color histograms and similaritys
runExampleSearch();

% Calculates the histogram for the original image.
histLOriginal = imhist(imgOriginal(:,:,1));
histAOriginal = imhist(imgOriginal(:,:,2));   
histBOriginal = imhist(imgOriginal(:,:,3));

% Calculates the histogram for all detected boxes.
for j = 1 : size(resultRects, 1)
    rect = resultRects(j, :);
    
    % Use this code to skip over drawing the false positives.
    % Or, comment it out to draw the false positives as blue rectangles.
    if rect(end) == 0
        similarity(j) = 0;
        continue;
    end
    
    % If the match is a good one (or an optional one), color it red.
    if (rect(end) ~= 0)
        histL = imhist(img(:,:,1));
        histA = imhist(img(:,:,2));   
        histB = imhist(img(:,:,3));
        
        productL = 0;
    
        % Calculates de similaritys between the histograms
        norma1L = 0;
        norma2L = 0;

        productA = 0;
        norma1A = 0;
        norma2A = 0;

        productB = 0;
        norma1B = 0;
        norma2B = 0;

        for i = 1:length(histLOriginal)
            productL = productL + histLOriginal(i,1)*histL(i,1);
            productA = productA + histAOriginal(i,1)*histA(i,1);
            productB = productB + histBOriginal(i,1)*histB(i,1);
        end

        for i = 1:length(histLOriginal)
            norma1L = norma1L + histLOriginal(i,1)*histLOriginal(i,1); 
            norma1A = norma1A + histAOriginal(i,1)*histAOriginal(i,1);
            norma1B = norma1B + histBOriginal(i,1)*histBOriginal(i,1);
        end
        norma1L = sqrt(norma1L);
        norma1A = sqrt(norma1A);
        norma1B = sqrt(norma1B);

        for i = 1:length(histL)
            norma2L = norma2L + histL(i,1)*histL(i,1);
            norma2A = norma2A + histA(i,1)*histA(i,1);
            norma2B = norma2B + histB(i,1)*histB(i,1);
        end
        norma2L = sqrt(norma2L);
        norma2A = sqrt(norma2A);
        norma2B = sqrt(norma2B);

        likenessL = productL/(norma1L*norma2L);
        likenessL = acos(likenessL);
        likenessA = productA/(norma1A*norma2A);
        likenessA = acos(likenessA);
        likenessB = productB/(norma1B*norma2B);
        likenessB = acos(likenessB);

        likeness = likenessL + likenessA + likenessB;
        difference = likeness*100*2/(3*pi);
        likeness = 100 - difference;

        similarity(j) = likeness;
    else
        similarity(j) = 0;
    end 
    
end

[result, index] = sort(similarity(:), 'descend');
bestIndex = index(1);

%% Draw the best result

% "Plot" the image.
hold off;
imagesc(img);
hold on;

% Draw the results.
drawRectangle(resultRects(bestIndex, :), 'r');

for i = 2:5
    drawRectangle(resultRects(index(i), :), 'b');
end

for i = 6:15
    drawRectangle(resultRects(index(i), :), 'g');
end