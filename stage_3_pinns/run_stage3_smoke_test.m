function results = run_stage3_smoke_test()
%RUN_STAGE3_SMOKE_TEST Fast execution test for deterministic [k,eta,alpha].
%
% This test deliberately skips the classical optimizer because the
% three-parameter full-solver fit is expensive. It only verifies that:
%
%   1) the Stage 3 synthetic dataset is generated;
%   2) the deterministic parameter system has rank 3;
%   3) k, eta, and alpha are all updated;
%   4) the PINN and Energy-PINN branches execute successfully.
%
% The tiny grids and iteration counts make the numerical estimates
% scientifically meaningless. Do not interpret parameter accuracy.

cfg = pinn_settings();

%% Separate smoke-test folders
cfg.data_dir = fullfile(cfg.root,'data_smoke_stage3');
cfg.results_dir = fullfile(cfg.root,'results_smoke_stage3');

if ~exist(cfg.data_dir,'dir')
    mkdir(cfg.data_dir);
end

if ~exist(cfg.results_dir,'dir')
    mkdir(cfg.results_dir);
end

%% Small forward-solver settings
cfg.forward_Nx = 30;
cfg.forward_steps_per_cycle = 120;
cfg.cycles_total = 2;
cfg.data_points_per_cycle = 20;

%% Very short neural-network training
cfg.pretrain.wall_iterations = 8;
cfg.pretrain.fluid_iterations = 8;

%% Very short deterministic inverse loop
cfg.inverse.outer_cycles = 2;
cfg.inverse.fluid_iterations_per_cycle = 3;
cfg.inverse.full_time_points_per_case = 40;
cfg.inverse.full_x_points = 15;

% First cycle has no energy term; second cycle activates a small one.
cfg.inverse.energy_weights = [0 25];

%% Small batches
cfg.batch.interior = 32;
cfg.batch.wall = 16;
cfg.batch.boundary = 16;
cfg.batch.initial = 16;
cfg.batch.data = 24;
cfg.batch.energy_times = 4;
cfg.batch.energy_x = 8;

cfg.display_every = 1;

%% Paths
addpath(cfg.root,cfg.forward_dir,cfg.physics_dir);

%% Generate Stage 3 data
% Stage 3 activates:
%   k
%   eta
%   alpha
dataset = generate_pinn_synthetic_data(3,cfg);

fprintf('\n=== STAGE 3 SMOKE TEST ===\n');
fprintf('Active parameters: k, eta, alpha\n');
fprintf('Classical optimizer skipped for speed.\n');

%% Shared wall and fluid pretraining
results.shared = pretrain_two_network_pinn(dataset,cfg);

%% Standard PINN
results.pinn = train_pinn_method( ...
    dataset,cfg,false,results.shared);

%% Energy-informed PINN
results.energy_pinn = train_pinn_method( ...
    dataset,cfg,true,results.shared);

%% Compact diagnostic summary
fprintf('\n=== STAGE 3 SMOKE-TEST SUMMARY ===\n');

fprintf('\nPINN final parameter ratios:\n');
fprintf('  k/k0         = %.6f\n', ...
    results.pinn.final_parameter_estimates.k/dataset.p0.k);
fprintf('  eta/eta0     = %.6f\n', ...
    results.pinn.final_parameter_estimates.eta/dataset.p0.eta);
fprintf('  alpha/alpha0 = %.6f\n', ...
    results.pinn.final_parameter_estimates.alpha/dataset.p0.alpha);

fprintf('\nEnergy-PINN final parameter ratios:\n');
fprintf('  k/k0         = %.6f\n', ...
    results.energy_pinn.final_parameter_estimates.k/dataset.p0.k);
fprintf('  eta/eta0     = %.6f\n', ...
    results.energy_pinn.final_parameter_estimates.eta/dataset.p0.eta);
fprintf('  alpha/alpha0 = %.6f\n', ...
    results.energy_pinn.final_parameter_estimates.alpha/dataset.p0.alpha);

fprintf(['\nStage-3 smoke test completed. Tiny grids and iteration ' ...
    'counts only; do not interpret parameter estimates.\n']);
fprintf(['The important checks are rank = 3, finite condition number, ' ...
    'and movement in all three parameters.\n']);
end