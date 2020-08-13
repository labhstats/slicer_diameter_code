function output_main_cells = deparse_mark_jason_slicer_4_11(working_BIDS_dir)
    %Deparses Slicer produced mrk.json files to collect diameter
    %measurements.
    %
    %Code works, but is nothing too sophisticated.
    %Alternative implementation can look in mrml files for diamters saved in Slicer.
    %%
    % Get the unique mrk.json locations.
    
    disp('-------------------')
    disp('Finding BIDS structure from input...')
    disp('-------------------')
    all_files = dir(working_BIDS_dir);    
    % Example path:
    % '/home/lars/Desktop/test_vasc/Vasculature/Testdata_aug_20_clean/*/3D_TOF/'
    
    n_files = length(all_files);
    
    all_folders = strings(n_files,1);
    
    for i = 1 :n_files
        all_folders(i,1) = all_files(i).folder;
    end
    all_folders = unique(all_folders);
    
    n_folders = length(all_folders);
    
    disp(all_folders);
    disp(n_folders);
    
    %%
    % For each n_files we must find each .mrk.json files, N => 1.
    disp('-------------------')
    disp('Finding mrk.json')
    disp('-------------------')
    
    %%
    % Storage cell
    n_storages = 3; %Change this depending on how many measurements there actually are in the data.
    output_main_cells = cell(0,n_storages + 1);
    
    for i = 1:n_folders
        %%
        % Append correct ending of file to find mrk.json
        curr_dir = all_folders(i);
        mrk_jsn_dir = fullfile(char(curr_dir),'*.mrk.json');
        
        disp(mrk_jsn_dir)
        
        mrk_jsn_files = dir(mrk_jsn_dir);
        
        disp(mrk_jsn_files)
        
        %%
        %Extract current ID.
        split_id_string = split(curr_dir,"/");
        cell_id_string = split_id_string(end-1,1); %Specifically chosen/hardcoded!
        current_ID_string = cell_id_string{1}; %To be paired with measurement.
        disp(['The current ID is: ' current_ID_string]);
        disp(['Number: ' string(i) ' of ' string(n_folders)]);
        
        %%
        % Extract each measurement
        n_mrk_json = length(mrk_jsn_files);
        
        new_store_measurments_i = cell(1,n_storages);
        
        z_coords = cell(1,n_mrk_json);
        
        for j = 1:n_mrk_json
            %%
            %Fullfiling the mrk.json files, so that it can be read.
            mj_j_folder = mrk_jsn_files(j).folder;
            mj_j_name = mrk_jsn_files(j).name;
            
            mj_fullpath = fullfile(char(mj_j_folder),char(mj_j_name));
            disp(mj_fullpath)
            
            %%
            %Decoding the json.
            fid = fopen(mj_fullpath);
            raw = fread(fid,inf);
            mrk_json_str = char(raw');
            fclose(fid);
            mrk_json_decoded = jsondecode(mrk_json_str);
            
            disp(mrk_json_decoded);
            
            %%
            %Extracting and calculating line length.
            
            %Only two points in a line.
            point_1 = mrk_json_decoded.markups.controlPoints(1).position;
            point_2 = mrk_json_decoded.markups.controlPoints(2).position;
            
            z_coords{1,j} = (point_1(3) + point_2(3))/2; 
            %Assumes that the line is measured in axial plane or at least with 
            %similar Z coordinates for each line for when the basilar is curving.
            
            disp(point_1);
            disp(point_2);
            
            delta_point = point_1 - point_2;
            line_length = norm(delta_point);
            
            disp(line_length);
            
            new_store_measurments_i{1,j} = line_length;
            
            disp(new_store_measurments_i);
            disp('-------Next mrk.json iter or end---------')
        end
        
        disp(z_coords);
        
        [~,idx_order] = sort(cell2mat(z_coords),'ascend'); 
        %Orientation: Lower order = Inferior, Higher order = Superior.
        
        idx_order = int2str(idx_order);
        idx_order_cell = cell(1,1);
        idx_order_cell{1,1} = idx_order;
        
        merge_cell_id_mms = horzcat(current_ID_string,new_store_measurments_i,idx_order_cell);
        disp(merge_cell_id_mms);
        
        output_main_cells = vertcat(output_main_cells,merge_cell_id_mms); %#ok<AGROW>
        
        disp('-------Next ID iter or end---------')
    end 
    
    %%
    % Ready to table
    output_main_cells = cell2table(output_main_cells);
    
end