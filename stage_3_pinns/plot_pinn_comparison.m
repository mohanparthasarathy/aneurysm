function plot_pinn_comparison(metrics,stageName,outdir)
%PLOT_PINN_COMPARISON Clean comparison figures.

if ~exist(outdir,'dir'), mkdir(outdir); end

labels = cellstr(string({metrics.method}));
labels = strrep(labels,'_',' ');
x = 1:numel(metrics);

Yparam = [[metrics.k_error_percent].', ...
          [metrics.eta_error_percent].', ...
          [metrics.alpha_error_percent].'];
parameterNames = {'k','eta','alpha'};
keep = ~all(isnan(Yparam),1);
Yparam = Yparam(:,keep);
parameterNames = parameterNames(keep);

fig = figure('Visible','off','Color','w');
if size(Yparam,2)==1
    bar(x,Yparam(:,1));
else
    bar(x,Yparam,'grouped');
end
set(gca,'XTick',x,'XTickLabel',labels);
ylabel('Absolute parameter error (%)');
legend(parameterNames,'Location','best');
title(strrep(stageName,'_',' '));
grid on;
exportgraphics(fig,fullfile(outdir, ...
    [stageName '_parameter_errors.png']),'Resolution',300);
close(fig);

Ystate = [[metrics.volume_NRMSE_percent].', ...
          [metrics.hidden_u_NRMSE_percent].'];

fig = figure('Visible','off','Color','w');
bar(x,Ystate,'grouped');
set(gca,'XTick',x,'XTickLabel',labels);
ylabel('NRMSE (%)');
legend({'Volume NRMSE','Hidden u NRMSE'},'Location','best');
title([strrep(stageName,'_',' ') ' state reconstruction']);
grid on;
exportgraphics(fig,fullfile(outdir, ...
    [stageName '_state_metrics.png']),'Resolution',300);
close(fig);

Yenergy = [metrics.energy_residual_common_fullgrid].';

fig = figure('Visible','off','Color','w');
bar(x,Yenergy);
set(gca,'XTick',x,'XTickLabel',labels);
ylabel('Common full-grid energy residual');
title([strrep(stageName,'_',' ') ' energy consistency']);
grid on;
exportgraphics(fig,fullfile(outdir, ...
    [stageName '_common_energy_residual.png']),'Resolution',300);
close(fig);
end
