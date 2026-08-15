function plot_baseline_cycle(p,settings,output_dir)
%PLOT_BASELINE_CYCLE Detailed final-cycle plots for baseline parameters.

[sol,m] = run_single_physics_case(p,settings);
T = 2*pi/p.pressure.omega;
idx = sol.t >= sol.t(end)-T;
t = sol.t(idx);
w = sol.w(idx);
V = sol.V(idx);
P = pressure_forcing(t,p);

figure('Color','w');
yyaxis left
plot(t,P/133.322,'LineWidth',1.5);
ylabel('pressure perturbation (mmHg)');
yyaxis right
plot(t,1e6*w,'LineWidth',1.5);
ylabel('wall displacement (\mum)');
xlabel('time (s)');
title(sprintf('Baseline final cycle: phase lag %.2f degrees',m.phase_lag_deg));
grid on;
saveas(gcf,fullfile(output_dir,'baseline_pressure_displacement.png'));

figure('Color','w');
plot(V*1e6,P/133.322,'LineWidth',1.5);
xlabel('aneurysm volume (mL)');
ylabel('pressure perturbation (mmHg)');
title(sprintf('Pressure-volume hysteresis: %.3e J/cycle', ...
    m.hysteresis_work_J_per_cycle));
grid on;
saveas(gcf,fullfile(output_dir,'baseline_pressure_volume_loop.png'));

Ctan = p.A_eff^2./(p.k+3*p.alpha*w.^2);
figure('Color','w');
plot(t,Ctan*1e9*133.322,'LineWidth',1.5);
xlabel('time (s)');
ylabel('tangent compliance (\muL/mmHg)');
title('Nonlinear tangent compliance through one cardiac cycle');
grid on;
saveas(gcf,fullfile(output_dir,'baseline_compliance_evolution.png'));

diag = evaluate_energy(sol);
tmid = 0.5*(sol.t(1:end-1)+sol.t(2:end));
step = tmid >= sol.t(end)-T;
labels = {'wall viscosity','radiation'};
dtall = diff(sol.t);
vals = [sum(dtall(step).*diag.Dwall_mid(step)), ...
        sum(dtall(step).*diag.Drad_mid(step))];
figure('Color','w');
bar(vals);
set(gca,'XTickLabel',labels);
ylabel('energy dissipated in final cycle (J)');
title('Baseline energy partition');
grid on;
saveas(gcf,fullfile(output_dir,'baseline_energy_partition.png'));
end
