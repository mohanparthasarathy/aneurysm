function exact = linear_analytic_solution(t, p)
%LINEAR_ANALYTIC_SOLUTION Exact linear outgoing-wave response.
%
% Valid when alpha=0, boundary="radiation", pressure is a pure sine with
% zero ramp, and initial wall displacement/velocity are zero.
%
% The outgoing wave gives an added radiation damping rho_f*c_f*A_f, so
% m_w*wdd + b_eff*wd + k*w = A_eff*P0*sin(omega*t).

if abs(p.alpha) > 0
    error('Analytical solution requires alpha=0.');
end
if ~strcmpi(p.boundary,'radiation')
    error('Analytical solution requires radiation boundary.');
end
if ~strcmpi(p.pressure.kind,'sine')
    error('Analytical solution requires sine pressure.');
end
if isfield(p.pressure,"ramp_time") && p.pressure.ramp_time ~= 0
    error('Analytical solution requires zero pressure ramp.');
end

m = p.m_w;
beff = p.eta + p.rho_f*p.c_f*p.A_f;
k = p.k;
F0 = p.A_eff*p.pressure.amplitude;
om = p.pressure.omega;
ph = p.pressure.phase;

% Augmented autonomous system for exact matrix-exponential evaluation:
% z=[w;wd;s;c], with s=sin(om*t+ph), c=cos(om*t+ph).
A = [0, 1, 0, 0;
    -k/m, -beff/m, F0/m, 0;
     0, 0, 0, om;
     0, 0, -om, 0];
z0 = [0;0;sin(ph);cos(ph)];

w = zeros(size(t));
wd = zeros(size(t));
for j = 1:numel(t)
    z = expm(A*t(j))*z0;
    w(j) = z(1);
    wd(j) = z(2);
end

exact.t = t(:);
exact.w = w(:);
exact.wdot = wd(:);
exact.V = p.V_ref + p.A_eff*exact.w;
exact.b_eff = beff;
end
