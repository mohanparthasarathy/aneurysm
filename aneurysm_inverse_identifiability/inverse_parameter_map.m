function [theta,full_log] = inverse_parameter_map(free_log,truth,free_mask,fixed_log)
%INVERSE_PARAMETER_MAP Reconstruct full positive parameter vector.

if nargin < 4 || isempty(fixed_log)
    fixed_log = log([truth.K_V truth.R_V truth.A_V]);
end
full_log = fixed_log(:).';
full_log(free_mask) = free_log(:).';

theta.M_V = truth.M_V;
theta.K_V = exp(full_log(1));
theta.R_V = exp(full_log(2));
theta.A_V = exp(full_log(3));
end
