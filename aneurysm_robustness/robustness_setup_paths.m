function robustness_setup_paths(r)
%ROBUSTNESS_SETUP_PATHS Put the Stage 3 engine first on the MATLAB path.

addpath(r.root,'-begin');

addpath(r.engine_dir,'-begin');
addpath(r.forward_dir,'-begin');
addpath(r.physics_dir,'-begin');
addpath(r.forward_physics_dir,'-begin');
rehash;
end
