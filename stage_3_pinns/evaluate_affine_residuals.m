function out = evaluate_affine_residuals(terms,parameters,lambdaWall,lambdaEnergy)
%EVALUATE_AFFINE_RESIDUALS Evaluate common wall and energy residual metrics.

parameters = parameters(:);
rw = terms.Aw*parameters + terms.Bw;
rE = terms.Ae*parameters + terms.Be;

out.wall_rms = sqrt(mean(rw.^2));
out.energy_rms = sqrt(mean(rE.^2));
out.combined_objective = lambdaWall*mean(rw.^2) + ...
    lambdaEnergy*mean(rE.^2);
end
