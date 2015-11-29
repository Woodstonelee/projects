% summarize and generate stats of ASD spectra measurements from the
% given Excel file of data.
%
% Zhan Li <zhanli86@bu.edu>
% Wed Nov 18 23:32:28 EST 2015

in_excel_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101_20140710_lophostemon_notes.xlsx';
out_summary_file = '/projectnb/echidna/lidar/zhanli86/workspace/data/projects/brisbane-dual-wavelength-spectra/gold0101_20140710_lophostemon_summary.csv';

[meta_data, meta_txt, ~] = xlsread(in_excel_file, 'notes');
[spectra, spectra_txt, ~] = xlsread(in_excel_file, 'spectra');

tape_ids = [135, 183, 187, 247, 267];
mean_spectra = zeros(size(spectra, 1), length(tape_ids));
std_spectra = zeros(size(spectra, 1), length(tape_ids));

N = length(tape_ids);
for n=1:N
    tmp_id = tape_ids(n);
    row_idx = find(meta_data(:, 1) == tmp_id);

    select_idx = meta_data(row_idx, 5):meta_data(row_idx, 6);
    select_idx = select_idx(select_idx ~= meta_data(row_idx, 7));
    select_idx = select_idx + 2;
    mean_spectra(:, n) = mean(spectra(:, select_idx), 2);
    std_spectra(:, n) = std(spectra(:, select_idx), 0, 2);
end

fid = fopen(out_summary_file, 'w');
headerstr = sprintf(['wavelength,', repmat('tape_id_%d_mean,tape_id_%d_std,', 1, N-1), 'tape_id_%d_mean,tape_id_%d_std\n'], [tape_ids; tape_ids]);
fprintf(fid, headerstr);
out_data = zeros(size(mean_spectra, 1), 1+2*size(mean_spectra, 2));
out_data(:, 1) = spectra(:, 1);
for n=1:N
    out_data(:, 2*n) = mean_spectra(:, n);
    out_data(:, 2*n+1) = std_spectra(:, n);
end
fprintf(fid, ['%d,', repmat('%.6f,%.6f,', 1, N-1), '%.6f,%.6f\n'], out_data');
fclose(fid);

fig = figure();
colorstr = ['r', 'g', 'b', 'c', 'm'];
legendstr = cell(size(tape_ids));
for n=1:N
    xx = [(spectra(:, 1))', fliplr((spectra(:, 1))')];
    y1 = mean_spectra(:, n) - std_spectra(:, n);
    y2 = mean_spectra(:, n) + std_spectra(:, n);
    yy = [y1', fliplr(y2')];
    fill(xx, yy, colorstr(n), 'FaceColor', colorstr(n), 'FaceAlpha', 0.6, 'EdgeColor', colorstr(n));
    legendstr{n} = num2str(tape_ids(n));
    hold on;
end
legend(legendstr);
grid on;
[path, name, ~] = fileparts(out_summary_file);
export_fig([fullfile(path, name), '.png'], '-r300', '-painters', '-png', fig);