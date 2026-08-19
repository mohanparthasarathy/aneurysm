function summary = aggregate_robustness_results(r)
%AGGREGATE_ROBUSTNESS_RESULTS Create run-level and mean +/- SD tables.

files = dir(fullfile(r.case_dir,'stage*','metrics.csv'));
assert(~isempty(files), ...
    'No completed robustness metrics found in %s.',r.case_dir);

allRuns = table();
for i = 1:numel(files)
    Ti = readtable(fullfile(files(i).folder,files(i).name), ...
        'TextType','string');
    allRuns = [allRuns;Ti]; %#ok<AGROW>
end
allRuns = sortrows(allRuns, ...
    {'stage_id','noise_fraction','points_per_cycle','seed_id','method'});
writetable(allRuns,fullfile(r.table_dir,'robustness_all_runs.csv'));

% A baseline case participates in both the noise and sparsity studies.
expanded = table();
noiseMask = allRuns.points_per_cycle == r.baseline_points & ...
    ismembertol(allRuns.noise_fraction,r.noise_levels,1e-12);
Tn = allRuns(noiseMask,:);
Tn.study = repmat("noise",height(Tn),1);
Tn.x_value = Tn.noise_percent;
Tn.x_label = string(compose('%.1f%%',Tn.noise_percent));
expanded = [expanded;Tn];

sparseMask = abs(allRuns.noise_fraction-r.baseline_noise)<1e-12 & ...
    ismember(allRuns.points_per_cycle,r.sparsity_points);
Ts = allRuns(sparseMask,:);
Ts.study = repmat("sparsity",height(Ts),1);
Ts.x_value = Ts.points_per_cycle;
Ts.x_label = string(Ts.points_per_cycle);
expanded = [expanded;Ts];

metrics = {'k_error_percent','eta_error_percent','alpha_error_percent', ...
    'volume_NRMSE_percent','hidden_u_NRMSE_percent', ...
    'energy_residual_common_fullgrid','runtime_s'};

keys = unique(expanded(:,{'study','stage_id','stage','method', ...
    'x_value','x_label','noise_percent','points_per_cycle'}),'rows');
rows = struct([]);
for i = 1:height(keys)
    mask = expanded.study == keys.study(i) & ...
        expanded.stage_id == keys.stage_id(i) & ...
        expanded.method == keys.method(i) & ...
        expanded.x_value == keys.x_value(i);
    G = expanded(mask,:);

    row.study = keys.study(i);
    row.stage_id = keys.stage_id(i);
    row.stage = keys.stage(i);
    row.method = keys.method(i);
    row.x_value = keys.x_value(i);
    row.x_label = keys.x_label(i);
    row.noise_percent = keys.noise_percent(i);
    row.points_per_cycle = keys.points_per_cycle(i);
    row.n_runs = height(G);

    for m = 1:numel(metrics)
        name = metrics{m};
        values = G.(name);
        row.([name '_mean']) = mean(values,'omitnan');
        row.([name '_std']) = std(values,'omitnan');
        row.([name '_median']) = median(values,'omitnan');
    end
    rows = [rows;row]; %#ok<AGROW>
end

summary = struct2table(rows);
summary = sortrows(summary,{'study','stage_id','x_value','method'});
writetable(summary,fullfile(r.table_dir,'robustness_summary.csv'));
writetable(summary(summary.study=="noise",:), ...
    fullfile(r.table_dir,'noise_robustness_summary.csv'));
writetable(summary(summary.study=="sparsity",:), ...
    fullfile(r.table_dir,'sparsity_robustness_summary.csv'));

% Compact baseline summary for the three repeated Stage-3 realizations.
baseline = summary(summary.study=="noise" & ...
    abs(summary.noise_percent-100*r.baseline_noise)<1e-12,:);
writetable(baseline,fullfile(r.table_dir, ...
    'baseline_five_seed_summary.csv'));

save(fullfile(r.output_dir,'robustness_aggregate.mat'), ...
    'allRuns','expanded','summary','r','-v7.3');
end
