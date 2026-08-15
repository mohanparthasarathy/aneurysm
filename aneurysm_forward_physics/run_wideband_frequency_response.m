function results = run_wideband_frequency_response(output_dir)
%RUN_WIDEBAND_FREQUENCY_RESPONSE Wide-band linear/nonlinear response.
%
% Frequencies span 0.1--100 Hz. The exact outgoing-wave reduction is used
% for efficiency. The function overlays the exact linear transfer function
% and validates selected frequencies with the full PDE solver.

if nargin < 1
    output_dir = fullfile(pwd,'extended_physics_results');
end
if ~exist(output_dir,'dir'), mkdir(output_dir); end

p0 = physiological_parameters();
freqs = logspace(-1,2,55);
models = {'linear','nonlinear'};
rows = {};
counter = 0;

fprintf('\n=== Wide-band frequency response ===\n');

for im = 1:numel(models)
    model_name = models{im};

    for j = 1:numel(freqs)
        f = freqs(j);
        p = p0;
        p.pressure.frequency_hz = f;
        p.pressure.omega = 2*pi*f;
        if strcmp(model_name,'linear')
            p.alpha = 0;
        end

        T = 1/f;
        p.pressure.ramp_time = T;

        % Fixed samples per cycle; implicit reduction has no CFL restriction.
        opts.dt = T/1200;
        opts.tspan = [0,10*T];

        sol = solve_reduced_wall(p,opts);
        m = analyze_reduced_cycles(sol,3);
        G = compute_dimensionless_groups(p,m);

        counter = counter+1;
        row.model = model_name;
        row.frequency_Hz = f;
        row.Omega = G.Omega;
        row.inertial_to_elastic = G.inertial_to_elastic;
        row.D_viscous_to_elastic = G.D;
        row.w_amplitude_um = 1e6*m.w_amplitude_m;
        row.dynamic_compliance_uL_per_mmHg = ...
            m.dynamic_compliance_uL_per_mmHg;
        row.phase_lag_deg = m.phase_lag_deg;
        row.hysteresis_J_per_cycle = m.hysteresis_work_J_per_cycle;
        row.wall_loss_fraction = m.wall_loss_fraction;
        row.radiation_loss_fraction = m.radiation_loss_fraction;
        row.nonlinearity_index = m.nonlinearity_index;
        row.THD = m.wall_THD;
        row.third_to_fundamental = m.wall_third_to_fundamental;
        rows{counter} = row; %#ok<AGROW>
    end
    fprintf('  completed %s model\n',model_name);
end

results = struct2table(vertcat(rows{:}));

% Exact linear harmonic response.
c_eff = p0.eta+p0.rho_f*p0.c_f*p0.A_f;
omega = 2*pi*freqs(:);
H = p0.A_eff ./ ...
    (p0.k-p0.m_w*omega.^2+1i*c_eff*omega);
linear_exact_um = 1e6*abs(H)*p0.pressure.amplitude;
linear_exact_phase_deg = angle(H)*180/pi;

% Append exact values on the linear rows where frequencies match.
results.linear_exact_amplitude_um = NaN(height(results),1);
results.linear_exact_phase_deg = NaN(height(results),1);
lin_idx = find(strcmp(results.model,'linear'));
results.linear_exact_amplitude_um(lin_idx) = linear_exact_um;
results.linear_exact_phase_deg(lin_idx) = linear_exact_phase_deg;

writetable(results,fullfile(output_dir,'wideband_frequency_response.csv'));

Slin = results(strcmp(results.model,'linear'),:);
Snl = results(strcmp(results.model,'nonlinear'),:);

figure('Color','w');
loglog(Slin.frequency_Hz,Slin.linear_exact_amplitude_um, ...
    ':','LineWidth',1.6); hold on;
loglog(Slin.frequency_Hz,Slin.w_amplitude_um, ...
    '--','LineWidth',1.4);
loglog(Snl.frequency_Hz,Snl.w_amplitude_um, ...
    '-','LineWidth',1.7);
xlabel('forcing frequency (Hz)');
ylabel('wall displacement amplitude (\mum)');
legend('linear exact transfer function','linear time-domain', ...
    'nonlinear time-domain','Location','best');
title('Wide-band frequency response');
grid on;
saveas(gcf,fullfile(output_dir,'wideband_frequency_response.png'));

figure('Color','w');
semilogx(Slin.frequency_Hz,Slin.linear_exact_phase_deg, ...
    ':','LineWidth',1.6); hold on;
semilogx(Slin.frequency_Hz,Slin.phase_lag_deg, ...
    '--','LineWidth',1.4);
semilogx(Snl.frequency_Hz,Snl.phase_lag_deg, ...
    '-','LineWidth',1.7);
xlabel('forcing frequency (Hz)');
ylabel('volume-pressure phase (degrees)');
legend('linear exact','linear time-domain','nonlinear time-domain', ...
    'Location','best');
title('Wide-band phase response');
grid on;
saveas(gcf,fullfile(output_dir,'wideband_phase_response.png'));

figure('Color','w');
semilogx(Snl.frequency_Hz,Snl.dynamic_compliance_uL_per_mmHg, ...
    'LineWidth',1.7);
xlabel('forcing frequency (Hz)');
ylabel('dynamic compliance (\muL/mmHg)');
title('Wide-band nonlinear dynamic compliance');
grid on;
saveas(gcf,fullfile(output_dir,'wideband_dynamic_compliance.png'));

% Full PDE validation at selected frequencies.
validation_freqs = [0.6,1.2,5,20,50];
validation_rows = {};
for j = 1:numel(validation_freqs)
    f = validation_freqs(j);
    p = p0;
    p.pressure.frequency_hz = f;
    p.pressure.omega = 2*pi*f;
    T = 1/f;
    p.pressure.ramp_time = T;

    settings = struct('Nx',80,'cycles',8,'analyze_cycles',2, ...
        'steps_per_cycle',1200,'max_dt',T/1200);
    [solPDE,mPDE] = run_single_physics_case(p,settings);

    opts.dt = T/1200;
    opts.tspan = [0,8*T];
    solRED = solve_reduced_wall(p,opts);
    mRED = analyze_reduced_cycles(solRED,2);

    vr.frequency_Hz = f;
    vr.pde_amplitude_um = 1e6*mPDE.w_amplitude_m;
    vr.reduced_amplitude_um = 1e6*mRED.w_amplitude_m;
    vr.relative_amplitude_difference = ...
        abs(vr.pde_amplitude_um-vr.reduced_amplitude_um)/ ...
        max(abs(vr.pde_amplitude_um),eps);
    vr.pde_phase_deg = mPDE.phase_lag_deg;
    vr.reduced_phase_deg = mRED.phase_lag_deg;
    vr.absolute_phase_difference_deg = ...
        abs(vr.pde_phase_deg-vr.reduced_phase_deg);
    validation_rows{j} = vr; %#ok<AGROW>
end
validation = struct2table(vertcat(validation_rows{:}));
writetable(validation, ...
    fullfile(output_dir,'wideband_PDE_reduction_validation.csv'));

% Report natural frequency and peak locations.
[~,iLin] = max(Slin.w_amplitude_um);
[~,iNL] = max(Snl.w_amplitude_um);
summary = table( ...
    sqrt(p0.k/p0.m_w)/(2*pi), ...
    Slin.frequency_Hz(iLin),Slin.w_amplitude_um(iLin), ...
    Snl.frequency_Hz(iNL),Snl.w_amplitude_um(iNL), ...
    'VariableNames',{'undamped_natural_frequency_Hz', ...
    'linear_peak_frequency_Hz','linear_peak_amplitude_um', ...
    'nonlinear_peak_frequency_Hz','nonlinear_peak_amplitude_um'});
writetable(summary,fullfile(output_dir,'frequency_response_summary.csv'));
disp(summary);

save(fullfile(output_dir,'wideband_frequency_response.mat'), ...
    'results','validation','summary','p0');
end
