function out = affine_k_optimum(terms,p0,cfg,lambdaWall,lambdaEnergy)
%AFFINE_K_OPTIMUM Bounded direct minimizer of common residual objective.

numWall = sum(terms.Aw.*terms.Bw);
denWall = sum(terms.Aw.^2);
numEnergy = sum(terms.Ae.*terms.Be);
denEnergy = sum(terms.Ae.^2);

num = lambdaWall*numWall + lambdaEnergy*numEnergy;
den = lambdaWall*denWall + lambdaEnergy*denEnergy;

if den <= eps || ~isfinite(den)
    kRaw = NaN;
else
    kRaw = -num/den;
end

kMin = cfg.inverse.k_lower_multiplier*p0.k;
kMax = cfg.inverse.k_upper_multiplier*p0.k;
kBounded = min(max(kRaw,kMin),kMax);

out.k_raw = kRaw;
out.k_bounded = kBounded;
out.k_ratio_raw = kRaw/p0.k;
out.k_ratio_bounded = kBounded/p0.k;
out.wall_only_ratio = -(numWall/denWall)/p0.k;
out.energy_only_ratio = -(numEnergy/denEnergy)/p0.k;
out.num_wall = numWall;
out.den_wall = denWall;
out.num_energy = numEnergy;
out.den_energy = denEnergy;
out.metrics_at_bounded = evaluate_affine_residuals( ...
    terms,kBounded,lambdaWall,lambdaEnergy);
end
