function out = sobol_saltelli(p0,s)
%SOBOL_SALTELLI Jansen total-order and Saltelli first-order estimators.
rng(s.random_seed); N=s.sobol_N; d=numel(s.parameters);
A=map_unit_samples(rand(N,d),p0,s); B=map_unit_samples(rand(N,d),p0,s);
fprintf('Evaluating Sobol A and B matrices...\n'); YA=evaluate_model_batch(A,p0,s); YB=evaluate_model_batch(B,p0,s);
q=size(YA,2); S1=nan(d,q); ST=nan(d,q); YAB=cell(d,1);
for j=1:d
    AB=A; AB(:,j)=B(:,j); fprintf('Evaluating Sobol AB_%d...\n',j);
    YAB{j}=evaluate_model_batch(AB,p0,s);
end
for k=1:q
    good=isfinite(YA(:,k)) & isfinite(YB(:,k)); V=var([YA(good,k);YB(good,k)],1);
    for j=1:d
        g=good & isfinite(YAB{j}(:,k));
        S1(j,k)=mean(YB(g,k).*(YAB{j}(g,k)-YA(g,k)))/V;
        ST(j,k)=0.5*mean((YA(g,k)-YAB{j}(g,k)).^2)/V;
    end
end
out.S1=S1; out.ST=ST; out.A=A; out.B=B; out.YA=YA; out.YB=YB; out.YAB=YAB;
end
