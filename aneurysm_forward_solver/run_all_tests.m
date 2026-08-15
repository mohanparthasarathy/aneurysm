%% RUN_ALL_TESTS
% Add this folder to the MATLAB path, then run this script.

clear; clc; close all;

fprintf("\n=== ENERGY TESTS ===\n");
energy_results = run_energy_tests();

fprintf("\n=== LINEAR ANALYTICAL VALIDATION ===\n");
analytic_result = run_analytic_validation();

fprintf("\n=== MANUFACTURED-SOLUTION CONVERGENCE ===\n");
convergence_table = run_manufactured_convergence();

fprintf("\nAll tests completed.\n");
