function theta = effective_volume_parameters(p)
%EFFECTIVE_VOLUME_PARAMETERS Convert wall parameters to volume-domain parameters.
%
% Model:
%   M_V v_ddot + R_V v_dot + K_V v + A_V v^3 = p_trans
%
% where v = V - V_ref.

c_rad = p.rho_f*p.c_f*p.A_f;

theta.M_V = p.m_w/p.A_eff^2;
theta.K_V = p.k/p.A_eff^2;
theta.R_V = (p.eta+c_rad)/p.A_eff^2;
theta.A_V = p.alpha/p.A_eff^4;

theta.C0_m3_per_Pa = 1/theta.K_V;
theta.C0_uL_per_mmHg = theta.C0_m3_per_Pa*1e9*133.322;
theta.c_radiation_volume = c_rad/p.A_eff^2;
theta.eta_intrinsic_volume = p.eta/p.A_eff^2;
theta.names = {'K_V','R_V','A_V'};
theta.units = {'Pa/m^3','Pa s/m^3','Pa/m^9'};
end
