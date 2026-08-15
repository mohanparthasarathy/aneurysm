function cfg = pinn_settings()
%PINN_SETTINGS Deterministic multi-parameter inverse PINN comparison.
root = fileparts(mfilename('fullpath'));
project = fileparts(root);
cfg.root = root;
cfg.data_dir = fullfile(root,'data');
cfg.results_dir = fullfile(root,'results');
cfg.forward_dir = fullfile(project,'aneurysm_forward_solver');
cfg.physics_dir = fullfile(project,'aneurysm_inverse_identifiability');
cfg.forward_physics_dir = fullfile(project,'aneurysm_forward_physics');

% Synthetic full PDE-ODE data.
cfg.seed = 20260802;
cfg.truth_multipliers = [1.30,0.70,1.80]; % [k eta alpha]
cfg.noise_fraction = 0.005;
cfg.forward_Nx = 80;
cfg.forward_steps_per_cycle = 500;
cfg.cycles_total = 5;
cfg.data_points_per_cycle = 80;

% Two-network architecture.
cfg.wall_hidden_width = 48;
cfg.wall_hidden_layers = 4;
cfg.fluid_hidden_width = 48;
cfg.fluid_hidden_layers = 4;

% Shared state pretraining.
cfg.pretrain.wall_iterations = 2500;
cfg.pretrain.fluid_iterations = 2000;

% Deterministic alternating inverse loop.
cfg.inverse.outer_cycles = 8;
cfg.inverse.fluid_iterations_per_cycle = 500;
cfg.inverse.full_time_points_per_case = 500;
cfg.inverse.full_x_points = 81;

% Relaxation applied to [k eta alpha] after each direct least-squares solve.
cfg.inverse.parameter_relaxation = [0.50 0.40 0.35];

% Physiological box bounds as baseline multipliers [k eta alpha].
cfg.inverse.lower_multiplier = [0.20 0.05 0.02];
cfg.inverse.upper_multiplier = [5.00 20.0 50.0];

% Energy branch schedule by outer cycle.
cfg.inverse.energy_weights = [0 50 100 200 400 750 1500 3000];

cfg.display_every = 100;
cfg.checkpoint_every = 25;

% Learning rates.
cfg.learning_rate.wall_pretrain = 3e-4;
cfg.learning_rate.fluid_pretrain = 3e-4;
cfg.learning_rate.fluid_inverse = 5e-5;
cfg.learning_rate.fluid_inverse_final = 1e-5;

% Batch sizes.
cfg.batch.interior = 512;
cfg.batch.wall = 256;
cfg.batch.boundary = 192;
cfg.batch.initial = 192;
cfg.batch.data = 384;
cfg.batch.energy_times = 20;
cfg.batch.energy_x = 32;

% Shared state-pretraining weights.
cfg.pretrain.fluid_pde = 1;
cfg.pretrain.fluid_radiation = 2;
cfg.pretrain.fluid_initial = 5;

% Fluid inverse-refinement weights. Wall network is frozen.
cfg.lambda.pde = 1;
cfg.lambda.wall = 75;
cfg.lambda.radiation = 2;
cfg.lambda.initial = 5;

% Classical full-solver fit.
cfg.classical_Nx = 50;
cfg.classical_steps_per_cycle = 300;
cfg.classical_max_iter = 75;
cfg.classical_display = 'iter';

% Evaluation.
cfg.eval_x_points = 41;
cfg.eval_t_points_per_case = 150;
cfg.save_networks = true;
end
