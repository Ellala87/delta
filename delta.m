% Define the folder containing the files
folder_path = 'E:\IOLR\oct23-may24\OLCI data 2023\'; % Replace with the actual folder path

% Get a list of all files in the folder
file_list = dir(fullfile(folder_path, '*.txt')); % List of files matching the pattern

% Define the coordinates for the area of interest (polygonal area)
polygon_lat = Latitude; % Example latitude of polygon vertices
polygon_lon = Longitude; % Example longitude of polygon vertices

% Define the grid resolution (adjust as needed)
resolution = 0.005; % Example resolution (in degrees)

% Initialize a cell array to store data grids for each file
data_grids = cell(1, numel(file_list));

% Loop through each file
for i = 1:numel(file_list)
    % Load the data from the file
    file_name = file_list(i).name;
    file_path = fullfile(folder_path, file_name);
    file_data = readtable(file_path);
    
    % Extract CHL_NN data (assuming it's stored in a variable named 'CHL_NN')
    chl_nn_data = file_data{:, "CHL_NN"}; % Adjust accordingly based on how the data is stored
        
    lat = file_data{:, "latitude"}; % Example latitude
    lon = file_data{:, "longitude"};

    % Load elevation data
    elevation_data = elevation;
    elevation_lat = Lat;
    elevation_lon = Lon;

    % Determine which points fall within the polygonal area
    in_polygon = inpolygon(file_data.latitude, file_data.longitude, polygon_lat, polygon_lon);
    filtered_lat = file_data.latitude(in_polygon);
    filtered_lon = file_data.longitude(in_polygon);
    filtered_chl_data = chl_nn_data(in_polygon);

    % Generate the grid within the polygon
    [grid_lon, grid_lat] = meshgrid(min(filtered_lon):resolution:max(filtered_lon), ...
                                     min(filtered_lat):resolution:max(filtered_lat));
    
    % Initialize matrices to store CHL values for each grid cell
    chl_grid = NaN(size(grid_lon));
    
    % Assign CHL values to the corresponding grid cells
    for j = 1:numel(filtered_lat)
        % Find the indices of the closest grid cell to the current data point
        [~, idx_lon] = min(abs(grid_lon(1, :) - filtered_lon(j)));
        [~, idx_lat] = min(abs(grid_lat(:, 1) - filtered_lat(j)));
        
        % Assign the CHL values to the corresponding grid cell
        chl_grid(idx_lat, idx_lon) = filtered_chl_data(j);
    end

    % Convert chl_grid to a sparse matrix
    chl_grid_sparse = sparse(chl_grid);

    % Limit CHL data between 0 and 5
    chl_grid(chl_grid < 0) = 0; % Set values below 0 to 0
    chl_grid(chl_grid > 5) = 5; % Set values above 5 to 5

    % Save CHL grid to a file
    output_file_name = ['CHL_Sqr_M_', file_name(1:end-4), '.xlsx']; % Remove '.txt' extension
    xlswrite(fullfile(folder_path, output_file_name), chl_grid, 'sqt_m');

    disp(['CHL per Square Meter for ', file_name, ' has been calculated and saved.']);
end

% Loop through each file again to calculate delta between each file and the previous one
for i = 2:numel(file_list)
    % Load the CHL per square meter data from the current and previous files
    file_name_previous = file_list(i).name;
    file_name_next = file_list(i+1).name;
    
    output_file_next = ['CHL_Sqr_M_', file_name_next(1:end-4), '.xlsx'];
    output_file_previous = ['CHL_Sqr_M_', file_name_previous(1:end-4), '.xlsx'];
    
    data_grid_next = xlsread(fullfile(folder_path, output_file_next), 'sqt_m');
    data_grid_previous = xlsread(fullfile(folder_path, output_file_previous), 'sqt_m');

    % Interpolate the current grid onto the grid of the previous grid
    data_grid_next_interpolated = interp2(data_grid_next, 'linear');

    % Adjust the size of data_grid_current_interpolated to match data_grid_previous
    data_grid_next_interpolated_resized = imresize(data_grid_next_interpolated, size(data_grid_previous));

    % Calculate the delta between the two data grids
    delta_grid = data_grid_next_interpolated_resized - data_grid_previous;

        % Flip the delta grid upside down
        delta_grid_flipped = flipud(delta_grid);

        % Set 0 values to NaN
        delta_grid_flipped(delta_grid_flipped == 0) = NaN;

%         % Plot the flipped delta grid
%         figure;
%         imagesc(delta_grid_flipped);
%         colorbar;
%         title('Delta Grid');
%         xlabel('Latitude');
%         ylabel('Longitude');
%         axis equal;
%         colormap('jet');

        % Save the delta grid to a new file
%         output_delta_file = ['delta_', output_file_name(1:end-5), '_', next_output_file(1:end-5), '.xlsx'];
%         xlswrite(fullfile(folder_path, output_delta_file), delta_grid, 'Delta');
end
output_delta_file = ['delta_', output_file1(1:end-4), '_', output_file2(1:end-4), '.xlsx'];
xlswrite(fullfile(folder_path, output_delta_file), delta_grid, 'Delta');

        disp(['Delta between ', output_file_name, ' and ', next_output_file, ' has been calculated and saved.']);
    %ddjkfehsjfsf


