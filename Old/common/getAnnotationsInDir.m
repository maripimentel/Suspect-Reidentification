function fileList = getAnnotationsInDir(annotDir, addDir)
% GETANNOTATIONSINDIR Retrieves a list of the annotations files in the specified 
%    directory.
%
%    The annotations files are returned as a cell array of strings. 
%    The files are just the filename (no path) unless addDir = true.

    % Get the data for the directory.
    dirData = dir(annotDir);

    % Get the indeces of any directories.
    dirIndex = [dirData.isdir];  

    % Get the list of files.
    initList = {dirData(~dirIndex).name};

    fileList = {};
    
    annotNum = 1;
    
    % For each file in the directory...
    for i = 1 : length(initList)
    
        % Get the next filename.
        annotFile = char(initList(i));

        % Grab the filename's extension.
        if (length(annotFile) <= 3)
            continue;
        else
            extension = annotFile((length(annotFile) - 2) : length(annotFile));
        end
        
        % If this is an image file...
        if (strcmp(extension, 'csv') == 1) || ...
           (strcmp(extension, 'CSV') == 1) 
        
            % Add the path if requested.
			if (addDir == true)
				annotFile = strcat(annotDir, annotFile);
            end
            
            % Add the file to the output list.
			fileList{annotNum} = annotFile;
			
            annotNum = annotNum + 1;
        end
    end
end