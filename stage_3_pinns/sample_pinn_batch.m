function b = sample_pinn_batch(dataset,cfg)
%SAMPLE_PINN_BATCH Random collocation, boundary, IC, and observation samples.
p = dataset.p0; cases = dataset.cases; nc = numel(cases);
make = @(n) randi(nc,1,n);

id = make(cfg.batch.interior);
b.int.case = id;
b.int.x = p.L*rand(1,numel(id));
b.int.t = arrayfun(@(q) rand*cases(q).t_obs(end),id);
b.int.amp = arrayfun(@(q) cases(q).amplitude_Pa,id);
b.int.freq = arrayfun(@(q) cases(q).frequency_Hz,id);

id = make(cfg.batch.wall);
b.wall.case = id; b.wall.x = zeros(1,numel(id));
b.wall.t = arrayfun(@(q) rand*cases(q).t_obs(end),id);
b.wall.amp = arrayfun(@(q) cases(q).amplitude_Pa,id);
b.wall.freq = arrayfun(@(q) cases(q).frequency_Hz,id);

id = make(cfg.batch.boundary);
b.bnd.case = id; b.bnd.x = p.L*ones(1,numel(id));
b.bnd.t = arrayfun(@(q) rand*cases(q).t_obs(end),id);
b.bnd.amp = arrayfun(@(q) cases(q).amplitude_Pa,id);
b.bnd.freq = arrayfun(@(q) cases(q).frequency_Hz,id);

id = make(cfg.batch.initial);
b.ic.case = id; b.ic.x = p.L*rand(1,numel(id)); b.ic.t = zeros(1,numel(id));
b.ic.amp = arrayfun(@(q) cases(q).amplitude_Pa,id);
b.ic.freq = arrayfun(@(q) cases(q).frequency_Hz,id);

id = make(cfg.batch.data);
b.data.case = id; b.data.x = zeros(1,numel(id));
b.data.t = zeros(1,numel(id)); b.data.w = zeros(1,numel(id));
for k = 1:numel(id)
    q = id(k); jj = randi(numel(cases(q).t_obs));
    b.data.t(k) = cases(q).t_obs(jj);
    b.data.w(k) = cases(q).w_obs(jj);
end
b.data.amp = arrayfun(@(q) cases(q).amplitude_Pa,id);
b.data.freq = arrayfun(@(q) cases(q).frequency_Hz,id);

id = make(cfg.batch.energy_times);
b.energy.case = id;
b.energy.t = arrayfun(@(q) rand*cases(q).t_obs(end),id);
b.energy.amp = arrayfun(@(q) cases(q).amplitude_Pa,id);
b.energy.freq = arrayfun(@(q) cases(q).frequency_Hz,id);
b.energy.x = linspace(0,p.L,cfg.batch.energy_x)';
end
