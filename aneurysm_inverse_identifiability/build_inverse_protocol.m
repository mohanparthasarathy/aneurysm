function data = build_inverse_protocol(protocol,p,s,noise_volume,noise_pressure,seed)
%BUILD_INVERSE_PROTOCOL Generate synchronized pressure-volume experiments.

if nargin < 4, noise_volume = 0; end
if nargin < 5, noise_pressure = 0; end
if nargin < 6, seed = s.random_seed; end
rng(seed,'twister');

truth = effective_volume_parameters(p);
nexp = numel(protocol.pressure_mmHg);
experiments = repmat(struct(),nexp,1);

for e = 1:nexp
    P0 = protocol.pressure_mmHg(e)*133.322;
    f = protocol.frequency_Hz(e);
    omega = 2*pi*f;
    T = 1/f;

    dt = T/s.samples_per_cycle;
    t = (0:dt:s.cycles_total*T).';
    ramp = min(t/T,1);
    pressure_true = P0*ramp.*sin(omega*t);

    theta = truth;
    sol = solve_volume_inverse_model(theta,t,pressure_true,0,0);

    keep = t >= (s.cycles_total-s.n_fit_cycles)*T;
    tt = t(keep);
    pp = pressure_true(keep);
    vv = sol.v(keep);

    p_scale = sqrt(mean((pp-mean(pp)).^2));
    v_scale = sqrt(mean((vv-mean(vv)).^2));

    sigma_p = max(noise_pressure*p_scale,eps);
    sigma_v = max(noise_volume*v_scale,eps);

    p_obs = pp + sigma_p*randn(size(pp));
    v_obs = vv + sigma_v*randn(size(vv));

    experiments(e).t = tt-tt(1);
    experiments(e).pressure_true = pp;
    experiments(e).pressure_obs = p_obs;
    experiments(e).volume_true = vv;
    experiments(e).volume_obs = v_obs;
    experiments(e).sigma_pressure = sigma_p;
    experiments(e).sigma_volume = sigma_v;
    experiments(e).pressure_amplitude_mmHg = protocol.pressure_mmHg(e);
    experiments(e).frequency_Hz = f;
end

data.protocol_name = protocol.name;
data.experiments = experiments;
data.truth = truth;
data.noise_volume_fraction = noise_volume;
data.noise_pressure_fraction = noise_pressure;
data.seed = seed;
end
