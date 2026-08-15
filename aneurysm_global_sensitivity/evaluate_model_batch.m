function Y = evaluate_model_batch(X,p0,s)
%EVALUATE_MODEL_BATCH Evaluate model rows, optionally in parallel.
n=size(X,1); q=numel(s.outputs); Y=nan(n,q);
if s.use_parallel && license('test','Distrib_Computing_Toolbox')
    parfor i=1:n, Y(i,:)=safe_eval(X(i,:),p0,s,q); end
else
    for i=1:n
        Y(i,:)=safe_eval(X(i,:),p0,s,q);
        if mod(i,max(1,round(n/20)))==0, fprintf('  %d/%d evaluations\n',i,n); end
    end
end
end
function y=safe_eval(x,p0,s,q)
try, y=evaluate_model_sample(x,p0,s); catch ME, warning('%s',ME.message); y=nan(1,q); end
end
