function out = morris_screening(p0,s)
%MORRIS_SCREENING Elementary-effects screening on a p-level grid.
rng(s.random_seed+1); d=numel(s.parameters); r=s.morris_trajectories; p=s.morris_levels;
delta=p/(2*(p-1)); EE=nan(r,d,numel(s.outputs));
for tr=1:r
    x=floor(rand(1,d)*(p/2))/(p-1); order=randperm(d); dir=2*(rand(1,d)>0.5)-1;
    % Ensure each step remains in [0,1].
    for j=1:d, if x(j)+dir(j)*delta<0 || x(j)+dir(j)*delta>1, dir(j)=-dir(j); end, end
    y0=evaluate_model_sample(map_unit_samples(x,p0,s),p0,s);
    for h=1:d
        j=order(h); xn=x; xn(j)=xn(j)+dir(j)*delta;
        y1=evaluate_model_sample(map_unit_samples(xn,p0,s),p0,s);
        EE(tr,j,:)=(y1-y0)/(dir(j)*delta); x=xn; y0=y1;
    end
    fprintf('  Morris trajectory %d/%d\n',tr,r);
end
mu_star=squeeze(mean(abs(EE),1,'omitnan')); sigma=squeeze(std(EE,0,1,'omitnan'));
out.EE=EE; out.mu_star=mu_star; out.sigma=sigma;
end
