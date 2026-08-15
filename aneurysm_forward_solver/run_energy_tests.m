function results = run_energy_tests()
%RUN_ENERGY_TESTS Check conservative and dissipative cases.

%% Conservative: eta=0, reflecting boundary, no forcing, linear wall.
p = default_parameters();
p.eta = 0;
p.alpha = 0;
p.boundary = 'reflecting';
p.pressure.kind = 'zero';

Nx = 200;
model = build_semidiscrete_model(p,Nx);
x = model.x;
q0 = 2e-5*cos(pi*x/(2*p.L));
v0 = zeros(size(q0));

solC = solve_forward(p,struct('Nx',Nx,'dt',2e-4,'tspan',[0,0.5], ...
    "q0",q0,'v0',v0));
dC = evaluate_energy(solC);
drift = max(abs(dC.E-dC.E(1)))/abs(dC.E(1));

fprintf("Conservative test: max relative energy drift = %.3e\n",drift);

%% Dissipative: eta>0 and radiation, no forcing.
p = default_parameters();
p.alpha = 0;
p.boundary = 'radiation';
p.pressure.kind = 'zero';

model = build_semidiscrete_model(p,Nx);
x = model.x;
q0 = 2e-5*cos(pi*x/(2*p.L));
v0 = zeros(size(q0));

solD = solve_forward(p,struct('Nx',Nx,'dt',2e-4,'tspan',[0,0.5], ...
    "q0",q0,'v0',v0));
dD = evaluate_energy(solD);
monotonicity_violation = max(diff(dD.E));

fprintf("Dissipative test: E(tf)/E(0) = %.6f\n",dD.E(end)/dD.E(1));
fprintf("Largest positive energy increment = %.3e J\n",monotonicity_violation);
fprintf('Relative midpoint energy-balance error = %.3e\n',dD.relative_balance_error);

figure;
plot(solC.t,dC.E/dC.E(1),"LineWidth",1.5);
xlabel("t (s)"); ylabel("E(t)/E(0)");
title("Conservative test: \eta=0, reflecting boundary");
grid on;

figure;
plot(solD.t,dD.E/dD.E(1),"LineWidth",1.5);
xlabel("t (s)"); ylabel("E(t)/E(0)");
title("Dissipative test: wall damping and radiation");
grid on;

results.conservative.solution = solC;
results.conservative.diagnostics = dC;
results.conservative.relative_drift = drift;
results.dissipative.solution = solD;
results.dissipative.diagnostics = dD;
results.dissipative.max_positive_increment = monotonicity_violation;
end
