function fit = fit_inverse_parameters(data,free_mask,s)
%FIT_INVERSE_PARAMETERS Multistart bounded optimization in log space.
%
% Uses fminsearch with a smooth bound transformation, avoiding dependence
% on Optimization Toolbox.

truth_vec = [data.truth.K_V data.truth.R_V data.truth.A_V];
lo = log(truth_vec.*s.lower_multiplier);
hi = log(truth_vec.*s.upper_multiplier);
fixed_log = log(truth_vec);

free_idx = find(free_mask);
lo_f = lo(free_idx);
hi_f = hi(free_idx);

best_f = Inf;
best_z = [];
all_starts = repmat(struct(),s.n_multistart,1);

for start = 1:s.n_multistart
    if start == 1
        x0 = log(truth_vec(free_idx));
    else
        x0 = lo_f+(hi_f-lo_f).*rand(size(lo_f));
    end
    z0 = logit_from_bounds(x0,lo_f,hi_f);

    obj = @(z) objective_z(z,lo_f,hi_f,data,free_mask,fixed_log);
    options = optimset('Display','off','MaxIter',1200, ...
        'MaxFunEvals',4000,'TolX',1e-8,'TolFun',1e-8);
    [z,fval,exitflag,output] = fminsearch(obj,z0,options);

    all_starts(start).fval = fval;
    all_starts(start).exitflag = exitflag;
    all_starts(start).iterations = output.iterations;

    if fval < best_f
        best_f = fval;
        best_z = z;
    end
end

best_log_free = bounds_from_logit(best_z,lo_f,hi_f);
[theta,full_log] = inverse_parameter_map(best_log_free,data.truth, ...
    free_mask,fixed_log);
r = inverse_residual_vector(best_log_free,data,free_mask,fixed_log);

fit.theta = theta;
fit.log_theta = full_log;
fit.free_mask = free_mask;
fit.sse_weighted = sum(r.^2);
fit.rmse_standardized = sqrt(mean(r.^2));
fit.residual = r;
fit.multistart = all_starts;
fit.lower_log = lo;
fit.upper_log = hi;
fit.success = isfinite(best_f);
end

function f = objective_z(z,lo,hi,data,free_mask,fixed_log)
x = bounds_from_logit(z,lo,hi);
try
    r = inverse_residual_vector(x,data,free_mask,fixed_log);
    f = sum(r.^2);
catch
    f = 1e30;
end
if ~isfinite(f), f = 1e30; end
end

function z = logit_from_bounds(x,lo,hi)
u = (x-lo)./(hi-lo);
u = min(max(u,1e-9),1-1e-9);
z = log(u./(1-u));
end

function x = bounds_from_logit(z,lo,hi)
u = 1./(1+exp(-z));
x = lo+(hi-lo).*u;
end
