function G = compute_dimensionless_groups(p, metrics)
%COMPUTE_DIMENSIONLESS_GROUPS Governing nondimensional parameters.
%
% Inertial frequency ratio:
%   Omega = omega/sqrt(k/m_w),     I = Omega^2 = m_w*omega^2/k
%
% Viscous-to-elastic dynamic ratio:
%   D = omega*c_eff/k = 2*zeta_total*Omega,
%   c_eff = eta + rho_f*c_f*A_f.
%
% The overdamped roll-off occurs near D=1, at
%   f_c = k/(2*pi*c_eff),
% rather than near the undamped natural frequency when zeta_total >> 1.

omega = p.pressure.omega;
omega_n = sqrt(p.k/p.m_w);
c_rad = p.rho_f*p.c_f*p.A_f;
c_total = p.eta + c_rad;
w_static = p.A_eff*p.pressure.amplitude/p.k;

if isfield(p,'material') && isfield(p.material,'w_reference')
    w_ref = p.material.w_reference;
else
    w_ref = max(abs(w_static),eps);
end

G.omega_n_rad_s = omega_n;
G.f_n_Hz = omega_n/(2*pi);
G.Omega = omega/omega_n;
G.inertial_to_elastic = G.Omega^2;

G.zeta_wall = p.eta/(2*sqrt(p.m_w*p.k));
G.zeta_radiation = c_rad/(2*sqrt(p.m_w*p.k));
G.zeta_total = c_total/(2*sqrt(p.m_w*p.k));

G.effective_damping_Ns_per_m = c_total;
G.viscous_to_elastic = omega*c_total/p.k;
G.D = G.viscous_to_elastic;
G.D_from_zeta_Omega = 2*G.zeta_total*G.Omega;
G.corner_omega_rad_s = p.k/c_total;
G.corner_frequency_Hz = G.corner_omega_rad_s/(2*pi);

G.Gamma_wall_to_radiation = p.eta/max(c_rad,eps);
G.radiation_impedance_Ns_per_m = c_rad;

G.static_displacement_scale_m = w_static;
G.Pi_force = p.A_eff*p.pressure.amplitude/(p.k*w_ref);
G.Lambda_force = p.alpha*w_static^2/p.k;
G.Xi_force_tangent = 3*G.Lambda_force;

G.static_compliance_m3_per_Pa = p.A_eff^2/p.k;
G.wave_transit_ratio = (p.L/p.c_f)/(2*pi/omega);
G.Courant_frequency_length = omega*p.L/p.c_f;

if nargin >= 2 && ~isempty(metrics)
    W1 = metrics.w_amplitude_m;
    G.Lambda_response = p.alpha*W1^2/p.k;
    G.Xi_response_tangent = 3*G.Lambda_response;
    G.dynamic_to_static_compliance = ...
        metrics.dynamic_compliance_m3_per_Pa/G.static_compliance_m3_per_Pa;
    G.phase_lag_deg = metrics.phase_lag_deg;
    G.wall_loss_fraction = metrics.wall_loss_fraction;
    G.radiation_loss_fraction = metrics.radiation_loss_fraction;
end
end
