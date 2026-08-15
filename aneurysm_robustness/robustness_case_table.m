function T = robustness_case_table(r)
%ROBUSTNESS_CASE_TABLE Unique factorial cases, avoiding duplicate baseline.

rows = struct([]);
for stage_id = r.stage_ids
    % Noise study at baseline observation density.
    for noise = r.noise_levels
        for seed = r.seed_ids
            row.stage_id = stage_id;
            row.noise_fraction = noise;
            row.points_per_cycle = r.baseline_points;
            row.seed_id = seed;
            row.case_id = string(robustness_case_id(stage_id,noise, ...
                r.baseline_points,seed));
            rows = [rows;row]; %#ok<AGROW>
        end
    end

    % Sparsity study at baseline noise. The 80-point baseline is already
    % present above and is not duplicated.
    for points = r.sparsity_points
        if points == r.baseline_points && ...
                any(abs(r.noise_levels-r.baseline_noise)<eps)
            continue
        end
        for seed = r.seed_ids
            row.stage_id = stage_id;
            row.noise_fraction = r.baseline_noise;
            row.points_per_cycle = points;
            row.seed_id = seed;
            row.case_id = string(robustness_case_id(stage_id, ...
                r.baseline_noise,points,seed));
            rows = [rows;row]; %#ok<AGROW>
        end
    end
end
T = struct2table(rows);
T = sortrows(T,{'stage_id','noise_fraction','points_per_cycle','seed_id'});
end
