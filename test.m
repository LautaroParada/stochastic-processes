clear; clc;
nObs = 100;
rng(randi([1 100]))
size0 = 5; % uncorrlated variables
size1 = 5; % correlated variables
sigma1 = 0.25; %volatility for the random correlated noise
mu = 0.03;

% creating correlation between the variables
approach = '1';

if strcmp(approach, '1')
    % generating some uncorrelated data
    x = sigma1.*randn(nObs, size0) + mu;
    cols = randi([1 size0-1], 1, size1);
    y = x(:, cols) + sigma1.*randn(nObs, numel(cols));
    x_ = [x y];
    r = cov(x_);
    c = chol(r, 'lower');
    x_ = (c * x_')';
else
    % generating some uncorrelated data
    x = randn(nObs, size0 + size1);
    r = cov(x);
    c = chol(r, 'lower');
    x_ = (c * x')';
end

% consolidating everythin in just one dataset
heatmap(corrcoef(x_))
% plotmatrix(x_)