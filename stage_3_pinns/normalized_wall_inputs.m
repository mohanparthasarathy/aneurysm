function Z = normalized_wall_inputs(t,amp,freq,meta)
%NORMALIZED_WALL_INPUTS Period-aware wall-network features.
%
% A plain tanh network has a strong low-frequency bias and can collapse to
% an almost constant prediction when asked to learn several cardiac cycles
% directly from time. Supplying phase features makes the periodic wall
% motion easy to represent:
%
%   [normalized time, amplitude, frequency, sin(phi), cos(phi), ramp],
%
% where phi = 2*pi*f*t.

znt = 2*t/meta.t_max - 1;
zna = 2*(amp-meta.amp_min)/(meta.amp_max-meta.amp_min+eps) - 1;
znf = 2*(freq-meta.freq_min)/(meta.freq_max-meta.freq_min+eps) - 1;

phase = 2*pi*freq.*t;
sphase = sin(phase);
cphase = cos(phase);

tau = min(max(t.*freq,0),1);
ramp = tau.^2.*(3-2*tau);
zramp = 2*ramp - 1;

Z = [znt;zna;znf;sphase;cphase;zramp];
end
