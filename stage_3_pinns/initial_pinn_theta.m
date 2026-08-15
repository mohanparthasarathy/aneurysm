function theta = initial_pinn_theta(cfg)
%INITIAL_PINN_THETA Raw variables corresponding to baseline multiplier one.
lo = cfg.parameter_lower_multiplier(:);
hi = cfg.parameter_upper_multiplier(:);
z = (1-lo)./(hi-lo);
z = min(max(z,1e-8),1-1e-8);
theta = dlarray(log(z./(1-z)));
end
