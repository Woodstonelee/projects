% Subtract ground level from an input point cloud by using a DEM
% file. 
% 
% Zhan Li <zhanli86@bu.edu>
% Tue Nov 17 10:58:46 EST 2015

% % input point cloud file
% in_pts_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/Aug3_BFP_tape_id_135.txt';
% % input DEM for ground level position
% dem_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/Aug3_BFP_Merged_Cube_NadirCorrect_Aligned_dual_cube_bsfix_pxc_update_atp2_ptcl_points_xyz_ground_edited.dem';


% output point cloud file with ground level subtracted
[pathname, filename, ext] = fileparts(in_pts_file);
out_pts_file = [fullfile(pathname, [filename, '_grd_rm']), ext];

% read DEM data
fid = fopen(dem_file, 'r');
data=textscan(fid, '%s %f', 6);
deminfo=data{1, 2};
formatstr = repmat('%f ', 1, deminfo(1));
data=textscan(fid,formatstr);
dem=cell2mat(data);
dem=flipud(dem);
fclose(fid);
clear data;

% read input point cloud
formatstr = [repmat('%f ', 1, 5), repmat('%d ', 1, 3), repmat('%f ', ...
                                                  1, 3), repmat('%d ', ...
                                                  1, 2), repmat('%f ', ...
                                                  1, 2), repmat('%d ', ...
                                                  1, 5)];
fid = fopen(in_pts_file, 'r');
% //X,Y,Z,d_I_nir,d_I_swir,return_number,number_of_returns,shot_number,range,theta,phi,sample,line,fwhm_nir,fwhm_swir,qa,scan_id,R,G,B
tree_pts = textscan(fid, repmat('%f', 1, 20), 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);
fid = fopen(in_pts_file, 'r');
headerstr = fgetl(fid);
fclose(fid);

pts_x = tree_pts{1};
pts_y = tree_pts{2};
pts_z = tree_pts{3};

N = length(pts_x);
for i = 1 : N;
    xpix = fix( ( pts_x(i) - deminfo(3) ) / deminfo(5) ) + 1;
    ypix = fix( ( pts_y(i) - deminfo(4) ) / deminfo(5) ) + 1;

    if xpix > 0 && xpix <= deminfo(1) && ypix > 0 && ypix <= deminfo(2) && dem(ypix, xpix)~=deminfo(6)
        pts_z(i) = pts_z(i) - dem(ypix, xpix);
    end
end

tree_pts{3} = pts_z;
outfid = fopen(out_pts_file, 'w');
fprintf(outfid, '%s\n', headerstr);
fprintf(outfid, [strjoin(strsplit(strtrim(formatstr)), ','), '\n'], (cell2mat(tree_pts))');
fclose(outfid);
