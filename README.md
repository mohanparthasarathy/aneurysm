# PINNs for intracranial aneurysm dynamics

MATLAB code and curated outputs accompanying the manuscript **“Modeling and simulation of biofluid--wall dynamics in intracranial
aneurysms using physics-informed neural networks”** by Mohan Parthasarathy and Padmanabhan Seshaiyer.

This repository contains the final computational workflow used for the forward model, analytical/numerical verification, forward transport experiments, local and practical identifiability, staged PINN comparisons, robustness experiments, and global sensitivity screening. The repository has been cleaned for publication: legacy stage copies, development-only utilities, cached runs, and redundant intermediate result archives have been removed. Technical comments needed to understand or reproduce the algorithms have been retained.

## Repository structure

- `aneurysm_forward_solver/` — coupled PDE--ODE solver, analytical validation, energy tests, manufactured-solution convergence, and verification-figure generation.
- `aneurysm_forward_physics/` — final reduced/full forward-physics experiments, amplitude-dependent compliance, wideband response, dimensional analysis, and parameter tables.
- `aneurysm_inverse_identifiability/` — reduced volume-domain inverse model, local SVD/Fisher analysis, Monte Carlo practical-identifiability utilities, and protocol construction. Shared forward-physics utilities are referenced from `aneurysm_forward_physics/` rather than duplicated here.
- `stage_3_pinns/` — final multi-stage inverse engine. Despite the historical folder name, `run_pinn_comparison([1 2 3])` runs Stages 1, 2, and 3 from one codebase. Final synthetic datasets are included in `stage_3_pinns/data/`.
- `aneurysm_robustness/` — noise, sparsity, and repeated-seed Stage-3 robustness workflow.
- `aneurysm_global_sensitivity/` — toolbox-free Saltelli--Sobol and Morris screening.
- `publication_figures/` — curated graphics used in the manuscript, when present in the archived source repository.
- `publication_results/` — curated CSV outputs underlying the principal manuscript tables and sensitivity/robustness summaries.
- `publication_workflow.m` — convenience dispatcher for the major experiments.

## Software requirements

The code is written in MATLAB. The inverse PINN experiments require the **Deep Learning Toolbox** (`dlnetwork`, `dlarray`, automatic differentiation, and `adamupdate`). The Sobol and Morris implementations included here are toolbox-free. No Python dependencies are required.


## Quick start

Clone or unzip the repository, start MATLAB in the repository root, and run one of the following:

```matlab
publication_workflow('verify')
publication_workflow('forward')
publication_workflow('identifiability')
publication_workflow('inverse')
publication_workflow('robustness')
publication_workflow('sensitivity')
```

The inverse, robustness, and global-sensitivity calculations can take substantial time. The dispatcher never launches an expensive calculation unless that action is requested explicitly.

## Reproducing the manuscript experiments

### 1. Forward-solver verification

```matlab
cd aneurysm_forward_solver
clear functions; clear classes; rehash
run_all_tests
make_verification_summary
```

This executes the conservative-energy test, dissipative-energy test, analytical outgoing-wave validation, and manufactured-solution convergence test. The publication summary is written to `aneurysm_forward_solver/figures/verification_summary.*`.

The manuscript reports approximately:

- maximum conservative relative energy drift: `5.489e-13`;
- dissipative final energy ratio: `1.76e-4`;
- relative midpoint energy-balance error: `1.955e-13`;
- maximum analytical wall-displacement error: `3.437e-10 m`;
- fitted manufactured-solution order: `2.0091`.

### 2. Forward transport and reduced-model experiments

```matlab
cd aneurysm_forward_physics
addpath('../aneurysm_forward_solver')
clear functions; clear classes; rehash
run_all_forward_physics
run_extended_physics
```

The module contains the baseline cycle, amplitude/compliance sweep, wideband frequency response, reduced/full PDE comparison, and dimensionless analysis. The final publication figures from the archived run are copied to `publication_figures/`.

### 3. Local and practical identifiability

```matlab
cd aneurysm_inverse_identifiability
addpath('../aneurysm_forward_physics')
clear functions; clear classes; rehash
run_inverse_identifiability_study
```

The local analysis differentiates the residual vector with respect to the logarithmic volume-domain parameters `(K_V,R_V,A_V)` using centered differences and applies an SVD directly to the resulting Jacobian. The manuscript condition numbers are 49.90 (single baseline), 17.94 (multi-amplitude), 51.37 (multi-frequency), and 17.19 (combined protocol).

The settings file enables profile likelihood by default. Disable `s.run_profile_likelihood` in `inverse_study_settings.m` if only the analyses reported in the main manuscript are needed.

### 4. Staged classical/PINN/Energy-PINN comparison

The final inverse implementation is consolidated in `stage_3_pinns/`; the older Stage-1 and Stage-2 source copies were removed because the final engine supports all three stages.

```matlab
cd stage_3_pinns
clear functions; clear classes; rehash
results = run_pinn_comparison([1 2 3]);
```

To run only one stage:

```matlab
results1 = run_pinn_comparison(1);
results2 = run_pinn_comparison(2);
results3 = run_pinn_comparison(3);
```

The included datasets correspond to the final synthetic truth multipliers `[1.30, 0.70, 1.80]` for `[k, eta, alpha]` and 0.5% volume noise. If the data files are removed, the code regenerates them from the full PDE--ODE model.

### 5. Robustness experiments

```matlab
cd aneurysm_robustness
clear functions; clear classes; rehash
run_robustness_suite('paper')
```

The paper profile evaluates the Stage-3 inverse problem under four noise levels, four observation densities, and three seeds. The robustness module expects the final inverse engine in `../stage_3_pinns`, the forward solver in `../aneurysm_forward_solver`, the identifiability utilities in `../aneurysm_inverse_identifiability`, and shared forward-physics utilities in `../aneurysm_forward_physics`.

For a short execution check, the retained smoke test can be run with:

```matlab
run_robustness_smoke_test
```

### 6. Global sensitivity screening

```matlab
cd aneurysm_global_sensitivity
clear functions; clear classes; rehash
results = run_global_sensitivity;
```

The final archived configuration uses a Saltelli base sample of 512, 200 bootstrap resamples, and 30 Morris trajectories over the multiplier ranges reported in the paper. These settings are intended as exploratory screening rather than high-precision uncertainty quantification.

## Key inverse settings

The full staged inverse run uses:

| Setting | Value |
|---|---:|
| random seed | 20260802 |
| wall network | 6 inputs, 4 hidden layers, 48 tanh units/layer |
| fluid network | 4 inputs, 4 hidden layers, 48 tanh units/layer |
| wall pretraining | 2500 iterations, learning rate `3e-4` |
| fluid pretraining | 2000 iterations, learning rate `3e-4` |
| outer inverse cycles | 8 |
| fluid refinement | 500 iterations/cycle |
| inverse learning rate | `5e-5`, then `1e-5` late in final cycle |
| affine grid | 500 time points/case × 81 spatial points |
| energy schedule | `[0 50 100 200 400 750 1500 3000]` |
| parameter relaxation | `[0.50 0.40 0.35]` for `[k eta alpha]` |
| multiplier bounds | lower `[0.20 0.05 0.02]`, upper `[5 20 50]` |
| classical discretization | 50 spatial intervals, 300 steps/cycle |
| classical budget | 75 iterations, 600 function evaluations |
| classical tolerances | `TolX = TolFun = 1e-4` |

See `stage_3_pinns/pinn_settings.m` for the complete configuration.

## Curated outputs

`publication_results/` contains lightweight CSV files corresponding to the principal numerical results. Large trained-network MAT files and intermediate optimizer checkpoints were intentionally omitted to keep the public repository manageable; they can be regenerated from the included code and synthetic datasets.

`publication_figures/` contains the figure files available in the supplied archive. The manuscript's conceptual schematic `biofluidwallmodel.png` was **not present in the uploaded code archive**, so it is not fabricated here. Add the final schematic image to `publication_figures/` before making the GitHub repository public if you want the repository to contain every manuscript graphic.

## Notes on reproducibility

1. Neural-network results can vary with MATLAB version, hardware, and low-level numerical behavior despite fixed random seeds. The manuscript reports the archived outputs in `publication_results/` and `publication_figures/`.
2. The full robustness study is substantially more expensive than the primary staged run. Resume behavior is enabled in `robustness_settings.m`.
3. The classical comparison is a deliberately budgeted Nelder--Mead benchmark, not a claim of a global optimum.
4. The synthetic inverse experiments treat pressure as known and add Gaussian noise to volume only, as described in the manuscript.
5. The effective-area and fluid-domain parameters are reduced-model quantities and should not be interpreted as direct patient-specific measurements.

## Citation

If you use this code, please cite the accompanying manuscript. A machine-readable citation template is provided in `CITATION.cff`; update the DOI once the article is published.

## Authors

- Mohan Parthasarathy — Thomas Jefferson High School for Science and Technology
- Padmanabhan Seshaiyer — Department of Mathematical Sciences, George Mason University

## License

No software license was specified in the source archive, so this cleaned repository does not add one automatically. Add the license agreed upon by the authors before public release if you intend to permit reuse beyond the rights granted by the publication and repository host.
