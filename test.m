clear; clc;
rng(randi([1 100], 1, 1), 'multFibonacci') % change the seed each time
workers = 4; % number of workers for the simulation
% creating the pool of workers
parpool('local', workers); % 4 workers for the pool
% creating the class for the price simulation
sim = randomProcesses('n', 125, 'T', 1000, 's0', 100);

% parallel simulation of prices, c is the composite of the simulation
spmd
   
    if labindex == 1
        c = sim.brownian_prices('mu', 0.13, 'sigma', 0.15);
        
    elseif labindex == 2
        c = sim.gbm_prices('mu', 0.5, 'sigma', 0.2);
        
    elseif labindex == 3
        c = sim.merton_prices('mu', 0.05, 'sigma', 0.3, 'lambda', 25);
        
    else
        c = sim.heston_prices('rf', 0.04, 'k', 0.8, 'theta', 0.9, 'sigma', 1);
        
    end     
    
end