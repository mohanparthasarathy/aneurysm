function metrics = evaluate_comparison_method(method,result,dataset,cfg)
%EVALUATE_COMPARISON_METHOD Parameter, state, energy, and timing metrics.
pfit = result.parameter_estimates; ptrue = dataset.ptrue;
metrics.method = string(method);
metrics.stage = string(dataset.stage.name);
metrics.k_est = pfit.k; metrics.eta_est = pfit.eta; metrics.alpha_est = pfit.alpha;
active = logical(dataset.stage.active(:));
metrics.k_error_percent = NaN;
metrics.eta_error_percent = NaN;
metrics.alpha_error_percent = NaN;
if active(1)
    metrics.k_error_percent = 100*abs(pfit.k-ptrue.k)/ptrue.k;
end
if active(2)
    metrics.eta_error_percent = 100*abs(pfit.eta-ptrue.eta)/ptrue.eta;
end
if active(3)
    metrics.alpha_error_percent = 100*abs(pfit.alpha-ptrue.alpha)/ptrue.alpha;
end
metrics.runtime_s = result.runtime_s;
volErr = []; uErr = []; uDen = []; energyRms = [];
for j = 1:numel(dataset.cases)
    c = dataset.cases(j);
    tEval = linspace(0,c.t_obs(end),cfg.eval_t_points_per_case);
    xEval = linspace(0,ptrue.L,cfg.eval_x_points)';
    [T,X] = meshgrid(tEval,xEval);
    Utrue = interp2(c.sol_truth.t,c.sol_truth.x,c.sol_truth.u,T,X,'linear');
    Vtrue = interp1(c.sol_truth.t,c.sol_truth.V,tEval,'pchip');
    if startsWith(lower(method),'classical')
        pp = pfit;
        pp.pressure.amplitude=c.amplitude_Pa; pp.pressure.frequency_hz=c.frequency_Hz;
        pp.pressure.omega=2*pi*c.frequency_Hz; pp.pressure.phase=0;
        pp.pressure.ramp_time=1/c.frequency_Hz;
        o.Nx=cfg.classical_Nx; o.dt=c.period/cfg.classical_steps_per_cycle; o.tspan=[0,c.t_obs(end)];
        sol=solve_forward(pp,o);
        U=interp2(sol.t,sol.x,sol.u,T,X,'linear');
        V=interp1(sol.t,sol.V,tEval,'pchip');
    else
        amp = dlarray(c.amplitude_Pa*ones(1,numel(T)),'CB');
        freq = dlarray(c.frequency_Hz*ones(1,numel(T)),'CB');
        xdl = dlarray(X(:)','CB');
        tdl = dlarray(T(:)','CB');
        [udl,wdl,~] = predict_pinn_state(result.model, ...
            xdl,tdl,amp,freq,result.meta);
        U = reshape(extractdata(udl),size(X));
        W = reshape(extractdata(wdl),size(X));
        V = ptrue.V_ref+ptrue.A_eff*W(1,:);
    end
    volErr=[volErr;(V(:)-Vtrue(:))]; %#ok<AGROW>
    uErr=[uErr;(U(:)-Utrue(:))]; %#ok<AGROW>
    uDen=[uDen;Utrue(:)]; %#ok<AGROW>
    energyRms(end+1)=numerical_energy_residual(U,V,tEval,xEval,c,pfit,ptrue); %#ok<AGROW>
end
metrics.volume_RMSE_m3 = sqrt(mean(volErr.^2));
allV = vertcat(dataset.cases.V_clean);
metrics.volume_NRMSE_percent = 100*metrics.volume_RMSE_m3/(max(allV)-min(allV)+eps);
metrics.hidden_u_RMSE_m = sqrt(mean(uErr.^2));
metrics.hidden_u_NRMSE_percent = 100*metrics.hidden_u_RMSE_m/(max(uDen)-min(uDen)+eps);
% Legacy diagnostic retained only for backward comparison.
metrics.energy_residual_legacy = mean(energyRms);
if ~startsWith(lower(method),'classical')
    metrics.energy_residual_common_fullgrid = ...
        common_energy_residual_metric(result.model,pfit,dataset,cfg);
else
    metrics.energy_residual_common_fullgrid = NaN;
end

end

function nrms = numerical_energy_residual(U,V,t,x,c,pfit,pgeom)
% Common finite-difference energy diagnostic for every method.
W=(V-pgeom.V_ref)/pgeom.A_eff;
dt=mean(diff(t)); dx=mean(diff(x));
Ut=diff_dim2(U,dt); Ux=diff_dim1(U,dx); Wt=diff_vector(W,dt);
Ef=0.5*pgeom.rho_f*pgeom.A_f*trapz(x,Ut.^2+pgeom.c_f^2*Ux.^2,1);
E=Ef+0.5*pgeom.m_w*Wt.^2+0.5*pfit.k*W.^2+0.25*pfit.alpha*W.^4;
dEdt=diff_vector(E,dt);
amp=c.amplitude_Pa; freq=c.frequency_Hz;
tau=min(max(t*freq,0),1); ramp=tau.^2.*(3-2*tau);
P=ramp.*amp.*sin(2*pi*freq*t);
r=dEdt-pgeom.A_eff*P.*Wt+pfit.eta*Wt.^2+ ...
    pgeom.rho_f*pgeom.c_f^3*pgeom.A_f*Ux(end,:).^2;
scale=max(mean(abs(pgeom.A_eff*P.*Wt)),eps);
nrms=sqrt(mean(r.^2))/scale;
end

function D=diff_dim2(A,h)
D=zeros(size(A)); D(:,2:end-1)=(A(:,3:end)-A(:,1:end-2))/(2*h);
D(:,1)=(A(:,2)-A(:,1))/h; D(:,end)=(A(:,end)-A(:,end-1))/h;
end
function D=diff_dim1(A,h)
D=zeros(size(A)); D(2:end-1,:)=(A(3:end,:)-A(1:end-2,:))/(2*h);
D(1,:)=(A(2,:)-A(1,:))/h; D(end,:)=(A(end,:)-A(end-1,:))/h;
end
function d=diff_vector(a,h)
a=a(:).'; d=zeros(size(a)); d(2:end-1)=(a(3:end)-a(1:end-2))/(2*h);
d(1)=(a(2)-a(1))/h; d(end)=(a(end)-a(end-1))/h;
end
