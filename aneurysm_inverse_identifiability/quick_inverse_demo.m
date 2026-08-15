%% QUICK_INVERSE_DEMO
shared_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'aneurysm_forward_physics');
addpath(shared_dir);
% Fast smoke test before running the complete Monte Carlo study.
clear; clc; close all;

s = inverse_study_settings();
s.n_monte_carlo = 3;
s.n_multistart = 3;
s.volume_noise_fraction = [0.005 0.01];
s.protocols = s.protocols([1 2 4]);
s.run_profile_likelihood = false;
s.output_dir = fullfile(pwd,'inverse_identifiability_quick_results');

if ~exist(s.output_dir,'dir'), mkdir(s.output_dir); end
p = physiological_parameters();

run_structural_identifiability(p,s);
run_practical_identifiability(p,s);

fprintf('\nQuick inverse demo complete.\n');
