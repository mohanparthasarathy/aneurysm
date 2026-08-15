function shared = pretrain_two_network_pinn(dataset,cfg)
%PRETRAIN_TWO_NETWORK_PINN Fit wall data, then fluid field with wall frozen.

seed = cfg.seed + 100*dataset.stage.active(1) + ...
    10*dataset.stage.active(2) + dataset.stage.active(3);
rng(seed,'twister');

wallNet = build_wall_network(cfg);
fluidNet = build_fluid_network(cfg);
meta = make_pinn_meta(dataset);

%% Phase A: wall-data pretraining
fprintf('\nShared Phase A: wall-data pretraining\n');
avgW = []; avgSqW = [];
wallHistory = nan(cfg.pretrain.wall_iterations,1);

% Wall-only fitting uses all observations on every iteration. This removes
% random minibatch variation and makes the fit reproducible.
wallBatch = build_full_wall_batch(dataset);

for it = 1:cfg.pretrain.wall_iterations
    [loss,gW] = dlfeval(@wall_pretrain_loss,wallNet,wallBatch,meta);
    [wallNet,avgW,avgSqW] = adamupdate(wallNet,gW, ...
        avgW,avgSqW,it,cfg.learning_rate.wall_pretrain);
    wallHistory(it) = gather(extractdata(loss));

    if mod(it,cfg.display_every)==0 || it==1
        fprintf('Wall pretrain %d/%d loss %.3e\n', ...
            it,cfg.pretrain.wall_iterations,wallHistory(it));
    end
end

%% Phase B: fluid-field pretraining with wall frozen
fprintf('\nShared Phase B: fluid-field pretraining\n');
avgF = []; avgSqF = [];
fluidHistory = nan(cfg.pretrain.fluid_iterations,4);

for it = 1:cfg.pretrain.fluid_iterations
    b = prepare_pinn_batch(sample_pinn_batch(dataset,cfg));
    [loss,gF,parts] = dlfeval(@fluid_pretrain_loss, ...
        wallNet,fluidNet,b,dataset,cfg,meta);
    [fluidNet,avgF,avgSqF] = adamupdate(fluidNet,gF, ...
        avgF,avgSqF,it,cfg.learning_rate.fluid_pretrain);

    vals = gather(extractdata([loss;parts]));
    fluidHistory(it,1:numel(vals)) = vals(:)';

    if mod(it,cfg.display_every)==0 || it==1
        fprintf(['Fluid pretrain %d/%d loss %.3e PDE %.2e ' ...
            'boundary %.2e IC %.2e\n'],it, ...
            cfg.pretrain.fluid_iterations,vals(1),vals(2), ...
            vals(3),vals(4));
    end
end

shared.wallNet = wallNet;
shared.fluidNet = fluidNet;
shared.meta = meta;
shared.wall_history = wallHistory;
shared.fluid_history = fluidHistory;
shared.parameter_estimates = dataset.p0;
end
