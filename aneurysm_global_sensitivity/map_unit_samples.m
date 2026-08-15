function X = map_unit_samples(U,p0,s)
%MAP_UNIT_SAMPLES Map [0,1] samples to dimensional parameter values.
d=numel(s.parameters); X=zeros(size(U));
for j=1:d
    base=get_base(p0,s.parameters{j}); lo=base*s.lower(j); hi=base*s.upper(j);
    switch lower(s.distribution{j})
        case 'uniform', X(:,j)=lo+(hi-lo)*U(:,j);
        case 'loguniform', X(:,j)=exp(log(lo)+(log(hi)-log(lo))*U(:,j));
        otherwise, error('Unknown distribution: %s',s.distribution{j});
    end
end
end
function x=get_base(p,n)
switch n
 case 'pressure_amplitude', x=p.pressure.amplitude;
 case 'frequency_hz', x=p.pressure.frequency_hz;
 otherwise, x=p.(n);
end
end
