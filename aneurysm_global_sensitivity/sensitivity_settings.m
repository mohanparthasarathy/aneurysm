function s = sensitivity_settings()
%SENSITIVITY_SETTINGS Global sensitivity configuration (toolbox-free).
root=fileparts(mfilename('fullpath')); s.root=root;
s.results_dir=fullfile(root,'results');
s.forward_dir=fullfile(fileparts(root),'aneurysm_forward_physics');
s.solver_dir=fullfile(fileparts(root),'aneurysm_forward_solver');
s.random_seed=20260725;
s.parameters={'k','eta','alpha','A_eff','A_f','c_f','pressure_amplitude','frequency_hz'};
% Multipliers around physiological baseline; use log-uniform for positive spans.
s.lower=[0.50,0.20,0.10,0.75,0.25,0.50,0.50,0.50];
s.upper=[2.00,5.00,10.0,1.25,4.00,2.00,2.00,3.00];
s.distribution=repmat({'loguniform'},size(s.parameters));
s.outputs={'dynamic_compliance_uL_per_mmHg','phase_lag_deg', ...
 'hysteresis_work_J_per_cycle','wall_THD','wall_loss_fraction'};
s.sobol_N=512;              % Saltelli base sample used in the manuscript screening
s.bootstrap_replicates=200;
s.morris_trajectories=30;    % Morris trajectories used in the manuscript screening
s.morris_levels=8;
s.dt_per_cycle=500;
s.settle_cycles=10;
s.analysis_cycles=2;
s.use_parallel=false;
end
