function plot_robustness_results(summary,r)
%PLOT_ROBUSTNESS_RESULTS Generate final paper-ready robustness figures.

methods = ["Classical","PINN","Energy_PINN"];
methodLabels = ["Classical","PINN","Energy-PINN"];

paramMetrics = {'k_error_percent','eta_error_percent','alpha_error_percent'};
paramLabels = {'k error (%)','\eta error (%)','\alpha error (%)'};
activeByStage = {[1],[1 2],[1 2 3]};

%% ------------------------------------------------------------------------
% Parameter-recovery figures
% -------------------------------------------------------------------------

for stage_id = r.stage_ids
    for study = ["noise","sparsity"]

        S = summary(summary.stage_id==stage_id & ...
            summary.study==study,:);

        if isempty(S)
            continue;
        end

        active = activeByStage{stage_id};

        fig = figure('Visible','off','Color','w', ...
            'Position',[100 100 470*numel(active) 390]);

        tiledlayout(1,numel(active), ...
            'Padding','compact', ...
            'TileSpacing','compact');

        for a = 1:numel(active)

            ax = nexttile;
            hold(ax,'on');

            metric = paramMetrics{active(a)};

            for im = 1:numel(methods)

                M = S(S.method==methods(im),:);
                M = sortrows(M,'x_value');

                if isempty(M)
                    continue;
                end

                y = M.([metric '_mean']);
                e = M.([metric '_std']);

                errorbar(M.x_value,y,e,'o-', ...
                    'LineWidth',1.5, ...
                    'MarkerSize',5, ...
                    'DisplayName',methodLabels(im));
            end

            xlabel(x_axis_label(study),'FontSize',11);
            ylabel(paramLabels{active(a)},'FontSize',11);

            % Stage labels are redundant for the Stage 3 manuscript
            % figures, but retained for Stages 1 and 2.
            if stage_id < 3
                title(sprintf('Stage %d',stage_id),'FontSize',11);
            end

            grid on;
            box on;
            set(gca,'FontSize',10);

            if a==1
                legend('Location','best','FontSize',9);
            end
        end

        filename = sprintf('%s_parameter_errors_stage%d.png', ...
            study,stage_id);

        exportgraphics(fig, ...
            fullfile(r.figure_dir,filename), ...
            'Resolution',300);

        close(fig);
    end
end


%% ------------------------------------------------------------------------
% Stage 3 state reconstruction and energy consistency
%
% These are the figures used in the main manuscript. Restricting them to
% Stage 3 avoids the previous 3-by-3 layout and makes each diagnostic
% readable at journal size.
% -------------------------------------------------------------------------

stateMetrics = { ...
    'volume_NRMSE_percent', ...
    'hidden_u_NRMSE_percent', ...
    'energy_residual_common_fullgrid'};

stateLabels = { ...
    'Volume NRMSE (%)', ...
    'Hidden u NRMSE (%)', ...
    'Common energy residual'};

for study = ["noise","sparsity"]

    S = summary(summary.study==study & summary.stage_id==3,:);

    if isempty(S)
        continue;
    end

    fig = figure('Visible','off','Color','w', ...
        'Position',[100 100 1400 390]);

    tiledlayout(1,3, ...
        'Padding','compact', ...
        'TileSpacing','compact');

    for m = 1:3

        ax = nexttile;
        hold(ax,'on');

        for im = 1:numel(methods)

            M = S(S.method==methods(im),:);
            M = sortrows(M,'x_value');

            if isempty(M)
                continue;
            end

            y = M.([stateMetrics{m} '_mean']);
            e = M.([stateMetrics{m} '_std']);

            errorbar(M.x_value,y,e,'o-', ...
                'LineWidth',1.5, ...
                'MarkerSize',5, ...
                'DisplayName',methodLabels(im));
        end

        xlabel(x_axis_label(study),'FontSize',11);
        ylabel(stateLabels{m},'FontSize',11);

        grid on;
        box on;
        set(gca,'FontSize',10);

        if m==1
            legend('Location','best','FontSize',9);
        end
    end

    exportgraphics(fig, ...
        fullfile(r.figure_dir, ...
        sprintf('%s_state_energy_metrics.png',study)), ...
        'Resolution',300);

    close(fig);
end


%% ------------------------------------------------------------------------
% Runtime figure
%
% Retain all three stages because this figure documents the computational
% scaling of the inverse methods and can be used in supplementary material.
% -------------------------------------------------------------------------

fig = figure('Visible','off','Color','w', ...
    'Position',[100 100 1200 370]);

tiledlayout(1,3, ...
    'Padding','compact', ...
    'TileSpacing','compact');

for stage_id = 1:3

    ax = nexttile;
    hold(ax,'on');

    S = summary(summary.study=="noise" & ...
        summary.stage_id==stage_id,:);

    for im = 1:numel(methods)

        M = S(S.method==methods(im),:);
        M = sortrows(M,'x_value');

        if isempty(M)
            continue;
        end

        errorbar(M.x_value, ...
            M.runtime_s_mean/60, ...
            M.runtime_s_std/60, ...
            'o-', ...
            'LineWidth',1.4, ...
            'MarkerSize',5, ...
            'DisplayName',methodLabels(im));
    end

    xlabel('Measurement noise (%)','FontSize',11);
    ylabel('Runtime (minutes)','FontSize',11);
    title(sprintf('Stage %d',stage_id),'FontSize',11);

    grid on;
    box on;
    set(gca,'FontSize',10);

    if stage_id==1
        legend('Location','best','FontSize',9);
    end
end

exportgraphics(fig, ...
    fullfile(r.figure_dir,'runtime_by_stage.png'), ...
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
