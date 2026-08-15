function [loss,gradWall] = wall_pretrain_loss(wallNet,b,meta)
%WALL_PRETRAIN_LOSS Fit the wall network directly to noisy wall data.
Zw = normalized_wall_inputs(b.data.t,b.data.amp,b.data.freq,meta);
w = meta.w_scale*forward(wallNet,Zw);
loss = mean(((w-b.data.w)/meta.w_scale).^2,'all');
gradWall = dlgradient(loss,wallNet.Learnables);
end
