function lambdaE = energy_weight_schedule(cfg,it,useEnergy)
if ~useEnergy
    lambdaE = 0;
    return
end
r = cfg.energy_ramp;
if it < r.level1_iteration
    tau = max(0,(it-r.start_iteration))/max(r.level1_iteration-r.start_iteration,1);
    lambdaE = tau*r.level1;
elseif it < r.level2_iteration
    tau = (it-r.level1_iteration)/max(r.level2_iteration-r.level1_iteration,1);
    lambdaE = r.level1 + tau*(r.level2-r.level1);
elseif it < r.full_iteration
    tau = (it-r.level2_iteration)/max(r.full_iteration-r.level2_iteration,1);
    lambdaE = r.level2 + tau*(r.full-r.level2);
else
    lambdaE = r.full;
end
end
