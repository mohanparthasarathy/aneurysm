function p = physiological_parameters()
%PHYSIOLOGICAL_PARAMETERS Literature-anchored baseline for forward studies.
%
% The directly physiological inputs are sac geometry, wall thickness and
% modulus, pressure amplitude, heart rate, fluid density, and effective CSF
% pulse-wave speed. Reduced parameters k, m_w, eta, and alpha are derived
% transparently below.
%
% IMPORTANT:
% eta and alpha are reduced-order calibration parameters. Direct human
% intracranial-aneurysm measurements of Kelvin-Voigt viscosity and cubic
% modal stiffness are not available. Their baseline values are therefore
% defined by dimensionless targets and swept broadly in the study.

p = default_parameters();

%% Representative aneurysm geometry
p.geometry.radius = 4.0e-3;       % m; representative 8-mm sac diameter
p.geometry.wall_thickness = 0.20e-3; % m
p.geometry.nu = 0.49;             % nearly incompressible wall tissue
p.geometry.rho_wall = 1050;       % kg/m^3

r = p.geometry.radius;
h = p.geometry.wall_thickness;
nu = p.geometry.nu;

p.V_ref = (4/3)*pi*r^3;
p.A_eff = 4*pi*r^2;  % dV/dw for a spherical radial expansion mode

%% Wall elasticity
p.material.E = 2.6e6;             % Pa; midpoint/median literature baseline

% Thin spherical shell linearization:
% w = (1-nu)*DeltaP*r^2/(2*E*h)
% and A_eff*DeltaP = k*w, hence k = 8*pi*E*h/(1-nu).
p.k = 8*pi*p.material.E*h/(1-nu);

% Modal mass: physical sac-wall mass for a uniform spherical shell.
p.m_w = p.geometry.rho_wall*p.A_eff*h;

%% Reduced wall viscosity
p.pressure.frequency_hz = 1.20;
p.pressure.omega = 2*pi*p.pressure.frequency_hz;

% Define eta from a baseline wall loss tangent:
% tan(delta_wall) = omega*eta/k.
% A modest 0.05 is used as a transparent baseline and eta is swept from
% zero to twice baseline. This is a modeling calibration, not a direct
% patient-specific measurement.
p.material.loss_tangent = 0.05;
p.eta = p.material.loss_tangent*p.k/p.pressure.omega;

%% Cubic stiffening
% Choose alpha so the tangent stiffness k+3*alpha*w^2 is 25% above k at a
% reference radial pulsation amplitude of 20 micrometers.
p.material.nonlinear_stiffening_fraction = 0.25;
p.material.w_reference = 20e-6;
p.alpha = p.material.nonlinear_stiffening_fraction*p.k / ...
    (3*p.material.w_reference^2);

%% Pressure forcing
% Sinusoidal amplitude is half of a representative 40-mmHg pulse pressure.
p.pressure.kind = 'sine';
p.pressure.amplitude = 20*133.322; % Pa = 20 mmHg
p.pressure.phase = 0;
p.pressure.ramp_time = 1/p.pressure.frequency_hz;

%% Surrounding-fluid / wave-domain parameters
p.rho_f = 1000;             % kg/m^3, CSF approximately water-like
p.c_f = 4.6;                % m/s, measured systolic CSF velocity-wave speed
p.A_f = 1.0e-4;             % m^2, effective communicating CSF area (1 cm^2)
p.L = 0.10;                 % m, reduced outgoing-wave domain length
p.boundary = 'radiation';

%% Metadata used by reports
p.metadata.pressure_amplitude_mmHg = p.pressure.amplitude/133.322;
p.metadata.diameter_mm = 2*r*1e3;
p.metadata.wall_thickness_mm = h*1e3;
p.metadata.young_modulus_MPa = p.material.E/1e6;
p.metadata.reference_volume_mL = p.V_ref*1e6;
p.metadata.Aeff_mm2 = p.A_eff*1e6;
p.metadata.k_N_per_m = p.k;
p.metadata.eta_Ns_per_m = p.eta;
p.metadata.alpha_N_per_m3 = p.alpha;
end
