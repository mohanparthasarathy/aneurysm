function stage = build_stage_protocols(stage_id)
%BUILD_STAGE_PROTOCOLS Staged inverse experiments.
switch stage_id
    case 1
        stage.name = 'stage1_k_only';
        stage.active = [true false false];
        stage.amplitude_mmHg = 20;
        stage.frequency_Hz = 1.2;
    case 2
        stage.name = 'stage2_k_eta';
        stage.active = [true true false];
        stage.amplitude_mmHg = [20 20 20];
        stage.frequency_Hz = [0.6 1.2 2.4];
    case 3
        stage.name = 'stage3_k_eta_alpha';
        [A,F] = ndgrid([10 20 30],[0.8 1.2 2.0]);
        stage.active = [true true true];
        stage.amplitude_mmHg = A(:)';
        stage.frequency_Hz = F(:)';
    otherwise
        error('stage_id must be 1, 2, or 3.');
end
stage.n_cases = numel(stage.amplitude_mmHg);
end
