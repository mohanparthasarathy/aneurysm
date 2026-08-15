function out = local_identifiability_analysis(data,free_mask,s)
%LOCAL_IDENTIFIABILITY_ANALYSIS Log-parameter sensitivity SVD and correlation.

truth_vec = [data.truth.K_V data.truth.R_V data.truth.A_V];
fixed_log = log(truth_vec);
x0 = fixed_log(free_mask);
h = s.sensitivity_step;

% Noise-free observed input/output is used for the structural/local test.
clean = data;
for e = 1:numel(clean.experiments)
    clean.experiments(e).pressure_obs = clean.experiments(e).pressure_true;
    clean.experiments(e).volume_obs = clean.experiments(e).volume_true;
    clean.experiments(e).sigma_volume = max( ...
        sqrt(mean((clean.experiments(e).volume_true- ...
        mean(clean.experiments(e).volume_true)).^2)),eps);
end

r0 = inverse_residual_vector(x0,clean,free_mask,fixed_log);
J = zeros(numel(r0),numel(x0));

for j = 1:numel(x0)
    xp = x0; xm = x0;
    xp(j) = xp(j)+h;
    xm(j) = xm(j)-h;
    rp = inverse_residual_vector(xp,clean,free_mask,fixed_log);
    rm = inverse_residual_vector(xm,clean,free_mask,fixed_log);
    J(:,j) = (rp-rm)/(2*h);
end

[~,S,V] = svd(J,'econ');
sv = diag(S);
tol = max(size(J))*eps(max(sv));
rankJ = sum(sv>tol);

F = J.'*J;
cov_approx = pinv(F);
d = sqrt(max(diag(cov_approx),0));
corr = cov_approx./max(d*d.',eps);
corr(1:size(corr,1)+1:end) = 1;

out.J = J;
out.singular_values = sv;
out.rank = rankJ;
out.condition_number = sv(1)/max(sv(end),eps);
out.fisher_information = F;
out.covariance_scaled = cov_approx;
out.correlation = corr;
out.weak_direction = V(:,end);
out.free_names = {'K_V','R_V','A_V'};
out.free_names = out.free_names(free_mask);
end
