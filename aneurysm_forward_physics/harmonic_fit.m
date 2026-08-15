function fit = harmonic_fit(t, y, omega, max_harmonic)
%HARMONIC_FIT Simultaneous Fourier least-squares fit at known frequency.
%
% fit = harmonic_fit(t,y,omega,max_harmonic) fits
%
%   y(t) = c + sum_{n=1}^N [a_n sin(n*omega*t)+b_n cos(n*omega*t)]
%
% and reports the conventional total harmonic distortion
%
%   THD = sqrt(A_2^2+...+A_N^2)/A_1,
%
% together with individual harmonic ratios such as A_3/A_1.  Fitting all
% harmonics simultaneously avoids attributing resolved higher harmonics to
% the residual of a fundamental-only fit.

if nargin < 4 || isempty(max_harmonic)
    max_harmonic = 9;
end

validateattributes(max_harmonic,{'numeric'}, ...
    {'scalar','integer','positive'},mfilename,'max_harmonic');

t = t(:);
y = y(:);
if numel(t) ~= numel(y)
    error('t and y must contain the same number of samples.');
end
if numel(t) < 2*max_harmonic+1
    error('Not enough samples to fit %d harmonics.',max_harmonic);
end

X = ones(numel(t),1);
for n = 1:max_harmonic
    X = [X, sin(n*omega*t), cos(n*omega*t)]; %#ok<AGROW>
end
beta = X\y;

A = zeros(max_harmonic,1);
phase = zeros(max_harmonic,1);
for n = 1:max_harmonic
    a = beta(2*n);
    b = beta(2*n+1);
    A(n) = hypot(a,b);
    phase(n) = atan2(b,a);
end

fit.mean = beta(1);
fit.amplitude = A(1);                 % backward-compatible fundamental
fit.phase_rad = phase(1);
fit.phase_deg = phase(1)*180/pi;
fit.harmonic_amplitudes = A;
fit.harmonic_phases_rad = phase;
fit.harmonic_phases_deg = phase*180/pi;
fit.fitted = X*beta;
fit.rms_residual = sqrt(mean((y-fit.fitted).^2));
fit.residual_to_fundamental = fit.rms_residual/max(A(1),eps);

fit.THD = sqrt(sum(A(2:end).^2))/max(A(1),eps);
fit.second_to_fundamental = value_or_zero(A,2)/max(A(1),eps);
fit.third_to_fundamental = value_or_zero(A,3)/max(A(1),eps);
fit.fifth_to_fundamental = value_or_zero(A,5)/max(A(1),eps);

% Retained only for compatibility with older scripts. This now means THD,
% not the residual of a fundamental-only fit.
fit.harmonic_distortion = fit.THD;
fit.max_harmonic = max_harmonic;
end

function v = value_or_zero(A,n)
if numel(A) >= n
    v = A(n);
else
    v = 0;
end
end
