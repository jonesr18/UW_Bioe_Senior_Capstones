classdef Imports < handle
    % A functional class for importing data and images from fast halo assays and comet assays.
    %
    %   Methods (static):
    %
    %       cometData    - Imports data from a standard comet assay data file.
    %       haloData     - Imports data from a standard fast halo assay data file.
    %       learningData - Imports learning data from a directory selected by the user.
    %       images       - Runs a GUI to import one or multiple images.
    %
    %   A handle to this object can be created as such:
    %
    %       in = Imports();
    %
    %
    % Copyright (C) 2014 Ross Jones, Singh Laboratory, University of Washington
    % 
    % Contact: jonesr18@gmail.com
    % 
    % This program is free software: you can redistribute it and/or modify it under the terms of the
    % GNU General Public License as published by the Free Software Foundation, either version 3 of 
    % the License, or (at your option) any later version.
    % 
    % This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    % without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    % See the GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along with this program. If
    % not see http://www.gnu.org/licenses/gpl.html
    % 
    % Updated 8.6.14
    
    methods (Static)
    %% public static double, double, <string> cometData(<string>)
        function [data, stats, varargout] = cometData(varargin)
            % Imports data from a standard comet assay data file. This method is static and thus can
            % be invoked without first creating a handle by calling Imports.cometData(...).
            % 
            %   For an Imports object with handle 'in':
            %
            %   [data, stats] = in.cometData()
            %
            %       Returns the collective data and stats for each cell as a matrix of doubles.
            %
            %   [data, stats, labels] = in.cometData()
            %
            %       Returns the labels for each metric as a cell array of strings. Elements match
            %       with the corresponding columns in data and stats.
            %
            %   [data, stats, labels, statLabels] = in.cometData()
            %
            %       Returns labels for the stats matrix as a cell array of strings. Elements match
            %       with the corresponding rows in stast.
            %
            %   [data, stats, ...] = in.cometData(filename)
            %
            %       Loads the CSV file in the current working directory with the given name (can but
            %       does not need to specify ".csv" at the end). Omitting this parameter will cause 
            %       a window to open to select a file. 
            
            % Check inputs
            filename = parseInputs(varargin{:});

            % Import file -- each file is a different treatment group
            fileID = fopen(filename, 'rt');
            while true
                line = regexp(fgetl(fileID), ',', 'split');
                if strcmp(line{1}, 'Select all [pixels]')
                    labels = line(6 : end - 1);
                    break
                end
            end

            % Extract raw data from file
            i = 0;
            while true
                i = i + 1;
                line = fgetl(fileID);
                if ischar(line)
                    raw(i, :) = regexp(line, ',', 'split'); %#ok<AGROW>
                else
                    break
                end
            end

            % Extract information from raw data
            statLabels = raw(1:5, 1);
            data = cellStr2mat(raw(7:end, 6 : end - 1));
            stats = cellStr2mat(raw(1:5, 6 : end - 1));

            varargout = {labels, statLabels};
            fclose(fileID);
        end
        
    %% public static double, double, <string> haloData(<string>)
        function [data, stats, varargout] = haloData(varargin)
            % Imports data from a standard fast halo assay data file. This method is static and thus
            % can be invoked without first creating a handle by calling Imports.cometData(...).
            %
            %   This method can be invoked to import both classification and damage data files, it
            %   will automatically determine which the user is importing.
            % 
            %   For an Imports object with handle 'in':
            %
            %   [data, stats] = in.haloData()
            %
            %       Returns the collective data and stats for each cell as a matrix of doubles.
            %
            %   [data, stats, labels] = in.haloData()
            %
            %       Returns the labels for each metric as a cell array of strings. Elements match
            %       with the corresponding columns in data and stats.
            %
            %   [data, stats, labels, statLabels] = in.haloData()
            %
            %       Returns labels for the stats matrix as a cell array of strings. Elements match
            %       with the corresponding rows in stast.
            %
            %   [data, stats, ...] = in.haloData(filename)
            %
            %       Loads the CSV file in the current working directory with the given name (can but
            %       does not need to specify ".csv" at the end). Omitting this parameter will cause 
            %       a window to open to select a file. 
            
            % Check inputs
            filename = parseInputs(varargin{:});

            % Import file -- each file is a different treatment group
            fileID = fopen(filename, 'rt');
            while true
                line = regexp(fgetl(fileID), ',', 'split');
                if strcmp(line{1}, 'Image #')
                    labels = line(3 : end);
                    break
                end
            end
            
            % Determine if classification of damage data
            if any(strcmpi(labels, {'apoptotic'}));
                numStatRows = 2;    % Classification data has 'num' and '%' stats
            else
                numStatRows = 3;    % Damage data has 'mean', 'stdev' and 'SEM' stats
            end
            
            % Extract raw data from file
            i = 0;
            j = 0;
            while true
                i = i + 1;
                line = fgetl(fileID);
                if ischar(line)
                    raw(i, :) = regexp(line, ',', 'split'); %#ok<AGROW>
                    if ~isempty(strfind(line, 'Cell'));
                        j = j + 1;
                        indices(j) = i; %#ok<AGROW>
                    end
                else
                    break
                end
            end
            
            % Extract information from raw data
            data = cellStr2mat(raw(indices, 3:end));
            stats = cellStr2mat(raw(1:numStatRows, 3:end));
            statLabels = raw(1:numStatRows, 2);

            varargout = {labels, statLabels};
            fclose(fileID);
        end
        
    %% public static double, cell, <double> learningData(string)
        function [data, answers, varargout] = learningData(dataType)
            % Imports learning data from a directory selected by the user. This method is static and
            % thus can be invoked without first creating a handle by calling Imports.cometData(...).
            %
            %   For an Imports object with handle 'in':
            %
            %   [data, answers] = learningData(dataType)
            %
            %       Returns the data and answers from the learning dataset selected by the user via
            %       a folder selection GUI and specified with the string dataType. Data is an NxM
            %       array, where N is the number of observations and M is a variable for magSpec
            %       and 100 for both allbins and innerbins, corresponding with the reshaped (and 
            %       potentially averaged) parts of the magnitude spectrum.
            %
            %       Datatype can be any of the following:
            %
            %           'magspec'   - Use selected frequencies from the magnitude spectrum
            %           'allbins'   - Use all frequencies binned into 100 average magnitudes
            %           'innerbins' - Use just low frequencies binned into 100 average magnitudes
            %
            %   [data, answers, freqCoords] = learningData(dataType)
            %
            %       Returns the coordinates of selected frequencies in freqCoords. If dataType is
            %       set to 'magspec', then freqCoords will be a Nx1 vector of points; otherwise, it
            %       will be left empty.
            
            % Let user select directory of data
            datapath = uigetdir(pwd, 'Learning Dataset Directory');
            
            % Get desired data type filename
            switch dataType
                case 'magspec'
                    filename = 'Selected Freqs';
                    freqCoords = 'Frequency Coords';
                case 'allbins'
                    filename = 'All Freq Bins';
                    freqCoords = [];
                case 'innerbins'
                    filename = 'Inner Freq Bins';
                    freqCoords = [];
            end
            
            % Extract raw data from file
            fileID1 = fopen(strcat(datapath, '\', filename, '.csv'), 'rt');
            fileID2 = fopen(strcat(datapath, '\Answers.csv'), 'rt');
            i = 0;
            fprintf(1, 'Loaded file: %s\n', fgetl(fileID1));
            fprintf(1, 'Loaded file: %s\n', fgetl(fileID2));
            while true
                i = i + 1;
                line = fgetl(fileID1);
                lineAns = fgetl(fileID2);
                if ischar(line) && ischar(lineAns)
                    raw(i, :) = regexp(line, ',', 'split');    %#ok<AGROW>
                    rawAns(i, :) = regexp(lineAns, ',', 'split'); %#ok<AGROW>
                elseif ~ischar(line) && ~ischar(lineAns)
                    break
                else
                    error('The input files %s and %s do not have the same number of lines.',...
                        strcat(filename, '.csv'), 'Answers.csv')
                end
            end
            fclose(fileID1);
            fclose(fileID2);
            
            % Load frequency coordinates if requested
            if ~isempty(freqCoords)
                fileID3 = fopen(strcat(datapath, '\', freqCoords, '.csv'), 'rt');
                i = 0;
                fprintf(1, 'Loaded file: %s\n', fgetl(fileID3));
                while true
                    i = i + 1;
                    line = fgetl(fileID3);
                    if ischar(line)
                        rawFC(i, :) = regexp(line, ',', 'split'); %#ok<AGROW>
                    else
                        break
                    end
                end
                fclose(fileID3);
            end
            
            % Extract information from raw data
            data = cellStr2mat(raw);
            answers = rawAns;
            if ~isempty(freqCoords)
                freqCoords = cellStr2mat(rawFC);
            end
            
            varargout = {freqCoords};
        end
        
    %% public static cell imArray()
        function imArray = images()
            % Runs a GUI to import one or multiple images. This method is static and thus can be
            % invoked without first creating a handle by calling Imports.cometData(...).
            % 
            %   For an Imports object with handle 'in':
            %
            %   imArray = in.images()
            %
            %       Returns a 1xN cell array where N is the number of files selected. Each element
            %       of the array is an image pre-processed with gaussian and average filters. No 
            %       arguments are accepted as input, the user can select one or more images from
            %       the same directory using the GUI that pops up. 
            
            % Run GUI to select file(s)
            [files, filePath] = uigetfile('*.jpeg; *.png; *.gif; *.tif', 'Pick image file(s)',...
                                          'MultiSelect', 'on');
            
            % Creates cell array of images
            if iscell(files)
                numFiles = numel(files);
                imArray = cell(1, numFiles);
                for i = 1:numFiles
                    image_i = rgb2gray(imread(fullfile(filePath, files{i})));
                    imArray{i} = imfilter(imfilter(image_i, fspecial('gaussian')), fspecial('average'));
                end
            else
                image = rgb2gray(imread(strcat(filePath, files)));
                imArray = {imfilter(imfilter(image, fspecial('gaussian')), fspecial('average'))};
            end
        end
        
    end
end

function filename = parseInputs(varargin)
    % Parses input text to make sure it is represents a valid CSV file. If no file name is
    % specified, opens a GUI to select one.
    
    narginchk(0, 1);
    if nargin > 0
        % Process filename if given
        filename = varargin{1};
        validateattributes(filename, {'char'}, {}, mfilename, 'filename', 1);
        if ~strcmp(filename(end - 4 : end), '.csv')
            filename = [filename, '.csv'];
        end
    else
        % Open GUI to select file otherwise
        [file, pathname] = uigetfile('*.csv', 'Pick file(s)', 'MultiSelect', 'off');
        filename = [pathname, file];
    end
    if ~exist(filename, 'file')
        error('File does not exist in current directory: %s', filename)
    end
end

function matrix = cellStr2mat(cellArray)
    % Converts a cell array of strings that are numbers to a MATLAB array of numbers.
    
    [H, W] = size(cellArray);
    matrix = zeros(H, W);
    for i = 1:H
        for j = 1:W
            matrix(i, j) = str2double(cellArray{i, j});
        end
    end
end