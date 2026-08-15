function net = build_wall_network(cfg)
%BUILD_WALL_NETWORK Period-aware wall displacement network.
%
% Inputs:
%   normalized time, amplitude, frequency, sin(phase), cos(phase), ramp.
%
% Output:
%   normalized wall displacement.

layers = featureInputLayer(6,'Normalization','none', ...
    'Name','wall_input');

for i = 1:cfg.wall_hidden_layers
    layers = [layers
        fullyConnectedLayer(cfg.wall_hidden_width, ...
            'Name',sprintf('wall_fc%d',i))
        tanhLayer('Name',sprintf('wall_tanh%d',i))]; %#ok<AGROW>
end

layers = [layers
    fullyConnectedLayer(1,'Name','wall_output')];

net = dlnetwork(layers);
end
