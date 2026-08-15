function y = evaluate_model_sample(x,p0,s)
%EVALUATE_MODEL_SAMPLE Run one reduced forward model and collect outputs.
p=p0;
for j=1:numel(s.parameters)
    n=s.parameters{j};
    switch n
        case 'pressure_amplitude', p.pressure.amplitude=x(j);
        case 'frequency_hz', p.pressure.frequency_hz=x(j); p.pressure.omega=2*pi*x(j);
        otherwise, p.(n)=x(j);
    end
end
p.pressure.ramp_time=1/p.pressure.frequency_hz;
T=1/p.pressure.frequency_hz; opts.dt=T/s.dt_per_cycle;
opts.tspan=[0,(s.settle_cycles+s.analysis_cycles)*T];
sol=solve_reduced_wall(p,opts); m=analyze_reduced_cycles(sol,s.analysis_cycles);
y=zeros(1,numel(s.outputs));
for k=1:numel(s.outputs), y(k)=m.(s.outputs{k}); end
end
