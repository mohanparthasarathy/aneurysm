function plot_robustness_results(summary,r)
%PLOT_ROBUSTNESS_RESULTS Generate final paper-ready robustness figures.

methods = ["Classical","PINN","Energy_PINN"];
methodLabels = ["Classical","PINN","Energy-PINN"];
paramMetrics = {'k_error_percent','eta_error_percent','alpha_error_percent'};
paramLabels = {'k error (%)','\eta error (%)','\alpha error (%)'};
activeByStage = {[1],[1 2],[1 2 3]};

for stage_id = r.stage_ids
    for study = ["noise","sparsity"]
        S = summary(summary.stage_id==stage_id & ...
            summary.study==study,:);
        if isempty(S), continue; end

        active = activeByStage{stage_id};
        fig = figure('Visible','off','Color','w', ...
            'Position',[100 100 420*numel(active) 360]);
        tiledlayout(1,numel(active),'Padding','compact', ...
            'TileSpacing','compact');

        for a = 1:numel(active)
            nexttile; hold on;
            metric = paramMetrics{active(a)};
            for im = 1:numel(methods)
                M = S(S.method==methods(im),:);
                M = sortrows(M,'x_value');
                y = M.([metric '_mean']);
                e = M.([metric '_std']);
                errorbar(M.x_value,y,e,'o-','LineWidth',1.2, ...
                    'DisplayName',methodLabels(im));
            end
            xlabel(x_axis_label(study));
            ylabel(paramLabels{active(a)});
            title(sprintf('Stage %d',stage_id));
            grid on;
            if a==1, legend('Location','best'); end
        end

        filename = sprintf('%s_parameter_errors_stage%d.png',study,stage_id);
        exportgraphics(fig,fullfile(r.figure_dir,filename),'Resolution',300);
        close(fig);
    end
end

% State reconstruction and energy consistency figures, one per study.
for study = ["noise","sparsity"]
    S = summary(summary.study==study,:);
    if isempty(S), continue; end

    fig = figure('Visible','off','Color','w', ...
        'Position',[100 100 1200 850]);
    tiledlayout(3,3,'Padding','compact','TileSpacing','compact');
    stateMetrics = {'volume_NRMSE_percent','hidden_u_NRMSE_percent', ...
        'energy_residual_common_fullgrid'};
    stateLabels = {'Volume NRMSE (%)','Hidden u NRMSE (%)', ...
        'Common energy residual'};

    for stage_id = 1:3
        for m = 1:3
            nexttile; hold on;
            for im = 1:numel(methods)
                M = S(S.stage_id==stage_id & S.method==methods(im),:);
                M = sortrows(M,'x_value');
                if isempty(M), continue; end
                y = M.([stateMetrics{m} '_mean']);
                e = M.([stateMetrics{m} '_std']);
                errorbar(M.x_value,y,e,'o-','LineWidth',1.1, ...
                    'DisplayName',methodLabels(im));
            end
            xlabel(x_axis_label(study));
            ylabel(stateLabels{m});
            title(sprintf('Stage %d',stage_id));
            grid on;
            if stage_id==1 && m==1, legend('Location','best'); end
        end
    end
    exportgraphics(fig,fullfile(r.figure_dir, ...
        sprintf('%s_state_energy_metrics.png',study)),'Resolution',300);
    close(fig);
end

% Runtime figure documents the computational tradeoff.
fig = figure('Visible','off','Color','w','Position',[100 100 1050 340]);
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
for stage_id = 1:3
    nexttile; hold on;
    S = summary(summary.study=="noise" & summary.stage_id==stage_id,:);
    for im = 1:numel(methods)
        M = sortrows(S(S.method==methods(im),:),'x_value');
        errorbar(M.x_value,M.runtime_s_mean/60,M.runtime_s_std/60, ...
            'o-','LineWidth',1.1,'DisplayName',methodLabels(im));
    end
    xlabel('Measurement noise (%)');
    ylabel('Runtime (minutes)');
    title(sprintf('Stage %d',stage_id));
    grid on;
    if stage_id==1, legend('Location','best'); end
end
exportgraphics(fig,fullfile(r.figure_dir,'runtime_by_stage.png'), ...
    'Resolution',300);
close(fig);
end

function label = x_axis_label(study)
if study=="noise"
    label = 'Measurement noise (%)';
else
    label = 'Observations per cycle';
end
end
