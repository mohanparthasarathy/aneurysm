function id = robustness_case_id(stage_id,noise_fraction,points_per_cycle,seed_id)
%ROBUSTNESS_CASE_ID Stable filename-safe identifier for a unique dataset.
noiseTag = round(1e5*noise_fraction);
id = sprintf('stage%d_noise%05d_points%03d_seed%02d', ...
    stage_id,noiseTag,points_per_cycle,seed_id);
end
