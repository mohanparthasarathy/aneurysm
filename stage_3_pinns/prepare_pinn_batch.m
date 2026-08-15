function b = prepare_pinn_batch(b)
%PREPARE_PINN_BATCH Convert differentiable batch fields to traced dlarrays.
%
% dlgradient can differentiate only with respect to dlarray inputs that are
% passed into dlfeval. Creating dlarray objects inside pinn_model_loss does
% not make them traced inputs. This helper is therefore called before
% dlfeval in train_pinn_method.

sections = {'int','wall','bnd','ic','data'};

for i = 1:numel(sections)
    name = sections{i};

    b.(name).x = dlarray(double(b.(name).x),'CB');
    b.(name).t = dlarray(double(b.(name).t),'CB');
    b.(name).amp = dlarray(double(b.(name).amp),'CB');
    b.(name).freq = dlarray(double(b.(name).freq),'CB');

    if isfield(b.(name),'w')
        b.(name).w = dlarray(double(b.(name).w),'CB');
    end
end

% Energy quadrature.
% Every network call must have one feature channel and samples along B.
% Store the spatial quadrature grid as 1-by-Nx, not Nx-by-1; otherwise
% MATLAB interprets Nx as the channel dimension of the feature input.
x_energy = double(b.energy.x(:).');
t_energy = double(b.energy.t(:).');
b.energy.x = dlarray(x_energy,'CB');
b.energy.t = dlarray(t_energy,'CB');
b.energy.amp = dlarray(double(b.energy.amp(:).'),'CB');
b.energy.freq = dlarray(double(b.energy.freq(:).'),'CB');

% Independent traced boundary coordinates used by the energy residual.
b.energy.x0 = dlarray(zeros(size(t_energy)),'CB');
b.energy.xL = dlarray(max(x_energy)*ones(size(t_energy)),'CB');
end
