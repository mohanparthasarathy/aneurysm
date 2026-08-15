function make_inverse_identifiability_plots(results,summary,s)
%MAKE_INVERSE_IDENTIFIABILITY_PLOTS Paper-oriented Monte Carlo figures.

protocol_order = {s.protocols.name};
noise_values = unique(summary.noise_volume_fraction);
param_names = {'K','R','A'};
rmse_vars = {'K_rmse_pct','R_rmse_pct','A_rmse_pct'};

for pidx = 1:3
    figure('Color','w');
    hold on;
    for ip = 1:numel(protocol_order)
        idx = strcmp(summary.protocol,protocol_order{ip}) & ...
            strcmp(summary.model,'K_R_A');
        S = sortrows(summary(idx,:),'noise_volume_fraction');
        plot(100*S.noise_volume_fraction,S.(rmse_vars{pidx}), ...
            'o-','LineWidth',1.5);
    end
    xlabel('volume noise (% of pulsatile RMS)');
    ylabel(sprintf('%s_V relative RMSE (%%)',param_names{pidx}));
    legend(protocol_order,'Location','best','Interpreter','none');
    title(sprintf('Practical identifiability of %s_V',param_names{pidx}));
    grid on;
    saveas(gcf,fullfile(s.output_dir, ...
        sprintf('monte_carlo_%s_rmse.png',param_names{pidx})));
end

% Compare model complexity for the combined protocol.
figure('Color','w');
hold on;
models = {'K_only','K_R','K_R_A'};
for im = 1:numel(models)
    idx = strcmp(summary.protocol,'combined') & ...
        strcmp(summary.model,models{im});
    S = sortrows(summary(idx,:),'noise_volume_fraction');
    plot(100*S.noise_volume_fraction,S.K_rmse_pct,'o-', ...
        'LineWidth',1.5);
end
xlabel('volume noise (% of pulsatile RMS)');
ylabel('K_V relative RMSE (%)');
legend(models,'Location','best','Interpreter','none');
title('Effect of inverse-model complexity on stiffness recovery');
grid on;
saveas(gcf,fullfile(s.output_dir,'model_complexity_K_recovery.png'));

% Scatter of joint estimates at 1% noise, combined protocol.
idx = strcmp(results.protocol,'combined') & ...
    strcmp(results.model,'K_R_A') & ...
    abs(results.noise_volume_fraction-0.01)<1e-12;
X = results(idx,:);
if ~isempty(X)
    figure('Color','w');
    scatter(100*X.K_relative_error,100*X.A_relative_error,40, ...
        100*X.R_relative_error,'filled');
    xlabel('K_V relative error (%)');
    ylabel('A_V relative error (%)');
    cb = colorbar;
    ylabel(cb,'R_V relative error (%)');
    title('Joint parameter-recovery errors: combined protocol, 1% noise');
    grid on;
    saveas(gcf,fullfile(s.output_dir,'joint_recovery_errors.png'));
end
end
