function dydt = coupled_rhs(t, y, p, model)
%COUPLED_RHS First-order semidiscrete PDE-ODE right-hand side.
%
% y = [q; v], where q(1)=w=u(0,t), q(2:end)=u(x_j,t),
% and v = dq/dt.

nq = numel(model.x);
q = y(1:nq);
v = y(nq+1:end);

fext = model.b * pressure_forcing(t,p);
fnl = zeros(nq,1);
fnl(1) = p.alpha * q(1)^3;

a = (fext - model.C*v - model.K*q - fnl) ./ model.Mdiag;
dydt = [v; a];
end
