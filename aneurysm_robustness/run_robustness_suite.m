function summary = run_robustness_suite(profile)
%RUN_ROBUSTNESS_SUITE Run the Stage-3 robustness experiment.
%
% Combines:
%   1) noise levels 0.1%, 0.5%, 1%, 2% at 80 points/cycle;
%   2) 80, 40, 20, 10 points/cycle at 0.5% noise;
%   3) three independent random seeds for every condition.
%
% The comparison includes the standard PINN and Energy-PINN. The suite is
% resumable; successful case folders are skipped on rerun.
%
% Usage:
%   summary = run_robustness_suite('pilot');
%   summary = run_robustness_suite('paper');

if nargin < 1, profile = 'paper'; end
r = robustness_settings(profile);
robustness_setup_paths(r);

cases = robustness_case_table(r);
fprintf('\nFinal robustness design: %d unique datasets.\n',height(cases));
fprintf('Profile: %s\n',r.profile);
fprintf('Results: %s\n\n',r.output_dir);

for i = 1:height(cases)
    fprintf('\nCase %d of %d\n',i,height(cases));
    try
        run_single_robustness_case( ...
            cases.stage_id(i),cases.noise_fraction(i), ...
            cases.points_per_cycle(i),cases.seed_id(i),r);
    catch ME
        warning('RobustnessSuite:CaseFailed', ...
            'Case %s failed and the suite stopped: %s', ...
            cases.case_id(i),ME.message);
        fprintf(['Fix the error and rerun the same command. Completed ' ...
            'cases will be skipped automatically.\n']);
        rethrow(ME)
    end
end

summary = aggregate_robustness_results(r);
plot_robustness_results(summary,r);
fprintf('\nRobustness suite complete.\n');
fprintf('Master table: %s\n', ...
    fullfile(r.table_dir,'robustness_all_runs.csv'));
fprintf('Summary table: %s\n', ...
    fullfile(r.table_dir,'robustness_summary.csv'));
end
