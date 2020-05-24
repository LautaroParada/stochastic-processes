clear; clc;
rng(randi([1 100], 1, 1), 'multFibonacci') % change the seed each time
% creating the class for the price simulation
stocks = randomProcesses('n', 1, 'T', 1000, 's0', 100);
rates = randomProcesses('n', 1, 'T', 1000, 's0', 1);

% simulating the stock prices
brownian = stocks.brownian_prices('mu', 0.1, 'sigma', 0.3);
gbm = stocks.gbm_prices('mu', 0.1, 'sigma', 0.3);
merton = stocks.merton_prices('mu', 0.1, 'sigma', 0.3, 'lambda', 252);
heston = stocks.heston_prices('rf', 0.04, 'k', 0.8, 'theta', 0.9, 'sigma', 1);

% simulating the rates
vas = rates.vas_rates('mu', 0.015, 'sigma', 0.0015, 'lambda', 0.3);
cir = rates.cir_rates('mu', 0.015, 'sigma', 0.0015, 'lambda', 0.3);

% all stocks in one place
prices = [brownian gbm merton heston];
[rows, cols] = size(prices);
volumes_stocks = zeros(rows, cols);

for v = 1:cols
    volumes_stocks(:, v) = stocks.order_flow('eta', 0.1, 'M', 0.2, ...
        'market_prices', prices(:, v));
end

% all rates in one place
rates_levels = [vas cir];

data = [prices volumes_stocks];
plot(prices)
title('Simulated prices')
ylabel('prices')
legend('Brownian', 'GBM', 'Merton', 'Heston')

% Generating the information driven bars
% heston model sample
inf_bars = [prices(:, end) volumes_stocks(:, end)];

tib = stocks.tib('ticks', inf_bars, 'window', 15);
vib = stocks.vib('ticks', inf_bars, 'window', 15);
dib = stocks.dib('ticks', inf_bars, 'window', 15);

% testing the volatility estimators
volatility = volatilityEst();
parkinson = volatility.parkinson('data', dib) * 100;
garman = volatility.garman('data', dib) * 100;
rogers = volatility.rogers('data', dib) * 100;
yang = volatility.yang('data', dib) * 100;

% displaying the volatility values
sprintf('Volatility of the Dollar Barsm \nParkinson = %.4f%% \nGarman = %.4f%% \nRogers = %.4f%% \nYang = %.4f%%', ...
    parkinson, garman, rogers, yang)

% Systemic risk Indicators
risk = systemicRisk('warmup', 100);
abs_ratio = risk.absortion_ratio('data', prices);
turbulence = risk.turbulence('data', prices);

% Checking the Systemic risk
tiledlayout(2, 2)

% Top plot
nexttile(1, [1 2])
yyaxis left
plot(abs_ratio, 'b')
title('Systemic Risk for the basket of assets')
ylabel('Absortion ratio')

yyaxis right
plot(turbulence, 'r')
ylabel('Financial turbulence')
legend('Absortion Ratio', 'Financial Turbulence')

nexttile(3)
sz = 40;
% calculating the linear relation
coeffs = polyfit(abs_ratio, turbulence, 1);
fitted = polyval(coeffs, abs_ratio);
scatter(abs_ratio, turbulence, sz, ...
    'MarkerEdgeColor', [0 .5 .5], ...
    'MarkerFaceColor', [0 .7 .7], ...
    'LineWidth', 1.5)
hold on; % Don't blow away prior plot
plot(abs_ratio, fitted, 'm-', 'LineWidth', 2);
legend('Original Data', 'Line Fit');
hold off

correlation = corrcoef(turbulence, abs_ratio);
sprintf('Correlation between Financial turbulence and Absortion ratio is %.4f', ...
    correlation(2))
