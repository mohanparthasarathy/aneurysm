%% RUN_ALL_FORWARD_PHYSICS
clear; clc; close all;

p = physiological_parameters();
disp(p.metadata);

write_parameter_table('physiological_parameter_table.csv');
results = run_forward_physics_tests('forward_physics_results');

fprintf('\nForward-physics study complete.\n');
