function T = write_parameter_table(filename)
%WRITE_PARAMETER_TABLE Export the baseline parameter definitions and values.

if nargin < 1
    filename = 'physiological_parameter_table.csv';
end
p = physiological_parameters();

symbol = {'r';'h';'V_ref';'A_eff';'E';'nu';'rho_w';'m_w'; ...
    'k';'eta';'alpha';'rho_f';'c_f';'A_f';'L';'P_0';'f_0'};

definition = {
    'Radius of the equivalent spherical aneurysm sac';
    'Uniform thickness of the load-bearing aneurysm wall shell';
    'Reference sac volume at the linearization pressure';
    'Modal area dV/dw converting radial modal motion to volume change';
    'Small-strain tangent Young modulus of the aneurysm wall';
    'Poisson ratio of nearly incompressible aneurysm tissue';
    'Mass density assigned to the aneurysm wall tissue';
    'Physical mass of the equivalent spherical aneurysm wall shell';
    'Generalized radial spring stiffness derived from thin-shell pressure expansion';
    'Kelvin-Voigt generalized wall dashpot coefficient';
    'Cubic generalized stiffness controlling strain stiffening';
    'Density of the surrounding cerebrospinal fluid';
    'Effective cardiac CSF velocity-wave speed in the compliant craniospinal pathway';
    'Effective CSF area communicating with the reduced outgoing-wave domain';
    'Length of the truncated one-dimensional outgoing-wave domain';
    'Amplitude of the sinusoidal transmural-pressure perturbation';
    'Fundamental cardiac forcing frequency'
    };

value = [p.geometry.radius; p.geometry.wall_thickness; p.V_ref; ...
    p.A_eff; p.material.E; p.geometry.nu; p.geometry.rho_wall; ...
    p.m_w; p.k; p.eta; p.alpha; p.rho_f; p.c_f; p.A_f; p.L; ...
    p.pressure.amplitude; p.pressure.omega/(2*pi)];

unit = {'m';'m';'m^3';'m^2';'Pa';'1';'kg/m^3';'kg';'N/m'; ...
    'N s/m';'N/m^3';'kg/m^3';'m/s';'m^2';'m';'Pa';'Hz'};

justification = {
    'Representative 8-mm-diameter unruptured intracranial aneurysm';
    'Representative uniform-wall modeling value; true walls are heterogeneous';
    'Computed as 4*pi*r^3/3';
    'Computed as 4*pi*r^2 for the spherical radial mode';
    'Literature midpoint used in prior intracranial-aneurysm FSI modeling';
    'Near-incompressible soft-tissue assumption';
    'Soft-tissue density close to water';
    'Computed as rho_w*A_eff*h';
    'Computed as 8*pi*E*h/(1-nu) from a thin spherical shell';
    'Calibrated to wall loss tangent omega*eta/k=0.05 at 1.2 Hz; swept broadly';
    'Calibrated for 25 percent tangent-stiffness increase at w=20 micrometers; swept broadly';
    'CSF is water-like in density';
    'Human MRI systolic CSF velocity-wave-speed measurement';
    'Reduced local communicating area; uncertain and should be sensitivity-tested';
    'Numerical truncation length for the reduced outgoing-wave domain';
    'Half of a representative 40-mmHg arterial pulse pressure';
    '72 beats/min representative resting cardiac frequency'
    };

T = table(symbol,definition,value,unit,justification);
writetable(T,filename);
end
