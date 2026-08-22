function plot_two_network_training(shared,pinn,energyPinn,stageName,outdir)
%PLOT_TWO_NETWORK_TRAINING Pretraining and parameter histories.

%% Common plotting settings
fontSize = 14;
labelFontSize = 15;
titleFontSize = 15;
legendFontSize = 12;
lineWidth = 2.0;
markerSize = 7;

%% Wall pretraining history
fig = figure('Visible','off','Color','w', ...
    'Position',[100 100 760 520]);

semilogy(shared.wall_history, ...
    'LineWidth',lineWidth);

xlabel('Iteration','FontSize',labelFontSize);
ylabel('Wall data loss','FontSize',labelFontSize);
title([strrep(stageName,'_',' ') ': frozen wall pretraining'], ...
    'FontSize',titleFontSize);

grid on;
box on;

ax = gca;
ax.FontSize = fontSize;
ax.LineWidth = 1.0;

exportgraphics(fig,fullfile(outdir, ...
    [stageName '_wall_pretraining.png']), ...
    'Resolution',300);

close(fig);


%% Fluid pretraining history
fig = figure('Visible','off','Color','w', ...
    'Position',[100 100 760 520]);

semilogy(shared.fluid_history(:,1), ...
    'LineWidth',lineWidth, ...
    'DisplayName','Total');
hold on;

semilogy(shared.fluid_history(:,2), ...
    'LineWidth',lineWidth, ...
    'DisplayName','PDE');

semilogy(shared.fluid_history(:,3), ...
    'LineWidth',lineWidth, ...
    'DisplayName','Boundary');

semilogy(shared.fluid_history(:,4), ...
    'LineWidth',lineWidth, ...
    'DisplayName','Initial');

legend('Location','best', ...
    'FontSize',legendFontSize);

xlabel('Iteration','FontSize',labelFontSize);
ylabel('Loss','FontSize',labelFontSize);
title([strrep(stageName,'_',' ') ': fluid pretraining'], ...
    'FontSize',titleFontSize);

grid on;
box on;

ax = gca;
ax.FontSize = fontSize;
ax.LineWidth = 1.0;

exportgraphics(fig,fullfile(outdir, ...
    [stageName '_fluid_pretraining.png']), ...
    'Resolution',300);

close(fig);


%% Parameter and residual histories
plot_branch(pinn,stageName,'PINN',outdir);
plot_branch(energyPinn,stageName,'Energy_PINN',outdir);

end


function plot_branch(result,stageName,label,outdir)

H = result.history;
outer = (1:size(H,1)).';

%% Common plotting settings
fontSize = 14;
labelFontSize = 15;
titleFontSize = 15;
legendFontSize = 12;
lineWidth = 2.0;
markerSize = 7;

%% Active parameters
if contains(stageName,'stage1')
    active = [true false false];
elseif contains(stageName,'stage2')
    active = [true true false];
else
    active = [true true true];
end

names = {'k/k_0','\eta/\eta_0','\alpha/\alpha_0'};
truth = [1.30 0.70 1.80];

activeIdx = find(active);


%% ------------------------------------------------------------------------
% Parameter history
% -------------------------------------------------------------------------

fig = figure('Visible','off','Color','w', ...
    'Position',[100 100 820 540]);

hold on;

% Explicitly store ONLY parameter-trajectory handles for the legend.
hParam = gobjects(numel(activeIdx),1);

for ii = 1:numel(activeIdx)

    j = activeIdx(ii);

    hParam(ii) = plot(outer,H(:,j), ...
        'o-', ...
        'LineWidth',lineWidth, ...
        'MarkerSize',markerSize);

    % Truth lines are reference lines, not separate legend entries.
    yline(truth(j),'--', ...
        'LineWidth',1.5, ...
        'HandleVisibility','off');
end

xlabel('Outer cycle','FontSize',labelFontSize);
ylabel('Parameter ratio to baseline','FontSize',labelFontSize);

legend(hParam,names(active), ...
    'Location','best', ...
    'FontSize',legendFontSize, ...
    'Interpreter','tex');

title([strrep(stageName,'_',' ') ': ' strrep(label,'_',' ')], ...
    'FontSize',titleFontSize);

grid on;
box on;

ax = gca;
ax.FontSize = fontSize;
ax.LineWidth = 1.0;

% Give the trajectories a little vertical breathing room.
yl = ylim;
pad = 0.05*(yl(2)-yl(1));
ylim([yl(1)-pad yl(2)+pad]);

exportgraphics(fig,fullfile(outdir, ...
    [stageName '_' label '_parameter_history.png']), ...
    'Resolution',300);

close(fig);


%% ------------------------------------------------------------------------
% Residual history
% -------------------------------------------------------------------------

fig = figure('Visible','off','Color','w', ...
    'Position',[100 100 760 520]);

semilogy(outer,max(H(:,7),eps), ...
    'o-', ...
    'LineWidth',lineWidth, ...
    'MarkerSize',markerSize, ...
    'DisplayName','Wall RMS');

hold on;

if result.use_energy

    semilogy(outer,max(H(:,8),eps), ...
        's-', ...
        'LineWidth',lineWidth, ...
        'MarkerSize',markerSize, ...
        'DisplayName','Energy RMS');
end

legend('Location','best', ...
    'FontSize',legendFontSize);

xlabel('Outer cycle','FontSize',labelFontSize);
ylabel('Common residual RMS','FontSize',labelFontSize);

title([strrep(stageName,'_',' ') ': residual history'], ...
    'FontSize',titleFontSize);

grid on;
box on;

ax = gca;
ax.FontSize = fontSize;
ax.LineWidth = 1.0;

exportgraphics(fig,fullfile(outdir, ...
    [stageName '_' label '_residual_history.png']), ...
    'Resolution',300);

close(fig);

end
