function Z = normalized_inputs(x,t,amp,freq,meta)
%NORMALIZED_INPUTS Map physical inputs to roughly [-1,1].
znx = 2*x/meta.L - 1;
znt = 2*t/meta.t_max - 1;
zna = 2*(amp-meta.amp_min)/(meta.amp_max-meta.amp_min+eps) - 1;
znf = 2*(freq-meta.freq_min)/(meta.freq_max-meta.freq_min+eps) - 1;
Z = [znx;znt;zna;znf];
end
