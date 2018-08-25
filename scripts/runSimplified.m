%runReidentification.m
%   Calculates the color histograms from the detected people boxes got by
%   runExampleSearch.m. Then, calculates the similaritys from the original
%   image and the image searched.

%% Load data

clear;

% Read the original image.
filesSuspects = getImagesInDir('./Dataset/Suspects/', true);

% Read the image searched.
files = getImagesInDir('./Dataset/Images/', true);
fprintf('Making the test for %d suspects in %d images.\n', length(filesSuspects), length(files));
%img = imread('./Images/Validation/IMG_9997.jpg');


annotFiles = getAnnotationsInDir('./Dataset/Images/', true);
annotFile = char(annotFiles(cont));
goodRects = load(annotFile);



% Read the original image.


for contSusp = 1 : length(filesSuspects)

    %% Running over the suspects
    imgOriginalFile = char(filesSuspects(contSusp));
    imgOriginal = imread(imgOriginalFile);

    fprintf('\nSuspect %d:\n', contSusp);
   
    clear bboxes1;
    clear bboxes2;
    
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
%         imgSave = img;
%         resultRects = runExampleSearch(img, cont);
%         img = imgSave;

        peopleDetector128x64 = vision.PeopleDetector('ClassificationModel','UprightPeople_128x64', 'ClassificationThreshold', 2.5, 'MergeDetections', false, 'WindowStride', [4,4]);
        [bboxes1, scores1] = peopleDetector128x64(img);
        peopleDetector96x48 = vision.PeopleDetector('ClassificationModel','UprightPeople_96x48', 'ClassificationThreshold', 2.5, 'MergeDetections', false, 'WindowStride', [4,4]);
        [bboxes2, scores2] = peopleDetector96x48(img);
        
        
        if (size(bboxes1)>0 | size(bboxes2)>0)
            if (size(bboxes1)>0 & size(bboxes2)>0) 
                img2 = insertObjectAnnotation(img,'rectangle',bboxes1,scores1);
                img3 = insertObjectAnnotation(img2,'rectangle',bboxes2,scores2);
                figure, imshow(img3)
            else
                if (size(bboxes1)>0)
                    img2 = insertObjectAnnotation(img,'rectangle',bboxes1,scores1);
                    figure, imshow(img2)
                else
                    img2 = insertObjectAnnotation(img,'rectangle',bboxes2,scores2);
                    figure, imshow(img2)
                end
            end
        else
            figure, imshow(img)
        end
        title('Detected people and detection scores');

        resultRects = [bboxes1;bboxes2];

        % Calculates the histogram for the original image.
        histLOriginal = imhist(imgOriginal(:,:,1));
        histAOriginal = imhist(imgOriginal(:,:,2));   
        histBOriginal = imhist(imgOriginal(:,:,3));

        % Calculates the histogram for all detected boxes.
        clear similarity;
        clear similarityMode;
        clear similarityDiscreteWeight;
        
        for j = 1 : size(resultRects, 1)
            rect = resultRects(j, :);

           
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
            
            %% Using Cossine to get the Similaritys
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
            
            %Searching for NAN and changing them to 0.
            if(isnan(likeness)~=1)
                similarity(j) = likeness;
            else
                similarity(j) = 0;
            end
            
            
            %% Using Mode to get the similaritys
            % Calculates de similaritys between the histograms using the
            % mode technique.
            modeL = 0;
            modeA = 0;
            modeB = 0;
            
            %Calculates the mode of the original image
            modeAOriginal = max(histA);
            modeBOriginal = max(histB);
            
            %Calculates the mode of all the other images
            modeA = max(histA);
            modeB = max(histB);
            
            %Calculates the relation between the plans A and B, for further
            %ponderation
            if(modeAOriginal>modeBOriginal)
                modeRatio = modeAOriginal/modeBOriginal;
                likenessMode = likenessA*modeRatio+likenessB;
            elseif(modeAOriginal<modeBOriginal)
                modeRatio = modeAOriginal\modeBOriginal;
                likenessMode = likenessB*modeRatio+likenessA;
            else
                likenessMode = likenessA+likenessB;
            end
            
            similarityMode(j) = likenessMode;
            
            %Searching for NAN and changing them to 0.
            if(isnan(likenessMode)~=1)
                similarityMode(j) = likenessMode;
            else
                similarityMode(j) = 0;
            end
            
            
            if (max(histA)>1.2*max(histB))
                likenessDiscreteWeight = likenessA*2;
            else
                if (max(histB)>1.2*max(histA))
                    likenessDiscreteWeight = likenessB*2;
                else
                    likenessDiscreteWeight = likenessA + likenessB;
                end
            end
            
            similarityDiscreteWeight(j) = likenessDiscreteWeight;
            
            %Searching for NAN and changing them to 0.
            if(isnan(likenessDiscreteWeight)~=1)
                similarityDiscreteWeight(j) = likenessDiscreteWeight;
            else
                similarityDiscreteWeight(j) = 0;
            end
        end 

        %Results matrix from the classical method
        [result, index] = sort(similarity(:), 'descend');
        bestIndex = index(1);

        %Results matrix from the mode method
        [resultMode, indexMode] = sort(similarityMode(:), 'descend');
        bestIndexMode = indexMode(1);

        %Results matrix from the mode method
        [resultDiscreteWeight, indexDiscreteWeight] = sort(similarityDiscreteWeight(:), 'descend');
        bestIndexDiscreteWeight = indexDiscreteWeight(1);
        
        %% Draw the best result

        %% Plot the histograms.

        % Cossine Technique.
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
        title('Top1 - L Histogram (Average)');
        subplot(3,2,4);
        imhist(img(x,y,2)); 
        title('Top1 - A Histogram (Average)');
        subplot(3,2,6);
        imhist(img(x,y,3));
        title('Top1 - B Histogram (Average)');

        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/Average/Histograms/test%d.png', contSusp, cont));

        % Mode Techinique
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

        %Results from the mode method
        rectMode = resultRects(bestIndexMode, :);
        if (rectMode(1)+rectMode(3)>img_size(1))
            xMode = rectMode(1):img_size(1);
        else
            xMode = rectMode(1):(rectMode(1)+rectMode(3));
        end
        if (rectMode(2)+rectMode(4)>img_size(2))
            yMode = rectMode(2):img_size(2);
        else
            yMode = rectMode(2):(rectMode(2)+rectMode(4));
        end
        subplot(3,2,2);
        imhist(img(xMode,yMode,1));
        title('Top1 - L Histogram (Mode)');
        subplot(3,2,4);
        imhist(img(xMode,yMode,2));   
        title('Top1 - A Histogram (Mode)');
        subplot(3,2,6);
        imhist(img(xMode,yMode,3));
        title('Top1 - B Histogram (Mode)');

        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/Mode/Histograms/test%d.png', contSusp, cont));

        
        % Discrete Weight Techinique
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

        %Results from the discrete weight method
        rectDiscreteWeight = resultRects(bestIndexDiscreteWeight, :);
        if (rectDiscreteWeight(1)+rectDiscreteWeight(3)>img_size(1))
            xDiscreteWeight = rectDiscreteWeight(1):img_size(1);
        else
            xDiscreteWeight = rectDiscreteWeight(1):(rectDiscreteWeight(1)+rectDiscreteWeight(3));
        end
        if (rectDiscreteWeight(2)+rectDiscreteWeight(4)>img_size(2))
            yDiscreteWeight = rectDiscreteWeight(2):img_size(2);
        else
            yDiscreteWeight = rectDiscreteWeight(2):(rectDiscreteWeight(2)+rectDiscreteWeight(4));
        end
        subplot(3,2,2);
        imhist(img(xDiscreteWeight,yDiscreteWeight,1));
        title('Top1 - L Histogram (DiscreteWeight)');
        subplot(3,2,4);
        imhist(img(xDiscreteWeight,yDiscreteWeight,2));   
        title('Top1 - A Histogram (DiscreteWeight)');
        subplot(3,2,6);
        imhist(img(xDiscreteWeight,yDiscreteWeight,3));
        title('Top1 - B Histogram (DiscreteWeight)');

        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/DiscreteWeight/Histograms/test%d.png', contSusp, cont));

        
        %Converting to RGB
        colorTransform = makecform('lab2srgb');
        img = applycform(img, colorTransform);
        imgOriginal = applycform(imgOriginal, colorTransform);

        %% Plot the comparing images

        % Cossine Techinique
        figure;
        subplot(1,3,1);
        imagesc(imgOriginal);
        title('Suspect');
        subplot(1,3,[2 3]);
        imagesc(img);
        title('Reidentification top 5 (Average)');
        hold on;
        plot(0,0,'r');
%         plot(0,0,'g');

        % Draw the results.
%         for i = 2:5
%             drawRectangle(resultRects(index(i), :), 'g');
%         end
        drawRectangle(resultRects(bestIndex, :), 'r');

        legend('Top 1', 'Top 2 to 5');

        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/Average/ImagesWithSuspect/test%d.png', contSusp, cont), '-native');

        % Mode Techinique
        figure;
        subplot(1,3,1);
        imagesc(imgOriginal);
        title('Suspect');
        subplot(1,3,[2 3]);
        imagesc(img);
        title('Reidentification top 5 (Mode)');
        hold on;
        plot(0,0,'r');
%         plot(0,0,'g');
% 
%         for i = 2:5
%             drawRectangle(resultRects(indexMode(i), :), 'g');
%         end
        drawRectangle(resultRects(bestIndexMode, :), 'r');

        legend('Top 1', 'Top 2 to 5');

        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/Mode/ImagesWithSuspect/test%d.png', contSusp, cont), '-native');


         % Discrete Weight Techinique
        figure;
        subplot(1,3,1);
        imagesc(imgOriginal);
        title('Suspect');
        subplot(1,3,[2 3]);
        imagesc(img);
        title('Reidentification top 5 (DiscreteWeight)');
        hold on;
        plot(0,0,'r');
%         plot(0,0,'g');
% 
%         for i = 2:5
%             drawRectangle(resultRects(indexMode(i), :), 'g');
%         end
        drawRectangle(resultRects(bestIndexDiscreteWeight, :), 'r');

        legend('Top 1', 'Top 2 to 5');

        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/DiscreteWeight/ImagesWithSuspect/test%d.png', contSusp, cont), '-native');

        %% Plot the result image

        % Cossine Technique
        figure;
        imagesc(img);
        title('Reidentification top 5 (Average)');
        hold on;
        plot(0,0,'r');
%         plot(0,0,'g');
% 
%         % Draw the results.
%         for i = 2:5
%             drawRectangle(resultRects(index(i), :), 'g');
%         end
        drawRectangle(resultRects(bestIndex, :), 'r');

        legend('Top 1', 'Top 2 to 5');
        
        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/Mode/Images/test%d.png', contSusp, cont), '-native');


        %Mode Technique
        figure;
        imagesc(img);
        title('Reidentification top 5 (Mode)');
        hold on;
        plot(0,0,'r');
%         plot(0,0,'g');
% 
%         % Draw the results.
%         for i = 2:5
%             drawRectangle(resultRects(indexMode(i), :), 'g');
%         end
        drawRectangle(resultRects(bestIndexMode, :), 'r');

        legend('Top 1', 'Top 2 to 5');
        
        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/Mode/Images/test%d.png', contSusp, cont), '-native');
       
        %Discrete Weight Technique
        figure;
        imagesc(img);
        title('Reidentification top 5 (DiscreteWeight)');
        hold on;
        plot(0,0,'r');
%         plot(0,0,'g');
% 
%         % Draw the results.
%         for i = 2:5
%             drawRectangle(resultRects(indexMode(i), :), 'g');
%         end
        drawRectangle(resultRects(bestIndexDiscreteWeight, :), 'r');

        legend('Top 1', 'Top 2 to 5');
        
        addpath('./export_fig/');
        export_fig(sprintf('./Test/Suspect%d/DiscreteWeight/Images/test%d.png', contSusp, cont), '-native');
       
        
     close all
        
    end   
    %end
end