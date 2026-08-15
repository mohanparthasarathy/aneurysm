function allResults = run_pinn_comparison(stage_ids)
%RUN_PINN_COMPARISON Classical vs PINN vs energy-informed PINN.
% Usage: run_pinn_comparison(1), run_pinn_comparison([1 2 3])

if nargin < 1, stage_ids = 1; end
cfg = pinn_settings();
addpath(cfg.root,cfg.forward_dir,cfg.physics_dir,cfg.forward_physics_dir);
if ~exist(cfg.results_dir,'dir'), mkdir(cfg.results_dir); end
assert(~isempty(ver('nnet')),'Deep Learning Toolbox is required.');

rows = [];
allResults = struct();

for sid = stage_ids
    dataset = load_or_generate_pinn_data(sid,cfg);
    fprintf('\n===== %s =====\n',dataset.stage.name);

    classical = fit_classical_method(dataset,cfg);

    % Shared wall/fluid pretraining.
    shared = pretrain_two_network_pinn(dataset,cfg);

    % Start both inverse branches from the same pretrained checkpoint.
    pinn = train_pinn_method(dataset,cfg,false,shared);
    energyPinn = train_pinn_method(dataset,cfg,true,shared);

    m1 = evaluate_comparison_method('Classical',classical,dataset,cfg);
    m2 = evaluate_comparison_method('PINN',pinn,dataset,cfg);
    m3 = evaluate_comparison_method('Energy_PINN', ...
        energyPinn,dataset,cfg);
    M = [m1 m2 m3];
    rows = [rows M]; %#ok<AGROW>

    stageResult.dataset_summary = rmfield(dataset,'cases');
    stageResult.classical = classical;
    stageResult.shared_pretraining = shared;
    stageResult.pinn = pinn;
    stageResult.energy_pinn = energyPinn;
    stageResult.metrics = M;
    allResults.(dataset.stage.name) = stageResult;

    T = struct2table(M);
    writetable(T,fullfile(cfg.results_dir, ...
        [dataset.stage.name '_comparison.csv']));
    save(fullfile(cfg.results_dir, ...
        [dataset.stage.name '_results.mat']),'stageResult','-v7.3');

    try
        plot_pinn_comparison(M,dataset.stage.name,cfg.results_dir);
        plot_two_network_training(shared,pinn,energyPinn, ...
            dataset.stage.name,cfg.results_dir);
    catch plotError
        warning('PINNComparison:PlotFailed', ...
            'Numerical results were saved, but plotting failed: %s', ...
            plotError.message);
    end

    disp(T(:,{'method','k_error_percent','eta_error_percent', ...
        'alpha_error_percent','volume_NRMSE_percent', ...
        'hidden_u_NRMSE_percent', ...
        'energy_residual_common_fullgrid','runtime_s'}));
end

writetable(struct2table(rows), ...
    fullfile(cfg.results_dir,'all_stage_comparison.csv'));
save(fullfile(cfg.results_dir,'all_pinn_results.mat'), ...
    'allResults','-v7.3');
end
