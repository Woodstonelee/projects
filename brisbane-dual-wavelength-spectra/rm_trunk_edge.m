% Remove returns from trunk edges (partial hits) by checking (1) the
% azimuth angles of returns in a slice of points, and (2) the number
% of returns.
% 
% Zhan Li <zhanli86@bu.edu>
% Tue Nov 17 14:52:15 EST 2015

function rm_trunk_edge(trk_pts_file, out_trk_pts_file)
% clear;
% trk_pts_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/grd-rm/trunk-extraction/Aug3_BFP_tape_id_183_grd_rm_trk.txt';
% out_trk_pts_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101-dwel-data/gold0101-dwel-data-pts/grd-rm/trunk-extraction/Aug3_BFP_tape_id_183_grd_rm_trk_edge_rm.txt';

% ID of scan locations to be used
scan_id = 1;
% scanning resolution
ang_step = radtodeg(2e-3);
% buffer zone to be extracted from trunk center (average azimuth
% angular location)
ang_buffer = ang_step*10;

% read points
fid = fopen(trk_pts_file, 'r');
trk_pts = textscan(fid, repmat('%f', 1, 20), 'HeaderLines', 1, 'Delimiter', ',');
fclose(fid);
trk_pts = cell2mat(trk_pts);
% column indexes to the attributes of each point used here.
num_returns_idx = 7; % number of returns in a waveform where a point is extracted from
zenith_idx = 10; % zenith angle, in unit of degree
az_idx = 11; % azimuth angle, in unit of degree
scan_id_idx = 17; % ID of scan location from which a point is extracted

% remove points from waveforms that have multiple returns
pts_mask = trk_pts(:, num_returns_idx) == 1 & trk_pts(:, scan_id_idx) == scan_id;
trk_pts = trk_pts(pts_mask, :);

% sort points according to zenith angles
[sort_zenith, sort_idx] = sort(trk_pts(:, zenith_idx));
num_pts = length(sort_idx);
tmp_start = 1;
tmp_end = 1;
% flag each point in or out
in_mask = false(size(sort_idx));
for n=1:num_pts
    if sort_zenith(n) > sort_zenith(tmp_end) + ang_step
        tmp_end = n-1;
        tmp_seq = sort_idx(tmp_start:tmp_end);
        tmp_az = trk_pts(tmp_seq, az_idx);
        if max(tmp_az) - min(tmp_az) > 180.0
            tmp_mask = tmp_az<180.0;
            tmp_az(tmp_mask) = tmp_az(tmp_mask) + 360.0;
        end
        mean_az = mean(tmp_az);
        tmp_mask = tmp_az > mean_az - ang_buffer & tmp_az < mean_az + ang_buffer;
        in_mask(tmp_seq(tmp_mask)) = true;

        tmp_start = n;
        tmp_end = n;
    end
end

% read input point cloud
formatstr = [repmat('%f ', 1, 5), repmat('%d ', 1, 3), repmat('%f ', ...
                                                  1, 3), repmat('%d ', ...
                                                  1, 2), repmat('%f ', ...
                                                  1, 2), repmat('%d ', ...
                                                  1, 5)];
fid = fopen(trk_pts_file, 'r');
headerstr = fgetl(fid);
fclose(fid);
outfid = fopen(out_trk_pts_file, 'w');
fprintf(fid, '%s\n', headerstr);
fprintf(outfid, [strjoin(strsplit(strtrim(formatstr)), ','), '\n'], (trk_pts(in_mask, :))');
fclose(outfid);