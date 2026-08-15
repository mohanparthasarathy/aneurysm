function p = default_parameters()
%DEFAULT_PARAMETERS Baseline dimensional parameters for the reduced model.
%
% Units are SI. These values are illustrative numerical baselines rather
% than patient-specific clinical estimates. Replace them after literature
% calibration.

p.rho_f = 1000.0;          % kg/m^3, density of surrounding fluid (e.g. CSF)
p.c_f = 20.0;              % m/s, effective wave speed in 1D fluid domain
p.A_f = 1.0e-5;            % m^2, effective waveguide cross-sectional area
p.L = 0.10;                % m, truncated fluid-domain length

p.A_eff = 1.0e-4;          % m^2, modal area: Delta V = A_eff*w
p.V_ref = 1.0e-6;          % m^3, reference aneurysm volume
p.m_w = 2.0e-4;            % kg, effective wall modal mass
p.k = 25.0;                % N/m, linear generalized wall stiffness
p.eta = 0.020;             % N*s/m, intrinsic wall damping
p.alpha = 2.0e7;           % N/m^3, cubic generalized wall stiffness

p.pressure.kind = 'sine';
p.pressure.amplitude = 250.0; % Pa, perturbation-pressure amplitude
p.pressure.omega = 2*pi*1.2;  % rad/s
p.pressure.phase = 0.0;
p.pressure.ramp_time = 0.0;   % s; 0 means no ramp

p.boundary = 'radiation';     % "radiation" or "reflecting"
end
