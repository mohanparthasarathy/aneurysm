function nrms = common_energy_residual_metric(model,pfit,dataset,cfg)
%COMMON_ENERGY_RESIDUAL_METRIC Full-grid normalized energy residual.

terms = collect_affine_residual_terms(model,pfit,dataset,cfg);
parameters = [pfit.k;pfit.eta;pfit.alpha];
rE = terms.Ae*parameters + terms.Be;
nrms = sqrt(mean(rE.^2));
end
