% Tentatively analyze CBL calibration panel scans from UMB Old Science Building.
% The basis of this analysis is lidar equation and try to find if we can
% empirically find out CBL's telescope efficiency model.
% 
% Zhan Li, zhanli86@bu.edu
% Created: 20140916
% Last revision: 20150417

% panel reflectace measurement after panels were painted
rho_vec = [0.987, 0.468, 0.349, 0.04];

% nominal panel range setup
nominal_ranges = 1:1:20;

% Read CBL's calibration data compiled in a text file. 
% One thing to NOTE: the range in this file is simply the nominal values of
% panel scan configuration. Maybe actually range values from the lidar data
% itself would be better. 
fid = fopen('/usr3/graduate/zhanli86/Programs/CBL/cbl-calibration/CBL_CAL_DN2_UMB.txt');
data = textscan(fid, '%f %f %f', 'Headerlines', 0);
fclose(fid);
data = cell2mat(data);

% remove rows with empty values in the data
data = data( ~(isnan(data(:,1))|isnan(data(:,2))|isnan(data(:,3))), :);

Pr = data(:,2); % intensity in DN
range = data(:,1)*1e-3; % range unit in mm
panel_id = data(:,3); % panel ID

clean_data_flag = true;
if clean_data_flag
    % first analysis with all data points suggest black panel is very weird and also
    % returns from 1-m range posistion is weird. Remove them and run analysis
    % again.
    tmpflag = panel_id ~= 3 & range > 1.5;
    Pr = Pr(tmpflag);
    range = range(tmpflag);
    panel_id = panel_id(tmpflag);
    rho_vec = rho_vec(1:3);
end

rho = rho_vec(fix(panel_id)+1);
rho = reshape(rho, length(rho), 1);

% % Previously from ESP data, we've discovered the CBL has a calibration constant
% % inversely related to panel reflectance. Thus the ratio of intensity from two
% % panels is NOT equal to the ratio of reflectance of the two panels. Now ignore
% % the possible change of panel reflectance due to drying out.
% % check the return intensity ratios between lambertian and painted panels at
% % each range. Compare it with measured panel reflectance. We may need to adjust
% % painted panel reflectance according to lambertian panel reflectance.
% range_id = zeros(size(panel_id));
% intensity_paint2lam = zeros(length(nominal_ranges), 3);
% mean_range = zeros(length(nominal_ranges), 4);
% std_range = zeros(length(nominal_ranges), 4);
% for n=1:20
%     tmplb = nominal_ranges(n) - 0.5;
%     tmpub = nominal_ranges(n) + 0.5;
%     tmpflag = range > tmplb & range < tmpub;
%     if sum(tmpflag)==0 
%         continue
%     end
%     range_id(tmpflag) = n;
%     tmp_Pr = Pr(tmpflag);
%     tmp_panel_id = panel_id(tmpflag);
%     tmp_range = range(tmpflag);

%     tmpflag = tmp_panel_id == 0;
%     if sum(tmpflag)==0 
%         continue
%     end
%     intensity_lam = mean(tmp_Pr(tmpflag));
%     mean_range(n, 1) = mean(tmp_range(tmpflag));
%     std_range(n, 1) = std(tmp_range(tmpflag));
%     for p=1:3
%         tmpflag = tmp_panel_id == p;
%         if sum(tmpflag)==0
%             continue
%         end
%         mean_range(n, p+1) = mean(tmp_range(tmpflag));
%         std_range(n, p+1) = std(tmp_range(tmpflag));
%         intensity_paint2lam(n, p) = mean(tmp_Pr(tmpflag))/(intensity_lam);
%     end
% end

% plot Pr*range^2 against rho
% expect to see a linear relation at far ranges
figure('Name', 'Pr*r^2 vs rho');
% plot(rho, Pr.*range.^2, '.');
subplot(1,2,1);
scatter(rho, Pr.*range.^2, 20, range);
xlabel('\rho');
ylabel('P_r*r^2');
title('colored by ranges');
subplot(1,2,2);
scatter(rho, Pr.*range.^2, 20, rho);
xlabel('\rho');
ylabel('P_r*r^2');
title('colored by reflectance');

% assume range power is not constant at 2
% plot log(rho)-log(Pr) against log(range)
figure('Name', 'variable range power');
% plot(log(range), log(rho)-log(Pr), '.');
subplot(1,2,1)
scatter(log(range), log(rho)-log(Pr), 36, range);
xlabel('ln(r)');
ylabel('ln(rho)-ln(P_r)');
title('colored by ranges');
subplot(1,2,2)
scatter(log(range), log(rho)-log(Pr), 36, rho);
xlabel('ln(r)');
ylabel('ln(rho)-ln(P_r)');
title('colored by reflectances');

% group data points into groups according to their panel reflectances.
% fit a line to points in each group
slope_vec = zeros(size(rho_vec));
intercept_vec = zeros(size(rho_vec));
for n=1:length(rho_vec)
    tmpind =  abs(rho-rho_vec(n)) < 0.001;
    p = polyfit(log(range(tmpind)), log(rho(tmpind))-log(Pr(tmpind)), 1);
    slope_vec(n) = p(1);
    intercept_vec(n) = p(2);
end
% plot calibration constant term C0 against reflectance or say return power
% to see change of detector gain
figure(); 
subplot(1,2,1);
plot(rho_vec, exp(intercept_vec), '.-');
xlabel('rho');
ylabel('1/C_0');
subplot(1,2,2);
plot(rho_vec, exp(-1*intercept_vec), '.-');
xlabel('rho');
ylabel('C_0');
% we see a nice positive linear relation between the reciprocal of the gain
% and the reflectance (or return power). This means CBL detect has a gain
% inverse to signal power. 
p = polyfit(rho_vec, exp(intercept_vec), 1);
% now the calibration equation for CBL if we have telescope efficiency
% implicit in the range power
alpha = p(1);
beta = p(2);
b = mean(slope_vec);
% check the predicted DN with this model against actual DN
figure();
Pr_model = rho .* range.^(-1*b) .* (1./(alpha*rho+repmat(beta, size(rho))));
plot(Pr, Pr_model, '.');
axis equal;
hold on; plot([min(Pr), max(Pr)], [min(Pr), max(Pr)], '-k')
rsquare = 1-sum((Pr-Pr_model).^2)/sum(Pr.^2);
xlabel('P_r from CBL');
ylabel('P_r from model');
title(sprintf('R^2=%.4f', rsquare));

% now let's hack more about the telescope efficiency
% assume the telescope efficiency is completely included in the term range^b
% and an empirical telescope efficiency model like EVI's (it's actually
% fairly universal to describe a saturation function)
x = min(range):0.1:100;
y = x.^(2-b);
% define a variable storing parameters Cp and Ck
param0=[max(y), 1]; % initial values
% define the function of telescope efficiency
Kr_fun = @(param, xdata)param(1)*(1-exp(-1*param(2)*xdata.^2));
obj_fun = @(param)sum((Kr_fun(param, x)-y).^2);
%[param, fval] = fminunc(obj_fun, param0);
[param, resnorm, ~, ~, output] = lsqcurvefit(Kr_fun, param0, x, y);
