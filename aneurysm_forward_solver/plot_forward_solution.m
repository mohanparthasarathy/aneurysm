function plot_forward_solution(sol)
%PLOT_FORWARD_SOLUTION Basic visualization of the coupled solution.

figure;
imagesc(sol.t,sol.x,sol.u);
axis xy;
xlabel("t (s)"); ylabel("x (m)");
title("Surrounding-fluid displacement u(x,t)");
colorbar;

figure;
plot(sol.t,sol.w,"LineWidth",1.5);
xlabel("t (s)"); ylabel("w(t) (m)");
title("Volume-equivalent aneurysm-wall displacement");
grid on;

figure;
plot(sol.t,sol.V,"LineWidth",1.5);
xlabel("t (s)"); ylabel("V(t) (m^3)");
title("Aneurysm volume");
grid on;
end
