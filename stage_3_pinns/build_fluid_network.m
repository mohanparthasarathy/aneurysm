function net = build_fluid_network(cfg)
%BUILD_FLUID_NETWORK [x,t,amplitude,frequency] -> auxiliary fluid field q.
layers = featureInputLayer(4,'Normalization','none','Name','fluid_input');
for i = 1:cfg.fluid_hidden_layers
    layers = [layers
        fullyConnectedLayer(cfg.fluid_hidden_width, ...
            'Name',sprintf('fluid_fc%d',i))
        tanhLayer('Name',sprintf('fluid_tanh%d',i))]; %#ok<AGROW>
end
layers = [layers
    fullyConnectedLayer(1,'Name','fluid_output')];
net = dlnetwork(layers);
end
