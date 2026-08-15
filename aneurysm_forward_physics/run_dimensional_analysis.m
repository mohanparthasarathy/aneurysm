function [baseline_table,sweep_table] = run_dimensional_analysis(output_dir)
%RUN_DIMENSIONAL_ANALYSIS Regime maps using the relevant overdamped scaling.
%
% The primary horizontal coordinate is
%   D = omega*(eta + rho_f*c_f*A_f)/k,
% the viscous-to-elastic force ratio. Omega and I=Omega^2 are retained in
% the output table to quantify inertial effects.

if nargin < 1
    output_dir = fullfile(pwd,'extended_physics_results');
end
if ~exist(output_dir,'dir'), mkdir(output_dir); end

p = physiological_parameters();
[~,m] = run_single_physics_case(p,struct('Nx',80,'cycles',7, ...
    'analyze_cycles',2,'steps_per_cycle',1200,'max_dt',5e-4));

baseline_table = dimensionless_groups_table(p,m);
writetable(baseline_table, ...
    fullfile(output_dir,'baseline_dimensionless_groups.csv'));
disp(baseline_table);

PmmHg = [5,10,20,30,40,50];
freqHz = logspace(-1,2,31);
rows = {};
counter = 0;

for i = 1:numel(PmmHg)
    for j = 1:numel(freqHz)
        pp = p;
        pp.pressure.amplitude = PmmHg(i)*133.322;
        pp.pressure.frequency_hz = freqHz(j);
        pp.pressure.omega = 2*pi*freqHz(j);

        T = 1/freqHz(j);
        pp.pressure.ramp_time = T;
        opts.dt = T/1000;
        opts.tspan = [0,8*T];

        sol = solve_reduced_wall(pp,opts);
        mm = analyze_reduced_cycles(sol,2);
        G = compute_dimensionless_groups(pp,mm);

        counter = counter+1;
        row.pressure_amplitude_mmHg = PmmHg(i);
        row.frequency_Hz = freqHz(j);
        row.Omega = G.Omega;
        row.inertial_to_elastic = G.inertial_to_elastic;
        row.D_viscous_to_elastic = G.D;
        row.zeta_total = G.zeta_total;
        row.Gamma = G.Gamma_wall_to_radiation;
        row.Lambda_force = G.Lambda_force;
        row.Lambda_response = G.Lambda_response;
        row.Xi_response_tangent = G.Xi_response_tangent;
        row.dynamic_to_static_compliance = ...
            G.dynamic_to_static_compliance;
        row.phase_lag_deg = mm.phase_lag_deg;
        row.THD = mm.wall_THD;
        row.third_to_fundamental = mm.wall_third_to_fundamental;
        rows{counter} = row; %#ok<AGROW>
    end
end

sweep_table = struct2table(vertcat(rows{:}));
writetable(sweep_table, ...
    fullfile(output_dir,'dimensionless_regime_map.csv'));

figure('Color','w');
scatter(sweep_table.D_viscous_to_elastic, ...
    sweep_table.dynamic_to_static_compliance,35, ...
    sweep_table.Xi_response_tangent,'filled');
set(gca,'XScale','log');
xlabel('D = \omega c_{eff}/k');
ylabel('C^*/C_0');
title('Compliance regimes: viscous dynamics and nonlinear stiffening');
cb = colorbar;
ylabel(cb,'\Xi_R = 3\alpha W_1^2/k');
xline(1,'--','D = 1','LabelVerticalAlignment','bottom');
grid on;
saveas(gcf,fullfile(output_dir,'dimensionless_compliance_regime_D.png'));

figure('Color','w');
scatter(sweep_table.D_viscous_to_elastic, ...
    abs(sweep_table.phase_lag_deg),35, ...
    sweep_table.pressure_amplitude_mmHg,'filled');
set(gca,'XScale','log','YScale','log');
xlabel('D = \omega c_{eff}/k');
ylabel('|phase lag| (degrees)');
title('Phase regimes governed by the viscous-to-elastic ratio');
cb = colorbar;
ylabel(cb,'pressure amplitude (mmHg)');
xline(1,'--','D = 1','LabelVerticalAlignment','bottom');
grid on;
saveas(gcf,fullfile(output_dir,'dimensionless_phase_regime_D.png'));

% Collapse check against the inertia-free linear prediction |phi|=atan(D).
Dline = logspace(log10(min(sweep_table.D_viscous_to_elastic)), ...
    log10(max(sweep_table.D_viscous_to_elastic)),300);
figure('Color','w');
scatter(sweep_table.D_viscous_to_elastic, ...
    abs(sweep_table.phase_lag_deg),28, ...
    sweep_table.Xi_response_tangent,'filled'); hold on;
plot(Dline,atan(Dline)*180/pi,'k--','LineWidth',1.6);
set(gca,'XScale','log');
xlabel('D = \omega c_{eff}/k');
ylabel('|phase lag| (degrees)');
title('Phase collapse relative to the overdamped linear prediction');
legend('nonlinear simulations','tan^{-1}(D)','Location','best');
cb = colorbar;
ylabel(cb,'\Xi_R');
grid on;
saveas(gcf,fullfile(output_dir,'dimensionless_phase_collapse_D.png'));

save(fullfile(output_dir,'dimensional_analysis.mat'), ...
    'baseline_table','sweep_table','p');
end
