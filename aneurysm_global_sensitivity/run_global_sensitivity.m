function results = run_global_sensitivity()
%RUN_GLOBAL_SENSITIVITY Run toolbox-free Sobol and Morris analyses.
s=sensitivity_settings(); addpath(s.forward_dir,s.solver_dir);
if ~exist(s.results_dir,'dir'), mkdir(s.results_dir); end
p0=physiological_parameters();
fprintf('Running Sobol analysis (%d parameters, N=%d)...\n',numel(s.parameters),s.sobol_N);
sob=sobol_saltelli(p0,s);
fprintf('Running Morris screening...\n'); mor=morris_screening(p0,s);
results.settings=s; results.sobol=sob; results.morris=mor;
save(fullfile(s.results_dir,'global_sensitivity_results.mat'),'results','-v7.3');
write_tables(sob,mor,s); plot_sensitivity_results(sob,mor,s);
fprintf('Global sensitivity complete. Results: %s\n',s.results_dir);
end
function write_tables(sob,mor,s)
for k=1:numel(s.outputs)
    T=table(string(s.parameters(:)),sob.S1(:,k),sob.ST(:,k),mor.mu_star(:,k),mor.sigma(:,k), ...
      'VariableNames',{'parameter','Sobol_First','Sobol_Total','Morris_mu_star','Morris_sigma'});
    writetable(T,fullfile(s.results_dir,['sensitivity_' s.outputs{k} '.csv']));
end
end
