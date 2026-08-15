function plot_sensitivity_results(sob,mor,s)
%PLOT_SENSITIVITY_RESULTS Export one Sobol and Morris plot per output.
for k=1:numel(s.outputs)
    f=figure('Color','w'); b=bar([sob.S1(:,k),sob.ST(:,k)]);
    set(gca,'XTick',1:numel(s.parameters),'XTickLabel',strrep(s.parameters,'_',' '),'XTickLabelRotation',35);
    ylabel('Sobol index'); legend(b,{'First order','Total order'},'Location','best'); grid on;
    title(strrep(s.outputs{k},'_',' ')); exportgraphics(f,fullfile(s.results_dir,['sobol_' s.outputs{k} '.png']),'Resolution',300); close(f);
    f=figure('Color','w'); scatter(mor.mu_star(:,k),mor.sigma(:,k),55,'filled');
    text(mor.mu_star(:,k),mor.sigma(:,k),strcat("  ",string(strrep(s.parameters,'_',' '))));
    xlabel('\mu^*'); ylabel('\sigma'); grid on; title(strrep(s.outputs{k},'_',' '));
    exportgraphics(f,fullfile(s.results_dir,['morris_' s.outputs{k} '.png']),'Resolution',300); close(f);
end
end
