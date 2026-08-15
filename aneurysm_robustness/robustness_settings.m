function r = robustness_settings(profile)
%ROBUSTNESS_SETTINGS Final Stage-3 robustness experiment.
%
% The final study evaluates the complete inverse problem:
%   [k, eta, alpha]
%
% Experiments:
%   1) noise robustness at 80 observations/cycle;
%   2) data sparsity at 0.5% noise;
%   3) three independent noise realizations.
%
% The classical method is not rerun for every robustness realization
% because it was already evaluated in the primary Stage-3 comparison.

if nargin < 1 || isempty(profile)
    profile = 'paper';
end

profile = lower(string(profile));

%% Paths
r.root = fileparts(mfilename('fullpath'));
r.project_root = fileparts(r.root);

r.engine_dir = fullfile(r.project_root,'stage_3_pinns');
r.forward_dir = fullfile(r.project_root,'aneurysm_forward_solver');
r.physics_dir = fullfile( ...
    r.project_root,'aneurysm_inverse_identifiability');
r.forward_physics_dir = fullfile(r.project_root,'aneurysm_forward_physics');

% Output folders for the reported robustness experiment.
r.output_dir = fullfile(r.root,'robustness_results_final');
r.case_dir = fullfile(r.output_dir,'cases');
r.cache_dir = fullfile(r.output_dir,'clean_truth_cache');
r.figure_dir = fullfile(r.output_dir,'figures');
r.table_dir = fullfile(r.output_dir,'tables');

assert(isfolder(r.engine_dir), ...
    'Expected Stage-3 engine folder at: %s',r.engine_dir);

assert(isfolder(r.forward_dir), ...
    'Expected forward solver folder at: %s',r.forward_dir);

%% Final experimental design

% Run robustness only for the complete three-parameter inverse problem.
r.stage_ids = 3;

% Noise study at 80 observations per cycle.
r.noise_levels = [0.001 0.005 0.010 0.020];

% Sparsity study at 0.5% noise.
r.sparsity_points = [80 40 20 10];

r.baseline_noise = 0.005;
r.baseline_points = 80;

% Three independent noise realizations.
r.seed_ids = 1:3;
r.base_seed = 20260820;

%% Methods

% Classical was already evaluated in the main Stage-3 comparison.
% Robustness focuses on PINN versus Energy-PINN.
r.run_classical = false;
r.run_pinn = true;
r.run_energy_pinn = true;

r.resume = true;
r.save_networks = false;
r.profile = char(profile);

%% Training budget

switch profile
    case "paper"

        % Reduced but still substantial publication-quality budget.
        r.engine_overrides.pretrain_wall_iterations = 1000;
        r.engine_overrides.pretrain_fluid_iterations = 800;

        r.engine_overrides.outer_cycles = 6;
        r.engine_overrides.fluid_iterations_per_cycle = 250;

        r.engine_overrides.full_time_points_per_case = 300;
        r.engine_overrides.full_x_points = 51;

        % Forward data generation remains reasonably resolved.
        r.engine_overrides.forward_Nx = 60;
        r.engine_overrides.forward_steps_per_cycle = 350;

    case "pilot"

        % Very short workflow check only.
        r.noise_levels = [0.005 0.020];
        r.sparsity_points = [80 20];
        r.seed_ids = 1:2;

        r.engine_overrides.pretrain_wall_iterations = 300;
        r.engine_overrides.pretrain_fluid_iterations = 250;

        r.engine_overrides.outer_cycles = 3;
        r.engine_overrides.fluid_iterations_per_cycle = 75;

        r.engine_overrides.full_time_points_per_case = 150;
        r.engine_overrides.full_x_points = 31;

        r.engine_overrides.forward_Nx = 40;
        r.engine_overrides.forward_steps_per_cycle = 200;

    otherwise
        error('profile must be ''paper'' or ''pilot''.');
end

%% Create output folders

folders = { ...
    r.output_dir, ...
    r.case_dir, ...
    r.cache_dir, ...
    r.figure_dir, ...
    r.table_dir};

for i = 1:numel(folders)
    if ~exist(folders{i},'dir')
        mkdir(folders{i});
    end
end
end