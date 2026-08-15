%% RUN_INVERSE_IDENTIFIABILITY_STUDY
clear; clc; close all;

shared_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'aneurysm_forward_physics');
addpath(shared_dir);

s = inverse_study_settings();
rng(s.random_seed,'twister');
if ~exist(s.output_dir,'dir'), mkdir(s.output_dir); end

p = physiological_parameters();
truth = effective_volume_parameters(p);

fprintf('\nEffective volume-domain truth:\n');
fprintf('  K_V = %.6e Pa/m^3\n',truth.K_V);
fprintf('  R_V = %.6e Pa s/m^3\n',truth.R_V);
fprintf('  A_V = %.6e Pa/m^9\n',truth.A_V);
fprintf('  C_0 = %.6f uL/mmHg\n',truth.C0_uL_per_mmHg);

structural_summary = run_structural_identifiability(p,s);
practical_results = run_practical_identifiability(p,s);

if s.run_profile_likelihood
    profiles = run_profile_likelihood(p,s); %#ok<NASGU>
end

save(fullfile(s.output_dir,'inverse_study_workspace.mat'), ...
    's','p','truth','structural_summary','practical_results');

fprintf('\nInverse identifiability study complete.\n');
fprintf('Results written to:\n%s\n',s.output_dir);
