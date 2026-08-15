function publication_workflow(action)
%PUBLICATION_WORKFLOW Entry point for the experiments reported in the paper.
%
% publication_workflow('verify')          Forward-solver verification
% publication_workflow('forward')         Forward physics and sweeps
% publication_workflow('identifiability') Local/practical identifiability
% publication_workflow('inverse')         Staged inverse comparison (1--3)
% publication_workflow('robustness')      Stage-3 robustness study
% publication_workflow('sensitivity')     Sobol/Morris screening
%
% Expensive runs are never started unless explicitly requested.

if nargin < 1
    fprintf(['Available actions: verify, forward, identifiability, inverse, ' ...
             'robustness, sensitivity.\n']);
    return;
end

root = fileparts(mfilename('fullpath'));
action = lower(string(action));

switch action
    case "verify"
        d = fullfile(root,'aneurysm_forward_solver');
        cd(d); addpath(d);
        run_all_tests;
        make_verification_summary;

    case "forward"
        d = fullfile(root,'aneurysm_forward_physics');
        cd(d); addpath(d,fullfile(root,'aneurysm_forward_solver'));
        run_all_forward_physics;
        run_extended_physics;

    case "identifiability"
        d = fullfile(root,'aneurysm_inverse_identifiability');
        cd(d); addpath(d,fullfile(root,'aneurysm_forward_physics'));
        run_inverse_identifiability_study;

    case "inverse"
        d = fullfile(root,'stage_3_pinns');
        cd(d); addpath(d);
        run_pinn_comparison([1 2 3]);

    case "robustness"
        d = fullfile(root,'aneurysm_robustness');
        cd(d); addpath(d);
        run_robustness_suite('paper');

    case "sensitivity"
        d = fullfile(root,'aneurysm_global_sensitivity');
        cd(d); addpath(d);
        run_global_sensitivity;

    otherwise
        error('Unknown action: %s',action);
end
end
