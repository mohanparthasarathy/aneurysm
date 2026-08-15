function pressure = pressure_dl(t,amp,freq)
%PRESSURE_DL Sine pressure with cubic smooth ramp over one period.
omega = 2*pi*freq;
raw = amp.*sin(omega.*t);
tau = min(max(t.*freq,0),1);
ramp = tau.^2.*(3-2*tau);
pressure = ramp.*raw;
end
