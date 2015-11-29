% Extract the trunk returns at DBH height from a single-tree point cloud. 

% Zhan Li <zhanli86@bu.edu>
% Thu Nov 12 15:50:08 EST 2015

function layer_stats = trunk_dual_intensity(single_tree_pts_file, out_profile_file, dem_file)

% single_tree_pts_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/Aug3_BFP_tape_id_135.txt';
% out_profile_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/processed/Aug3_BFP_tape_id_135_trk_summary.txt';
% % input DEM for ground level position
% dem_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/Aug3_BFP_Merged_Cube_NadirCorrect_Aligned_dual_cube_bsfix_pxc_update_atp2_ptcl_points_xyz_ground_edited.dem';

switch nargin
    case 2
      dem_file = '';
end

% the thickness of slices to check the height profile of return intensity
layer_thickness = 0.2;
scan_id = [1];
min_pts_num = 5; % minumum number of points to calculate the mean and std. 

% set the lower and upper heights of the layer to be extracted
layer_lb = 1.6;
layer_ub = 2.2;

% read input point cloud
fid = fopen(single_tree_pts_file, 'r');
% //X,Y,Z,d_I_nir,d_I_swir,return_number,number_of_returns,shot_number,range,theta,phi,sample,line,fwhm_nir,fwhm_swir,qa,scan_id,R,G,B
tree_pts = textscan(fid, repmat('%f ', 1, 20), 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);

pts_x = tree_pts{1};
pts_y = tree_pts{2};
pts_z = tree_pts{3};
pts_cal_int_nir = tree_pts{4}*1e-3;
pts_cal_int_swir = tree_pts{5}*1e-3;
pts_qa = tree_pts{16};
pts_scan_id = tree_pts{17};
pts_rg = tree_pts{9};
pts_zen = tree_pts{10};

min_z = min(pts_z);
max_z = min_z + 0.5 * (max(pts_z)-min_z);

% if DEM file is given, remove ground level from the points
if ~isempty(dem_file)
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
    % average location of trunk points as the trunk center
    tmp_mask = pts_z >= min_z & pts_z < max_z;
    mean_x = mean(pts_x(tmp_mask));
    mean_y = mean(pts_y(tmp_mask));
    % get the ground position from the DEM
    xpix = fix( ( mean_x - deminfo(3) ) / deminfo(5) ) + 1;
    ypix = fix( ( mean_y - deminfo(4) ) / deminfo(5) ) + 1;
    if xpix > 0 && xpix <= deminfo(1) && ypix > 0 && ypix <= deminfo(2) ...
            && dem(ypix, xpix)~=deminfo(6)
        ground_z = dem(ypix, xpix);
    else
        ground_z = 0;
    end
    % remove ground from points
    pts_z = pts_z - ground_z;
    min_z = min_z - ground_z;
    max_z = max_z - ground_z;
end

% calculate NDI of each point
pts_ndi = (pts_cal_int_nir - pts_cal_int_swir) ./ (pts_cal_int_nir + pts_cal_int_swir);

% get stats of the given layer
tmp_mask = pts_z>=layer_lb & pts_z<layer_ub;
tmp_mask = tmp_mask & ismember(pts_scan_id, scan_id) & pts_qa==0;
% layer stats: num_pts, mean_rg, std_rg, min_nir, max_nir, mean_nir, std_nir, min_swir,
% max_swir, mean_swir, std_swir, min_ndi, max_ndi, mean_ndi, std_ndi
layer_stats = [sum(tmp_mask), ...
               mean(pts_rg(tmp_mask)), std(pts_rg(tmp_mask)), ...
               min(pts_cal_int_nir(tmp_mask)), max(pts_cal_int_nir(tmp_mask)), ...
               mean(pts_cal_int_nir(tmp_mask)), std(pts_cal_int_nir(tmp_mask)), ...
               min(pts_cal_int_swir(tmp_mask)), max(pts_cal_int_swir(tmp_mask)), ...
               mean(pts_cal_int_swir(tmp_mask)), std(pts_cal_int_swir(tmp_mask)), ...
               min(pts_ndi(tmp_mask)), max(pts_ndi(tmp_mask)), ...
               mean(pts_ndi(tmp_mask)), std(pts_ndi(tmp_mask)), ...
               mean(abs(cos(degtorad(pts_zen(tmp_mask))))), std(abs(cos(degtorad(pts_zen(tmp_mask))))), ...
               min(pts_zen(tmp_mask)), max(pts_zen(tmp_mask)), mean(pts_zen(tmp_mask)), std(pts_zen(tmp_mask)), ...
               ];

% get the dual intensities at different trunk heights
bin_ctr = min_z+layer_thickness*0.5:layer_thickness:max_z-layer_thickness*0.5;
mean_int_nir = zeros(size(bin_ctr));
mean_int_swir = zeros(size(bin_ctr)); 
mean_ndi = zeros(size(bin_ctr));
mean_z = zeros(size(bin_ctr));
std_int_nir = zeros(size(bin_ctr));
std_int_swir = zeros(size(bin_ctr)); 
std_ndi = zeros(size(bin_ctr));
std_z = zeros(size(bin_ctr));
num_pts = zeros(size(bin_ctr));
for n = 1:length(bin_ctr)
  z_lower = bin_ctr(n)-layer_thickness*0.5;
  z_upper = bin_ctr(n)+layer_thickness*0.5;
  tmp_mask = pts_z>=z_lower & pts_z<z_upper;
  tmp_mask = tmp_mask & ismember(pts_scan_id, scan_id) & pts_qa==0;

  num_pts(n) = sum(tmp_mask);
  if num_pts(n) < min_pts_num
    continue;
  end

  mean_int_nir(n) = mean(pts_cal_int_nir(tmp_mask));
  mean_int_swir(n) = mean(pts_cal_int_swir(tmp_mask));
  mean_ndi(n) = mean(pts_ndi(tmp_mask));
  mean_z(n) = mean(pts_z(tmp_mask));

  std_int_nir(n) = std(pts_cal_int_nir(tmp_mask));
  std_int_swir(n) = std(pts_cal_int_swir(tmp_mask));
  std_ndi(n) = std(pts_ndi(tmp_mask));
  std_z(n) = std(pts_z(tmp_mask));
end

% write output summary
fid = fopen(out_profile_file, 'w');
ofprintf(fid, 'num_pts, mean_z, std_z, mean_cal_int_nir, std_cal_int_nir, mean_cal_int_swir, std_cal_int_swir, mean_ndi, std_ndi\n');
fprintf(fid, [repmat('%.3f, ', 1, 8), '%.3f\n'], [num_pts; mean_z; std_z; mean_int_nir; std_int_nir; mean_int_swir; std_int_swir; mean_ndi; std_ndi]);
fclose(fid);

% plot
[pathname, name, ~] = fileparts(out_profile_file);
fig = figure('Name', name);
subplot(1, 3, 1);
errorbarxy(mean_int_nir, mean_z, std_int_nir, zeros(size(std_z)), ...
           {'.k', 'r', 'r'});
xlabel('NIR app. refl.');
ylabel('Height, m');
subplot(1, 3, 2);
errorbarxy(mean_int_swir, mean_z, std_int_swir, zeros(size(std_z)), ...
           {'.k', 'r', 'r'});
xlabel('SWIR app. refl.');
ylabel('Height, m');
title(name, 'Interpreter', 'none');
subplot(1, 3, 3);
errorbarxy(mean_ndi, mean_z, std_ndi, zeros(size(std_z)), {'.k', 'r', ...
                   'r'});
xlabel('NDI');
ylabel('Height, m');

export_fig([fullfile(pathname, name), '.png'], '-png', '-r300', '-painters', fig);