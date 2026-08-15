function profiles = run_profile_likelihood(p,s)
%RUN_PROFILE_LIKELIHOOD One-at-a-time profiles for the combined protocol.
%
% Profiles are generated from one representative 1% volume-noise dataset.
% The other two parameters are reoptimized at each fixed parameter value.

protocol = s.protocols(strcmp({s.protocols.name},'combined'));
data = build_inverse_protocol(protocol,p,s,0.01, ...
    s.pressure_noise_fraction,s.random_seed+88001);

truth_vec = [data.truth.K_V data.truth.R_V data.truth.A_V];
names = {'K_V','R_V','A_V'};
profiles = struct();

fprintf('\n=== Profile likelihood: combined protocol, 1%% volume noise ===\n');

for j = 1:3
    grid = truth_vec(j)*s.profile_grid_multiplier;
    sse = zeros(size(grid));

    for g = 1:numel(grid)
        fixed_log = log(truth_vec);
        fixed_log(j) = log(grid(g));
        free_mask = true(1,3);
        free_mask(j) = false;

        % Local multistart optimization with the profiled parameter fixed.
        fit = fit_with_fixed_log(data,free_mask,fixed_log,s);
        sse(g) = fit.sse_weighted;
    end

    delta = sse-min(sse);
    P.parameter = names{j};
    P.grid = grid;
    P.multiplier = grid/truth_vec(j);
    P.sse = sse;
    P.delta_chi2 = delta;
    profiles.(names{j}) = P;

    T = table(P.multiplier(:),P.grid(:),P.sse(:),P.delta_chi2(:), ...
        'VariableNames',{'truth_multiplier','parameter_value', ...
        'weighted_sse','delta_chi2'});
    writetable(T,fullfile(s.output_dir, ...
        ['profile_likelihood_' names{j} '.csv']));

    if s.make_figures
        figure('Color','w');
        semilogx(P.multiplier,P.delta_chi2,'o-','LineWidth',1.5);
        hold on;
        yline(s.profile_delta_chi2_95,'--','95% threshold');
        xline(1,':','truth');
        xlabel([names{j} ' / truth']);
        ylabel('\Delta \chi^2');
        title(['Profile likelihood: ' names{j}]);
        grid on;
        saveas(gcf,fullfile(s.output_dir, ...
            ['profile_likelihood_' names{j} '.png']));
    end
end

save(fullfile(s.output_dir,'profile_likelihoods.mat'),'profiles','data');
end

function fit = fit_with_fixed_log(data,free_mask,fixed_log,s)
truth_vec = [data.truth.K_V data.truth.R_V data.truth.A_V];
lo = log(truth_vec.*s.lower_multiplier);
hi = log(truth_vec.*s.upper_multiplier);
idx = find(free_mask);
lo_f = lo(idx);
hi_f = hi(idx);

best = Inf;
best_x = [];
for k = 1:s.n_multistart
    if k == 1
        x0 = log(truth_vec(idx));
    else
        x0 = lo_f+(hi_f-lo_f).*rand(size(lo_f));
    end
    z0 = invbound(x0,lo_f,hi_f);
    obj = @(z) objfun(z,lo_f,hi_f,data,free_mask,fixed_log);
    opt = optimset('Display','off','MaxIter',1000, ...
        'MaxFunEvals',3500,'TolX',1e-8,'TolFun',1e-8);
    [z,fval] = fminsearch(obj,z0,opt);
    if fval < best
        best = fval;
        best_x = frombound(z,lo_f,hi_f);
    end
end

[theta,full_log] = inverse_parameter_map(best_x,data.truth, ...
    free_mask,fixed_log);
fit.theta = theta;
fit.log_theta = full_log;
fit.sse_weighted = best;
end

function f = objfun(z,lo,hi,data,mask,fixed)
x = frombound(z,lo,hi);
try
    r = inverse_residual_vector(x,data,mask,fixed);
    f = sum(r.^2);
catch
    f = 1e30;
end
end

function z = invbound(x,lo,hi)
u = min(max((x-lo)./(hi-lo),1e-9),1-1e-9);
z = log(u./(1-u));
end

function x = frombound(z,lo,hi)
x = lo+(hi-lo)./(1+exp(-z));
end
