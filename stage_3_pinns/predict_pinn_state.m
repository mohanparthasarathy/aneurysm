function [u,w,q] = predict_pinn_state(model,x,t,amp,freq,meta)
%PREDICT_PINN_STATE Two-network state with exact interface coupling.
%
% w = N_w(t,amplitude,frequency)
% q = N_q(x,t,amplitude,frequency)
% u = w + (x/L)q
%
% Therefore u(0,t)=w(t) exactly, and w has no spatial input.

Zw = normalized_wall_inputs(t,amp,freq,meta);
Zq = normalized_inputs(x,t,amp,freq,meta);

w = meta.w_scale*forward(model.wallNet,Zw);
q = meta.w_scale*forward(model.fluidNet,Zq);
u = w + (x/meta.L).*q;
end
