function [sol,metrics] = run_single_physics_case(p, settings)
%RUN_SINGLE_PHYSICS_CASE Run enough cycles to estimate steady-cycle metrics.

if nargin < 2
    settings = struct();
end
if ~isfield(settings,'Nx'), settings.Nx = 60; end
if ~isfield(settings,'cycles'), settings.cycles = 7; end
if ~isfield(settings,'analyze_cycles'), settings.analyze_cycles = 2; end
if ~isfield(settings,'steps_per_cycle'), settings.steps_per_cycle = 1200; end
if ~isfield(settings,'max_dt'), settings.max_dt = 5e-4; end

T = 2*pi/p.pressure.omega;
p.pressure.ramp_time = T;
dt = min(T/settings.steps_per_cycle,settings.max_dt);
tf = settings.cycles*T;

opts = struct('Nx',settings.Nx,'dt',dt,'tspan',[0,tf], ...
    'newton_tol',1e-10,'newton_abs_tol',1e-14, ...
    'newton_maxit',25);
sol = solve_forward(p,opts);
metrics = analyze_steady_cycles(sol,settings.analyze_cycles);
end
