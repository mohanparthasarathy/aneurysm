function [loss,gTheta,parts] = parameter_only_loss( ...
    wallNet,fluidNet,theta,b,dataset,cfg,meta,useEnergy)

model.wallNet = wallNet;
model.fluidNet = fluidNet;
p = dataset.p0;
pfit = decode_pinn_parameters(theta,dataset,cfg);
k = pfit.k; eta = pfit.eta; alpha = pfit.alpha;

[uw,ww,~] = predict_pinn_state(model,b.wall.x,b.wall.t, ...
    b.wall.amp,b.wall.freq,meta);
uwx = dlgradient(sum(uw,'all'),b.wall.x, ...
    'EnableHigherDerivatives',true);
wwt = dlgradient(sum(ww,'all'),b.wall.t, ...
    'EnableHigherDerivatives',true);
wwtt = dlgradient(sum(wwt,'all'),b.wall.t, ...
    'EnableHigherDerivatives',true);
pres = pressure_dl(b.wall.t,b.wall.amp,b.wall.freq);

rWall = (p.m_w*wwtt + eta*wwt + k*ww + alpha*ww.^3 ...
    - p.A_eff*pres - p.rho_f*p.c_f^2*p.A_f*uwx)/meta.force_scale;
Lwall = mean(rWall.^2,'all');

Lenergy = 0*Lwall;
if useEnergy && cfg.lambda.energy > 0
    Lenergy = two_network_energy_loss(model,b.energy,dataset, ...
        meta,k,eta,alpha);
end

loss = cfg.lambda.wall*Lwall + cfg.lambda.energy*Lenergy;
gTheta = dlgradient(loss,theta);
parts = [Lwall;Lenergy];
end
