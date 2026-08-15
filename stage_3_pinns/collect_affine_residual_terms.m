function terms = collect_affine_residual_terms(model,pcurrent,dataset,cfg)
%COLLECT_AFFINE_RESIDUAL_TERMS Full-grid affine residual decomposition.
%
% With neural states fixed,
%
%   r_wall = [w, w_t, w^3] [k; eta; alpha] + b_wall
%
% and
%
%   r_energy = [w*w_t, w_t^2, w^3*w_t] ...
%              [k; eta; alpha] + b_energy.
%
% The same implementation is used for Stage 1, Stage 2, Stage 3, energy
% diagnostics, and deterministic parameter updates.

p = dataset.p0;
meta = make_pinn_meta(dataset);

Aw = [];
Bw = [];
Ae = [];
Be = [];
caseIndex = [];

for icase = 1:numel(dataset.cases)
    c = dataset.cases(icase);
    nt = cfg.inverse.full_time_points_per_case;
    nx = cfg.inverse.full_x_points;

    t = linspace(0,c.t_obs(end),nt);
    x = linspace(0,p.L,nx).';
    [T,X] = meshgrid(t,x);

    amp = dlarray(c.amplitude_Pa*ones(1,numel(T)),'CB');
    freq = dlarray(c.frequency_Hz*ones(1,numel(T)),'CB');
    xdl = dlarray(X(:).','CB');
    tdl = dlarray(T(:).','CB');

    [udl,wdl,~] = predict_pinn_state(model,xdl,tdl,amp,freq,meta);
    U = reshape(gather(extractdata(udl)),size(X));
    Wgrid = reshape(gather(extractdata(wdl)),size(X));
    W = Wgrid(1,:);

    dt = mean(diff(t));
    dx = mean(diff(x));
    Wt = diff_vector_local(W,dt);
    Wtt = diff_vector_local(Wt,dt);
    Ut = diff_dim2_local(U,dt);
    Ux = diff_dim1_local(U,dx);

    tau = min(max(t*c.frequency_Hz,0),1);
    ramp = tau.^2.*(3-2*tau);
    P = ramp.*c.amplitude_Pa.*sin(2*pi*c.frequency_Hz*t);

    % Parameter-free wall residual.
    bWall = p.m_w*Wtt - p.A_eff*P - ...
        p.rho_f*p.c_f^2*p.A_f*Ux(1,:);

    % Parameter-free energy residual.
    Efluid = 0.5*p.rho_f*p.A_f*trapz(x, ...
        Ut.^2+p.c_f^2*Ux.^2,1);
    Ekinetic = 0.5*p.m_w*Wt.^2;
    dEbaseDt = diff_vector_local(Efluid+Ekinetic,dt);

    bEnergy = dEbaseDt - p.A_eff*P.*Wt + ...
        p.rho_f*p.c_f^3*p.A_f*Ux(end,:).^2;

    keep = 3:(nt-2);

    AwCase = [W(keep).', Wt(keep).', W(keep).'.^3] / ...
        meta.force_scale;
    AeCase = [(W(keep).*Wt(keep)).', Wt(keep).'.^2, ...
        (W(keep).^3.*Wt(keep)).'] / meta.power_scale;

    Aw = [Aw;AwCase]; %#ok<AGROW>
    Bw = [Bw;bWall(keep).'/meta.force_scale]; %#ok<AGROW>
    Ae = [Ae;AeCase]; %#ok<AGROW>
    Be = [Be;bEnergy(keep).'/meta.power_scale]; %#ok<AGROW>
    caseIndex = [caseIndex;icase*ones(numel(keep),1)]; %#ok<AGROW>
end

terms.Aw = Aw;
terms.Bw = Bw;
terms.Ae = Ae;
terms.Be = Be;
terms.case_index = caseIndex;
terms.meta = meta;
terms.current_parameters = [pcurrent.k;pcurrent.eta;pcurrent.alpha];
end

function D = diff_dim2_local(A,h)
D = zeros(size(A));
D(:,2:end-1) = (A(:,3:end)-A(:,1:end-2))/(2*h);
D(:,1) = (A(:,2)-A(:,1))/h;
D(:,end) = (A(:,end)-A(:,end-1))/h;
end

function D = diff_dim1_local(A,h)
D = zeros(size(A));
D(2:end-1,:) = (A(3:end,:)-A(1:end-2,:))/(2*h);
D(1,:) = (A(2,:)-A(1,:))/h;
D(end,:) = (A(end,:)-A(end-1,:))/h;
end

function d = diff_vector_local(a,h)
a = a(:).';
d = zeros(size(a));
d(2:end-1) = (a(3:end)-a(1:end-2))/(2*h);
d(1) = (a(2)-a(1))/h;
d(end) = (a(end)-a(end-1))/h;
end
