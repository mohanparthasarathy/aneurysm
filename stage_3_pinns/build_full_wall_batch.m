function b = build_full_wall_batch(dataset)
%BUILD_FULL_WALL_BATCH Use every observed wall-data point deterministically.
%
% This avoids stochastic minibatch behavior during wall-only pretraining and
% makes the wall fit exactly reproducible.

t = [];
amp = [];
freq = [];
w = [];

for i = 1:numel(dataset.cases)
    c = dataset.cases(i);
    ti = c.t_obs(:).';
    wi = c.w_obs(:).';
    ni = numel(ti);

    t = [t,ti]; %#ok<AGROW>
    w = [w,wi]; %#ok<AGROW>
    amp = [amp,c.amplitude_Pa*ones(1,ni)]; %#ok<AGROW>
    freq = [freq,c.frequency_Hz*ones(1,ni)]; %#ok<AGROW>
end

b.data.x = dlarray(zeros(size(t)),'CB');
b.data.t = dlarray(double(t),'CB');
b.data.amp = dlarray(double(amp),'CB');
b.data.freq = dlarray(double(freq),'CB');
b.data.w = dlarray(double(w),'CB');
end
