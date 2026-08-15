function results = run_pinn_smoke_test()
%RUN_PINN_SMOKE_TEST Fast deterministic Stage-1 execution test.
cfg = pinn_settings();
cfg.forward_Nx = 30;
cfg.forward_steps_per_cycle = 150;
cfg.cycles_total = 2;
cfg.data_points_per_cycle = 25;
cfg.classical_Nx = 25;
cfg.classical_steps_per_cycle = 120;
cfg.classical_max_iter = 8;
cfg.classical_display = 'off';

cfg.pretrain.wall_iterations = 4;
cfg.pretrain.fluid_iterations = 4;
cfg.inverse.outer_cycles = 2;
cfg.inverse.fluid_iterations_per_cycle = 3;
cfg.inverse.full_time_points_per_case = 40;
cfg.inverse.full_x_points = 15;
cfg.inverse.energy_weights = [0 25];
cfg.display_every = 1;

cfg.batch.interior = 32;
cfg.batch.wall = 16;
cfg.batch.boundary = 16;
cfg.batch.initial = 16;
cfg.batch.data = 24;
cfg.batch.energy_times = 4;
cfg.batch.energy_x = 8;

addpath(cfg.root,cfg.forward_dir,cfg.physics_dir);
dataset = generate_pinn_synthetic_data(1,cfg);
results.classical = fit_classical_method(dataset,cfg);
results.shared = pretrain_two_network_pinn(dataset,cfg);
results.pinn = train_pinn_method(dataset,cfg,false,results.shared);
results.energy_pinn = train_pinn_method( ...
    dataset,cfg,true,results.shared);

fprintf(['Deterministic-k PINN smoke test completed. ' ...
    'Tiny grids and iteration counts only; do not interpret estimates.\n']);
end
