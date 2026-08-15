function s = inverse_study_settings()
%INVERSE_STUDY_SETTINGS Reproducible settings for identifiability experiments.

s.random_seed = 240719;
s.output_dir = fullfile(pwd,'inverse_identifiability_results');

% Measurement protocols. Each experiment is one pressure-amplitude/frequency pair.
s.protocols(1).name = 'single_baseline';
s.protocols(1).pressure_mmHg = 20;
s.protocols(1).frequency_Hz = 1.2;

s.protocols(2).name = 'multi_amplitude';
s.protocols(2).pressure_mmHg = [5 10 20 30 40];
s.protocols(2).frequency_Hz = 1.2*ones(1,5);

s.protocols(3).name = 'multi_frequency';
s.protocols(3).pressure_mmHg = 20*ones(1,6);
s.protocols(3).frequency_Hz = [0.6 1.2 3 8 20 30];

s.protocols(4).name = 'combined';
[P,F] = ndgrid([5 10 20 30 40],[0.6 1.2 5 20 30]);
s.protocols(4).pressure_mmHg = P(:).';
s.protocols(4).frequency_Hz = F(:).';

% Time sampling. The last n_fit_cycles are retained as observations.
s.cycles_total = 7;
s.n_fit_cycles = 2;
s.samples_per_cycle = 120;

% Noise is expressed relative to the RMS pulsatile signal in each experiment.
s.volume_noise_fraction = [0.0025 0.005 0.01 0.02];
s.pressure_noise_fraction = 0.0025;

% Monte Carlo size used for the exploratory practical-identifiability screen.
s.n_monte_carlo = 30;
s.n_multistart = 8;

% Log-parameter bounds relative to truth. Wide enough to test identifiability.
s.lower_multiplier = [0.20 0.05 0.02];  % K_V, R_V, A_V
s.upper_multiplier = [5.00 20.0 50.0];

% Finite-difference step in log parameter space for sensitivity analysis.
s.sensitivity_step = 2e-4;

% Profile-likelihood grid and confidence cutoff for one fitted parameter.
s.profile_grid_multiplier = logspace(log10(0.25),log10(4),25);
s.profile_delta_chi2_95 = 3.841; % one degree of freedom

% Run controls.
s.run_profile_likelihood = true;
s.make_figures = true;
end
