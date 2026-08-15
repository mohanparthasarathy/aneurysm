function dataset = robustness_build_dataset(clean,cfg,noise_fraction,points_per_cycle,seed_id)
%ROBUSTNESS_BUILD_DATASET Add controlled noise and temporal sparsity.

rng(cfg.seed + 7919*seed_id,'twister');
cases = clean.cases;
excursions = zeros(numel(cases),1);

% Build clean observations at the requested points per cycle.
for j = 1:numel(cases)
    sol = cases(j).sol_truth;
    nObs = clean.cycles_total*points_per_cycle + 1;
    tObs = linspace(sol.t(1),sol.t(end),nObs)';
    Vclean = interp1(sol.t,sol.V,tObs,'pchip');
    cases(j).t_obs = tObs;
    cases(j).V_clean = Vclean;
    excursions(j) = max(Vclean)-min(Vclean);
end

% One physically comparable noise scale for all cases in the protocol.
noiseScale = noise_fraction*median(excursions);
for j = 1:numel(cases)
    noise = noiseScale*randn(size(cases(j).V_clean));
    cases(j).V_obs = cases(j).V_clean + noise;
    cases(j).w_obs = (cases(j).V_obs-clean.ptrue.V_ref)/clean.ptrue.A_eff;
end

dataset.stage = clean.stage;
dataset.p0 = clean.p0;
dataset.ptrue = clean.ptrue;
dataset.cases = cases;
dataset.noise_scale_m3 = noiseScale;
dataset.noise_fraction = noise_fraction;
dataset.points_per_cycle = points_per_cycle;
dataset.seed_id = seed_id;
dataset.created = datetime('now');
end
