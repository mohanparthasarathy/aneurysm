function result = train_pinn_method(dataset,cfg,useEnergy,shared)
%TRAIN_PINN_METHOD Deterministic multi-parameter / fluid alternation.
%
% Supports:
%   Stage 1: k
%   Stage 2: k, eta
%   Stage 3: k, eta, alpha
%
% The wall network stays frozen after data pretraining. Each outer cycle:
%   1) solves a bounded deterministic least-squares problem for all active
%      material parameters;
%   2) freezes those parameters and refines only the fluid network.

wallNet = shared.wallNet;
fluidNet = shared.fluidNet;
meta = shared.meta;
pfit = dataset.p0;

seed = cfg.seed + 9000 + ...
    100*dataset.stage.active(1) + ...
    10*dataset.stage.active(2) + dataset.stage.active(3);
rng(seed,'twister');

avgF = []; avgSqF = [];
nOuter = cfg.inverse.outer_cycles;
nInner = cfg.inverse.fluid_iterations_per_cycle;

% Columns:
% accepted ratios [k eta alpha], raw ratios [k eta alpha],
% wall RMS, energy RMS, post-fluid raw ratios [k eta alpha], lambdaE.
history = nan(nOuter,12);
fluidHistory = nan(nOuter*nInner,9);
globalIt = 0;

bestScore = Inf;
bestFluid = fluidNet;
bestP = pfit;
bestCycle = 0;

tic;
for outer = 1:nOuter
    if useEnergy
        lambdaE = cfg.inverse.energy_weights( ...
            min(outer,numel(cfg.inverse.energy_weights)));
    else
        lambdaE = 0;
    end

    model.wallNet = wallNet;
    model.fluidNet = fluidNet;

    info = deterministic_parameter_update(model,pfit,dataset,cfg, ...
        useEnergy,lambdaE);

    pfit.k = info.parameters_updated(1);
    pfit.eta = info.parameters_updated(2);
    pfit.alpha = info.parameters_updated(3);

    activeNames = ["k","eta","alpha"];
    active = logical(dataset.stage.active(:));
    ratioText = "";
    for j = find(active).'
        name = char(activeNames(j));
        ratioText = ratioText + string(sprintf(' %s/%s0=%.4f', ...
            name,name,info.parameter_ratios_updated(j)));
    end

    fprintf(['%s outer %d/%d%s wall RMS %.3e, ' ...
        'cond %.3e, rank %d, lambdaE %.1f\n'], ...
        ternary(useEnergy,'Energy-PINN','PINN'), ...
        outer,nOuter,ratioText,info.wall_residual_rms, ...
        info.condition_number,info.rank,lambdaE);

    for inner = 1:nInner
        globalIt = globalIt + 1;
        if outer == nOuter && inner > 0.6*nInner
            lr = cfg.learning_rate.fluid_inverse_final;
        else
            lr = cfg.learning_rate.fluid_inverse;
        end

        b = prepare_pinn_batch(sample_pinn_batch(dataset,cfg));
        [loss,gF,parts] = dlfeval(@fluid_inverse_refinement_loss, ...
            wallNet,fluidNet,pfit,b,dataset,cfg,meta, ...
            useEnergy,lambdaE);
        [fluidNet,avgF,avgSqF] = adamupdate(fluidNet,gF, ...
            avgF,avgSqF,globalIt,lr);

        vals = gather(extractdata([loss;parts]));
        fluidHistory(globalIt,1:numel(vals)) = vals(:).';
        fluidHistory(globalIt,7:9) = ...
            [pfit.k/dataset.p0.k, ...
             pfit.eta/dataset.p0.eta, ...
             pfit.alpha/dataset.p0.alpha];

        if mod(inner,cfg.display_every)==0 || inner==1
            fprintf(['  fluid %d/%d loss %.3e PDE %.2e wall %.2e ' ...
                'energy %.2e\n'],inner,nInner,vals(1),vals(2), ...
                vals(3),vals(end));
        end
    end

    model.fluidNet = fluidNet;

    % Fixed checkpoint objective across all outer cycles.
    if useEnergy
        checkpointLambdaE = cfg.inverse.energy_weights(end);
    else
        checkpointLambdaE = 0;
    end

    postInfo = deterministic_parameter_update(model,pfit,dataset,cfg, ...
        useEnergy,checkpointLambdaE);

    score = postInfo.wall_residual_rms;
    if useEnergy && isfinite(postInfo.energy_residual_rms)
        score = score + sqrt(checkpointLambdaE)* ...
            postInfo.energy_residual_rms;
    end

    history(outer,:) = [ ...
        info.parameter_ratios_updated(:).', ...
        info.parameter_ratios_raw(:).', ...
        info.wall_residual_rms, ...
        info.energy_residual_rms, ...
        postInfo.parameter_ratios_raw(:).', ...
        lambdaE];

    if score < bestScore
        bestScore = score;
        bestFluid = fluidNet;
        bestP = pfit;
        bestCycle = outer;
    end
end

result.runtime_s = toc;

result.model.wallNet = wallNet;
result.model.fluidNet = bestFluid;
result.parameter_estimates = bestP;
result.best_iteration = bestCycle;
result.best_checkpoint_score = bestScore;

result.final_model.wallNet = wallNet;
result.final_model.fluidNet = fluidNet;
result.final_parameter_estimates = pfit;

result.history = history;
result.fluid_history = fluidHistory(1:globalIt,:);
result.meta = meta;
result.use_energy = useEnergy;
result.shared_pretraining = shared;
end

function y = ternary(c,a,b)
if c, y=a; else, y=b; end
end
