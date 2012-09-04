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

% This script is performing self-calibration of a laser range finder offset
% based on Tim Barfoot's example. This is the definitive version of the
% iterative algorithm we need.

% motion model (without noise)
h = @(x, u, T) [(x(:, 1) + T .* cos(x(:, 3)) .* u(:, 1)), (x(:, 2) +...
  T .* sin(x(:, 3)) .* u(:, 1)), (x(:, 3) + T .* u(:, 2))];

% angle normalization between -pi and pi
normalizeAngle = @(x) atan2(sin(x), cos(x));

% Odometry
x_odom = zeros(length(x_true), 3);
x_odom(1, :) = [x_true(1), y_true(1), th_true(1)];

% odometry measurements
u = [v, om];

% motion model covariance
Q = [v_var, 0; 0, om_var];

% observation model covariance
R = [r_var, 0; 0, b_var];

% batch size
batchSize = 100;

% batch indices saved for optimization
batchIndices = [];

% mutual information threshold in bits
miThreshold = 0.5;

% Estimates
x_est = [];
l_init = l + randn * 0.1;
l_est = l_init;
d_est = d + randn * 0.1

varianceRecord = [];

% loop over dataset
%for i = 2:length(x_odom)
for i = 2:1000
  % compute odometry estimate
  x_odom(i, :) = h(x_odom(i - 1, :), u(i, :), t(i) - t(i - 1));
  x_odom(i, 3) = normalizeAngle(x_odom(i, 3));

  % process batch
  if mod(i, batchSize) == 0
    i

    % initial estimates
    x_est_temp = [x_est; x_odom(i - batchSize + 1:i, :)];
    d_est_temp = d_est;
    l_est_temp = l_est;

    % temporarily add this batch
    batchIndices = [batchIndices; i];

    % count how many laser range measurements to be considered
    obsCount = 0;
    for j = 1:length(batchIndices)
      for k = batchIndices(j) - batchSize + 2:batchIndices(j)
        for m = 1:rows(l_est_temp)
          if r(k, m) > 0
            obsCount = obsCount + 1;
          end
        end
      end
    end

    % jacobian matrix allocation
    H = sparse(3 * (batchSize - 1) * length(batchIndices) + obsCount * 2, ...
      3 * batchSize * length(batchIndices) + 2 * rows(l_est_temp) + 1);

    % error terms allocation
    e = zeros(3 * (batchSize - 1) * length(batchIndices) + obsCount * 2, 1);

    % optimization using old and new dataset
    tol = 1e-6;
    maxNumIter = 200;
    oldll = 0;
    for s = 1:maxNumIter
      % emit iteration number
      s;

      % build matrices
      row = 1;
      col = 1;
      tic;
      n = 1;
      for j = 1:length(batchIndices)
        n = n + 1;
        for k = batchIndices(j) - batchSize + 2:batchIndices(j)
          % some pre-computations
          stm1 = sin(x_est_temp(n - 1, 3));
          ctm1 = cos(x_est_temp(n - 1, 3));

          % jacobian of motion model with respect to noise
          H_w = zeros(3, 2);
          H_w(1, 1) = (t(k) - t(k - 1)) * ctm1;
          H_w(2, 1) = (t(k) - t(k - 1)) * stm1;
          H_w(3, 2) = (t(k) - t(k - 1));

          % covariance matrix
          W = H_w * Q * H_w';

          % inverted covariance matrix
          % (simplification because of numerical issues)
          invW = diag(1 ./ diag(W));

          % Cholesky factor of covariance matrix
          invW_sqrt = chol(invW);

          % jacobian of motion model with respect to state variables
          H_x = eye(cols(x_est_temp), cols(x_est_temp));
          H_x(1, 3) = -(t(k) - t(k - 1)) * stm1 * u(k, 1);
          H_x(2, 3) = (t(k) - t(k - 1)) * ctm1 * u(k, 1);
          H_x_cov = -invW_sqrt * H_x;

          % setting everything into H and e
          H(row, col) = H_x_cov(1, 1);
          H(row, col + 2) = H_x_cov(1, 3);
          H(row + 1, col + 1) = H_x_cov(2, 2);
          H(row + 1, col + 2) = H_x_cov(2, 3);
          H(row + 2, col + 2) = H_x_cov(3, 3);
          id_cov = invW_sqrt * eye(cols(x_est_temp), cols(x_est_temp));
          H(row, col + 3) = id_cov(1, 1);
          H(row + 1, col + 4) = id_cov(2, 2);
          H(row + 2, col + 5) = id_cov(3, 3);
          e(row:row + 2) = x_est_temp(n, :)' -...
            h(x_est_temp(n - 1, :), u(k, :), t(k) - t(k - 1))';
          e(row + 2) = normalizeAngle(e(row + 2));
          e(row:row + 2) = invW_sqrt * e(row:row + 2);
          row = row + cols(x_est_temp);
          col = col + cols(x_est_temp);

          % some pre-computations
          st1 = sin(x_est_temp(n, 3));
          ct1 = cos(x_est_temp(n, 3));

          % covariance matrix of observation model
          N = R;

          % inverted covariance matrix
          invN = diag(1 ./ diag(R));

          % Cholesky factor of covariance matrix
          invN_sqrt = chol(invN);

          % loop over the observations
          for m = 1:rows(l_est_temp)
            if r(k, m) > 0
              % some pre-computations
              a1 = l_est_temp(m, 1) - x_est_temp(n, 1) - d_est_temp * ct1;
              b1 = l_est_temp(m, 2) - x_est_temp(n, 2) - d_est_temp * st1;
              temp1 = a1^2 + b1^2;
              temp2 = sqrt(temp1);

              % jacobian of observation model with respect to state variables
              G_x = zeros(2, 3);
              G_x(1, 1) = -a1 / temp2;
              G_x(1, 2) = -b1 / temp2;
              G_x(1, 3) = (a1 * d_est_temp * st1 - b1 * d_est_temp * ct1) /...
                temp2;
              G_x(2, 1) = b1 / temp1;
              G_x(2, 2) = -a1 / temp1;
              G_x(2, 3) = -(a1 * d_est_temp * ct1 + b1 * d_est_temp * st1) /...
                temp1 - 1;
              G_x_cov = -invN_sqrt * G_x;

              % jacobian of observation model with respect to landmark positions
              G_l = zeros(2, 2);
              G_l(1, 1) = a1 / temp2;
              G_l(1, 2) = b1 / temp2;
              G_l(2, 1) = -b1 / temp1;
              G_l(2, 2) = a1 / temp1;
              G_l_cov = -invN_sqrt * G_l;

              % jacobian of observation model with respect to calibration param.
              G_d = zeros(2, 1);
              G_d(1, 1) = -(a1 * ct1 + b1 * st1) / temp2;
              G_d(2, 1) = (-a1 * st1 + b1 * ct1) / temp1;
              G_d_cov = -invN_sqrt * G_d;

              % setting everything into H and e
              H(row, col) = G_x_cov(1, 1);
              H(row, col + 1) = G_x_cov(1, 2);
              H(row, col + 2) = G_x_cov(1, 3);
              H(row + 1, col) = G_x_cov(2, 1);
              H(row + 1, col + 1) = G_x_cov(2, 2);
              H(row + 1, col + 2) = G_x_cov(2, 3);
              H(row, end) = G_d_cov(1, 1);
              H(row + 1, end) = G_d_cov(2, 1);
              temp3 = 3 * batchSize * length(batchIndices) + 1 + (m - 1) * 2;
              H(row, temp3) = G_l_cov(1, 1);
              H(row, temp3 + 1) = G_l_cov(1, 2);
              H(row + 1, temp3) = G_l_cov(2, 1);
              H(row + 1, temp3 + 1) = G_l_cov(2, 2);
              e(row) = r(k, m) - temp2;
              e(row + 1) = b(k, m) - (atan2(b1, a1) - x_est_temp(n, 3));
              e(row + 1) = normalizeAngle(e(row + 1));
              e(row:row + 1) = invN_sqrt * e(row:row + 1);
              row = row + 2;
            end
          end
          n = n + 1;
        end
        col = col + cols(x_est_temp);
      end
      toc;

      % convergence check
      ll = norm(e);
      if oldll == 0
        oldll = ll;
      else
        if abs(oldll - ll) < tol
          break;
        else
          oldll = ll;
        end
      end

      ll;

      % compute update
      tic;
      dx = spqr_solve(H, -e, struct('tol', 5));
      toc;

      % update estimate
      temp = batchSize * 3 * length(batchIndices);
      x_update = [dx(1:3:temp) dx(2:3:temp) dx(3:3:temp)];
      x_est_temp = x_est_temp + x_update;
      x_est_temp(:, 3) = normalizeAngle(x_est_temp(:, 3));
      l_update = [dx(temp + 1:2:end - 1) dx(temp + 2:2:end - 1)];
      l_est_temp = l_est_temp + l_update;
      d_update = dx(end);
      d_est_temp = d_est_temp + d_update;
    end

    % variance on the calibration parameter
    [C1, R1, P1] = spqr(H, -e, struct('permutation', 'matrix', 'econ', ...
      cols(H)));
    R1 = P1 * R1 * P1';
    variance = 1 / R1(end, end)^2;

    % check if we need this batch
    if length(batchIndices) == 1 % first batch always taken
      x_est = x_est_temp;
      d_est = d_est_temp;
      l_est = l_est_temp;
      varianceRecord = variance;
    else
      % compute mutual information
      mi = 0.5 * log2(varianceRecord / variance);

      % add batch if needed
      if mi > miThreshold
        x_est = x_est_temp;
        d_est = d_est_temp;
        l_est = l_est_temp;
        varianceRecord = variance;
      else
        % kick out the batch
        batchIndices(end) = [];
      end
    end
  end
end
