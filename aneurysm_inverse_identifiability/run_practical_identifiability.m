function results = run_practical_identifiability(p,s)
%RUN_PRACTICAL_IDENTIFIABILITY Monte Carlo recovery under noisy observations.

model_names = {'K_only','K_R','K_R_A'};
masks = {[true false false],[true true false],[true true true]};
truth = effective_volume_parameters(p);
truth_vec = [truth.K_V truth.R_V truth.A_V];

rows = {};
counter = 0;

fprintf('\n=== Practical identifiability Monte Carlo ===\n');
for ip = 1:numel(s.protocols)
    protocol = s.protocols(ip);

    for in = 1:numel(s.volume_noise_fraction)
        nv = s.volume_noise_fraction(in);

        fprintf('  protocol=%-18s volume noise=%5.2f%%\n', ...
            protocol.name,100*nv);

        for rep = 1:s.n_monte_carlo
            data = build_inverse_protocol(protocol,p,s,nv, ...
                s.pressure_noise_fraction, ...
                s.random_seed+100000*ip+1000*in+rep);

            for im = 1:numel(masks)
                fit = fit_inverse_parameters(data,masks{im},s);
                est = [fit.theta.K_V fit.theta.R_V fit.theta.A_V];

                counter = counter+1;
                row.protocol = protocol.name;
                row.noise_volume_fraction = nv;
                row.noise_pressure_fraction = s.pressure_noise_fraction;
                row.replicate = rep;
                row.model = model_names{im};
                row.K_V_est = est(1);
                row.R_V_est = est(2);
                row.A_V_est = est(3);
                row.K_relative_error = est(1)/truth_vec(1)-1;
                row.R_relative_error = est(2)/truth_vec(2)-1;
                row.A_relative_error = est(3)/truth_vec(3)-1;
                row.weighted_rmse = fit.rmse_standardized;
                row.success = fit.success;
                rows{counter} = row; %#ok<AGROW>
            end
        end
    end
end

results = struct2table(vertcat(rows{:}));
writetable(results,fullfile(s.output_dir, ...
    'practical_identifiability_monte_carlo.csv'));

summary = summarize_monte_carlo(results);
writetable(summary,fullfile(s.output_dir, ...
    'practical_identifiability_summary.csv'));

save(fullfile(s.output_dir,'practical_identifiability.mat'), ...
    'results','summary','truth','s');

if s.make_figures
    make_inverse_identifiability_plots(results,summary,s);
end
end

function S = summarize_monte_carlo(T)
groups = unique(T(:,{'protocol','noise_volume_fraction','model'}),'rows');
rows = {};

for i = 1:height(groups)
    idx = strcmp(T.protocol,groups.protocol{i}) & ...
        T.noise_volume_fraction==groups.noise_volume_fraction(i) & ...
        strcmp(T.model,groups.model{i});
    X = T(idx,:);

    row.protocol = groups.protocol{i};
    row.noise_volume_fraction = groups.noise_volume_fraction(i);
    row.model = groups.model{i};

    row.K_bias_pct = 100*mean(X.K_relative_error);
    row.K_rmse_pct = 100*sqrt(mean(X.K_relative_error.^2));
    row.K_median_abs_error_pct = 100*median(abs(X.K_relative_error));

    row.R_bias_pct = 100*mean(X.R_relative_error);
    row.R_rmse_pct = 100*sqrt(mean(X.R_relative_error.^2));
    row.R_median_abs_error_pct = 100*median(abs(X.R_relative_error));

    row.A_bias_pct = 100*mean(X.A_relative_error);
    row.A_rmse_pct = 100*sqrt(mean(X.A_relative_error.^2));
    row.A_median_abs_error_pct = 100*median(abs(X.A_relative_error));

    row.success_rate = mean(X.success);
    row.median_weighted_rmse = median(X.weighted_rmse);
    rows{end+1} = row; %#ok<AGROW>
end
S = struct2table(vertcat(rows{:}));
end
