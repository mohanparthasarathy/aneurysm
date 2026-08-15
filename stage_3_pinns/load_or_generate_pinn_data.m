function dataset = load_or_generate_pinn_data(stage_id,cfg)
stage = build_stage_protocols(stage_id);
file = fullfile(cfg.data_dir,[stage.name '_synthetic.mat']);
if exist(file,'file')
    S = load(file,'dataset'); dataset = S.dataset;
else
    dataset = generate_pinn_synthetic_data(stage_id,cfg);
end
end
