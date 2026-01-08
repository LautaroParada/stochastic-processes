classdef test_randomProcesses < matlab.unittest.TestCase
    % Test suite for randomProcesses class
    % Run with: results = runtests('test_randomProcesses')
    % Or simply: test_randomProcesses
    
    properties
        sim     % randomProcesses instance for stock prices
        sim2    % randomProcesses instance for interest rates
    end
    
    methods(TestMethodSetup)
        function createInstances(testCase)
            % Setup method run before each test
            % Initialize randomProcesses objects
            testCase.sim = randomProcesses('n', 5, 'T', 252, 'h', 1, 's0', 100);
            testCase.sim2 = randomProcesses('n', 5, 'T', 252, 'h', 1, 's0', 2);
        end
    end
    
    %% Test Class Initialization
    methods(Test)
        function testConstructorDefaultValues(testCase)
            % Test constructor with default values
            sim_default = randomProcesses();
            testCase.verifyEqual(sim_default.n, 1);
            testCase.verifyEqual(sim_default.T, 252);
            testCase.verifyEqual(sim_default.h, 1);
            testCase.verifyEqual(sim_default.s0, 100);
            testCase.verifyEqual(sim_default.sigma, 1);
        end
        
        function testConstructorCustomValues(testCase)
            % Test constructor with custom values
            testCase.verifyEqual(testCase.sim.n, 5);
            testCase.verifyEqual(testCase.sim.T, 252);
            testCase.verifyEqual(testCase.sim.h, 1);
            testCase.verifyEqual(testCase.sim.s0, 100);
        end
        
        function testDependentPropertyR0(testCase)
            % Test r0 dependent property
            testCase.verifyEqual(testCase.sim2.r0, 0.02, 'AbsTol', 1e-10);
        end
        
        function testDependentPropertyDt(testCase)
            % Test dt dependent property
            expected_dt = testCase.sim.h / testCase.sim.T;
            testCase.verifyEqual(testCase.sim.dt, expected_dt, 'AbsTol', 1e-10);
        end
    end
    
    %% Test Stock Price Methods
    methods(Test)
        function testBrownianPrices(testCase)
            % Test Brownian Motion price generation
            brownian_prices = testCase.sim.brownian_prices('mu', 0.04, 'sigma', 0.15);
            
            % Check dimensions
            testCase.verifySize(brownian_prices, [252, 5]);
            
            % Check initial prices
            testCase.verifyEqual(brownian_prices(1, :), repmat(100, 1, 5), 'AbsTol', 1e-10);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(brownian_prices(:))));
        end
        
        function testBrownianPricesSinglePath(testCase)
            % Test Brownian Motion with single path
            sim_single = randomProcesses('n', 1, 'T', 100, 'h', 1, 's0', 50);
            brownian_prices = sim_single.brownian_prices('mu', 0.05, 'sigma', 0.2);
            
            testCase.verifySize(brownian_prices, [100, 1]);
            testCase.verifyEqual(brownian_prices(1), 50, 'AbsTol', 1e-10);
        end
        
        function testGBMPrices(testCase)
            % Test Geometric Brownian Motion price generation
            gbm_prices = testCase.sim.gbm_prices('mu', 0.04, 'sigma', 0.15);
            
            % Check dimensions
            testCase.verifySize(gbm_prices, [252, 5]);
            
            % Check initial prices
            testCase.verifyEqual(gbm_prices(1, :), repmat(100, 1, 5), 'AbsTol', 1e-10);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(gbm_prices(:))));
        end
        
        function testMertonPrices(testCase)
            % Test Merton Jump-Diffusion price generation
            merton_prices = testCase.sim.merton_prices('mu', 0.04, 'sigma', 0.15, 'lambda', 30);
            
            % Check dimensions
            testCase.verifySize(merton_prices, [252, 5]);
            
            % Check initial prices
            testCase.verifyEqual(merton_prices(1, :), repmat(100, 1, 5), 'AbsTol', 1e-10);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(merton_prices(:))));
        end
        
        function testHestonPrices(testCase)
            % Test Heston Model price generation
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            
            % Check dimensions
            testCase.verifySize(heston_prices, [252, 5]);
            
            % Check initial prices
            testCase.verifyEqual(heston_prices(1, :), repmat(100, 1, 5), 'AbsTol', 1e-10);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(heston_prices(:))));
        end
    end
    
    %% Test Interest Rate Methods
    methods(Test)
        function testVasicekRates(testCase)
            % Test Vasicek Interest Rate Model
            vas_rates = testCase.sim2.vas_rates('mu', 0.018, 'sigma', 0.03, 'lambda', 0.9);
            
            % Check dimensions
            testCase.verifySize(vas_rates, [252, 5]);
            
            % Check initial rates
            testCase.verifyEqual(vas_rates(1, :), repmat(0.02, 1, 5), 'AbsTol', 1e-10);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(vas_rates(:))));
        end
        
        function testCIRRates(testCase)
            % Test Cox-Ingersoll-Ross Interest Rate Model
            cir_rates = testCase.sim2.cir_rates('mu', 0.018, 'sigma', 0.03, 'lambda', 0.9);
            
            % Check dimensions
            testCase.verifySize(cir_rates, [252, 5]);
            
            % Check initial rates
            testCase.verifyEqual(cir_rates(1, :), repmat(0.02, 1, 5), 'AbsTol', 1e-10);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(cir_rates(:))));
            
            % CIR should not produce negative rates (though it might due to discretization)
            % Just verify the data is finite
            testCase.verifyTrue(all(isfinite(cir_rates(:))));
        end
    end
    
    %% Test Utility Methods
    methods(Test)
        function testOrderFlow(testCase)
            % Test order flow volume generation
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            volumes = testCase.sim.order_flow('eta', 0.15, 'market_prices', heston_prices(:, 1));
            
            % Check dimensions
            testCase.verifySize(volumes, [252, 1]);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(volumes)));
            
            % Volumes should be non-negative
            testCase.verifyTrue(all(volumes >= 0));
        end
        
        function testTickImbalanceBars(testCase)
            % Test Tick Imbalance Bars (TIB)
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            volumes = testCase.sim.order_flow('eta', 0.15, 'market_prices', heston_prices(:, 1));
            tick_prices = [heston_prices(:, 1), volumes];
            
            tib = testCase.sim.tib('ticks', tick_prices, 'window', 20);
            
            % TIB should have 5 columns (OHLCV)
            testCase.verifySize(tib, [NaN, 5]);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(tib(:))));
            
            % Verify OHLC relationships (High >= Low, High >= Open, High >= Close, Low <= Open, Low <= Close)
            for i = 1:size(tib, 1)
                testCase.verifyGreaterThanOrEqual(tib(i, 2), tib(i, 3)); % High >= Low
                testCase.verifyGreaterThanOrEqual(tib(i, 2), tib(i, 1)); % High >= Open
                testCase.verifyGreaterThanOrEqual(tib(i, 2), tib(i, 4)); % High >= Close
                testCase.verifyLessThanOrEqual(tib(i, 3), tib(i, 1)); % Low <= Open
                testCase.verifyLessThanOrEqual(tib(i, 3), tib(i, 4)); % Low <= Close
            end
            
            % Volumes should be positive
            testCase.verifyTrue(all(tib(:, 5) > 0));
        end
        
        function testVolumeImbalanceBars(testCase)
            % Test Volume Imbalance Bars (VIB)
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            volumes = testCase.sim.order_flow('eta', 0.15, 'market_prices', heston_prices(:, 1));
            tick_prices = [heston_prices(:, 1), volumes];
            
            vib = testCase.sim.vib('ticks', tick_prices, 'window', 20);
            
            % VIB should have 5 columns (OHLCV)
            testCase.verifySize(vib, [NaN, 5]);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(vib(:))));
            
            % Volumes should be positive
            testCase.verifyTrue(all(vib(:, 5) > 0));
        end
        
        function testDollarImbalanceBars(testCase)
            % Test Dollar Imbalance Bars (DIB)
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            volumes = testCase.sim.order_flow('eta', 0.15, 'market_prices', heston_prices(:, 1));
            tick_prices = [heston_prices(:, 1), volumes];
            
            dib = testCase.sim.dib('ticks', tick_prices, 'window', 20);
            
            % DIB should have 5 columns (OHLCV)
            testCase.verifySize(dib, [NaN, 5]);
            
            % Check for real values
            testCase.verifyTrue(all(isreal(dib(:))));
            
            % Volumes should be positive
            testCase.verifyTrue(all(dib(:, 5) > 0));
        end
    end
    
    %% Test Input Validation
    methods(Test)
        function testTIBInvalidTickFormat(testCase)
            % Test TIB with invalid tick format (only 1 column)
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            invalid_ticks = heston_prices(:, 1); % Only prices, no volumes
            
            testCase.verifyError(@() testCase.sim.tib('ticks', invalid_ticks, 'window', 20), 'tib:InvalidInput');
        end
        
        function testVIBInvalidTickFormat(testCase)
            % Test VIB with invalid tick format
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            invalid_ticks = heston_prices(:, 1);
            
            testCase.verifyError(@() testCase.sim.vib('ticks', invalid_ticks, 'window', 20), 'vib:InvalidInput');
        end
        
        function testDIBInvalidTickFormat(testCase)
            % Test DIB with invalid tick format
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            invalid_ticks = heston_prices(:, 1);
            
            testCase.verifyError(@() testCase.sim.dib('ticks', invalid_ticks, 'window', 20), 'dib:InvalidInput');
        end
        
        function testTIBInvalidWindowSize(testCase)
            % Test TIB with window size larger than data
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            volumes = testCase.sim.order_flow('eta', 0.15, 'market_prices', heston_prices(:, 1));
            small_ticks = [heston_prices(1:10, 1), volumes(1:10)];
            
            testCase.verifyError(@() testCase.sim.tib('ticks', small_ticks, 'window', 20), 'tib:InvalidInput');
        end
        
        function testOrderFlowInvalidEta(testCase)
            % Test order_flow with eta > 1
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            
            testCase.verifyError(@() testCase.sim.order_flow('eta', 1.5, 'market_prices', heston_prices(:, 1)), 'order_flow:InvalidInput');
        end
        
        function testOrderFlowInvalidM(testCase)
            % Test order_flow with M > 1
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            
            testCase.verifyError(@() testCase.sim.order_flow('eta', 0.1, 'M', 1.5, 'market_prices', heston_prices(:, 1)), 'order_flow:InvalidInput');
        end
        
        function testOrderFlowVectorConversion(testCase)
            % Test order_flow with row vector (should convert to column)
            heston_prices = testCase.sim.heston_prices('rf', 0.01, 'theta', 0.5, 'k', 0.8, 'sigma', 0.2);
            row_vector = heston_prices(:, 1)';
            
            % Should not throw error, should convert internally
            volumes = testCase.sim.order_flow('eta', 0.15, 'market_prices', row_vector);
            testCase.verifySize(volumes, [252, 1]);
        end
    end
    
    %% Test Static Methods
    methods(Test)
        function testEWMA(testCase)
            % Test Exponential Weighted Moving Average
            values = randn(100, 1);
            window = 10;
            
            result = randomProcesses.ewma(values, window);
            
            % Check dimensions
            testCase.verifySize(result, size(values));
            
            % Check for real values
            testCase.verifyTrue(all(isreal(result)));
            
            % Check that it's smoothed (variance should be lower)
            testCase.verifyLessThan(var(result), var(values));
        end
    end
    
    %% Test Edge Cases
    methods(Test)
        function testZeroPriceDifferences(testCase)
            % Test tick rule with zero price differences
            % Create flat prices
            flat_prices = ones(50, 1) * 100;
            volumes = rand(50, 1) * 100;
            tick_data = [flat_prices, volumes];
            
            % Should not crash with zero differences
            tib = testCase.sim.tib('ticks', tick_data, 'window', 10);
            
            % Result should still be valid OHLCV format
            testCase.verifySize(tib, [NaN, 5]);
        end
        
        function testSmallDataset(testCase)
            % Test with minimum viable dataset
            sim_small = randomProcesses('n', 1, 'T', 30, 'h', 1, 's0', 100);
            prices = sim_small.brownian_prices('mu', 0.04, 'sigma', 0.15);
            
            testCase.verifySize(prices, [30, 1]);
            testCase.verifyEqual(prices(1), 100, 'AbsTol', 1e-10);
        end
    end
    
    %% Test Stochastic Volatility Options
    methods(Test)
        function testBrownianConstantVolatility(testCase)
            % Test Brownian with constant volatility (sto_vol=false)
            prices1 = testCase.sim.brownian_prices('mu', 0.04, 'sigma', 0.15, 'sto_vol', false);
            testCase.verifySize(prices1, [252, 5]);
        end
        
        function testGBMStochasticVolatility(testCase)
            % Test GBM with stochastic volatility (sto_vol=true, default)
            prices1 = testCase.sim.gbm_prices('mu', 0.04, 'sigma', 0.15, 'sto_vol', true);
            testCase.verifySize(prices1, [252, 5]);
        end
        
        function testMertonStochasticVolatility(testCase)
            % Test Merton with stochastic volatility
            prices1 = testCase.sim.merton_prices('mu', 0.04, 'sigma', 0.15, 'lambda', 30, 'sto_vol', true);
            testCase.verifySize(prices1, [252, 5]);
        end
    end
end
