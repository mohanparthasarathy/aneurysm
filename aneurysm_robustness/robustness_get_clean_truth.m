function clean = robustness_get_clean_truth(stage_id,cfg,r)
%ROBUSTNESS_GET_CLEAN_TRUTH Generate or load noise-free full PDE-ODE truth.
%
% The expensive forward simulations are cached once per stage and reused
% for every noise level, sampling density, and random seed.

cacheFile = fullfile(r.cache_dir,sprintf( ...
    'stage%d_Nx%d_steps%d_cycles%d_clean_truth.mat', ...
    stage_id,cfg.forward_Nx,cfg.forward_steps_per_cycle,cfg.cycles_total));
if isfile(cacheFile)
    S = load(cacheFile,'clean');
    clean = S.clean;
    return
end

robustness_setup_paths(r);
stage = build_stage_protocols(stage_id);
p0 = physiological_parameters();
ptrue = p0;
ptrue.k = cfg.truth_multipliers(1)*p0.k;
ptrue.eta = cfg.truth_multipliers(2)*p0.eta;
ptrue.alpha = cfg.truth_multipliers(3)*p0.alpha;

cases = repmat(struct(),stage.n_cases,1);
for j = 1:stage.n_cases
    p = ptrue;
    p.pressure.kind = 'sine';
    p.pressure.amplitude = stage.amplitude_mmHg(j)*133.322;
    p.pressure.frequency_hz = stage.frequency_Hz(j);
    p.pressure.omega = 2*pi*p.pressure.frequency_hz;
    p.pressure.phase = 0;
    p.pressure.ramp_time = 1/p.pressure.frequency_hz;

    T = 1/p.pressure.frequency_hz;
    opts.Nx = cfg.forward_Nx;
    opts.dt = T/cfg.forward_steps_per_cycle;
    opts.tspan = [0,cfg.cycles_total*T];
    sol = solve_forward(p,opts);

    cases(j).amplitude_Pa = p.pressure.amplitude;
    cases(j).frequency_Hz = p.pressure.frequency_hz;
    cases(j).period = T;
    cases(j).sol_truth = sol;
end

clean.stage = stage;
clean.p0 = p0;
clean.ptrue = ptrue;
clean.cases = cases;
clean.cycles_total = cfg.cycles_total;
clean.forward_Nx = cfg.forward_Nx;
clean.forward_steps_per_cycle = cfg.forward_steps_per_cycle;
clean.created = datetime('now');
save(cacheFile,'clean','-v7.3');
fprintf('Cached clean Stage %d truth: %s\n',stage_id,cacheFile);
end
