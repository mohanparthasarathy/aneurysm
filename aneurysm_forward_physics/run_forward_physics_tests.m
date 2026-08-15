function results = run_forward_physics_tests(output_dir)
%RUN_FORWARD_PHYSICS_TESTS One-at-a-time forward-physics parameter sweeps.
%
% Studies effects of k, eta, alpha, pressure amplitude, and forcing
% frequency on:
%   displacement and volume amplitude,
%   dynamic and tangent compliance,
%   phase lag,
%   pressure-volume hysteresis,
%   wall/radiation energy partition,
%   harmonic distortion and nonlinear stiffening.

if nargin < 1
    output_dir = fullfile(pwd,'forward_physics_results');
end
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

p0 = physiological_parameters();
settings = struct('Nx',60,'cycles',7,'analyze_cycles',2, ...
    'steps_per_cycle',1200,'max_dt',5e-4);

sweeps = {
    'k',                 [0.50 0.75 1.00 1.50 2.00];
    'eta',               [0.00 0.25 0.50 1.00 2.00];
    'alpha',             [0.00 0.25 0.50 1.00 2.00];
    'pressure_amplitude',[0.25 0.50 1.00 1.50 2.00];
    'frequency',         [0.50 0.75 1.00 1.50 2.00 3.00]
    };

rows = {};
counter = 0;

for s = 1:size(sweeps,1)
    parameter = sweeps{s,1};
    multipliers = sweeps{s,2};

    fprintf('\n=== Sweep: %s ===\n',parameter);

    for j = 1:numel(multipliers)
        mult = multipliers(j);
        p = p0;

        switch parameter
            case 'k'
                p.k = mult*p0.k;
            case 'eta'
                p.eta = mult*p0.eta;
            case 'alpha'
                p.alpha = mult*p0.alpha;
            case 'pressure_amplitude'
                p.pressure.amplitude = mult*p0.pressure.amplitude;
            case 'frequency'
                p.pressure.frequency_hz = mult*p0.pressure.frequency_hz;
                p.pressure.omega = 2*pi*p.pressure.frequency_hz;
            otherwise
                error('Unknown sweep parameter.');
        end

        fprintf('  multiplier = %.3g ... ',mult);
        [sol,m] = run_single_physics_case(p,settings);
        fprintf('w_amp=%.3g um, lag=%.2f deg, balance=%.2e\n', ...
            1e6*m.w_amplitude_m,m.phase_lag_deg, ...
            m.energy_balance_relative_error);

        counter = counter+1;
        base = struct();
        base.sweep_parameter = parameter;
        base.multiplier = mult;
        base.k_N_per_m = p.k;
        base.eta_Ns_per_m = p.eta;
        base.alpha_N_per_m3 = p.alpha;
        base.pressure_amplitude_Pa = p.pressure.amplitude;
        base.pressure_amplitude_mmHg = p.pressure.amplitude/133.322;
        base.frequency_Hz = p.pressure.omega/(2*pi);
        rows{counter} = metrics_struct_to_row(base,m); %#ok<AGROW>

        % Save baseline full solution for detailed plotting.
        if abs(mult-1) < 1e-12
            save(fullfile(output_dir, ...
                ['baseline_from_' parameter '_sweep.mat']),'sol','m','p');
        end
    end
end

results = struct2table(vertcat(rows{:}));
writetable(results,fullfile(output_dir,'forward_physics_metrics.csv'));

make_forward_physics_plots(results,p0,output_dir);
plot_baseline_cycle(p0,settings,output_dir);
save(fullfile(output_dir,'forward_physics_results.mat'), ...
    'results','p0','settings');

fprintf('\nResults written to:\n%s\n',output_dir);
end
