%runReidentification.m
%   Calculates the color histograms from the detected people boxes got by
%   runExampleSearch.m. Then, calculates the similaritys from the original
%   image and the image searched.

%% Load data

clear;

% Read the image searched.
files = getImagesInDir('./Images/Validation/', true);
fprintf('Making the test for %d images.', length(files));
%img = imread('./Images/Validation/IMG_9997.jpg');

% Read the original image.
imgOriginal = imread('./INRIAPerson/test_64x128_H96/pos/crop001501g.png');

for cont = 1 : length(files)
    %% Running over the images 
    % Get the next filename.
    imgFile = char(files(cont));

    % Print the current iteration (using some clever formatting to
    % overwrite).
    fprintf('\nImage %d:\n', cont);
    %fprintf('%s\n', imgFile);
    % Load the image into a matrix.
    img = imread(imgFile);
    %img = imresize(img,[130 66]);

    %Converting to LAB
    colorTransform = makecform('srgb2lab');
    img = applycform(img, colorTransform);
    imgOriginal = applycform(imgOriginal, colorTransform);

    % Load the pre-configured and pre-trained HOG detector.
    load('hog_model.mat');

    %% Calculates the color histograms and similaritys
    imgSave = img;
    resultRects = runExampleSearch(img, cont);
    img = imgSave;
    
    % Calculates the histogram for the original image.
    histLOriginal = imhist(imgOriginal(:,:,1));
    histAOriginal = imhist(imgOriginal(:,:,2));   
    histBOriginal = imhist(imgOriginal(:,:,3));

    % Calculates the histogram for all detected boxes.
    clear similarity;
    for j = 1 : size(resultRects, 1)
        rect = resultRects(j, :);

        % Use this code to skip over drawing the false positives.
        % Or, comment it out to draw the false positives as blue rectangles.
        if rect(end) == 0 || rect(end) == -1
            similarity(j) = 0;
            continue;
        end

        % If the match is a good one (or an optional one), color it red.
        if (rect(end) ~= 0)
            img_size = size(img);
            if (rect(1)+rect(3)>img_size(1))
                x = rect(1):img_size(1);
            else
                x = rect(1):(rect(1)+rect(3));
            end
            if (rect(2)+rect(4)>img_size(2))
                y = rect(2):img_size(2);
            else
                y = rect(2):(rect(2)+rect(4));
            end
            histL = imhist(img(x,y,1));
            histA = imhist(img(x,y,2));   
            histB = imhist(img(x,y,3));

            % Calculates de similaritys between the histograms using the
            % cossine technique.
            productL = 0;
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

            likeness = 0*likenessL + likenessA + likenessB;
            difference = likeness*100*2/(2*pi);
            likeness = 100 - difference;

            similarity(j) = likeness;
        else
            similarity(j) = 0;
        end 

    end

    [result, index] = sort(similarity(:), 'descend');
    bestIndex = index(1);

    %% Draw the best result

    % Plot the histograms.
    figure;
    subplot(3,2,1);
    imhist(imgOriginal(:,:,1));
    title('Suspect - L Histogram');
    subplot(3,2,3);
    imhist(imgOriginal(:,:,2));
    title('Suspect - A Histogram');
    subplot(3,2,5);
    imhist(imgOriginal(:,:,3));
    title('Suspect - B Histogram');

    rect = resultRects(bestIndex, :);
    img_size = size(img);
    if (rect(1)+rect(3)>img_size(1))
        x = rect(1):img_size(1);
    else
        x = rect(1):(rect(1)+rect(3));
    end
    if (rect(2)+rect(4)>img_size(2))
        y = rect(2):img_size(2);
    else
        y = rect(2):(rect(2)+rect(4));
    end
    subplot(3,2,2);
    imhist(img(x,y,1));
    title('Top1 - L Histogram');
    subplot(3,2,4);
    imhist(img(x,y,2)); 
    title('Top1 - A Histogram');
    subplot(3,2,6);
    imhist(img(x,y,3));
    title('Top1 - B Histogram');
    
    addpath('./export_fig/');
    export_fig(sprintf('./Test/test%d_histograms.png', cont));
    
    %Converting to RGB
    colorTransform = makecform('lab2srgb');
    img = applycform(img, colorTransform);
    imgOriginal = applycform(imgOriginal, colorTransform);

    %Plot the images
    figure;
    subplot(1,3,1);
    imagesc(imgOriginal);
    title('Suspect');
    subplot(1,3,[2 3]);
    imagesc(img);
    title('Reidentification top 5');
    hold on;
    plot(0,0,'r');
    plot(0,0,'g');

    % Draw the results.
    for i = 2:5
        drawRectangle(resultRects(index(i), :), 'g');
    end
    drawRectangle(resultRects(bestIndex, :), 'r');

    legend('Top 1', 'Top 2 to 5');

    addpath('./export_fig/');
    export_fig(sprintf('./Test/test%d_images.png', cont), '-native');
end