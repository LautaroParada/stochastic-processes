% run_all_tests.m
% Script to run all tests for the randomProcesses class
%
% Usage:
%   Simply run this script in MATLAB:
%   >> run_all_tests
%
% Or run from command line:
%   matlab -batch "run_all_tests"

fprintf('=======================================================\n');
fprintf('Running Test Suite for randomProcesses Class\n');
fprintf('=======================================================\n\n');

% Add the class to the path if needed
addpath('@randomProcesses');

% Run the test suite
try
    % Run tests and capture results
    results = runtests('test_randomProcesses');
    
    % Display summary
    fprintf('\n=======================================================\n');
    fprintf('Test Results Summary\n');
    fprintf('=======================================================\n');
    fprintf('Total Tests:  %d\n', numel(results));
    fprintf('Passed:       %d\n', sum([results.Passed]));
    fprintf('Failed:       %d\n', sum([results.Failed]));
    fprintf('Incomplete:   %d\n', sum([results.Incomplete]));
    fprintf('Duration:     %.2f seconds\n', sum([results.Duration]));
    fprintf('=======================================================\n\n');
    
    % Display details for failed tests
    failed_tests = results(~[results.Passed]);
    if ~isempty(failed_tests)
        fprintf('Failed Tests:\n');
        for i = 1:numel(failed_tests)
            fprintf('  - %s\n', failed_tests(i).Name);
            if ~isempty(failed_tests(i).Details.DiagnosticRecord)
                fprintf('    Reason: %s\n', failed_tests(i).Details.DiagnosticRecord.Report);
            end
        end
        fprintf('\n');
    end
    
    % Exit with appropriate code
    if all([results.Passed])
        fprintf('✓ All tests passed!\n\n');
        exit(0);
    else
        fprintf('✗ Some tests failed.\n\n');
        exit(1);
    end
catch ME
    fprintf('\n=======================================================\n');
    fprintf('ERROR: Test execution failed\n');
    fprintf('=======================================================\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  File: %s\n', ME.stack(i).file);
        fprintf('  Line: %d\n', ME.stack(i).line);
        fprintf('  Function: %s\n', ME.stack(i).name);
    end
    exit(1);
end
