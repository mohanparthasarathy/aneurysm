function summary = run_robustness_postprocess(profile)
%RUN_ROBUSTNESS_POSTPROCESS Rebuild tables and figures without retraining.
if nargin < 1, profile = 'paper'; end
r = robustness_settings(profile);
summary = aggregate_robustness_results(r);
plot_robustness_results(summary,r);
fprintf('Tables and figures rebuilt from completed case CSV files.\n');
end
