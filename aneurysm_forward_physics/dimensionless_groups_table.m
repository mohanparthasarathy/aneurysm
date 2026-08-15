function T = dimensionless_groups_table(p, metrics)
%DIMENSIONLESS_GROUPS_TABLE Human-readable governing-group table.

if nargin < 2
    metrics = [];
end
G = compute_dimensionless_groups(p,metrics);

symbol = {'Omega';'I';'D';'zeta_w';'zeta_r';'zeta';'Gamma'; ...
    'Pi_P';'Lambda_P';'Xi_P';'tau_f/T';'kL_f'};

definition = {
    'Forcing frequency divided by undamped wall natural frequency';
    'Inertial force divided by elastic force: m_w omega^2/k';
    'Effective viscous force divided by elastic force: omega c_eff/k';
    'Intrinsic wall damping divided by critical damping';
    'Radiation damping divided by critical damping';
    'Total damping ratio including wall and radiation losses';
    'Ratio of intrinsic wall damping to radiation impedance';
    'Static pressure-force displacement scale divided by reference displacement';
    'Cubic-to-linear force ratio at the static pressure displacement';
    'Fractional tangent-stiffness increment at the static pressure displacement';
    'Fluid-domain wave-transit time divided by forcing period';
    'Forcing angular frequency times domain length divided by wave speed'
    };

value = [G.Omega;G.inertial_to_elastic;G.D;G.zeta_wall; ...
    G.zeta_radiation;G.zeta_total;G.Gamma_wall_to_radiation; ...
    G.Pi_force;G.Lambda_force;G.Xi_force_tangent; ...
    G.wave_transit_ratio;G.Courant_frequency_length];

interpretation = {
    'Small Omega means forcing is far below the undamped natural frequency';
    'I much less than one means wall inertia is negligible';
    'D less than one is elastic-dominated; D near one marks viscous roll-off';
    'Controls phase lag and hysteresis caused by wall viscosity';
    'Measures damping caused by outgoing-fluid radiation';
    'Values much greater than one indicate an overdamped response';
    'Gamma greater than one means intrinsic wall loss dominates radiation loss';
    'Measures forcing strength relative to the nonlinear reference displacement';
    'A forcing-based measure of cubic-force importance';
    'A forcing-based estimate of nonlinear tangent stiffening';
    'Small values imply little wave delay across the truncated domain';
    'Small values imply a nearly spatially uniform harmonic phase'
    };

T = table(symbol,definition,value,interpretation);

if ~isempty(metrics)
    extra_symbol = {'Lambda_R';'Xi_R';'Cstar_over_C0'};
    extra_definition = {
        'Cubic-to-linear force ratio at the simulated fundamental amplitude';
        'Fractional nonlinear tangent-stiffness increment at simulated amplitude';
        'Dynamic compliance divided by reference static compliance'
        };
    extra_value = [G.Lambda_response;G.Xi_response_tangent; ...
        G.dynamic_to_static_compliance];
    extra_interpretation = {
        'Response-based nonlinear-force measure';
        'Response-based nonlinear tangent-stiffness measure';
        'Dynamic and nonlinear departure from static compliance'
        };
    T = [T;table(extra_symbol,extra_definition,extra_value, ...
        extra_interpretation,'VariableNames',T.Properties.VariableNames)];
end

corner = table({'f_c_Hz'},{'Viscous corner frequency k/(2 pi c_eff)'}, ...
    G.corner_frequency_Hz,{'D equals one at this frequency'}, ...
    'VariableNames',T.Properties.VariableNames);
T = [T;corner];
end
