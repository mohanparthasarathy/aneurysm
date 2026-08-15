function make_forward_physics_plots(T,p0,output_dir)
%MAKE_FORWARD_PHYSICS_PLOTS Summary figures for each one-at-a-time sweep.

parameters = {'k','eta','alpha','pressure_amplitude','frequency'};

for i = 1:numel(parameters)
    name = parameters{i};
    S = T(strcmp(T.sweep_parameter,name),:);
    [x,order] = sort(S.multiplier);
    S = S(order,:);

    xlab = [name ' / baseline'];
    if strcmp(name,'frequency')
        xplot = S.frequency_Hz;
        xlab = 'forcing frequency (Hz)';
    elseif strcmp(name,'pressure_amplitude')
        xplot = S.pressure_amplitude_mmHg;
        xlab = 'pressure amplitude (mmHg)';
    else
        xplot = x;
    end

    figure('Color','w');
    plot(xplot,1e6*S.w_amplitude_m,'o-','LineWidth',1.5);
    xlabel(xlab); ylabel('wall displacement amplitude (\mum)');
    title([name ' sweep: displacement amplitude']);
    grid on;
    saveas(gcf,fullfile(output_dir,[name '_displacement.png']));

    figure('Color','w');
    plot(xplot,S.volume_pulsation_percent,'o-','LineWidth',1.5);
    xlabel(xlab); ylabel('volume oscillation amplitude (% of V_{ref})');
    title([name ' sweep: volume pulsation']);
    grid on;
    saveas(gcf,fullfile(output_dir,[name '_volume.png']));

    figure('Color','w');
    plot(xplot,S.dynamic_compliance_uL_per_mmHg,'o-','LineWidth',1.5);
    xlabel(xlab); ylabel('dynamic compliance (\muL/mmHg)');
    title([name ' sweep: dynamic compliance']);
    grid on;
    saveas(gcf,fullfile(output_dir,[name '_compliance.png']));

    figure('Color','w');
    plot(xplot,S.phase_lag_deg,'o-','LineWidth',1.5);
    xlabel(xlab); ylabel('volume phase minus pressure phase (degrees)');
    title([name ' sweep: phase lag']);
    grid on;
    saveas(gcf,fullfile(output_dir,[name '_phase.png']));

    figure('Color','w');
    plot(xplot,S.hysteresis_work_J_per_cycle,'o-','LineWidth',1.5);
    xlabel(xlab); ylabel('P-V loop area (J/cycle)');
    title([name ' sweep: hysteresis']);
    grid on;
    saveas(gcf,fullfile(output_dir,[name '_hysteresis.png']));

    figure('Color','w');
    plot(xplot,S.wall_loss_fraction,'o-','LineWidth',1.5); hold on;
    plot(xplot,S.radiation_loss_fraction,'s--','LineWidth',1.5);
    xlabel(xlab); ylabel('fraction of dissipated energy');
    legend('wall viscosity','radiation','Location','best');
    title([name ' sweep: energy partition']);
    ylim([0 1]); grid on;
    saveas(gcf,fullfile(output_dir,[name '_energy_partition.png']));
end

% Combined frequency-response plot.
S = T(strcmp(T.sweep_parameter,'frequency'),:);
[~,order] = sort(S.frequency_Hz);
S = S(order,:);
figure('Color','w');
plot(S.frequency_Hz,1e6*S.w_amplitude_m,'o-','LineWidth',1.5);
xlabel('forcing frequency (Hz)');
ylabel('steady wall amplitude (\mum)');
title('Frequency response');
grid on;
saveas(gcf,fullfile(output_dir,'frequency_response.png'));
end
