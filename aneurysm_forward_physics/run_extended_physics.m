%% RUN_EXTENDED_PHYSICS
clear; clc; close all;

output_dir = 'extended_physics_results';
if ~exist(output_dir,'dir'), mkdir(output_dir); end

fprintf('\n1. Amplitude-dependent compliance curve\n');
amplitude_results = run_amplitude_compliance_curve(output_dir);

fprintf('\n2. Wide-band frequency response\n');
frequency_results = run_wideband_frequency_response(output_dir);

fprintf('\n3. Dimensionless analysis\n');
[baseline_groups,regime_map] = run_dimensional_analysis(output_dir);

fprintf('\nExtended physics studies complete.\nResults written to:\n%s\n', ...
    output_dir);
