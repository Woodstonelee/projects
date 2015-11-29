% Tentatively analyze CBL calibration panel scans from Brisbane corridor. 
% The basis of this analysis is lidar equation and try to find if we can
% empirically find out CBL's telescope efficiency model. 
% 
% Zhan Li, zhanli86@bu.edu
% Created: 20140916
% Last revision: 20140916

% Read CBL's calibration data compiled in a text file. 
% One thing to NOTE: the range in this file is simply the nominal values of
% panel scan configuration. Maybe actually range values from the lidar data
% itself would be better. 
fid = fopen('/home/zhanli/Workspace/data/cbl/CBLCal.csv');
data = textscan(fid, '%f %f %f', 'Delimiter', ',', 'Headerlines', 1);
fclose(fid);
data = cell2mat(data);

% remove rows with empty values in the data
data = data( ~(isnan(data(:,1))|isnan(data(:,2))|isnan(data(:,3))), :);

Pr = data(:,1);
rho = data(:,2);
range = data(:,3);

% plot Pr*range^2 against rho
% expect to see a linear relation at far ranges
figure('Name', 'Pr*r^2 vs rho');
% plot(rho, Pr.*range.^2, '.');
subplot(1,2,1);
scatter(rho, Pr.*range.^2, 20, range);
xlabel('rho');
ylabel('P_r*r^2');
title('colored by ranges');
subplot(1,2,2);
scatter(rho, Pr.*range.^2, 20, rho);
xlabel('rho');
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
rho_vec = [0.895, 0.5415, 0.303, 0.1639, 0.1112, 0.0887];
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
