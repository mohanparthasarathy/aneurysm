function ptilde = pressure_forcing(t, p)
%PRESSURE_FORCING Prescribed transmural-pressure perturbation.
%
% ptilde = p_tm(t) - p_ref, in Pa.

switch lower(p.pressure.kind)
    case 'sine'
        raw = p.pressure.amplitude .* ...
            sin(p.pressure.omega .* t + p.pressure.phase);

    case 'zero'
        raw = zeros(size(t));

    case 'manufactured'
        % Pressure needed by the exact right-traveling manufactured solution
        % u(x,t) = W0*sin(omega*(t-x/c_f)).
        W0 = p.mms.W0;
        om = p.mms.omega;
        w = W0 .* sin(om .* t);
        wt = W0 .* om .* cos(om .* t);
        wtt = -W0 .* om.^2 .* sin(om .* t);
        ux0 = -(W0 .* om ./ p.c_f) .* cos(om .* t);

        raw = (p.m_w .* wtt + p.eta .* wt + p.k .* w + ...
            p.alpha .* w.^3 - p.rho_f .* p.c_f.^2 .* p.A_f .* ux0) ...
            ./ p.A_eff;

    otherwise
        error('Unknown pressure kind: %s', p.pressure.kind);
end

if isfield(p.pressure, "ramp_time") && p.pressure.ramp_time > 0
    % Smooth C1 ramp to reduce startup transients.
    tau = min(max(t ./ p.pressure.ramp_time, 0), 1);
    ramp = tau.^2 .* (3 - 2*tau);
    ptilde = ramp .* raw;
else
    ptilde = raw;
end
end
