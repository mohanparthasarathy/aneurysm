function r = inverse_residual_vector(free_log,data,free_mask,fixed_log)
%INVERSE_RESIDUAL_VECTOR Weighted residuals for all experiments.

theta = inverse_parameter_map(free_log,data.truth,free_mask,fixed_log);
r = [];

for e = 1:numel(data.experiments)
    d = data.experiments(e);

    % Use the measured pressure waveform as the known input.
    sol = solve_volume_inverse_model(theta,d.t,d.pressure_obs, ...
        d.volume_obs(1),0);

    rr = (sol.v-d.volume_obs)/d.sigma_volume;
    r = [r;rr]; %#ok<AGROW>
end

if any(~isfinite(r))
    r(:) = 1e12;
end
end
