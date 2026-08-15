function [loss,gFluid,parts] = fluid_inverse_refinement_loss( ...
    wallNet,fluidNet,pfit,b,dataset,cfg,meta,useEnergy,lambdaE)
%FLUID_INVERSE_REFINEMENT_LOSS Update only the fluid network.
%
% The wall network and material parameters are frozen. This prevents the
% accurate measured wall waveform from drifting during physics training.

model.wallNet = wallNet;
model.fluidNet = fluidNet;
p = dataset.p0;

% Interior wave PDE.
[u,~,~] = predict_pinn_state(model,b.int.x,b.int.t, ...
    b.int.amp,b.int.freq,meta);
ut = dlgradient(sum(u,'all'),b.int.t, ...
    'EnableHigherDerivatives',true);
ux = dlgradient(sum(u,'all'),b.int.x, ...
    'EnableHigherDerivatives',true);
utt = dlgradient(sum(ut,'all'),b.int.t, ...
    'EnableHigherDerivatives',true);
uxx = dlgradient(sum(ux,'all'),b.int.x, ...
    'EnableHigherDerivatives',true);
rPDE = (utt-p.c_f^2*uxx)/meta.pde_scale;
LPDE = mean(rPDE.^2,'all');

% Wall traction equation.
[uw,ww,~] = predict_pinn_state(model,b.wall.x,b.wall.t, ...
    b.wall.amp,b.wall.freq,meta);
uwx = dlgradient(sum(uw,'all'),b.wall.x, ...
    'EnableHigherDerivatives',true);
wwt = dlgradient(sum(ww,'all'),b.wall.t, ...
    'EnableHigherDerivatives',true);
wwtt = dlgradient(sum(wwt,'all'),b.wall.t, ...
    'EnableHigherDerivatives',true);
pres = pressure_dl(b.wall.t,b.wall.amp,b.wall.freq);
rWall = (p.m_w*wwtt+pfit.eta*wwt+pfit.k*ww+ ...
    pfit.alpha*ww.^3-p.A_eff*pres- ...
    p.rho_f*p.c_f^2*p.A_f*uwx)/meta.force_scale;
Lwall = mean(rWall.^2,'all');

% Radiation boundary.
[uL,~,~] = predict_pinn_state(model,b.bnd.x,b.bnd.t, ...
    b.bnd.amp,b.bnd.freq,meta);
uLt = dlgradient(sum(uL,'all'),b.bnd.t, ...
    'EnableHigherDerivatives',true);
uLx = dlgradient(sum(uL,'all'),b.bnd.x, ...
    'EnableHigherDerivatives',true);
rB = (uLt+p.c_f*uLx)/meta.velocity_scale;
Lbnd = mean(rB.^2,'all');

% Initial fluid state. Wall state remains anchored by its frozen network.
[ui,~,~] = predict_pinn_state(model,b.ic.x,b.ic.t, ...
    b.ic.amp,b.ic.freq,meta);
uit = dlgradient(sum(ui,'all'),b.ic.t, ...
    'EnableHigherDerivatives',true);
Lic = mean((ui/meta.w_scale).^2 + ...
    (uit/meta.velocity_scale).^2,'all');

Lenergy = 0*Lwall;
if useEnergy && lambdaE > 0
    Lenergy = two_network_energy_loss(model,b.energy,dataset, ...
        meta,pfit.k,pfit.eta,pfit.alpha);
end

loss = cfg.lambda.pde*LPDE + cfg.lambda.wall*Lwall + ...
    cfg.lambda.radiation*Lbnd + cfg.lambda.initial*Lic + ...
    lambdaE*Lenergy;

gFluid = dlgradient(loss,fluidNet.Learnables);
parts = [LPDE;Lwall;Lbnd;Lic;Lenergy];
end
