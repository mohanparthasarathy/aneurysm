function summary = run_robustness_stage(stage_id,profile)
%RUN_ROBUSTNESS_STAGE Run all noise/sparsity/seeds for one stage.
%
% Useful for splitting the full study into three resumable jobs:
%   run_robustness_stage(1,'paper')
%   run_robustness_stage(2,'paper')
%   run_robustness_stage(3,'paper')

if nargin < 2, profile = 'paper'; end
assert(ismember(stage_id,1:3),'stage_id must be 1, 2, or 3.');
r = robustness_settings(profile);
r.stage_ids = stage_id;
robustness_setup_paths(r);
cases = robustness_case_table(r);

for i = 1:height(cases)
    fprintf('\nStage %d case %d of %d\n',stage_id,i,height(cases));
    run_single_robustness_case(cases.stage_id(i), ...
        cases.noise_fraction(i),cases.points_per_cycle(i), ...
        cases.seed_id(i),r);
end

summary = aggregate_robustness_results(r);
plot_robustness_results(summary,r);
end
