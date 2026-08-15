function diag = evaluate_energy(sol)
%EVALUATE_ENERGY Discrete energy and midpoint power-balance diagnostics.
%
% For the linear wall law, the implicit midpoint update satisfies exactly
%
% E_{n+1}-E_n = dt*(P_in,m - D_wall,m - D_rad,m)
%
% up to Newton and floating-point error. Therefore the cumulative work is
% evaluated at step midpoints rather than by trapezoidal integration of
% nodal powers.

p = sol.params;
model = sol.model;
Nt = numel(sol.t);

E = zeros(Nt,1);
Pin = zeros(Nt,1);
Dwall = zeros(Nt,1);
Drad = zeros(Nt,1);

for n = 1:Nt
    q = sol.q(:,n);
    v = sol.v(:,n);

    E(n) = 0.5*v.'*model.M*v + 0.5*q.'*model.K*q ...
        + 0.25*p.alpha*q(1)^4;

    pt = pressure_forcing(sol.t(n),p);
    Pin(n) = p.A_eff*pt*v(1);
    Dwall(n) = p.eta*v(1)^2;
    Drad(n) = model.radiation_coefficient*v(end)^2;
end

% Step-midpoint powers, consistent with implicit midpoint.
nsteps = Nt-1;
Pin_mid = zeros(nsteps,1);
Dwall_mid = zeros(nsteps,1);
Drad_mid = zeros(nsteps,1);
step_work = zeros(nsteps,1);

for n = 1:nsteps
    dt = sol.t(n+1)-sol.t(n);
    tm = 0.5*(sol.t(n+1)+sol.t(n));
    vm = 0.5*(sol.v(:,n+1)+sol.v(:,n));

    Pin_mid(n) = p.A_eff*pressure_forcing(tm,p)*vm(1);
    Dwall_mid(n) = p.eta*vm(1)^2;
    Drad_mid(n) = model.radiation_coefficient*vm(end)^2;
    step_work(n) = dt*(Pin_mid(n)-Dwall_mid(n)-Drad_mid(n));
end

work = [0; cumsum(step_work)];
balance_error = E-E(1)-work;

diag.E = E;
diag.Pin = Pin;
diag.Dwall = Dwall;
diag.Drad = Drad;
diag.Pin_mid = Pin_mid;
diag.Dwall_mid = Dwall_mid;
diag.Drad_mid = Drad_mid;
diag.step_work = step_work;
diag.cumulative_net_work = work;
diag.balance_error = balance_error;
diag.max_abs_balance_error = max(abs(balance_error));

% A forced run may start from E(0)=0, so normalizing by E(0) is meaningless.
% Use the largest physically relevant accumulated energy/work scale instead.
energy_scale = max([max(abs(E)), max(abs(work)), ...
    sum(abs(step_work)), eps]);
diag.energy_balance_scale = energy_scale;
diag.relative_balance_error = diag.max_abs_balance_error / energy_scale;
end
