function tableOut = run_manufactured_convergence()
%RUN_MANUFACTURED_CONVERGENCE Joint space-time manufactured-solution test.
%
% The exact right-traveling wave is used with dt proportional to dx, so a
% second-order spatial method plus second-order implicit midpoint method
% should give O(dx^2 + dt^2) convergence. A larger manufactured amplitude
% and tight Newton tolerance keep the test above the roundoff/solver floor.

p = default_parameters();
p.pressure.kind = 'manufactured';
p.pressure.ramp_time = 0;
p.boundary = 'radiation';

% Use the linear wall for a clean formal-order verification. The nonlinear
% model is tested separately in forward runs.
p.alpha = 0;
p.mms.W0 = 1.0e-3;
p.mms.omega = 2*pi*2.0;

tf = 0.15;
Nxs = [25,50,100,200];
errs = zeros(size(Nxs));
relerrs = zeros(size(Nxs));
dxs = zeros(size(Nxs));
dts = zeros(size(Nxs));

for j = 1:numel(Nxs)
    Nx = Nxs(j);
    dx = p.L/Nx;
    dt = 0.15*dx/p.c_f;

    model = build_semidiscrete_model(p,Nx);
    ex0 = manufactured_exact(model.x,0,p);

    opts = struct('Nx',Nx,'dt',dt,'tspan',[0,tf], ...
        'q0',ex0.u(:,1),'v0',ex0.ut(:,1), ...
        'newton_tol',1e-10,'newton_abs_tol',1e-14,'newton_maxit',20);
    sol = solve_forward(p,opts);
    exf = manufactured_exact(sol.x,sol.t(end),p);

    e = sol.q(:,end)-exf.u(:,end);
    err = sqrt(sol.model.dx*sum(e.^2));
    exact_norm = sqrt(sol.model.dx*sum(exf.u(:,end).^2));

    errs(j) = err;
    relerrs(j) = err/max(exact_norm,eps);
    dxs(j) = dx;
    dts(j) = sol.dt;
end

orders = [NaN, log(errs(1:end-1)./errs(2:end))./ ...
    log(dxs(1:end-1)./dxs(2:end))];

% Least-squares slope over all points and over the first three points.
fit_all = polyfit(log(dxs),log(errs),1);
fit_pre_floor = polyfit(log(dxs(1:3)),log(errs(1:3)),1);

tableOut = table(Nxs(:),dxs(:),dts(:),errs(:),relerrs(:),orders(:), ...
    'VariableNames',{'Nx','dx','dt','L2_error','relative_L2_error', ...
    'observed_order'});
disp(tableOut);
fprintf('Log-log fitted order (all grids): %.4f\n',fit_all(1));
fprintf('Log-log fitted order (first three grids): %.4f\n',fit_pre_floor(1));

figure;
loglog(dxs,errs,'o-','LineWidth',1.5); hold on;
loglog(dxs,errs(end)*(dxs/dxs(end)).^2,'--','LineWidth',1.2);
set(gca,'XDir','reverse');
xlabel('\Delta x'); ylabel('L^2 error at final time');
legend('Measured','Second-order reference','Location','best');
title('Manufactured-solution joint convergence');
grid on;
end
