function cfg = robustness_engine_config(r,stage_id,noise_fraction,points_per_cycle,seed_id,case_id)
%ROBUSTNESS_ENGINE_CONFIG Build one isolated Stage 1/2/3 engine config.

robustness_setup_paths(r);
cfg = pinn_settings();

% Keep each robustness case in an isolated output directory.
cfg.root = r.engine_dir;
cfg.data_dir = fullfile(r.case_dir,case_id,'data');
cfg.results_dir = fullfile(r.case_dir,case_id,'engine_results');
if ~exist(cfg.data_dir,'dir'), mkdir(cfg.data_dir); end
if ~exist(cfg.results_dir,'dir'), mkdir(cfg.results_dir); end

cfg.forward_dir = r.forward_dir;
cfg.physics_dir = r.physics_dir;
cfg.forward_physics_dir = r.forward_physics_dir;
% Paired design: the same seed gives the same network initialization and,
% at fixed sampling density, the same standardized noise realization across
% noise levels. This reduces Monte Carlo variance in robustness comparisons.
cfg.seed = r.base_seed + 10000*stage_id + 100*seed_id;
cfg.noise_fraction = noise_fraction;
cfg.data_points_per_cycle = points_per_cycle;
cfg.save_networks = r.save_networks;
cfg.classical_display = 'off';

% Optional pilot overrides.
o = r.engine_overrides;
if isfield(o,'pretrain_wall_iterations')
    cfg.pretrain.wall_iterations = o.pretrain_wall_iterations;
end
if isfield(o,'pretrain_fluid_iterations')
    cfg.pretrain.fluid_iterations = o.pretrain_fluid_iterations;
end
if isfield(o,'outer_cycles')
    cfg.inverse.outer_cycles = o.outer_cycles;
    cfg.inverse.energy_weights = cfg.inverse.energy_weights( ...
        1:min(o.outer_cycles,numel(cfg.inverse.energy_weights)));
end
if isfield(o,'fluid_iterations_per_cycle')
    cfg.inverse.fluid_iterations_per_cycle = o.fluid_iterations_per_cycle;
end
if isfield(o,'full_time_points_per_case')
    cfg.inverse.full_time_points_per_case = o.full_time_points_per_case;
end
if isfield(o,'full_x_points')
    cfg.inverse.full_x_points = o.full_x_points;
end
if isfield(o,'classical_max_iter')
    cfg.classical_max_iter = o.classical_max_iter;
end
if isfield(o,'forward_Nx')
    cfg.forward_Nx = o.forward_Nx;
end
if isfield(o,'forward_steps_per_cycle')
    cfg.forward_steps_per_cycle = o.forward_steps_per_cycle;
end
end
