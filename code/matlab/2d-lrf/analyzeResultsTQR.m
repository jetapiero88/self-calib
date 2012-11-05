%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) 2012 by Jerome Maye                                            %
% jerome.maye@gmail.com                                                        %
%                                                                              %
% This program is free software; you can redistribute it and/or modify         %
% it under the terms of the Lesser GNU General Public License as published by  %
% the Free Software Foundation; either version 3 of the License, or            %
% (at your option) any later version.                                          %
%                                                                              %
% This program is distributed in the hope that it will be useful,              %
% but WITHOUT ANY WARRANTY; without even the implied warranty of               %
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                %
% Lesser GNU General Public License for more details.                          %
%                                                                              %
% You should have received a copy of the Lesser GNU General Public License     %
% along with this program. If not, see <http://www.gnu.org/licenses/>.         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script performs the analysis of the results

function analyzeResultsTQR(filename)

load(filename);

dx_ls = zeros(ampResTQR(1).rep, cols(ampResTQR));
dy_ls = zeros(ampResTQR(1).rep, cols(ampResTQR));
psi_ls = zeros(ampResTQR(1).rep, cols(ampResTQR));
dx_ekf = zeros(ampResTQR(1).rep, cols(ampResTQR));
dy_ekf = zeros(ampResTQR(1).rep, cols(ampResTQR));
psi_ekf = zeros(ampResTQR(1).rep, cols(ampResTQR));
dx_tqr = zeros(ampResTQR(1).rep, cols(ampResTQR));
dy_tqr = zeros(ampResTQR(1).rep, cols(ampResTQR));
psi_tqr = zeros(ampResTQR(1).rep, cols(ampResTQR));

for i = 1:cols(ampResTQR)
  dx_ls(:, i) = ampResTQR(i).Theta_ls(:, 1);
  dy_ls(:, i) = ampResTQR(i).Theta_ls(:, 2);
  psi_ls(:, i) = ampResTQR(i).Theta_ls(:, 3);
  dx_ekf(:, i) = ampResTQR(i).Theta_ekf(:, 1);
  dy_ekf(:, i) = ampResTQR(i).Theta_ekf(:, 2);
  psi_ekf(:, i) = ampResTQR(i).Theta_ekf(:, 3);
  dx_tqr(:, i) = ampResTQR(i).Theta_tqr(:, 1);
  dy_tqr(:, i) = ampResTQR(i).Theta_tqr(:, 2);
  psi_tqr(:, i) = ampResTQR(i).Theta_tqr(:, 3);
end

save('dx_ls.mat', 'dx_ls');
save('dy_ls.mat', 'dy_ls');
save('psi_ls.mat', 'psi_ls');
save('dx_ekf.mat', 'dx_ekf');
save('dy_ekf.mat', 'dy_ekf');
save('psi_ekf.mat', 'psi_ekf');
save('dx_tqr.mat', 'dx_tqr');
save('dy_tqr.mat', 'dy_tqr');
save('psi_tqr.mat', 'psi_tqr');

boxplot(dx_ls, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'dx_ls.eps');
close;
boxplot(dy_ls, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'dy_ls.eps');
close;
boxplot(psi_ls, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'psi_ls.eps');
close;
boxplot(dx_ekf, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'dx_ekf.eps');
close;
boxplot(dy_ekf, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'dy_ekf.eps');
close;
boxplot(psi_ekf, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'psi_ekf.eps');
close;
boxplot(dx_tqr, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'dx_tqr.eps');
close;
boxplot(dy_tqr, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'dy_tqr.eps');
close;
boxplot(psi_tqr, 'labels', [0; 0.5; 1.0; 1.5; 2.0; 2.5; 3.0; 3.5; 4.0; 4.5; 5.0]);
exportEPSFig(gcf, 'psi_tqr.eps');
close;
