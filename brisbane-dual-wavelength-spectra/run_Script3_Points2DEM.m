% Set up file names of inputs and outputs and parameters to run
% Script3_Points2DEM. 
% 
% Zhan Li <zhanli86@bu.edu>
% Tue Nov 17 09:26:45 EST 2015

GroundPtsPathName = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts';
GroundPtsFileName = 'Aug3_BFP_Merged_Cube_NadirCorrect_Aligned_dual_cube_bsfix_pxc_update_atp2_ptcl_points_xyz_ground_edited.txt';
% files to output
demfilename = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/Aug3_BFP_Merged_Cube_NadirCorrect_Aligned_dual_cube_bsfix_pxc_update_atp2_ptcl_points_xyz_ground_edited.dem';
% parameters to input
cellsize = 0.2; % resolution of DEM, unit: same with input points
nodata = -9999; % the value of no data
maxTINedgelen = 10; % the maximum length of boundary edges of
% TIN, unit: same with input points
% Whether to fill the nodata area in the DEM from TIN with RANSAC fitting.
fill_nodata = true;
cal_extent = true;

cmd = ['/usr3/graduate/zhanli86/Programs/TIES-TLS/' ...
       'Script3_Points2DEM.m'];
run(cmd);