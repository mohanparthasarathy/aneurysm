function sol = solve_forward(p, opts)
%SOLVE_FORWARD Implicit-midpoint solver for the coupled forward model.
%
% Usage:
%   sol = solve_forward(p)
%   sol = solve_forward(p, opts)
%
% where opts is a struct that may contain:
%   Nx, dt, tspan, q0, v0, newton_tol, newton_maxit
%
% The implicit midpoint rule is second-order accurate, A-stable, and
% exactly preserves quadratic energy for undamped linear autonomous systems.
% A Newton iteration handles the cubic wall force.

if nargin < 2 || isempty(opts)
    opts = struct();
end

opts = set_default(opts,"Nx",200);
opts = set_default(opts,"dt",1e-4);
opts = set_default(opts,"tspan",[0,1]);
opts = set_default(opts,"q0",[]);
opts = set_default(opts,"v0",[]);
opts = set_default(opts,"newton_tol",1e-10);
opts = set_default(opts,"newton_abs_tol",1e-14);
opts = set_default(opts,"newton_maxit",20);

validateattributes(opts.Nx,{'numeric'},{'scalar','integer','>',2});
validateattributes(opts.dt,{'numeric'},{'scalar','positive'});
validateattributes(opts.tspan,{'numeric'},{'vector','numel',2});
validateattributes(opts.newton_tol,{'numeric'},{'scalar','positive'});
validateattributes(opts.newton_abs_tol,{'numeric'},{'scalar','positive'});
validateattributes(opts.newton_maxit,{'numeric'},{'scalar','integer','positive'});

model = build_semidiscrete_model(p,opts.Nx);
nq = numel(model.x);
t0 = opts.tspan(1);
tf = opts.tspan(2);

if tf <= t0
    error('opts.tspan must satisfy tf > t0.');
end

Nt = ceil((tf-t0)/opts.dt);
dt = (tf-t0)/Nt;
t = linspace(t0,tf,Nt+1).';

if isempty(opts.q0)
    q = zeros(nq,1);
else
    q = opts.q0(:);
end

if isempty(opts.v0)
    v = zeros(nq,1);
else
    v = opts.v0(:);
end

if numel(q) ~= nq || numel(v) ~= nq
    error('Initial vectors q0 and v0 must each have Nx+1 entries.');
end

Y = zeros(2*nq,Nt+1);
Y(:,1) = [q;v];

M = model.M;
C = model.C;
K = model.K;
b = model.b;
I = eye(nq);

for n = 1:Nt
    tn = t(n);
    tnp1 = t(n+1);
    tm = 0.5*(tn+tnp1);

    qn = Y(1:nq,n);
    vn = Y(nq+1:end,n);

    % Predictor.
    qnp1 = qn + dt*vn;
    vnp1 = vn;

    pm = pressure_forcing(tm,p);

    converged = false;

    for it = 1:opts.newton_maxit
        qm = 0.5*(qn+qnp1);
        vm = 0.5*(vn+vnp1);

        % Energy-consistent discrete gradient of Phi(w)=alpha*w^4/4.
        % This satisfies
        %   g(w_n,w_{n+1})*(w_{n+1}-w_n)
        %     = Phi(w_{n+1})-Phi(w_n),
        % so the fully discrete nonlinear energy law is exact.
        wn = qn(1);
        wnp1 = qnp1(1);
        fnl = zeros(nq,1);
        fnl(1) = (p.alpha/4)*(wnp1+wn)*(wnp1^2+wn^2);

        Rq = qnp1 - qn - dt*vm;
        Rv = M*(vnp1-vn) - dt*(b*pm - C*vm - K*qm - fnl);
        R = [Rq;Rv];

        residual_scale = max([norm(M*(vnp1-vn),inf), ...
            dt*norm(b*pm - C*vm - K*qm - fnl,inf), 1e-30]);
        residual_tol = opts.newton_abs_tol + ...
            opts.newton_tol*residual_scale;
        if norm(R,inf) <= residual_tol
            converged = true;
            break
        end

        Knl = zeros(nq);
        % Derivative of the discrete-gradient force with respect to w_{n+1}.
        Knl(1,1) = (p.alpha/4)*(3*wnp1^2 + 2*wn*wnp1 + wn^2);

        J11 = I;
        J12 = -(dt/2)*I;
        J21 = (dt/2)*K + dt*Knl;
        J22 = M + (dt/2)*C;
        J = [J11,J12;J21,J22];

        delta = -J\R;
        qnp1 = qnp1 + delta(1:nq);
        vnp1 = vnp1 + delta(nq+1:end);
    end

    if ~converged
        error('Newton iteration failed at t=%g. Residual=%g', ...
            tnp1,norm(R,inf));
    end

    Y(:,n+1) = [qnp1;vnp1];
end

sol.t = t;
sol.x = model.x;
sol.q = Y(1:nq,:);
sol.v = Y(nq+1:end,:);
sol.w = sol.q(1,:).';
sol.wdot = sol.v(1,:).';
sol.u = sol.q;
sol.ut = sol.v;
sol.V = p.V_ref + p.A_eff*sol.w;
sol.model = model;
sol.params = p;
sol.dt = dt;
end

function s = set_default(s,name,value)
if ~isfield(s,name) || isempty(s.(name))
    s.(name) = value;
end
end
