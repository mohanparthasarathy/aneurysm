function sol = solve_reduced_wall(p, opts)
%SOLVE_REDUCED_WALL Energy-consistent solver for the exact outgoing-wave reduction.
%
% For a purely outgoing fluid wave,
%   u_x(0,t) = -w_dot/c_f,
% so the coupled model reduces exactly to
%
%   m_w*w_ddot + (eta + rho_f*c_f*A_f)*w_dot
%       + k*w + alpha*w^3 = A_eff*p_tilde(t).
%
% The method is implicit midpoint with a discrete-gradient cubic force.

if nargin < 2, opts = struct(); end
if ~isfield(opts,'dt'), opts.dt = 1e-4; end
if ~isfield(opts,'tspan'), opts.tspan = [0 1]; end
if ~isfield(opts,'w0'), opts.w0 = 0; end
if ~isfield(opts,'v0'), opts.v0 = 0; end
if ~isfield(opts,'newton_tol'), opts.newton_tol = 1e-11; end
if ~isfield(opts,'newton_abs_tol'), opts.newton_abs_tol = 1e-14; end
if ~isfield(opts,'newton_maxit'), opts.newton_maxit = 30; end

t0 = opts.tspan(1);
tf = opts.tspan(2);
Nt = ceil((tf-t0)/opts.dt);
dt = (tf-t0)/Nt;
t = linspace(t0,tf,Nt+1).';

w = zeros(Nt+1,1);
v = zeros(Nt+1,1);
w(1) = opts.w0;
v(1) = opts.v0;

m = p.m_w;
c = p.eta + p.rho_f*p.c_f*p.A_f;
k = p.k;
A = p.A_eff;

for n = 1:Nt
    wn = w(n);
    vn = v(n);
    tm = 0.5*(t(n)+t(n+1));
    pm = pressure_forcing(tm,p);

    wnew = wn + dt*vn;
    vnew = vn;

    converged = false;
    for it = 1:opts.newton_maxit
        vm = 0.5*(vn+vnew);
        wm = 0.5*(wn+wnew);

        g = (p.alpha/4)*(wnew+wn)*(wnew^2+wn^2);
        dg = (p.alpha/4)*(3*wnew^2+2*wn*wnew+wn^2);

        R1 = wnew-wn-dt*vm;
        R2 = m*(vnew-vn)-dt*(A*pm-c*vm-k*wm-g);
        R = [R1;R2];

        scale = max([abs(m*(vnew-vn)), ...
            dt*abs(A*pm-c*vm-k*wm-g),1e-30]);
        tol = opts.newton_abs_tol + opts.newton_tol*scale;
        if norm(R,inf) <= tol
            converged = true;
            break
        end

        J = [1, -dt/2;
             dt*(k/2+dg), m+dt*c/2];

        delta = -J\R;
        wnew = wnew+delta(1);
        vnew = vnew+delta(2);
    end

    if ~converged
        error('Reduced-wall Newton solve failed at t=%g.',t(n+1));
    end

    w(n+1) = wnew;
    v(n+1) = vnew;
end

sol.t = t;
sol.w = w;
sol.wdot = v;
sol.V = p.V_ref+p.A_eff*w;
sol.params = p;
sol.dt = dt;
end
