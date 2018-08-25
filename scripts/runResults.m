%runReidentification.m
%   Calculates the color histograms from the detected people boxes got by
%   runExampleSearch.m. Then, calculates the similaritys from the original
%   image and the image searched.

%% Load data
% Load the pre-configured and pre-trained HOG detector.
load('hog_model.mat');

clear;

% tic;
% timerVal = tic;

allsuspects = {'black1'; 'black2'; 'blue1'; 'blue2'; 'brown1'; 'brown2'; 'gray1'; 'gray2'; 'red1'; 'white1'; 'white2'; 'white3'; 'white4'; 'white5'; 'white6'; 'white7'; 'white8'; 'white9'}
maxSusp = size(allsuspects());
maxSusp = maxSusp(1);
lab = true;

for nsuspect = 1:maxSusp
    
    clear suspectFile;
    clear imgOriginal;
    clear annotFile;
    clear annotData;
    
    
    suspect = allsuspects(nsuspect,:);
    suspect = suspect{1};
    
     fprintf('\n\n%d - Making the test for %s \n', nsuspect, suspect);
    

    % Load the suspect image
    suspectFile = strcat('./Matches/Groundtruth/Suspeitos/', suspect, '.png');
    imgOriginal = imread(suspectFile);

    % What images to run
    annotFile = strcat('./Matches/Groundtruth/Suspeitos/', suspect, '.CSV');
    annotFile = fopen(annotFile);
    annotData = fscanf(annotFile, '%c');
    annotData = split(annotData, '|');

    % fprintf('Making the test for 1 suspect in %d images.\n', length(annotData));

    groundtruthData={};

    numTruePositivesAvg = 0;
    numFalsePositivesAvg = 0;
    numTruePositivesMode = 0;
    numFalsePositivesMode = 0;
    numTruePositivesDiscreteWeight = 0;
    numFalsePositivesDiscreteWeight = 0;
    numTruePositivesOnlyA = 0;
    numFalsePositivesOnlyA = 0;
    numTruePositivesOnlyB = 0;
    numFalsePositivesOnlyB = 0;

    % Read the image searched and the groundtruth.
    for cont = 1 : (length(annotData)-1)
        clear groundtruthFile;
        clear groundtruthAux;
        clear groundtruthNums;
        
        fprintf('\t\t%d/%d\n', cont, (length(annotData)-1));

        imageFile = strcat('./Matches/Groundtruth/Imagem/', char(annotData(cont)), '.png');
        img = imread(imageFile);
        groundtruthFile = strcat('./Matches/Groundtruth/Adaptado/', annotData(cont), '.CSV');
        groundtruthFile = fopen(groundtruthFile);
        groundtruthAux = fscanf(groundtruthFile, '%s');
        groundtruthNums = split(groundtruthAux, '|');


        clear bestIndex;
        clear bestIndexOnlyA;
        clear bestIndexOnlyB;
        clear bestIndexMode;
        clear bestIndexDiscreteWeight;

        clear groundtruthMatrix;
        for contJ = 1 : length(groundtruthNums)/5
            for contI = 1 : 5
                groundtruthMatrix(contJ, contI) = groundtruthNums((contJ-1)*5+contI);
            end
        end

        %% Running over the images 
        % Get the next filename.
        imgFile = img;

        % Print the current iteration (using some clever formatting to
        % overwrite).
    %     fprintf('\nImage %d:\n', cont);

        imgRGB = img;

        if (lab == true) 
            %Converting to LAB
            colorTransform = makecform('srgb2lab');
            img = applycform(img, colorTransform);
            imgOriginal = applycform(imgOriginal, colorTransform);
        end



    %     figure, imshow(imgOriginal);
    %     title('Suspeito - Espaco de Cores LAB')
    %         figure, imshow(img);
    %     title('Imagem - Espaco de Cores LAB');
    %     

        %% Calculates the color histograms and similaritys

        peopleDetector128x64 = vision.PeopleDetector('ClassificationModel','UprightPeople_128x64', 'ClassificationThreshold', 0, 'MergeDetections', false, 'WindowStride', [4,4]);
        [bboxes1, scores1] = peopleDetector128x64(img);
        peopleDetector96x48 = vision.PeopleDetector('ClassificationModel','UprightPeople_96x48', 'ClassificationThreshold', 0, 'MergeDetections', false, 'WindowStride', [4,4]);
        [bboxes2, scores2] = peopleDetector96x48(img);


        if (size(bboxes1)>0 | size(bboxes2)>0)
            if (size(bboxes1)>0 & size(bboxes2)>0) 
                img2 = insertObjectAnnotation(img,'rectangle',bboxes1,scores1);
                img3 = insertObjectAnnotation(img2,'rectangle',bboxes2,scores2);
%                  figure, imshow(img3)
            else
                if (size(bboxes1)>0)
                    img2 = insertObjectAnnotation(img,'rectangle',bboxes1,scores1);
%                      figure, imshow(img2)
                else
                    img2 = insertObjectAnnotation(img,'rectangle',bboxes2,scores2);
%                      figure, imshow(img2)
                end
            end
        else
    %         figure, imshow(img)
        end

    %     title('Detected people and detection scores');

        resultRects = [bboxes1;bboxes2];

        % Calculates the histogram for the original image.
        histLOriginal = imhist(imgOriginal(:,:,1));
        histAOriginal = imhist(imgOriginal(:,:,2));   
        histBOriginal = imhist(imgOriginal(:,:,3));

        % Calculates the histogram for all detected boxes.
        clear similarity;
        clear similarityMode;
        clear similarityDiscreteWeight;


        numFalsePositives = 0;
        numTruePositives = 0;

        groundtruthMatrixNum = str2double(groundtruthMatrix);

        clear rectsFound;
        numVisiblePeople = size(groundtruthMatrix,1);
        rectsFound = zeros(numVisiblePeople, 1);

        resultRects = [resultRects, zeros(size(resultRects, 1), 1)];

        seeImg = imgRGB;

        clear wanted;
        wanted = zeros(size(resultRects, 1));
        ind=1;
        clear indeces;

%         toc;
%         middle = toc;
        for j = 1 : size(resultRects, 1)


            rect = resultRects(j, :);

    %         for i = 1 : size(groundtruthMatrix, 1)
    %            ground = str2double(groundtruthMatrix(i,:));
    %            if (rect(1)>=ground(1)-20 && rect(2)>=ground(2)-20 && (rect(1)+rect(3))<=ground(1)+20 && (rect(2)+rect(4))<=ground(1)+20)
    %                positive=true
    %                break;
    %            else
    %                positive=false;
    %            end
    %         end
    %         
    %         if positive == false
    %             continue;
    %         end

            %for i = 1 : size(groundtruthMatrix,1)

            indeces = checkRectOverlap(resultRects(j, :), groundtruthMatrixNum(:,1:4), 0.5);

            % If we didn't find a match...
            if (isempty(indeces))
                % Indicate it's a bad result.
                resultRects(j, end) = 0;

                % Increment the number of false positives.
                numFalsePositives = numFalsePositives + 1;
                continue;
            else     
                 % For each of the matches...
                for i = 1 : length(indeces)

                    % Indicate we found this person.
                    if(rectsFound(indeces(i)) == 0)
                        % Indicate it's a good result.
                        resultRects(j, end) = 1;
                        rectsFound(indeces(i)) = 1;

                        % Increment the number of true positives.
                        numTruePositives = numTruePositives + 1;

                         seeImg = insertObjectAnnotation(seeImg,'rectangle',resultRects(j,1:4), indeces(i));
                         figure, imshow(seeImg)
                    else
                        if (rectsFound(indeces(i)) == 1)
                            resultRects(j, end) = -1;
                            break;
                        end
                    end

                    if (groundtruthMatrixNum(indeces(i),5) == 1)
                        wanted(ind) = j;
                        ind = ind + 1;
                    end
                end 
                if resultRects(j, end) == -1
                    continue;
                end
            end

    %     end
    %     
    %     for j = 1 : size(groundtruthMatrixNum, 1)
    %         
    %         rect = groundtruthMatrixNum(:,1:4);

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

            likenessOnlyA = 0*likenessL + 2*likenessA + 1*likenessB;
            differenceOnlyA = likenessOnlyA*100*2/(3*pi);
            likenessOnlyA = 100 - differenceOnlyA;

            %Searching for NAN and changing them to 0.
            if(isnan(likenessOnlyA)~=1)
                similarityOnlyA(j) = likenessOnlyA;
            else
                similarityOnlyA(j) = 0;
            end

            likenessOnlyB = 0*likenessL + 1*likenessA + 2*likenessB;
            differenceOnlyB = likenessOnlyB*100*2/(3*pi);
            likenessOnlyB = 100 - differenceOnlyB;

            %Searching for NAN and changing them to 0.
            if(isnan(likenessOnlyB)~=1)
                similarityOnlyB(j) = likenessOnlyB;
            else
                similarityOnlyB(j) = 0;
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
                likenessDiscreteWeight = likenessA*5+likenessB;
            else
                if (max(histB)>1.2*max(histA))
                    likenessDiscreteWeight = likenessB*5+likenessA;
                else
                    likenessDiscreteWeight = 3*likenessA + 3*likenessB;
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

        totalVisibleFound = sum(rectsFound);

    %     % Print the results.
    %     fprintf('Found %d / %d people (%.2f%%), with %d false positives.\n', ...
    %     totalVisibleFound, numVisiblePeople, ...
    %     totalVisibleFound / numVisiblePeople * 100.0, ...
    %     numFalsePositives);

        clear bestIndex;
        clear bestIndexOnlyA;
        clear bestIndexOnlyB;
        clear bestIndexMode;
        clear bestIndexDiscreteWeight;

        %Results matrix from the classical method
        if (exist('similarity'))
            [result, index] = sort(similarity(:), 'descend');
            bestIndex = index(1);
        else
            bestIndex = -1;
        end

        if (exist('similarityOnlyA'))
            [resultOnlyA, indexOnlyA] = sort(similarityOnlyA(:), 'descend');
            bestIndexOnlyA = indexOnlyA(1);
        else
            bestIndexOnlyA = -1;
        end

        if (exist('similarityOnlyB'))
            [resultOnlyB, indexOnlyB] = sort(similarityOnlyB(:), 'descend');
            bestIndexOnlyB = indexOnlyB(1);
        else
            bestIndexOnlyB = -1;
        end

        passed = false;
        for (i = 1:ind)
            if(bestIndex == wanted(i))
               numTruePositivesAvg = numTruePositivesAvg+1;
               passed = true;
            end
        end
        if (passed == false)
           numFalsePositivesAvg = numFalsePositivesAvg + 1;
        end

        passed = false;
        for (i = 1:ind)
            if(bestIndexOnlyA == wanted(i))
               numTruePositivesOnlyA = numTruePositivesOnlyA+1;
               passed = true;
            end
        end
        if (passed == false)
            numFalsePositivesOnlyA = numFalsePositivesOnlyA + 1;
        end

        passed = false;
        for (i = 1:ind)
            if(bestIndexOnlyB == wanted(i))
               numTruePositivesOnlyB = numTruePositivesOnlyB+1;
               passed = true;
            end
        end
        if (passed == false)
            numFalsePositivesOnlyB = numFalsePositivesOnlyB + 1;
        end

        %Results matrix from the mode method
        if (exist('similarityMode'))
            [resultMode, indexMode] = sort(similarityMode(:), 'descend');
            bestIndexMode = indexMode(1);
        else
            bestIndexMode = -1;
        end

        passed = false;
        for (i = 1:ind)
            if(bestIndexMode == wanted(i))
               numTruePositivesMode = numTruePositivesMode+1;
               passed = true;
            end
        end
        if (passed == false)
            numFalsePositivesMode = numFalsePositivesMode + 1;
        end

        %Results matrix from the mode method
        if (exist('similarityDiscreteWeight'))
            [resultDiscreteWeight, indexDiscreteWeight] = sort(similarityDiscreteWeight(:), 'descend');
            bestIndexDiscreteWeight = indexDiscreteWeight(1);
        else
            bestIndexDiscreteWeight = -1;
        end

        passed = false;
        for (i = 1:ind)
            if(bestIndexDiscreteWeight == wanted(i))
               numTruePositivesDiscreteWeight = numTruePositivesDiscreteWeight+1;
               passed = true;
            end
        end
        if (passed == false)
            numFalsePositivesDiscreteWeight = numFalsePositivesDiscreteWeight + 1;
        end

        %% Draw the best result

        %% Plot the histograms.

         if (bestIndex ~= -1) && (bestIndexMode ~= -1) && (bestIndexDiscreteWeight ~= -1)
%             % Cossine Technique.
%             figure;
%             subplot(3,2,1);
%             imhist(imgOriginal(:,:,1));
%             title('Suspeito - Histograma L');
%             subplot(3,2,3);
%             imhist(imgOriginal(:,:,2));
%             title('Suspeito - Histograma A');
%             subplot(3,2,5);
%             imhist(imgOriginal(:,:,3));
%             title('Suspeito - Histograma B');
% 
%             rect = resultRects(bestIndex, :);
%             img_size = size(img);
%             if (rect(1)+rect(3)>img_size(1))
%                 x = rect(1):img_size(1);
%             else
%                 x = rect(1):(rect(1)+rect(3));
%             end
%             if (rect(2)+rect(4)>img_size(2))
%                 y = rect(2):img_size(2);
%             else
%                 y = rect(2):(rect(2)+rect(4));
%             end
%             subplot(3,2,2);
%             imhist(img(x,y,1));
%             title('Top1 - Histograma L (Metodo 1)');
%             subplot(3,2,4);
%             imhist(img(x,y,2)); 
%             title('Top1 - Histograma A (Metodo 1)');
%             subplot(3,2,6);
%             imhist(img(x,y,3));
%             title('Top1 - Histograma B (Metodo 1)');
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/Average/Histograms/%s.png', suspect, char(annotData(cont))));
% 
%             % OnlyA Technique.
%             figure;
%             subplot(3,2,1);
%             imhist(imgOriginal(:,:,1));
%             title('Suspeito - Histograma L');
%             subplot(3,2,3);
%             imhist(imgOriginal(:,:,2));
%             title('Suspeito - Histograma A');
%             subplot(3,2,5);
%             imhist(imgOriginal(:,:,3));
%             title('Suspeito - Histograma B');
% 
%             rect = resultRects(bestIndexOnlyA, :);
%             img_size = size(img);
%             if (rect(1)+rect(3)>img_size(1))
%                 x = rect(1):img_size(1);
%             else
%                 x = rect(1):(rect(1)+rect(3));
%             end
%             if (rect(2)+rect(4)>img_size(2))
%                 y = rect(2):img_size(2);
%             else
%                 y = rect(2):(rect(2)+rect(4));
%             end
%             subplot(3,2,2);
%             imhist(img(x,y,1));
%             title('Top1 - Histograma L (Metodo 4)');
%             subplot(3,2,4);
%             imhist(img(x,y,2)); 
%             title('Top1 - Histograma A (Metodo 4)');
%             subplot(3,2,6);
%             imhist(img(x,y,3));
%             title('Top1 - Histograma B (Metodo 4)');
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/OnlyA/Histograms/%s.png', suspect, char(annotData(cont))));
% 
%             % OnlyB Technique.
%             figure;
%             subplot(3,2,1);
%             imhist(imgOriginal(:,:,1));
%             title('Suspeito - Histograma L');
%             subplot(3,2,3);
%             imhist(imgOriginal(:,:,2));
%             title('Suspeito - Histograma A');
%             subplot(3,2,5);
%             imhist(imgOriginal(:,:,3));
%             title('Suspeito - Histograma B');
% 
%             rect = resultRects(bestIndexOnlyB, :);
%             img_size = size(img);
%             if (rect(1)+rect(3)>img_size(1))
%                 x = rect(1):img_size(1);
%             else
%                 x = rect(1):(rect(1)+rect(3));
%             end
%             if (rect(2)+rect(4)>img_size(2))
%                 y = rect(2):img_size(2);
%             else
%                 y = rect(2):(rect(2)+rect(4));
%             end
%             subplot(3,2,2);
%             imhist(img(x,y,1));
%             title('Top1 - Histograma L (Metodo 5)');
%             subplot(3,2,4);
%             imhist(img(x,y,2)); 
%             title('Top1 - Histograma A (Metodo 5)');
%             subplot(3,2,6);
%             imhist(img(x,y,3));
%             title('Top1 - Histograma B (Metodo 5)');
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/OnlyB/Histograms/%s.png', suspect, char(annotData(cont))));
% 
% 
%             % Mode Techinique
%             figure;
%             subplot(3,2,1);
%             imhist(imgOriginal(:,:,1));
%             title('Suspeito - Histograma L');
%             subplot(3,2,3);
%             imhist(imgOriginal(:,:,2));
%             title('Suspeito - Histograma A');
%             subplot(3,2,5);
%             imhist(imgOriginal(:,:,3));
%             title('Suspeito - Histograma B');
% 
%             %Results from the mode method
%             rectMode = resultRects(bestIndexMode, :);
%             if (rectMode(1)+rectMode(3)>img_size(1))
%                 xMode = rectMode(1):img_size(1);
%             else
%                 xMode = rectMode(1):(rectMode(1)+rectMode(3));
%             end
%             if (rectMode(2)+rectMode(4)>img_size(2))
%                 yMode = rectMode(2):img_size(2);
%             else
%                 yMode = rectMode(2):(rectMode(2)+rectMode(4));
%             end
%             subplot(3,2,2);
%             imhist(img(xMode,yMode,1));
%             title('Top1 - Histograma L (Metodo 2)');
%             subplot(3,2,4);
%             imhist(img(xMode,yMode,2));   
%             title('Top1 - Histograma A (Metodo 2)');
%             subplot(3,2,6);
%             imhist(img(xMode,yMode,3));
%             title('Top1 - Histograma B (Metodo 2)');
% 
%             addpath('./export_fig/');    
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/Mode/Histograms/%s.png', suspect, char(annotData(cont))));
% 
% 
%             % Discrete Weight Techinique
            figure;
            subplot(3,2,1);
            imhist(imgOriginal(:,:,1));
            title('Suspeito - Histograma L');
            subplot(3,2,3);
            imhist(imgOriginal(:,:,2));
            title('Suspeito - Histograma A');
            subplot(3,2,5);
            imhist(imgOriginal(:,:,3));
            title('Suspeito - Histograma B');

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
            title('Top1 - Histograma L (Metodo 3)');
            subplot(3,2,4);
            imhist(img(xDiscreteWeight,yDiscreteWeight,2));   
            title('Top1 - Histograma A (Metodo 3)');
            subplot(3,2,6);
            imhist(img(xDiscreteWeight,yDiscreteWeight,3));
            title('Top1 - Histograma B ((Metodo 3)');

            addpath('./export_fig/');
            export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/MPR5x1/DiscreteWeight/Histograms/%s.png', suspect, char(annotData(cont))));

            if (lab == true)
                %Converting to RGB
                colorTransform = makecform('lab2srgb');
                img = applycform(img, colorTransform);
                imgOriginal = applycform(imgOriginal, colorTransform);
            end

            %% Plot the comparing images

%             % Cossine Techinique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndex, 1:4), 1);
%             subplot(1,3,1);
%             imagesc(imgOriginal);
%             title('Suspeito');
%             subplot(1,3,[2 3]);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (Metodo 1)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/Average/ImagesWithSuspect/%s.png', suspect, char(annotData(cont))), '-native');
% 
%             % OnlyA Techinique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndexOnlyA, 1:4), 1);
%             subplot(1,3,1);
%             imagesc(imgOriginal);
%             title('Suspeito');
%             subplot(1,3,[2 3]);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (Metodo 4)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/OnlyA/ImagesWithSuspect/%s.png', suspect, char(annotData(cont))), '-native');
% 
% 
%             % OnlyB Techinique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndexOnlyB, 1:4), 1);
%             subplot(1,3,1);
%             imagesc(imgOriginal);
%             title('Suspeito');
%             subplot(1,3,[2 3]);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (Metodo 5)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/OnlyB/ImagesWithSuspect/%s.png', suspect, char(annotData(cont))), '-native');
% 
% 
% 
%             % Mode Techinique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndexMode, 1:4), 1);
%             subplot(1,3,1);
%             imagesc(imgOriginal);
%             title('Suspeito');
%             subplot(1,3,[2 3]);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (Metodo 2)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/Mode/ImagesWithSuspect/%s.png', suspect, char(annotData(cont))), '-native');
% 
%              % Discrete Weight Techinique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndexDiscreteWeight, 1:4), 1);
%             subplot(1,3,1);
%             imagesc(imgOriginal);
%             title('Suspeito');
%             subplot(1,3,[2 3]);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (Metodo 3)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/DiscreteWeight/ImagesWithSuspect/%s.png', suspect, char(annotData(cont))), '-native');
% 
%             %% Plot the result image
% 
%             % Cossine Technique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndex, 1:4), 1);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (MS)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/Average/Images/%s.png', suspect, char(annotData(cont))), '-native');
% 
% 
%             % Cossine Technique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndexOnlyA, 1:4), 1);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (MPA)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/OnlyA/Images/%s.png', suspect, char(annotData(cont))), '-native');
% 
% 
%             % Cossine Technique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndexOnlyB, 1:4), 1);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (MPB)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/OnlyB/Images/%s.png', suspect, char(annotData(cont))), '-native');
% 
% 
%             %Mode Technique
%             figure;
%             seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndexMode, 1:4), 1);
%             imagesc(seeImg);
%             title('Top 1 - Reidentificacao (MPFE)');
%             hold on;
% 
%             addpath('./export_fig/');
%             export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/RGB/Mode/Images/%s.png', suspect, char(annotData(cont))), '-native');

            %Discrete Weight Technique
            figure;
            seeImg = insertObjectAnnotation(img,'rectangle',resultRects(bestIndexDiscreteWeight, 1:4), 1);
            imagesc(seeImg);
            title('Top 1 - Reidentificacao (MPR)');
            hold on;

            addpath('./export_fig/');
            export_fig(sprintf('./Matches/Groundtruth/Resultados/%s/MPR5x1/DiscreteWeight/Images/%s.png', suspect, char(annotData(cont))), '-native');
%             close all
         end

%          close all
    end

end
% toc;
% final = toc;
% 
% fprintf('\n\n\nAverage technique reidetificated %d/%d people with %d false positives. \n', numTruePositivesAvg, length(annotData)-1, numFalsePositivesAvg);
% fprintf('Mode technique reidetificated %d/%d people with %d false positives. \n', numTruePositivesMode, length(annotData)-1, numFalsePositivesMode);
% fprintf('Discrete technique reidetificated %d/%d people with %d false positives. \n', numTruePositivesDiscreteWeight, length(annotData)-1, numFalsePositivesDiscreteWeight);
% fprintf('Only A technique reidetificated %d/%d people with %d false positives. \n', numTruePositivesOnlyA, length(annotData)-1, numFalsePositivesOnlyA);
% fprintf('Only B technique reidetificated %d/%d people with %d false positives. \n', numTruePositivesOnlyB, length(annotData)-1, numFalsePositivesOnlyB);