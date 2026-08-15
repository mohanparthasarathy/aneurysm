function sol = solve_volume_inverse_model(theta,t,pressure,v0,vdot0)
%SOLVE_VOLUME_INVERSE_MODEL Energy-consistent volume-domain forward solver.
%
% theta = [K_V R_V A_V], while M_V is passed as theta(4) when desired.
% Preferred input is a structure with fields M_V,K_V,R_V,A_V.
%
% Pressure may be a vector sampled at t or a function handle.

if isstruct(theta)
    M = theta.M_V;
    K = theta.K_V;
    R = theta.R_V;
    A = theta.A_V;
else
    if numel(theta) ~= 4
        error('Numeric theta must be [M_V K_V R_V A_V].');
    end
    M = theta(1); K = theta(2); R = theta(3); A = theta(4);
end

t = t(:);
if nargin < 4 || isempty(v0), v0 = 0; end
if nargin < 5 || isempty(vdot0), vdot0 = 0; end

if isa(pressure,'function_handle')
    pfun = pressure;
else
    pressure = pressure(:);
    if numel(pressure) ~= numel(t)
        error('Pressure vector and time vector must have the same length.');
    end
    pfun = @(tt) interp1(t,pressure,tt,'linear','extrap');
end

N = numel(t);
v = zeros(N,1);
q = zeros(N,1);
v(1) = v0;
q(1) = vdot0;

newton_rel = 1e-11;
newton_abs = 1e-15;
newton_max = 35;

for n = 1:N-1
    dt = t(n+1)-t(n);
    if dt <= 0, error('Time samples must be strictly increasing.'); end

    vn = v(n);
    qn = q(n);
    tm = 0.5*(t(n)+t(n+1));
    pm = pfun(tm);

    vnew = vn+dt*qn;
    qnew = qn;

    converged = false;
    for it = 1:newton_max
        vm = 0.5*(vn+vnew);
        qm = 0.5*(qn+qnew);

        % Discrete gradient of A*v^4/4.
        g = (A/4)*(vnew+vn)*(vnew^2+vn^2);
        dg = (A/4)*(3*vnew^2+2*vn*vnew+vn^2);

        F1 = vnew-vn-dt*qm;
        F2 = M*(qnew-qn)-dt*(pm-R*qm-K*vm-g);
        F = [F1;F2];

        scale = max([abs(vnew),abs(vn),dt*abs(qm), ...
            abs(M*(qnew-qn)),dt*abs(pm),1e-30]);
        if norm(F,inf) <= newton_abs+newton_rel*scale
            converged = true;
            break
        end

        J = [1, -dt/2;
             dt*(K/2+dg), M+dt*R/2];
        step = -J\F;
        vnew = vnew+step(1);
        qnew = qnew+step(2);
    end

    if ~converged
        error('Volume-model Newton iteration failed at t = %.8g.',t(n+1));
    end

    v(n+1) = vnew;
    q(n+1) = qnew;
end

sol.t = t;
sol.v = v;
sol.vdot = q;
sol.pressure = arrayfun(pfun,t);
end
