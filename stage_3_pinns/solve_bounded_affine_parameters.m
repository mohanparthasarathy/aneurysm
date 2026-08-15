function out = solve_bounded_affine_parameters( ...
    terms,pcurrent,dataset,cfg,lambdaWall,lambdaEnergy)
%SOLVE_BOUNDED_AFFINE_PARAMETERS Exact box-constrained LS for <=3 parameters.
%
% The solve is performed in dimensionless baseline multipliers
% [k/k0, eta/eta0, alpha/alpha0] to avoid unit-driven ill-conditioning.
% All free/lower/upper active-set combinations are enumerated. With at most
% three parameters this requires no more than 27 tiny least-squares solves.

p0vec = [dataset.p0.k;dataset.p0.eta;dataset.p0.alpha];
current = [pcurrent.k;pcurrent.eta;pcurrent.alpha];
currentRatio = current./p0vec;
active = logical(dataset.stage.active(:));

lowerRatio = cfg.inverse.lower_multiplier(:);
upperRatio = cfg.inverse.upper_multiplier(:);

Mw = sqrt(lambdaWall/max(size(terms.Aw,1),1))*terms.Aw;
bw = sqrt(lambdaWall/max(size(terms.Aw,1),1))*terms.Bw;

if lambdaEnergy > 0
    Me = sqrt(lambdaEnergy/max(size(terms.Ae,1),1))*terms.Ae;
    be = sqrt(lambdaEnergy/max(size(terms.Ae,1),1))*terms.Be;
    M = [Mw;Me];
    b = [bw;be];
else
    M = Mw;
    b = bw;
end

% Convert columns from dimensional parameters to baseline multipliers.
Mratio = M.*p0vec.';

inactive = ~active;
bActive = b + Mratio(:,inactive)*currentRatio(inactive);
A = Mratio(:,active);

lo = lowerRatio(active);
hi = upperRatio(active);
n = sum(active);

states = all_constraint_states(n);
bestObj = Inf;
bestRatioActive = currentRatio(active);

for i = 1:size(states,1)
    state = states(i,:);
    fixedLow = state == -1;
    fixedHigh = state == 1;
    free = state == 0;

    q = zeros(n,1);
    q(fixedLow) = lo(fixedLow);
    q(fixedHigh) = hi(fixedHigh);

    fixedContribution = zeros(size(bActive));
    if any(~free)
        fixedContribution = A(:,~free)*q(~free);
    end
    rhs = -(bActive + fixedContribution);

    if any(free)
        q(free) = A(:,free)\rhs;
    end

    if any(q < lo-1e-10) || any(q > hi+1e-10) || ...
            any(~isfinite(q))
        continue
    end

    obj = mean((A*q+bActive).^2);
    if obj < bestObj
        bestObj = obj;
        bestRatioActive = q;
    end
end

ratioRaw = currentRatio;
ratioRaw(active) = bestRatioActive;
ratioBounded = min(max(ratioRaw,lowerRatio),upperRatio);
parametersRaw = ratioRaw.*p0vec;
parametersBounded = ratioBounded.*p0vec;

out.parameters_raw = parametersRaw;
out.parameters_bounded = parametersBounded;
out.parameter_ratios_raw = ratioRaw;
out.parameter_ratios_bounded = ratioBounded;
out.objective = bestObj;
out.metrics = evaluate_affine_residuals( ...
    terms,parametersBounded,lambdaWall,lambdaEnergy);

if isempty(A)
    out.condition_number = NaN;
    out.rank = 0;
else
    singularValues = svd(A,'econ');
    tolerance = max(size(A))*eps(max(singularValues));
    out.rank = sum(singularValues > tolerance);
    if isempty(singularValues) || min(singularValues) <= tolerance
        out.condition_number = Inf;
    else
        out.condition_number = ...
            max(singularValues)/min(singularValues);
    end
end
end

function states = all_constraint_states(n)
% Rows contain -1 (lower), 0 (free), +1 (upper).
if n == 0
    states = zeros(1,0);
    return
end

grid = cell(1,n);
[grid{:}] = ndgrid(-1:1);
states = zeros(numel(grid{1}),n);
for j = 1:n
    states(:,j) = grid{j}(:);
end
end
