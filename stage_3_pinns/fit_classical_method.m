function result = fit_classical_method(dataset,cfg)
%FIT_CLASSICAL_METHOD Fit active parameters with verified full PDE-ODE solver.
addpath(cfg.forward_dir,cfg.physics_dir,cfg.forward_physics_dir);
mask = double(dataset.stage.active(:));
obj = @(z) classical_objective(z,dataset,cfg,mask);
options = optimset('Display',cfg.classical_display,'MaxIter',cfg.classical_max_iter, ...
    'MaxFunEvals',8*cfg.classical_max_iter,'TolX',1e-4,'TolFun',1e-4);
tic;
[z,fval,exitflag,output] = fminsearch(obj,zeros(sum(mask),1),options);
runtime = toc;
theta = zeros(3,1); theta(logical(mask)) = z;
pfit = dataset.p0;
pfit.k = pfit.k*exp(theta(1));
pfit.eta = pfit.eta*exp(theta(2));
pfit.alpha = pfit.alpha*exp(theta(3));
result.runtime_s = runtime;
result.theta = theta;
result.parameter_estimates = pfit;
result.objective = fval;
result.exitflag = exitflag;
result.output = output;
end

function J = classical_objective(z,dataset,cfg,mask)
theta = zeros(3,1); theta(logical(mask)) = z;
p = dataset.p0;
p.k = p.k*exp(theta(1)); p.eta = p.eta*exp(theta(2)); p.alpha = p.alpha*exp(theta(3));
res = [];
try
    for j = 1:numel(dataset.cases)
        c = dataset.cases(j);
        pj = p;
        pj.pressure.amplitude = c.amplitude_Pa;
        pj.pressure.frequency_hz = c.frequency_Hz;
        pj.pressure.omega = 2*pi*c.frequency_Hz;
        pj.pressure.phase = 0; pj.pressure.ramp_time = 1/c.frequency_Hz;
        opts.Nx = cfg.classical_Nx;
        opts.dt = c.period/cfg.classical_steps_per_cycle;
        opts.tspan = [0,c.t_obs(end)];
        sol = solve_forward(pj,opts);
        V = interp1(sol.t,sol.V,c.t_obs,'pchip');
        scale = max(max(c.V_obs)-min(c.V_obs),dataset.noise_scale_m3);
        res = [res;(V-c.V_obs)/scale]; %#ok<AGROW>
    end
    J = mean(res.^2) + 1e-6*sum(z.^2);
    if ~isfinite(J), J=1e12; end
catch
    J = 1e12 + sum(z.^2);
end
end
