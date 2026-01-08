# Testing Guide for randomProcesses

This directory contains comprehensive test coverage for the `randomProcesses` MATLAB class.

## Test Files

- **`test_randomProcesses.m`** - Main test suite using MATLAB's unit testing framework
- **`run_all_tests.m`** - Convenience script to run all tests with formatted output

## Running Tests

### Option 1: Using the test runner script (Recommended)

```matlab
>> run_all_tests
```

### Option 2: Using MATLAB's runtests function

```matlab
>> results = runtests('test_randomProcesses')
```

### Option 3: From command line

```bash
matlab -batch "run_all_tests"
```

### Option 4: Run specific test methods

```matlab
>> results = runtests('test_randomProcesses', 'Name', 'testBrownianPrices')
```

## Test Coverage

The test suite covers:

### 1. Class Initialization (4 tests)
- Constructor with default values
- Constructor with custom values
- Dependent property `r0` (initial rate)
- Dependent property `dt` (time delta)

### 2. Stock Price Methods (5 tests)
- Brownian Motion (`brownian_prices`)
- Geometric Brownian Motion (`gbm_prices`)
- Merton Jump-Diffusion Model (`merton_prices`)
- Heston Model (`heston_prices`)
- Single path generation

### 3. Interest Rate Methods (2 tests)
- Vasicek Interest Rate Model (`vas_rates`)
- Cox-Ingersoll-Ross Model (`cir_rates`)

### 4. Utility Methods (4 tests)
- Order Flow (`order_flow`)
- Tick Imbalance Bars (`tib`)
- Volume Imbalance Bars (`vib`)
- Dollar Imbalance Bars (`dib`)

### 5. Input Validation (8 tests)
- Invalid tick data format detection
- Invalid window size detection
- Parameter bounds checking (eta, M)
- Vector shape conversion
- Error message verification

### 6. Static Methods (1 test)
- Exponential Weighted Moving Average (`ewma`)

### 7. Edge Cases (2 tests)
- Zero price differences handling
- Small dataset handling

### 8. Stochastic Volatility Options (3 tests)
- Brownian with constant volatility
- GBM with stochastic volatility
- Merton with stochastic volatility

**Total: 29 test methods**

## Test Structure

Each test method follows this pattern:

```matlab
function testMethodName(testCase)
    % Test description
    
    % 1. Setup: Create test data
    % 2. Execute: Call the method being tested
    % 3. Verify: Assert expected results
    
    testCase.verifyEqual(actual, expected);
    testCase.verifySize(result, expectedSize);
    testCase.verifyError(@() method(), 'expectedErrorID');
end
```

## Verification Methods Used

- `verifyEqual` - Check exact equality (with tolerance)
- `verifySize` - Check array dimensions
- `verifyTrue`/`verifyFalse` - Check boolean conditions
- `verifyError` - Check that expected errors are thrown
- `verifyGreaterThanOrEqual`/`verifyLessThanOrEqual` - Check ordering
- `verifyLessThan` - Check strict inequality

## Adding New Tests

To add a new test:

1. Open `test_randomProcesses.m`
2. Add a new test method in the appropriate section:

```matlab
function testNewFeature(testCase)
    % Test description
    result = testCase.sim.newMethod();
    testCase.verifyEqual(result, expectedValue);
end
```

3. Run the tests to verify the new test works

## Understanding Test Results

When you run tests, you'll see output like:

```
Running testConstructorDefaultValues
.
Running testBrownianPrices
.
...

Total Tests:  29
Passed:       29
Failed:       0
Incomplete:   0
Duration:     5.23 seconds

✓ All tests passed!
```

If a test fails, you'll see details:

```
Failed Tests:
  - testBrownianPrices
    Reason: Verification failed...
    Expected: [252, 5]
    Actual: [252, 4]
```

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run MATLAB tests
  run: matlab -batch "run_all_tests"
```

## Test Data

Tests use randomly generated data with fixed parameters to ensure reproducibility. Each test method runs independently with fresh instances created in the setup phase.

## Known Limitations

- Tests use random number generation, so exact values may vary between runs
- Some stochastic processes may occasionally produce outliers
- Tests verify dimensions, ranges, and statistical properties rather than exact values

## Troubleshooting

**Error: "Undefined function or variable 'randomProcesses'"**
- Solution: Make sure you're running from the repository root directory

**Error: "Test framework not found"**
- Solution: Requires MATLAB R2013a or later with the Testing Framework

**Tests run but some fail intermittently**
- This is expected with stochastic processes
- Failing tests should still pass on retry
- If consistently failing, check the implementation

## Additional Resources

- [MATLAB Unit Testing Framework Documentation](https://www.mathworks.com/help/matlab/matlab-unit-test-framework.html)
- See `REVIEW_SUMMARY.md` for details on recent code improvements
- See `README.md` for usage examples of each method
