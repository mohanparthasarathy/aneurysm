%% EXAMPLE_FORWARD_RUN
clear; clc; close all;

p = default_parameters();
p.alpha = 2.0e7;
p.eta = 0.020;
p.boundary = 'radiation';
p.pressure.kind = 'sine';
p.pressure.amplitude = 250;
p.pressure.omega = 2*pi*1.2;
p.pressure.ramp_time = 0.05;

sol = solve_forward(p,struct('Nx',250,'dt',1e-4,'tspan',[0,1.5]));
diag = evaluate_energy(sol);

plot_forward_solution(sol);

figure;
plot(sol.t,diag.E,"LineWidth",1.5);
xlabel("t (s)"); ylabel("E(t) (J)");
title("Total discrete mechanical energy");
grid on;

fprintf("Relative midpoint energy-balance error: %.3e\n", ...
    diag.relative_balance_error);
