function info = deterministic_parameter_update( ...
    model,pcurrent,dataset,cfg,useEnergy,lambdaE)
%DETERMINISTIC_PARAMETER_UPDATE Direct update for active [k eta alpha].

terms = collect_affine_residual_terms(model,pcurrent,dataset,cfg);

if useEnergy
    usedLambdaE = lambdaE;
else
    usedLambdaE = 0;
end

opt = solve_bounded_affine_parameters(terms,pcurrent,dataset,cfg, ...
    cfg.lambda.wall,usedLambdaE);

current = [pcurrent.k;pcurrent.eta;pcurrent.alpha];
active = logical(dataset.stage.active(:));
relax = cfg.inverse.parameter_relaxation(:);

updated = current;
updated(active) = (1-relax(active)).*current(active) + ...
    relax(active).*opt.parameters_bounded(active);

metrics = evaluate_affine_residuals(terms,updated, ...
    cfg.lambda.wall,usedLambdaE);

info.parameters_raw = opt.parameters_raw;
info.parameters_bounded = opt.parameters_bounded;
info.parameters_updated = updated;
info.parameter_ratios_raw = opt.parameter_ratios_raw;
info.parameter_ratios_updated = updated ./ ...
    [dataset.p0.k;dataset.p0.eta;dataset.p0.alpha];
info.wall_residual_rms = metrics.wall_rms;
info.energy_residual_rms = metrics.energy_rms;
info.condition_number = opt.condition_number;
info.rank = opt.rank;
info.lambda_energy = usedLambdaE;
end
