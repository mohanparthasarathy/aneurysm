function ex = manufactured_exact(x,t,p)
%MANUFACTURED_EXACT Exact right-traveling wave used in convergence tests.
%
% u(x,t)=W0*sin(omega*(t-x/c_f)), w(t)=u(0,t).
% It satisfies u_tt=c_f^2*u_xx and u_t+c_f*u_x=0 exactly.

W0 = p.mms.W0;
om = p.mms.omega;
[X,T] = ndgrid(x(:),t(:));

phase = om*(T-X/p.c_f);
ex.u = W0*sin(phase);
ex.ut = W0*om*cos(phase);
ex.ux = -(W0*om/p.c_f)*cos(phase);
ex.w = W0*sin(om*t(:));
ex.wdot = W0*om*cos(om*t(:));
end
