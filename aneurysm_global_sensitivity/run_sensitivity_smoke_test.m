function run_sensitivity_smoke_test()
%RUN_SENSITIVITY_SMOKE_TEST Fast installation check, not paper-quality.
s=sensitivity_settings(); s.sobol_N=16; s.morris_trajectories=4;
s.dt_per_cycle=200; s.settle_cycles=4; s.analysis_cycles=1;
addpath(s.forward_dir,s.solver_dir); p0=physiological_parameters();
sob=sobol_saltelli(p0,s); mor=morris_screening(p0,s);
disp(sob.ST); disp(mor.mu_star); fprintf('Smoke test passed.\n');
end
