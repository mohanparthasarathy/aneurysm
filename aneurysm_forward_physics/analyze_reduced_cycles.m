function metrics = analyze_reduced_cycles(sol,n_cycles)
%ANALYZE_REDUCED_CYCLES Steady-cycle metrics for reduced wall solution.

if nargin < 2, n_cycles = 2; end
p = sol.params;
omega = p.pressure.omega;
T = 2*pi/omega;
idx = sol.t >= sol.t(end)-n_cycles*T;

t = sol.t(idx);
w = sol.w(idx);
v = sol.wdot(idx);
V = sol.V(idx);
P = pressure_forcing(t,p);

fitP = harmonic_fit(t,P,omega);
fitW = harmonic_fit(t,w,omega);
fitV = harmonic_fit(t,V,omega);

phase = mod((fitV.phase_deg-fitP.phase_deg)+180,360)-180;
Ctan = p.A_eff^2./(p.k+3*p.alpha*w.^2);

wall_loss = trapz(t,p.eta*v.^2)/n_cycles;
rad_coeff = p.rho_f*p.c_f*p.A_f;
rad_loss = trapz(t,rad_coeff*v.^2)/n_cycles;
loop_area = abs(trapz(V,P))/n_cycles;

metrics.w_amplitude_m = fitW.amplitude;
metrics.volume_amplitude_m3 = fitV.amplitude;
metrics.dynamic_compliance_m3_per_Pa = ...
    fitV.amplitude/max(fitP.amplitude,eps);
metrics.dynamic_compliance_uL_per_mmHg = ...
    metrics.dynamic_compliance_m3_per_Pa*1e9*133.322;
metrics.phase_lag_deg = phase;
metrics.hysteresis_work_J_per_cycle = loop_area;
metrics.wall_loss_J_per_cycle = wall_loss;
metrics.radiation_loss_J_per_cycle = rad_loss;
metrics.wall_loss_fraction = wall_loss/max(wall_loss+rad_loss,eps);
metrics.radiation_loss_fraction = rad_loss/max(wall_loss+rad_loss,eps);
metrics.tangent_compliance_min_m3_per_Pa = min(Ctan);
metrics.tangent_compliance_mean_m3_per_Pa = mean(Ctan);
metrics.tangent_compliance_max_m3_per_Pa = max(Ctan);
metrics.nonlinearity_index = 3*p.alpha*fitW.amplitude^2/max(p.k,eps);
metrics.wall_harmonic_distortion = fitW.THD;
metrics.wall_THD = fitW.THD;
metrics.wall_second_to_fundamental = fitW.second_to_fundamental;
metrics.wall_third_to_fundamental = fitW.third_to_fundamental;
metrics.wall_fifth_to_fundamental = fitW.fifth_to_fundamental;
metrics.wall_fourier_residual_to_fundamental = ...
    fitW.residual_to_fundamental;
end
