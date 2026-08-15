function [pfit,multipliers] = decode_pinn_parameters(theta,dataset,cfg)
%DECODE_PINN_PARAMETERS Bounded positive parameter transform.
p0 = dataset.p0;
active = double(dataset.stage.active(:));
lo = cfg.parameter_lower_multiplier(:);
hi = cfg.parameter_upper_multiplier(:);
sig = 1./(1+exp(-theta(:)));
multipliers = lo+(hi-lo).*sig;
multipliers = active.*multipliers+(1-active);
pfit = p0;
pfit.k = p0.k*multipliers(1);
pfit.eta = p0.eta*multipliers(2);
pfit.alpha = p0.alpha*multipliers(3);
end
