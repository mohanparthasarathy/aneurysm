function results = run_amplitude_compliance_curve(output_dir)
%RUN_AMPLITUDE_COMPLIANCE_CURVE Dense pressure-amplitude compliance study.
%
% Runs both the nonlinear baseline and a matched linear-wall control over
% pressure amplitudes from 1 to 50 mmHg.

if nargin < 1
    output_dir = fullfile(pwd,'extended_physics_results');
end
if ~exist(output_dir,'dir'), mkdir(output_dir); end

p0 = physiological_parameters();
PmmHg = unique([1:2:15,18:3:30,35:5:50]);
models = {'linear','nonlinear'};
rows = {};

fprintf('\n=== Dense pressure-amplitude compliance sweep ===\n');

counter = 0;
for im = 1:numel(models)
    model_name = models{im};

    for j = 1:numel(PmmHg)
        p = p0;
        p.pressure.amplitude = PmmHg(j)*133.322;
        if strcmp(model_name,'linear')
            p.alpha = 0;
        end

        T = 2*pi/p.pressure.omega;
        p.pressure.ramp_time = T;
        opts.dt = min(T/1200,5e-4);
        opts.tspan = [0,7*T];

        sol = solve_reduced_wall(p,opts);
        m = analyze_reduced_cycles(sol,2);
        G = compute_dimensionless_groups(p,m);

        counter = counter+1;
        row.model = model_name;
        row.pressure_amplitude_mmHg = PmmHg(j);
        row.w_amplitude_um = 1e6*m.w_amplitude_m;
        row.volume_amplitude_uL = 1e9*m.volume_amplitude_m3;
        row.dynamic_compliance_uL_per_mmHg = ...
            m.dynamic_compliance_uL_per_mmHg;
        row.phase_lag_deg = m.phase_lag_deg;
        row.hysteresis_J_per_cycle = m.hysteresis_work_J_per_cycle;
        row.tangent_compliance_min_uL_per_mmHg = ...
            m.tangent_compliance_min_m3_per_Pa*1e9*133.322;
        row.tangent_compliance_mean_uL_per_mmHg = ...
            m.tangent_compliance_mean_m3_per_Pa*1e9*133.322;
        row.tangent_compliance_max_uL_per_mmHg = ...
            m.tangent_compliance_max_m3_per_Pa*1e9*133.322;
        row.nonlinearity_index = m.nonlinearity_index;
        row.THD = m.wall_THD;
        row.second_to_fundamental = m.wall_second_to_fundamental;
        row.third_to_fundamental = m.wall_third_to_fundamental;
        row.fifth_to_fundamental = m.wall_fifth_to_fundamental;
        row.fourier_residual_to_fundamental = ...
            m.wall_fourier_residual_to_fundamental;
        row.Lambda_response = G.Lambda_response;
        row.Xi_response_tangent = G.Xi_response_tangent;
        row.dynamic_to_static_compliance = ...
            G.dynamic_to_static_compliance;
        rows{counter} = row; %#ok<AGROW>

        fprintf('  %-9s P0=%5.1f mmHg: C*=%.4f uL/mmHg, w=%.2f um\n', ...
            model_name,PmmHg(j),m.dynamic_compliance_uL_per_mmHg, ...
            1e6*m.w_amplitude_m);
    end
end

results = struct2table(vertcat(rows{:}));
writetable(results,fullfile(output_dir,'amplitude_compliance_curve.csv'));

Slin = results(strcmp(results.model,'linear'),:);
Snl = results(strcmp(results.model,'nonlinear'),:);

figure('Color','w');
plot(Slin.pressure_amplitude_mmHg, ...
    Slin.dynamic_compliance_uL_per_mmHg,'--','LineWidth',1.5); hold on;
plot(Snl.pressure_amplitude_mmHg, ...
    Snl.dynamic_compliance_uL_per_mmHg,'-','LineWidth',1.7);
xlabel('pressure amplitude (mmHg)');
ylabel('dynamic volume compliance (\muL/mmHg)');
legend('linear wall','nonlinear wall','Location','best');
title('Amplitude-dependent dynamic compliance');
grid on;
saveas(gcf,fullfile(output_dir,'amplitude_dependent_compliance.png'));

figure('Color','w');
plot(Slin.pressure_amplitude_mmHg,Slin.w_amplitude_um, ...
    '--','LineWidth',1.5); hold on;
plot(Snl.pressure_amplitude_mmHg,Snl.w_amplitude_um, ...
    '-','LineWidth',1.7);
xlabel('pressure amplitude (mmHg)');
ylabel('wall displacement amplitude (\mum)');
legend('linear wall','nonlinear wall','Location','best');
title('Sublinear pressure-displacement response');
grid on;
saveas(gcf,fullfile(output_dir,'pressure_displacement_nonlinearity.png'));

figure('Color','w');
plot(Snl.pressure_amplitude_mmHg,100*Snl.THD, ...
    'o-','LineWidth',1.5); hold on;
plot(Snl.pressure_amplitude_mmHg,100*Snl.third_to_fundamental, ...
    's--','LineWidth',1.5);
xlabel('pressure amplitude (mmHg)');
ylabel('harmonic ratio (%)');
legend('THD','W_3/W_1','Location','best');
title('Fourier-resolved nonlinear distortion');
grid on;
saveas(gcf,fullfile(output_dir,'amplitude_fourier_distortion.png'));

figure('Color','w');
plot(Snl.pressure_amplitude_mmHg,Snl.Xi_response_tangent, ...
    'o-','LineWidth',1.5);
xlabel('pressure amplitude (mmHg)');
ylabel('\Xi_R = 3\alpha W_1^2/k');
title('Response-based nonlinear tangent-stiffness ratio');
grid on;
saveas(gcf,fullfile(output_dir,'amplitude_dimensionless_nonlinearity.png'));

save(fullfile(output_dir,'amplitude_compliance_curve.mat'), ...
    'results','p0');
end
