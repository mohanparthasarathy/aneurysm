function model = build_semidiscrete_model(p, Nx)
%BUILD_SEMIDISCRETE_MODEL Energy-consistent finite-difference/FV model.
%
% q = [w, u_1, ..., u_N]^T, with u_0 = w and x_j = j*dx.
%
% The wave domain is represented by centered second differences in the
% interior and half-cell masses at x=0 and x=L. This is equivalent to a
% lumped-mass linear finite-element discretization and gives a transparent
% discrete energy law.

if nargin < 2
    error('build_semidiscrete_model requires p and Nx.');
end
validateattributes(Nx,{'numeric'},{'scalar','integer','>',2});

N = Nx;
dx = p.L / N;
nq = N + 1;

% Trapezoidal quadrature masses for the fluid kinetic energy.
mfluid = p.rho_f * p.A_f * dx * ones(nq,1);
mfluid([1,end]) = 0.5 * mfluid([1,end]);

M = diag(mfluid);
M(1,1) = M(1,1) + p.m_w;

% Discrete fluid strain energy:
% 1/2 * sum rho*c^2*A/dx * (q_{j+1}-q_j)^2.
s = p.rho_f * p.c_f^2 * p.A_f / dx;
K = zeros(nq);
for j = 1:N
    idx = [j,j+1];
    K(idx,idx) = K(idx,idx) + s * [1,-1;-1,1];
end
K(1,1) = K(1,1) + p.k;

C = zeros(nq);
C(1,1) = C(1,1) + p.eta;

switch lower(p.boundary)
    case 'radiation'
        % Acoustic impedance rho*c*A at the outgoing boundary.
        C(end,end) = C(end,end) + p.rho_f*p.c_f*p.A_f;
    case 'reflecting'
        % No boundary damping; discrete Neumann/natural boundary.
    otherwise
        error('Unknown boundary type: %s', p.boundary);
end

b = zeros(nq,1);
b(1) = p.A_eff;

x = linspace(0,p.L,nq).';

model.Nx = N;
model.dx = dx;
model.x = x;
model.M = M;
model.C = C;
model.K = K;
model.b = b;
model.Mdiag = diag(M);
model.radiation_coefficient = C(end,end);
end
