function T = run_single_robustness_case(stage_id,noise_fraction,points_per_cycle,seed_id,r)
%RUN_SINGLE_ROBUSTNESS_CASE Run Classical, PINN, and Energy-PINN once.

caseId = robustness_case_id(stage_id,noise_fraction,points_per_cycle,seed_id);
caseFolder = fullfile(r.case_dir,caseId);
if ~exist(caseFolder,'dir'), mkdir(caseFolder); end
csvFile = fullfile(caseFolder,'metrics.csv');
matFile = fullfile(caseFolder,'case_result.mat');
statusFile = fullfile(caseFolder,'status.mat');

if r.resume && isfile(csvFile) && isfile(statusFile)
    S = load(statusFile,'status');
    if isfield(S,'status') && strcmp(S.status,'success')
        T = readtable(csvFile,'TextType','string');
        fprintf('Skipping completed case: %s\n',caseId);
        return
    end
end

cfg = robustness_engine_config(r,stage_id,noise_fraction, ...
    points_per_cycle,seed_id,caseId);
clean = robustness_get_clean_truth(stage_id,cfg,r);
dataset = robustness_build_dataset(clean,cfg,noise_fraction, ...
    points_per_cycle,seed_id);

fprintf('\n============================================================\n');
fprintf('Robustness case: %s\n',caseId);
fprintf('Stage %d | noise %.3f%% | points/cycle %d | seed %d\n', ...
    stage_id,100*noise_fraction,points_per_cycle,seed_id);
fprintf('============================================================\n');

status = 'running';
save(statusFile,'status');
caseStart = tic;

% Temporary method-level checkpoints make long cases resumable even if
% MATLAB is interrupted halfway through the Energy-PINN branch.
classicalFile = fullfile(caseFolder,'checkpoint_classical.mat');
sharedFile = fullfile(caseFolder,'checkpoint_shared.mat');
pinnFile = fullfile(caseFolder,'checkpoint_pinn.mat');
energyFile = fullfile(caseFolder,'checkpoint_energy_pinn.mat');

try
    methods = struct();
    metricCells = {};

    if r.run_classical
        if isfile(classicalFile)
            S = load(classicalFile,'classical');
            methods.classical = S.classical;
        else
            classical = fit_classical_method(dataset,cfg);
            save(classicalFile,'classical','-v7.3');
            methods.classical = classical;
        end
        metricCells{end+1} = evaluate_comparison_method( ...
            'Classical',methods.classical,dataset,cfg); %#ok<AGROW>
    end

    % Both PINNs branch from exactly the same shared state.
    if r.run_pinn || r.run_energy_pinn
        if isfile(sharedFile)
            S = load(sharedFile,'shared');
            shared = S.shared;
        else
            shared = pretrain_two_network_pinn(dataset,cfg);
            save(sharedFile,'shared','-v7.3');
        end
    else
        shared = [];
    end

    if r.run_pinn
        if isfile(pinnFile)
            S = load(pinnFile,'pinn');
            methods.pinn = S.pinn;
        else
            pinn = train_pinn_method(dataset,cfg,false,shared);
            save(pinnFile,'pinn','-v7.3');
            methods.pinn = pinn;
        end
        metricCells{end+1} = evaluate_comparison_method( ...
            'PINN',methods.pinn,dataset,cfg); %#ok<AGROW>
    end

    if r.run_energy_pinn
        if isfile(energyFile)
            S = load(energyFile,'energyPinn');
            methods.energy_pinn = S.energyPinn;
        else
            energyPinn = train_pinn_method(dataset,cfg,true,shared);
            save(energyFile,'energyPinn','-v7.3');
            methods.energy_pinn = energyPinn;
        end
        metricCells{end+1} = evaluate_comparison_method( ...
            'Energy_PINN',methods.energy_pinn,dataset,cfg); %#ok<AGROW>
    end

    metrics = [metricCells{:}];
    T = struct2table(metrics);
    n = height(T);
    T.case_id = repmat(string(caseId),n,1);
    T.stage_id = repmat(stage_id,n,1);
    T.noise_fraction = repmat(noise_fraction,n,1);
    T.noise_percent = repmat(100*noise_fraction,n,1);
    T.points_per_cycle = repmat(points_per_cycle,n,1);
    T.seed_id = repmat(seed_id,n,1);
    T.profile = repmat(string(r.profile),n,1);
    T.case_runtime_s = repmat(toc(caseStart),n,1);

    % Put experimental identifiers first.
    first = {'case_id','stage_id','stage','method','noise_fraction', ...
        'noise_percent','points_per_cycle','seed_id','profile'};
    rest = setdiff(T.Properties.VariableNames,first,'stable');
    T = T(:,[first rest]);
    writetable(T,csvFile);

    dataset_summary = rmfield(dataset,'cases');
    if r.save_networks
        save(matFile,'methods','metrics','dataset_summary','cfg','-v7.3');
    else
        % Keep numerical histories and parameters, but omit large networks.
        compact = compact_methods(methods);
        save(matFile,'compact','metrics','dataset_summary','cfg','-v7.3');
    end

    status = 'success';
    save(statusFile,'status');

    % Numerical summaries are sufficient for the final robustness study.
    % Remove temporary network checkpoints after a successful compact save.
    if ~r.save_networks
        temporary = {classicalFile,sharedFile,pinnFile,energyFile};
        for q = 1:numel(temporary)
            if isfile(temporary{q}), delete(temporary{q}); end
        end
    end
    fprintf('Completed %s in %.1f minutes.\n',caseId,toc(caseStart)/60);
catch ME
    status = 'failed';
    error_message = getReport(ME,'extended','hyperlinks','off');
    save(statusFile,'status','error_message');
    fprintf(2,'FAILED %s\n%s\n',caseId,error_message);
    rethrow(ME)
end
end

function compact = compact_methods(methods)
names = fieldnames(methods);
compact = struct();
for i = 1:numel(names)
    x = methods.(names{i});
    if isfield(x,'model'), x = rmfield(x,'model'); end
    if isfield(x,'final_model'), x = rmfield(x,'final_model'); end
    if isfield(x,'shared_pretraining'), x = rmfield(x,'shared_pretraining'); end
    compact.(names{i}) = x;
end
end
