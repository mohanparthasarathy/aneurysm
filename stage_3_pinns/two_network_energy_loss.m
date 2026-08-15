function LE = two_network_energy_loss(model,e,dataset,meta,k,eta,alpha)
%TWO_NETWORK_ENERGY_LOSS Global energy-balance residual.
p = dataset.p0;
nx = numel(e.x);
nt = numel(e.t);
xgrid = e.x;
tE = e.t;
dx = p.L/(nx-1);

% Wall state and velocity at all energy times.
[~,wAll,~] = predict_pinn_state(model,e.x0,tE,e.amp,e.freq,meta);
wtAll = dlgradient(sum(wAll,'all'),tE, ...
    'EnableHigherDerivatives',true);

Ecell = cell(1,nt);
for j = 1:nt
    tj = tE(j)+0*xgrid;
    aj = e.amp(j)+0*xgrid;
    fj = e.freq(j)+0*xgrid;
    [u,~,~] = predict_pinn_state(model,xgrid,tj,aj,fj,meta);
    ut = dlgradient(sum(u,'all'),tj, ...
        'EnableHigherDerivatives',true);
    ux = dlgradient(sum(u,'all'),xgrid, ...
        'EnableHigherDerivatives',true);

    density = 0.5*p.rho_f*p.A_f.* ...
        (ut.^2+p.c_f^2*ux.^2);
    Efluid = dx*(0.5*density(1)+ ...
        sum(density(2:end-1),'all')+0.5*density(end));

    wj = wAll(j);
    wtj = wtAll(j);
    Ewall = 0.5*p.m_w*wtj.^2+0.5*k*wj.^2+ ...
        0.25*alpha*wj.^4;
    Ecell{j} = Efluid+Ewall;
end

E = cat(2,Ecell{:});
dEdt = dlgradient(sum(E,'all'),tE, ...
    'EnableHigherDerivatives',true);

[uL,~,~] = predict_pinn_state(model,e.xL,tE,e.amp,e.freq,meta);
uLx = dlgradient(sum(uL,'all'),e.xL, ...
    'EnableHigherDerivatives',true);

pres = pressure_dl(tE,e.amp,e.freq);
rE = (dEdt-p.A_eff*pres.*wtAll+eta*wtAll.^2+ ...
    p.rho_f*p.c_f^3*p.A_f*uLx.^2)/meta.power_scale;
LE = mean(rE.^2,'all');
end
