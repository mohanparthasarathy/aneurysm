function metrics = analyze_steady_cycles(sol, n_cycles)
%ANALYZE_STEADY_CYCLES Metrics over the final n_cycles of a periodic run.

if nargin < 2
    n_cycles = 2;
end

p = sol.params;
omega = p.pressure.omega;
T = 2*pi/omega;
t_end = sol.t(end);
t_start = t_end - n_cycles*T;

idx = sol.t >= t_start;
t = sol.t(idx);
w = sol.w(idx);
V = sol.V(idx);
pressure = pressure_forcing(t,p);

fitP = harmonic_fit(t,pressure,omega);
fitW = harmonic_fit(t,w,omega);
fitV = harmonic_fit(t,V,omega);

phase_lag = wrap_to_180(fitV.phase_deg-fitP.phase_deg);

C_tangent = p.A_eff^2 ./ (p.k + 3*p.alpha*w.^2);
C_dynamic = fitV.amplitude/max(fitP.amplitude,eps);

% Pressure-volume loop area. Positive dissipation is reported by magnitude.
loop_work_total = abs(trapz(V,pressure)); % integral p dV, summed over cycles
loop_work_per_cycle = loop_work_total/n_cycles;

diag = evaluate_energy(sol);
tmid = 0.5*(sol.t(1:end-1)+sol.t(2:end));
step_idx = tmid >= t_start;

wall_loss_total = sum(diag.step_work(step_idx)*0); %#ok<NASGU>
dt_steps = diff(sol.t);
wall_loss_total = sum(dt_steps(step_idx).*diag.Dwall_mid(step_idx));
rad_loss_total = sum(dt_steps(step_idx).*diag.Drad_mid(step_idx));
pressure_work_total = sum(dt_steps(step_idx).*diag.Pin_mid(step_idx));

wall_loss_cycle = wall_loss_total/n_cycles;
rad_loss_cycle = rad_loss_total/n_cycles;
pressure_work_cycle = pressure_work_total/n_cycles;
total_loss_cycle = wall_loss_cycle+rad_loss_cycle;

metrics.w_amplitude_m = fitW.amplitude;
metrics.volume_amplitude_m3 = fitV.amplitude;
metrics.volume_pulsation_percent = 100*fitV.amplitude/max(p.V_ref,eps);
metrics.dynamic_compliance_m3_per_Pa = C_dynamic;
metrics.dynamic_compliance_uL_per_mmHg = C_dynamic*1e9*133.322;
metrics.phase_lag_deg = phase_lag;
metrics.hysteresis_work_J_per_cycle = loop_work_per_cycle;
metrics.wall_loss_J_per_cycle = wall_loss_cycle;
metrics.radiation_loss_J_per_cycle = rad_loss_cycle;
metrics.pressure_work_J_per_cycle = pressure_work_cycle;
metrics.wall_loss_fraction = wall_loss_cycle/max(total_loss_cycle,eps);
metrics.radiation_loss_fraction = rad_loss_cycle/max(total_loss_cycle,eps);
metrics.tangent_compliance_min_m3_per_Pa = min(C_tangent);
metrics.tangent_compliance_mean_m3_per_Pa = mean(C_tangent);
metrics.tangent_compliance_max_m3_per_Pa = max(C_tangent);
metrics.nonlinearity_index = ...
    3*p.alpha*fitW.amplitude^2/max(p.k,eps);
metrics.wall_harmonic_distortion = fitW.THD;
metrics.wall_THD = fitW.THD;
metrics.wall_second_to_fundamental = fitW.second_to_fundamental;
metrics.wall_third_to_fundamental = fitW.third_to_fundamental;
metrics.wall_fifth_to_fundamental = fitW.fifth_to_fundamental;
metrics.wall_fourier_residual_to_fundamental = ...
    fitW.residual_to_fundamental;
metrics.energy_balance_relative_error = diag.relative_balance_error;
metrics.analysis_start_s = t_start;
metrics.analysis_end_s = t_end;
end

function a = wrap_to_180(a)
a = mod(a+180,360)-180;
end
