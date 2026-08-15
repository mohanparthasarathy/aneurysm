function plot_two_network_training(shared,pinn,energyPinn,stageName,outdir)
%PLOT_TWO_NETWORK_TRAINING Pretraining and parameter histories.

fig = figure('Visible','off','Color','w');
semilogy(shared.wall_history,'LineWidth',1.3);
xlabel('iteration'); ylabel('wall data loss'); grid on;
title([strrep(stageName,'_',' ') ': frozen wall pretraining']);
exportgraphics(fig,fullfile(outdir, ...
    [stageName '_wall_pretraining.png']),'Resolution',300);
close(fig);

fig = figure('Visible','off','Color','w');
semilogy(shared.fluid_history(:,1),'LineWidth',1.3); hold on;
semilogy(shared.fluid_history(:,2),'LineWidth',1.1);
semilogy(shared.fluid_history(:,3),'LineWidth',1.1);
semilogy(shared.fluid_history(:,4),'LineWidth',1.1);
legend({'total','PDE','boundary','initial'},'Location','best');
xlabel('iteration'); ylabel('loss'); grid on;
title([strrep(stageName,'_',' ') ': fluid pretraining']);
exportgraphics(fig,fullfile(outdir, ...
    [stageName '_fluid_pretraining.png']),'Resolution',300);
close(fig);

plot_branch(pinn,stageName,'PINN',outdir);
plot_branch(energyPinn,stageName,'Energy_PINN',outdir);
end

function plot_branch(result,stageName,label,outdir)
H = result.history;
outer = (1:size(H,1)).';

if contains(stageName,'stage1')
    active = [true false false];
elseif contains(stageName,'stage2')
    active = [true true false];
else
    active = [true true true];
end

names = {'k/k_0','\eta/\eta_0','\alpha/\alpha_0'};
truth = [1.30 0.70 1.80];

fig = figure('Visible','off','Color','w');
hold on;
for j = find(active)
    plot(outer,H(:,j),'o-','LineWidth',1.3);
    yline(truth(j),'--',[names{j} ' truth']);
end
xlabel('outer cycle');
ylabel('accepted parameter ratio');
legend(names(active),'Location','best');
title([strrep(stageName,'_',' ') ': ' strrep(label,'_',' ')]);
grid on;
exportgraphics(fig,fullfile(outdir, ...
    [stageName '_' label '_parameter_history.png']),'Resolution',300);
close(fig);

fig = figure('Visible','off','Color','w');
semilogy(outer,max(H(:,7),eps),'o-','LineWidth',1.2); hold on;
if result.use_energy
    semilogy(outer,max(H(:,8),eps),'s-','LineWidth',1.2);
    legend({'wall RMS','energy RMS'},'Location','best');
else
    legend({'wall RMS'},'Location','best');
end
xlabel('outer cycle');
ylabel('common residual RMS');
title([strrep(stageName,'_',' ') ': residual history']);
grid on;
exportgraphics(fig,fullfile(outdir, ...
    [stageName '_' label '_residual_history.png']),'Resolution',300);
close(fig);
end
