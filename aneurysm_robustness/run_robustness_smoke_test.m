function T = run_robustness_smoke_test()
%RUN_ROBUSTNESS_SMOKE_TEST One tiny Stage 3 case; not interpretable.

r = robustness_settings('pilot');
r.output_dir = fullfile(r.root,'robustness_smoke_results');
r.case_dir = fullfile(r.output_dir,'cases');
r.cache_dir = fullfile(r.output_dir,'clean_truth_cache');
r.figure_dir = fullfile(r.output_dir,'figures');
r.table_dir = fullfile(r.output_dir,'tables');
folders = {r.output_dir,r.case_dir,r.cache_dir,r.figure_dir,r.table_dir};
for i = 1:numel(folders)
    if ~exist(folders{i},'dir'), mkdir(folders{i}); end
end

% Make the smoke test genuinely short.
r.engine_overrides.pretrain_wall_iterations = 8;
r.engine_overrides.pretrain_fluid_iterations = 8;
r.engine_overrides.outer_cycles = 2;
r.engine_overrides.fluid_iterations_per_cycle = 3;
r.engine_overrides.full_time_points_per_case = 40;
r.engine_overrides.full_x_points = 15;
r.engine_overrides.classical_max_iter = 8;
r.engine_overrides.forward_Nx = 30;
r.engine_overrides.forward_steps_per_cycle = 120;
r.resume = false;

T = run_single_robustness_case(3,0.02,20,1,r);
disp(T(:,{'method','k_error_percent','eta_error_percent', ...
    'alpha_error_percent','volume_NRMSE_percent', ...
    'energy_residual_common_fullgrid'}));
fprintf(['Smoke test complete. Tiny settings only; do not interpret ' ...
    'the parameter estimates.\n']);
end
