
classdef randomProcesses
        % Rationale
        % This toolbox packages a set of stochastic processes for prices and 
        % rates simulation, aiming to create a synthetic dataset for 
        % quantitative back-testing of trading strategies and asset allocations
        % methods.
        % Simulating synthetic stock prices and bond rates provides an 
        % alternative back-testing method that uses history to generate 
        % datasets with statistical characteristics estimated from the observed
        % data. This method allows back-testing on a large sample of unseen 
        % scenarios, hence reducing the likelihood of overfitting to a 
        % particular historical data set.
        %
        % Because each trading strategy needs an implementation tactic 
        % (a.k.a., trading rules) to enter, maintain, and exit the respective
        % positions on each instrument, a simulation over thousands of 
        % different scenarios is mandatory. However, there is an implicit 
        % tradeoff. 
        %
        % The historical data will show the 'real' state of the financial 
        % instruments based on the realized combinations of events that 
        % affect each market. Thereby, a traditional portfolio manager will
        % design a set of rules that optimize or hedge the profits for those
        % specific combinations of events. Therefore, an investment strategy
        % that relies on parameters fitted solely by one combination of 
        % events is doomed to fail.
        %
        % Such a framework for designing trading strategies is limited in 
        % the amount of knowledge that can incorporate. So, simulating 
        % thousands or even millions of possibles scenarios for the future 
        % will robust the way that an econometric method exploits an 
        % inefficiency in the market.
        %
        % Based on the previous postulate, I have created a toolbox that 
        % packages different stochastic processes (a.k.a, valuation methods)
        % for back-testing synthetic data. 
        %
        % The processes that were for this version of the toolbox are: 
        % Stock prices
        %     Brownian Motion
        %     Geometric Brownian motion
        %     Merton model
        %     Heston model
        % Bond Rates
        %     Vasicek model
        %     Cox Ingersoll Ross model
    
    
    % -------------------------------------------
    % 1. Properties - values that define the class
    % -------------------------------------------
    
    % 1.1 Public properties
    properties
        n(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} %number of paths to generate
        T(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} %number of observations to generate
        h(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} %size of the step
        s0(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} %initial price
        sigma(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} %trading intensity
    end 
    
    % 1.2 Private properties - only accessible inside the class
    properties(Access = protected)
    end
    
    % 1.3 Constant properties - do not vary with the manipulation, this is
    % also used as references in the class
    properties(Constant)
    end
    
    % 1.4 Dependet properties - their value derive from the public
    % properties
    properties(Dependent)
        r0% initial rate
        dt%step for the incremental returns
    end
    
    % -------------------------------------------
    % 2. Methods - actions of the class
    % -------------------------------------------
    %  2.1 Public methods - accessible for the user
    
    % Class Constructor Methods - similar to the __init__ in python
    methods
        function self = randomProcesses(params)
            % This method initialize the randomProcess class with 
            % the desired values inputed by the user.
            % Args: 
            %   n(int) = number of paths to simulate
            %   T(int) = number of time steps to simulate for each serie.
            %   s0(float) = initial price or percentage rate to use
            %   h(int) = time step to use between T_i and T_i+1
            %
            % Usage:
            % >> simulation = randomProcess('n', 123, 'T', 252, 's0', 100)
            
            arguments
                params.n(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 1    %number of paths to generate
                params.T(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 252  %number of observations to generate
                params.h(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 1    %size of the step
                params.s0(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 100 %initial price
                params.sigma(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 1 %trading intensity
            end
            
            % different cases of parameter assigment
            
            self.n = params.n;
            self.T = params.T;
            self.s0 = params.s0;
            self.h = params.h;
            self.sigma = params.sigma;
        end
        
        % getter methods for the dependant properties
        % Initial rate - based on s0
        function rate = get.r0(self)
            rate = self.s0 / 100;
        end
        % time delta to agregate for the simulation
        function delta = get.dt(self)
            delta = self.h / self.T;
        end
        
        % methods for the simulation
        % -------------------------------------------
        % Tick Imbalance Bars
        % -------------------------------------------
        function tib_ = tib(self, params)
            % Description goes here
            
            arguments
                self
                params.ticks double {mustBeReal, mustBeNonempty}
                params.window(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 15
            end
            
            diffs = diff(params.ticks(:, 1)); % just the prices
            b_t = zeros(numel(diffs), 1);
            
            % Applying the Tick rule to the differences
            for i = 1:numel(diffs)
                if diffs(i) ~= 0
                    b_t(i) = abs(diffs(i)) ./ diffs(i); 
                else
                    b_t(i) = b_t(i-1);
                end
            end
            
            theta = cumsum(b_t); % tick imbalance at time T
            E_theta = self.ewma(theta, params.window); % expected size of the tick bar
            E_bt = self.ewma(b_t, params.window); % expected unconditional probability
            
            tib_ = zeros(numel(theta), 5); % preallocate the response (OHLCV)
            
            % condition for the tick imbalance
            it = 1; % helper for the price samnpling
            for j = 1:numel(theta)
                if abs(theta(j)) >= E_theta(j) * abs(E_bt)
                    tib_(j, 1) = params.ticks(it, 1);              % open
                    tib_(j, 2) = max(params.ticks(it:j, 1));       % high
                    tib_(j, 3) = min(params.ticks(it:j, 1));       % low
                    tib_(j, 4) = params.ticks(j, 1);               % close
                    tib_(j, 5) = sum(params.ticks(it:j, 2));       % volume
                    it = j;
                end
            end
            
            % filtering only for useful data - if the open is 0 remove it
            % https://la.mathworks.com/matlabcentral/answers/16275-how-do-i-delete-an-entire-row-if-a-specific-column-contains-a-zero#answer_22016
             tib_ = tib_(logical(tib_(:, 1)), :);
        end
        
        % -------------------------------------------
        % Volume Imbalance Bars
        % -------------------------------------------
        function vib_ = vib(self, params)
            % Description goes here
            
            arguments
                self
                params.ticks double {mustBeReal, mustBeNonempty}
                params.window(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 15
            end
            
            ticks_diffs = diff(params.ticks(:, 1)); % prices
            vols_diffs = diff(params.ticks(:, 2)); % volume
            
            % Applying the Tick rule to the price differences
            % preallocate the data
             b_t = zeros(numel(ticks_diffs), 1);
             v_t = zeros(numel(vols_diffs), 1);
             
             % iterating trough the records
             % tick rule
            for i = 1:numel(ticks_diffs)
                if ticks_diffs(i) ~= 0
                    b_t(i) = abs(ticks_diffs(i)) ./ ticks_diffs(i); 
                else
                    b_t(i) = b_t(i-1);
                end
            end
            
            % volume rule
            for i = 1:numel(vols_diffs)
                if vols_diffs(i) ~= 0
                    v_t(i) = abs(vols_diffs(i)) ./ vols_diffs(i);
                else
                    v_t(i) = v_t(i-1);
                end
            end
            
            % the imbalance at time T
            theta = cumsum( b_t .* v_t );
            E_theta = self.ewma(theta, params.window); % expected size of the tick bar
            E_bt = self.ewma( b_t .* v_t, params.window); % expected unconditional probability
            
            vib_ = zeros(numel(theta), 5); % preallocate the response (OHLCV)
            
            % condition for the tick imbalance
            it = 1; % helper for the price samnpling
            for j = 1:numel(theta)
                if abs(theta(j)) >= E_theta(j) * abs(E_bt)
                    vib_(j, 1) = params.ticks(it, 1);              % open
                    vib_(j, 2) = max(params.ticks(it:j, 1));       % high
                    vib_(j, 3) = min(params.ticks(it:j, 1));       % low
                    vib_(j, 4) = params.ticks(j, 1);               % close
                    vib_(j, 5) = sum(params.ticks(it:j, 2));       % volume
                    it = j;
                end
            end
        
            % filtering only for useful data - if the open is 0 remove it
            % https://la.mathworks.com/matlabcentral/answers/16275-how-do-i-delete-an-entire-row-if-a-specific-column-contains-a-zero#answer_22016
             vib_ = vib_(logical(vib_(:, 1)), :);
        end
        
        % -------------------------------------------
        % Dollar Imbalance Bars
        % -------------------------------------------
        function dib_ = dib(self, params)
            % Description goes here
            
            arguments
                self
                params.ticks double {mustBeReal, mustBeNonempty}
                params.window(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 15
            end
            
            ticks_diffs = diff(params.ticks(:, 1)); % prices
            doll_diffs = diff( params.ticks(:, 1) .* params.ticks(:, 2) ); % dollars traded
            
            % Applying the Tick rule to the price differences
            % preallocate the data
             b_t = zeros(numel(ticks_diffs), 1);
             d_t = zeros(numel(doll_diffs), 1);
            
             % iterating trough the records
             % tick rule
            for i = 1:numel(ticks_diffs)
                if ticks_diffs(i) ~= 0
                    b_t(i) = abs(ticks_diffs(i)) ./ ticks_diffs(i); 
                else
                    b_t(i) = b_t(i-1);
                end
            end
            
            % dollar rule
            for i = 1:numel(doll_diffs)
                if doll_diffs(i) ~= 0
                    d_t(i) = abs(doll_diffs(i)) ./ doll_diffs(i);
                else
                    d_t(i) = d_t(i-1);
                end
            end
            
            % the imbalance at time T
            theta = cumsum( b_t .* d_t );
            E_theta = self.ewma(theta, params.window); % expected size of the tick bar
            E_bt = self.ewma( b_t .* d_t, params.window); % expected unconditional probability
            
            dib_ = zeros(numel(theta), 5); % preallocate the response (OHLCV)
            
            % condition for the tick imbalance
            it = 1; % helper for the price samnpling
            for j = 1:numel(theta)
                if abs(theta(j)) >= E_theta(j) * abs(E_bt)
                    dib_(j, 1) = params.ticks(it, 1);              % open
                    dib_(j, 2) = max(params.ticks(it:j, 1));       % high
                    dib_(j, 3) = min(params.ticks(it:j, 1));       % low
                    dib_(j, 4) = params.ticks(j, 1);               % close
                    dib_(j, 5) = sum(params.ticks(it:j, 2));       % volume
                    it = j;
                end
            end
        
            % filtering only for useful data - if the open is 0 remove it
            % https://la.mathworks.com/matlabcentral/answers/16275-how-do-i-delete-an-entire-row-if-a-specific-column-contains-a-zero#answer_22016
             dib_ = dib_(logical(dib_(:, 1)), :);
             
        end
            
        % -------------------------------------------
        % Asymmetric Information and the Distribution of Trading Volume
        % -------------------------------------------
        function vols = order_flow(self, params)
            % Description goes here
            arguments
                self
                params.eta(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 0.1
                params.M(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 0.3
                params.market_prices double {mustBeReal, mustBeFinite, mustBeNonempty}
            end
            
            signals = diff(params.market_prices); % evolution of prices for signals
            signals = [randn(1); signals]; % helper for the final response
            sigma_u = (1 - params.eta) * self.sigma; % trading intensity for uninformed traders
            sigma_v = params.eta * self.sigma; % trading intensity for informed tarders
            sigma_e = rand(1); % implicit error
            m = params.eta * params.M; %informed liquidity seekers
            n_ = (1 - params.eta) * params.M; %uninformed liquidity seekers

            lambda = sqrt(m * (sigma_v^2 + sigma_e^2)) / ...
                ((m + 1)*sqrt(n_*sigma_u));
            
            beta = sqrt( (n_*sigma_u) / ...
                (m*(sigma_v^2 * sigma_e^2)) );

            asymetric_info = (1/(2*lambda)) - ((m-1)/2)*beta;

            vols = abs(signals * asymetric_info);
        end
        
        % -------------------------------------------
        % The Brownian Motion Stochastic Process (Wiener Process)
        % -------------------------------------------
        function bro_prices = brownian_prices(self, params)
            % Discrete time stochastic process for a 
            % Brownian motion that satisfies the following stochastic 
            % differential equation (SDE):
            %
            % dXt = µXtdt + σXtdWt
            % X(0) = X0
            %
            % The Euler–Maruyama method is used for the numerical solution
            % of the SDE and has the following recurrence:
            %
            % X(k+1) = X(k) + µX(k-1)Δt + σX(k-1)W
            % where W = Z(k)√Δt ; Z(k) is white noise
            %
            % Args:
            %   mu(float) = historical means of returns
            %   sigma(float) = historical volatility of returns
            %   sto_vol(logical) = optional argument for the helper
            %   function random_disturbance
            %
            % Usage:
            % >>plot(randomProcesses().brownian_prices())
            %
            % Author: Lautaro Parada Opazo
            
            % Function Argument Validation
            arguments
                self
                params.mu(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 0
                params.sigma(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 1
                params.sto_vol(1,1) logical {mustBeNumericOrLogical} = false
            end
            
            % preallocate the data
            bro_prices = zeros(self.T, self.n);
            % check the size of the output matrix
            if self.n > 1
                for i = 1:self.n
                    % several securities to simulate
                    bro_prices(:, i) = self.brownian_returns(params.mu, ...
                        params.sigma, params.sto_vol);
                end
            else
                % the case for only 1 simulation
                bro_prices = self.brownian_returns(params.mu, ...
                    params.sigma, params.sto_vol);
            end
        end
        
        % -------------------------------------------
        % Geometric Brownian motion
        % -------------------------------------------
        function gbm_pricess = gbm_prices(self, params)
            % The Geometric Brownian Motion (GBM) was popularized by Fisher 
            % Black and Myron Scholes in their paper The Pricing of Options
            % and Corporate Liabilities. In that paper, they derive the 
            % Black Scholes equation. 
            % The GBM is essentially a Brownian Motion with a constant drift 
            % and stochastic volatility component. 
            %
            % The stochastic differential equation (SDE) which describes the 
            % evolution of a Geometric Brownian Motion stochastic process
            % is the following:
            %
            % dXt = µXtdt + σ(t)XtdWt
            % X(0) = X0
            %
            % The Euler–Maruyama method is used for the numerical solution
            % of the SDE and has the following recurrence:
            %
            % X(k+1) = X(k) + µX(k-1)Δt + σ(k)X(k-1)W
            % where W = Z(k)√Δt ; Z(k) is white noise
            %
            % Args:
            %   mu(float) = historical mean of returns
            %   sigma(float) = historical volatility of returns
            %   sto_vol(logical) = optional argument for the helper
            %   function random_disturbance
            %
            % Usage:
            % >>plot(randomProcesses().gbm_prices())
            %
            % Author: Lautaro Parada Opazo
            
            % Function Argument Validation
            arguments
                self
                params.mu(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 0
                params.sigma(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 1
                params.sto_vol(1,1) logical {mustBeNumericOrLogical} = true
            end
            % preallocate the data
            gbm_pricess = zeros(self.T, self.n);
            % check the size of the output matrix
            if self.n > 1
                for i = 1:self.n
                    % several securities to simulate
                    gbm_pricess(:, i) = self.brownian_returns(params.mu, ...
                        params.sigma, params.sto_vol);
                end
            else
                % the case for only 1 simulation
                gbm_pricess = self.brownian_returns(params.mu, ...
                    params.sigma, params.sto_vol);
            end
        end
        
        % -------------------------------------------
        % The Merton Jump Diffusion Stochastic Process
        % -------------------------------------------
        function mert_prices = merton_prices(self, params)
            % Merton’s Jump-Diffusion Model
            % In essence, this is a process that allows for a positive probability
            % of a stock price change of extraordinary magnitude, no matter
            % how small the time interval between successive observations. 
            % More formally this is a Poisson-driven process, in which the
            % "event" is the arrival of an important piece of information
            % that creates an abnormal increase/decrease of the price.
            %
            % The stochastic differential equation (SDE) which describes the 
            % evolution of a Merton stochastic process is the following:
            %
            % dXt = μXtdt + σ(t)XtdWt + dJt
            % X(0) = X0
            %
            % The Euler–Maruyama method is used for the numerical solution
            % of the SDE and has the following recurrence:
            %
            % X(k+1) = X(k) + µX(k-1)Δt + σ(k)X(k-1)W 
            %               + X(k)(Nt∑i=0(Yi−1))
            % where Nt is a Poisson process with rate λ and Yi has a 
            % log normal distribution and W = Z(k)√Δt; Z(k) is white noise
            %
            % Args;
            %   lambda(double)= moment of arrival of an important piece 
            %                   of information.
            %   mu(double)= historical mean of returns
            %   sigma(double)=historical volatility of returns
            %   sto_vol(logical) = optional argument for the helper
            %   function random_disturbance
            %
            % Usage:
            % >>plot(randomProcesses().merton_prices())
            %
            % Author: Lautaro Parada Opazo
            
            arguments
                self
                params.mu(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 0
                params.sigma(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 1
                params.lambda(1,1) double {mustBeReal, mustBeFinite, mustBeNonempty} = 50
                params.sto_vol(1,1) logical {mustBeNumericOrLogical} = true
            end
            
            % preallocate the data
            mert_prices = zeros(self.T, self.n);
            if self.n > 1
                for i = 1:self.n
                    % several securities to simulate
                    mert_prices(:, i) = self.merton_returns(params.mu, ...
                        params.sigma, params.lambda, params.sto_vol);
                end
            else
                % the case for only 1 simulation
                mert_prices = self.merton_returns(params.mu, params.sigma, ...
                    params.lambda, params.sto_vol);
            end
        end
        
        % -------------------------------------------
        % Vasicek Interest Rate Model
        % -------------------------------------------
        function ou_ratess = vas_rates(self, params)
            % The Vasicek interest rate model (or simply the Vasicek model)
            % is a mathematical method of modeling interest rate movements.
            % The model describes the movement of an interest rate as a 
            % factor composed of market risk, time, and equilibrium value, 
            % where the rate tends to revert towards the mean of those factors 
            % over time. Essentially, it predicts where interest rates will 
            % end up at the end of a given period of time, given current 
            % market volatility, the long-run mean interest rate value, and 
            % a given market risk factor.
            % The stochastic differential equation (SDE) for the Vasicek 
            % Interest Rate Model process is given by
            %
            % dSt = λ(μ−St)dt + σdWt
            %
            % The Euler–Maruyama method is used for the numerical solution
            % of the SDE and has the following recurrence:
            %
            % S(k) = λ( μ −S(k-1) )Δt + σS(k-1)W
            % where W = Z(k)√Δt ; Z(k) is white noise
            %
            % Args:
            %   mu(double)= Long term mean level. All future trajectories 
            %               of s will evolve around a mean level μ in 
            %               the long run.
            %   sigma(double)= Instantaneous volatility, measures instant 
            %               by instant the amplitude of randomness entering
            %               the system. Higher σ implies more randomness.
            %   lambda(double)= Speed of reversion. λ characterizes the 
            %               velocity at which such trajectories will 
            %               regroup around μ in time
            %
            % Usage
            % >> plot(randomProcesses().vas_rates())
            %
            % Author: Lautaro Parada Opazo
            % sources
            % https://www.investopedia.com/terms/v/vasicek-model.asp
            % https://en.wikipedia.org/wiki/Vasicek_model
            
            % Method parameters validation
            arguments
                self
                params.mu(1,1) double {mustBeReal, mustBeFinite} = 0
                params.sigma(1,1) double {mustBeReal, mustBeFinite} = 1
                params.lambda(1,1) double {mustBeReal, mustBeFinite} = 0.5
                params.sto_vol(1,1) logical {mustBeNumericOrLogical} = false
            end
            
            % preallocate the data
            ou_ratess = zeros(self.T, self.n);
            if self.n > 1
                for i = 1:self.n
                    % several securities to simulate
                    ou_ratess(:, i) = self.vas_returns(params.mu, ...
                        params.sigma, params.lambda, params.sto_vol);
                end
            else
                % the case for only 1 simulation
                ou_ratess = self.vas_returns(params.mu, params.sigma, ...
                    params.lambda, params.sto_vol);
            end
        end
        
        % -------------------------------------------
        % Cox Ingersoll Ross (CIR) stochastic proces
        % -------------------------------------------
        function cir_ratess = cir_rates(self, params)
            % The Cox-Ingersoll-Ross model (CIR) is a mathematical 
            % formula used to model interest rate movements and is 
            % driven by a sole source of market risk. It is used as 
            % a method to forecast interest rates
            % The stochastic differential equation (SDE) for the Cox-Ingersoll-Ross 
            % Interest Rate Model process is given by
            %
            % dSt = λ(μ−St)dt + σ√rdWt
            %
            % The Euler–Maruyama method is used for the numerical solution
            % of the SDE and has the following recurrence:
            %
            % S(k) = λ( μ −S(k-1) )Δt + σ√S(k-1)W
            % where W = Z(k)√Δt ; Z(k) is white noise
            %
            % Args:
            %   mu(double)= Long term mean level. All future trajectories 
            %               of s will evolve around a mean level μ in 
            %               the long run.
            %   sigma(double)= Instantaneous volatility, measures instant 
            %               by instant the amplitude of randomness entering
            %               the system. Higher σ implies more randomness.
            %   lambda(double)= Speed of reversion. λ characterizes the 
            %               velocity at which such trajectories will 
            %               regroup around μ in time
            % Usage:
            % >> plot(randomProcesses().cir_rates())
            %
            % Author: Lautaro Parada Opazo
            % sources
            % https://www.investopedia.com/terms/v/vasicek-model.asp
            % https://en.wikipedia.org/wiki/Vasicek_model
            
            arguments
                self
                params.mu(1,1) double {mustBeReal, mustBeFinite} = 0
                params.sigma(1,1) double {mustBeReal, mustBeFinite} = 1
                params.lambda(1,1) double {mustBeReal, mustBeFinite} = 0.5
                params.sto_vol(1,1) logical {mustBeNumericOrLogical} = false
            end
            
            % preallocate the data
            cir_ratess = zeros(self.T, self.n);
            if self.n > 1
                for i = 1:self.n
                    % several securities to simulate
                    cir_ratess(:, i) = self.cir_returns(params.mu, ...
                        params.sigma, params.lambda, params.sto_vol);
                end
            else
                % the case for only 1 simulation
                cir_ratess = self.cir_returns(params.mu, params.sigma, ...
                    params.lambda, params.sto_vol);
            end
        end
        
        % -------------------------------------------
        % Heston Stochastic Volatility Process
        % -------------------------------------------
        function hes_prices = heston_prices(self, params)
            % The original Geometric Brownian Motion stochastic process 
            % assumes that volatility over time is constant. In the early 
            % 1990s, Steven Heston relaxed this assumption and extended the
            % Geometric Brownian Motion model to include stochastic volatility.
            % The resulting model is called the Heston model. 
            %
            % In the Heston model, the volatility over time evolves according 
            % to the Cox Ingersoll Ross stochastic process. As such, the 
            % model makes use of two Wiener processes, one for the Cox 
            % Ingersoll Ross process and another for the Geometric Brownian
            % Motion process. These two Wiener processes are correlated 
            % using Singular Value Decomposition.
            % 
            % The stochastic differential equation (SDE) for the Cox-Ingersoll-Ross 
            % Interest Rate Model process is given by
            %
            % dSt = μStdt + St√vdW1 -> price evolution
            % dvt = k( θ − vt )dt + σ√vdW2 -> volatility evolution
            %
            % The Euler–Maruyama method is used for the numerical solution
            % of the SDE and has the following recurrence:
            %
            % Price numerical approximation
            % S(i) = rfS(i-1)Δt + √V(i)S(i-1)W1
            % where W1 = Z1(k)√Δt ; Z1(k) is the correlated white noise
            %
            % Volatility numerical approximation
            % V(j) = k( θ −V(j-1) )Δt + σ√V(j-1)W2
            % where W2 = Z2(k)√Δt ; Z2(k) is the correlated white noise
            %
            % Author: Lautaro Parada Opazo
            %
            % sources
            % https://www.investopedia.com/terms/h/heston-model.asp            
            
            arguments
                self
                params.rf(1,1) double {mustBeReal, mustBeFinite} = 0.02
                params.k(1,1) double {mustBeReal, mustBeFinite} = 0.5
                params.theta(1,1) double {mustBeReal, mustBeFinite} = 1
                params.sigma(1,1) double {mustBeReal, mustBeFinite} = 1
                params.sto_vol(1,1) logical {mustBeNumericOrLogical} = false
            end
            
            hes_prices = zeros(self.T, self.n);
            if self.n > 1
                for col = 1:self.n
                    hes_prices(:, col) = self.heston_returns(params.rf, ...
                        params.k, params.theta, params.sigma, ...
                        params.sto_vol);
                end
            else
                hes_prices = self.heston_returns(params.rf, params.k, ...
                    params.theta, params.sigma, params.sto_vol);
            end
        end 
    end 
    
    %  Private methods - Helper methods that are used across the class
    methods(Access = private)
        
        % -------------------------------------------
        % Heston Stochastic Volatility Process
        % -------------------------------------------
        % ----------- Volatility Factor for the Heston model ----------- %
        function hes_dis_vol = heston_dis_vol(self, k, theta, vt, sigma, w2)
            % heston mean reverting volatility recurrence
            hes_dis_vol = k * ( theta - vt ) * self.dt + ...
                sigma * sqrt(abs(vt) * self.dt) * w2;
        end       
        
        % ----------- Actual Stochastic Differential model ----------- %
        function heston_dis = heston_discrete(self, rf, st, V, w1)
            % Discrete form of the Heston model
            
            heston_dis = rf * st * self.dt + ...
                sqrt(abs(V) * self.dt) * st * w1;
        end
        
        function heston_ret = heston_returns(self, rf, k, theta, sigma, sto_vol)
            
            % integrate a random correlation level
            [corr_wn1, corr_wn2] = self.corr_noise();
            
            % integrating into the mean reverting volatility
            % pre-allocating the whinte for the volatility process
            wn2 = self.random_disturbance(sto_vol);
            dw2 = zeros(self.T, 1);
            dw2(1) = corr_wn2(1);
            for cir = 2:self.T
                dw2(cir) = self.heston_dis_vol(k, theta, corr_wn2(cir), ...
                    sigma, wn2(cir));
            end
            
            % creating the data for the actual process
            % pre-allocating the whinte for the return process
            heston_ret = zeros(self.T, 1);
            heston_ret(1) = self.s0;
            % building the stochastic process for the discretized increments
            for hes = 2:self.T
                heston_ret(hes) = heston_ret(hes-1) + self.heston_discrete(...
                    rf, heston_ret(hes-1), dw2(hes), corr_wn1(hes));
            end
        end
            
        % -------------------------------------------
        % Cox Ingersoll Ross (CIR) stochastic proces
        % -------------------------------------------
        function cir_dis = cir_discrete(self, mu, sigma, lambda, st, vol)
            % Cox Ingersoll Ross discrete process evolution
            
            cir_dis = lambda * ( mu - st ) * self.dt + ...
                sigma * sqrt( st * self.dt ) * vol;
        end
        
        function cir_ret = cir_returns(self, mu, sigma, lambda, sto_vol)
            %Compute the rate series for a Cox Ingersoll Ross process
            
            % pre-allocate the volatility
            volatility = self.random_disturbance(sto_vol);
            %pre-allocate the returns response
            cir_ret = zeros(self.T, 1);
            cir_ret(1) = self.r0;
            % compute the rest of the values
            for t = 2:self.T
                cir_ret(t) = cir_ret(t-1) + self.cir_discrete(mu, sigma, ...
                    lambda, cir_ret(t-1), volatility(t));
            end   
        end
        
        % -------------------------------------------
        % Vasicek Interest Rate Model
        % -------------------------------------------      
        function vas_dis = vas_discrete(self, mu, sigma, lambda, st, vol)
            % Ornstein-Uhlenbech discrete evolution process
            vas_dis = lambda * ( mu - st ) * self.dt + ...
                sigma * sqrt( self.dt ) * vol;
        end
        
        function vas_rets = vas_returns(self, mu, sigma, lambda, sto_vol)
            % Compute the rate series for a Ornstein-Uhlenbech process
            
            % pre-allocate the volatility
            volatility = self.random_disturbance(sto_vol);
            %pre-allocate the returns response
            vas_rets = zeros(self.T, 1);
            vas_rets(1) = self.r0;
            % compute the rest of the values
            for t = 2:self.T
                vas_rets(t) = vas_rets(t-1) + self.vas_discrete(mu, sigma, ...
                    lambda, vas_rets(t-1), volatility(t));
            end
         end
        
        % -------------------------------------------
        % The Merton Jump Diffusion Stochastic Process
        % -------------------------------------------
        function jumps = jumps_diffusion(self, lambda)
            % Algorithm for generating a compound Poisson process up to a 
            % desired time T to get X(T)
            %
            %   1) t = 0, N = 0, X = 0.
            %	2) Generate a U
            %	3) t = t + [−(1/λ) ln (U)]. If t > T, then stop.
            %	4) Generate B distributed as G.
            %	5) Set N = N + 1 and set X = X + B
            %   6) Go back to 2.
            %
            % source http://www.columbia.edu/~ks20/4703-Sigman/4703-07-Notes-PP-NSPP.pdf
            % page 8
            % https://www.csie.ntu.edu.tw/~lyuu/finance1/2015/20150513.pdf
            % https://www.lpsm.paris/pageperso/tankov/tankov_voltchkova.pdf
            % pag 5
            
            t = 0;
            jumps = zeros(self.T, 1);
            lambda_ = lambda / self.T;
            small_lambda = -(1.0 / lambda_);
            pd = makedist('Poisson', 'lambda', lambda);
            
            % applying the psudo-code of the algorithm
            for i = 1:self.T
                t = t + small_lambda * log(rand(1));
                if t > self.T
                    jumps(i:end) = (mean(pd)*rand(1)+std(pd)) ^ randi([-1 1]); 
                    % the t parameter is restituted to the original value
                    % for several jumps in the future
                    t = small_lambda;
                end
            end
        end
        
        function merton_ret = merton_returns(self, mu, sigma, lambda, sto_vol)
            % Merton’s Jump-Diffusion Model
            
            geometric_brownian_motion = self.brownian_returns(mu, sigma, sto_vol);            
            jump_diffusion_ = self.jumps_diffusion(lambda);            
            merton_ret = geometric_brownian_motion + jump_diffusion_;
            
        end
                
        % -------------------------------------------
        % The Brownian Motion Stochastic Process (Wiener Process)
        % -------------------------------------------
        function bro_discrete = brownian_discrete(self, mu, sigma, st, vol)
            % Discrete evolution of prices for brownian motion
            bro_discrete = ( mu * st * self.dt ) + ...
                ( sigma * st * sqrt(self.dt) * vol );
        end
        
        function bro_returns = brownian_returns(self, mu, sigma, sto_vol)            
            % compute the price series for a bownian motion
            % preallocate the volatility
            volatility = self.random_disturbance(sto_vol);
            % preallocate the price series
            bro_returns = zeros(self.T, 1);
            bro_returns(1) = self.s0;
            for t = 2:self.T
                bro_returns(t) = bro_returns(t-1) + self.brownian_discrete(...
                    mu, sigma, bro_returns(t-1), volatility(t));
            end
        end   
        
        % -------------------------------------------
        % Helper methods
        % -------------------------------------------
        function rd = random_disturbance(self, sto_vol)
            % Calculates the stochastic volatility for a simulated prices
            % series, if sto_vol is set to False is the traditional White
            % noise; if True, calculates a changing volatility based on
            
            % White noise
            if ~sto_vol
                rd = randn(self.T, 1);
                
            else
                % random numbers with specific mean and variance
                % The general theory of random variables states that if x
                % is a random variable whose mean is μ and variance is σ
                % , then the random variable, y, defined by y=ax+b, where
                % a and b are constants,
                rd = rand(self.T, 1) .* randn(self.T, 1);
                
            end
        end 
        
        function [dw1, dw2] = corr_noise(self)
            % A straightforward way to create noise processes with a 
            % specified correlation is through the singular value 
            % decomposition (SVD) 
            % see Sauer T (2006) Numerical Analysis. Pearson, Boston
            % for a detailed description
            
            % generate two uncorrelated Brownian processes
            z1 = self.random_disturbance(false);
            z2 = self.random_disturbance(false);
            
            % randonmly create an absolute correlation power
            rho = rand(1);
            
            corr1 = sqrt( (1 + rho) / 2 );
            corr2 = sqrt( (1 - rho) / 2 );
            
            % correlating the brownian processes
            dw1 = corr1 * z1 + corr2 * z2;
            dw2 = corr1 * z1 - corr2 * z2;
        end
    end
    
    % ethods are associated with a class, but not with specific instances of that class
    methods(Static)
        function a = ewma(values, window)
            % Exponential weighted moving average
            
            % https://la.mathworks.com/videos/using-convolution-to-smooth-data-with-a-moving-average-in-matlab-97193.html
            % https://www.youtube.com/watch?v=3y9GESSZmS0

            weights = exp(linspace(-1, 0, window));
            weights = weights ./ sum(weights);
            a = conv(values, weights, 'same');
        end
    end
end

    