function dataset = generate_pinn_synthetic_data(stage_id,cfg)
%GENERATE_PINN_SYNTHETIC_DATA Full PDE-ODE synthetic observations and truth.
if nargin < 2, cfg = pinn_settings(); end
addpath(cfg.forward_dir,cfg.physics_dir,cfg.forward_physics_dir);
if ~exist(cfg.data_dir,'dir'), mkdir(cfg.data_dir); end
rng(cfg.seed + stage_id,'twister');
stage = build_stage_protocols(stage_id);
p0 = physiological_parameters();
ptrue = p0;
ptrue.k = cfg.truth_multipliers(1)*p0.k;
ptrue.eta = cfg.truth_multipliers(2)*p0.eta;
ptrue.alpha = cfg.truth_multipliers(3)*p0.alpha;

cases = repmat(struct(),stage.n_cases,1);
all_excursions = zeros(stage.n_cases,1);
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
    nObs = cfg.cycles_total*cfg.data_points_per_cycle + 1;
    tObs = linspace(sol.t(1),sol.t(end),nObs)';
    Vclean = interp1(sol.t,sol.V,tObs,'pchip');
    all_excursions(j) = max(Vclean)-min(Vclean);
    cases(j).amplitude_Pa = p.pressure.amplitude;
    cases(j).frequency_Hz = p.pressure.frequency_hz;
    cases(j).period = T;
    cases(j).t_obs = tObs;
    cases(j).V_clean = Vclean;
    cases(j).sol_truth = sol;
end
noise_scale = cfg.noise_fraction*median(all_excursions);
for j = 1:stage.n_cases
    cases(j).V_obs = cases(j).V_clean + noise_scale*randn(size(cases(j).V_clean));
    cases(j).w_obs = (cases(j).V_obs-ptrue.V_ref)/ptrue.A_eff;
end

dataset.stage = stage;
dataset.p0 = p0;
dataset.ptrue = ptrue;
dataset.cases = cases;
dataset.noise_scale_m3 = noise_scale;
dataset.noise_fraction = cfg.noise_fraction;
dataset.created = datetime('now');
file = fullfile(cfg.data_dir,[stage.name '_synthetic.mat']);
save(file,'dataset','-v7.3');
fprintf('Saved %s\n',file);
end
