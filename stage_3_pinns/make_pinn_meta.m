function meta = make_pinn_meta(dataset)
p = dataset.p0;
meta.L = p.L;
meta.t_max = max(arrayfun(@(c)c.t_obs(end),dataset.cases));
amps = [dataset.cases.amplitude_Pa];
freqs = [dataset.cases.frequency_Hz];
meta.amp_min = min(amps); meta.amp_max = max(amps);
meta.freq_min = min(freqs); meta.freq_max = max(freqs);
if meta.amp_max == meta.amp_min
    meta.amp_min = 0.5*meta.amp_min; meta.amp_max = 1.5*meta.amp_max;
end
if meta.freq_max == meta.freq_min
    meta.freq_min = 0.5*meta.freq_min; meta.freq_max = 1.5*meta.freq_max;
end
meta.P_scale = max(amps);
meta.T_scale = 1/max(freqs);
meta.w_scale = max(p.A_eff*meta.P_scale/p.k,1e-7);
meta.force_scale = p.A_eff*meta.P_scale;
meta.pde_scale = meta.w_scale/meta.T_scale^2;
meta.velocity_scale = meta.w_scale/meta.T_scale;
meta.power_scale = meta.force_scale*meta.velocity_scale;
end
