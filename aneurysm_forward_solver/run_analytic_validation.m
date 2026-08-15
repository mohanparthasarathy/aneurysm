function result = run_analytic_validation()
%RUN_ANALYTIC_VALIDATION Compare FD solution with exact linear response.

p = default_parameters();
p.alpha = 0;
p.boundary = 'radiation';
p.pressure.kind = 'sine';
p.pressure.ramp_time = 0;

opts = struct('Nx',300,'dt',1e-4,'tspan',[0,0.8]);
sol = solve_forward(p,opts);
ex = linear_analytic_solution(sol.t,p);

err_inf = max(abs(sol.w-ex.w));
err_rel = err_inf/max(max(abs(ex.w)),eps);

fprintf("Analytical validation: max |w_h-w_exact| = %.3e m\n",err_inf);
fprintf("Analytical validation: relative max error = %.3e\n",err_rel);

figure;
plot(sol.t,ex.w,"-","LineWidth",1.7); hold on;
plot(sol.t,sol.w,"--","LineWidth",1.3);
xlabel("t (s)"); ylabel("w(t) (m)");
legend("Analytical","Finite difference","Location","best");
title("Linear outgoing-wave validation");
grid on;

figure;
plot(sol.t,sol.w-ex.w,"LineWidth",1.3);
xlabel("t (s)"); ylabel("error in w(t) (m)");
title("Finite-difference error relative to analytical solution");
grid on;

result.solution = sol;
result.exact = ex;
result.max_error = err_inf;
result.relative_error = err_rel;
end
