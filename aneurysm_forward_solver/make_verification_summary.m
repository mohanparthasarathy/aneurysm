function make_verification_summary()
%MAKE_VERIFICATION_SUMMARY
% Build the four-panel verification figure used in the manuscript.
%
% Panels:
%   (a) Conservative energy preservation
%   (b) Dissipative energy decay
%   (c) Analytical vs numerical linear solution
%   (d) Manufactured-solution convergence
%
% Output:
%   figures/verification_summary.pdf
%   figures/verification_summary.png

close all
clc

root = fileparts(mfilename('fullpath'));
figDir = fullfile(root,'figures');

if ~exist(figDir,'dir')
    mkdir(figDir);
end

%% ============================================================
% 1. ENERGY TESTS
% =============================================================

fprintf('\nRunning energy verification...\n');

before = findall(groot,'Type','figure');
A = run_energy_tests;
after = findall(groot,'Type','figure');

figEnergy = setdiff(after,before);

if numel(figEnergy) ~= 2
    error(['Expected run_energy_tests to create exactly two figures, ' ...
           'but found %d.'],numel(figEnergy));
end

% Sort by figure number so ordering is deterministic.
[~,idx] = sort([figEnergy.Number]);
figEnergy = figEnergy(idx);

% Determine which plot is conservative and which is dissipative.
% Conservative energy should have essentially no vertical range;
% dissipative energy should show a large decay.
rangeEnergy = nan(1,2);

for i = 1:2
    ax = findobj(figEnergy(i),'Type','axes');
    ax = ax(1);

    ln = findobj(ax,'Type','line');

    yy = [];
    for j = 1:numel(ln)
        yj = ln(j).YData;
        yy = [yy; yj(:)]; %#ok<AGROW>
    end

    rangeEnergy(i) = max(yy)-min(yy);
end

[~,iConservative] = min(rangeEnergy);
[~,iDissipative]  = max(rangeEnergy);

figConservative = figEnergy(iConservative);
figDissipative  = figEnergy(iDissipative);


%% ============================================================
% 2. ANALYTICAL VALIDATION
% =============================================================

fprintf('\nRunning analytical validation...\n');

before = findall(groot,'Type','figure');
B = run_analytic_validation;
after = findall(groot,'Type','figure');

figAnalytic = setdiff(after,before);

if isempty(figAnalytic)
    error('run_analytic_validation did not create any figures.');
end

% Sort figures by figure number for deterministic behavior.
[~,idx] = sort([figAnalytic.Number]);
figAnalytic = figAnalytic(idx);

% If the analytical validation creates multiple figures, identify the
% main solution-comparison figure as the one containing the largest
% number of plotted data points. The other figure is typically the
% pointwise-error plot.
nPoints = zeros(size(figAnalytic));

for i = 1:numel(figAnalytic)
    axs = findobj(figAnalytic(i),'Type','axes');

    for ia = 1:numel(axs)
        ln = findobj(axs(ia),'Type','line');

        for j = 1:numel(ln)
            nPoints(i) = nPoints(i) + numel(ln(j).YData);
        end
    end
end

[~,iMain] = max(nPoints);
figAnalyticMain = figAnalytic(iMain);

fprintf('Analytical validation created %d figure(s); using figure %d for panel (c).\n', ...
    numel(figAnalytic),figAnalyticMain.Number);


%% ============================================================
% 3. MANUFACTURED-SOLUTION CONVERGENCE
% =============================================================

fprintf('\nRunning manufactured-solution convergence...\n');

before = findall(groot,'Type','figure');
C = run_manufactured_convergence;
after = findall(groot,'Type','figure');

figManufactured = setdiff(after,before);

if numel(figManufactured) ~= 1
    error(['Expected run_manufactured_convergence to create exactly one ' ...
           'figure, but found %d.'],numel(figManufactured));
end


%% ============================================================
% 4. BUILD PUBLICATION FIGURE
% =============================================================

fprintf('\nBuilding four-panel publication figure...\n');

figOut = figure( ...
    'Units','inches', ...
    'Position',[1 1 12 8], ...
    'Color','w');

tl = tiledlayout(figOut,2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');


% ------------------------------------------------------------
% Panel (a): conservative energy
% ------------------------------------------------------------
axA = nexttile(tl,1);

srcA = primary_axes(figConservative);
copy_axes(srcA,axA);

title(axA,'(a) Conservative energy','FontWeight','bold');

xlabel(axA,'Time (s)');
ylabel(axA,'Normalized energy, $E(t)/E(0)$', ...
    'Interpreter','latex');

grid(axA,'on');
box(axA,'on');


% ------------------------------------------------------------
% Panel (b): dissipative energy
% ------------------------------------------------------------
axB = nexttile(tl,2);

srcB = primary_axes(figDissipative);
copy_axes(srcB,axB);

title(axB,'(b) Dissipative energy','FontWeight','bold');

xlabel(axB,'Time (s)');
ylabel(axB,'Normalized energy, $E(t)/E(0)$', ...
    'Interpreter','latex');

grid(axB,'on');
box(axB,'on');


% ------------------------------------------------------------
% Panel (c): analytical validation
% ------------------------------------------------------------
axC = nexttile(tl,3);

srcC = primary_axes(figAnalyticMain);
copy_axes(srcC,axC);

title(axC,'(c) Analytical validation','FontWeight','bold');

% Keep labels produced by the original validation routine if present.
if strlength(string(axC.XLabel.String)) == 0
    xlabel(axC,'Time (s)');
end

if strlength(string(axC.YLabel.String)) == 0
    ylabel(axC,'Wall displacement');
end

grid(axC,'on');
box(axC,'on');

% Reconstruct legend from copied DisplayName fields, if available.
make_legend_if_possible(axC);


% ------------------------------------------------------------
% Panel (d): manufactured convergence
% ------------------------------------------------------------
axD = nexttile(tl,4);

srcD = primary_axes(figManufactured);
copy_axes(srcD,axD);

title(axD,'(d) Manufactured-solution convergence', ...
    'FontWeight','bold');

grid(axD,'on');
box(axD,'on');

make_legend_if_possible(axD);


%% ============================================================
% 5. COMMON FORMATTING
% =============================================================

axs = [axA axB axC axD];

for ax = axs
    ax.FontSize = 10;
    ax.LineWidth = 0.8;

    % Make plotted curves publication-readable.
    lines = findobj(ax,'Type','line');
    for j = 1:numel(lines)
        if lines(j).LineWidth < 1.3
            lines(j).LineWidth = 1.3;
        end
    end
end


%% ============================================================
% 6. EXPORT
% =============================================================

pdfFile = fullfile(figDir,'verification_summary.pdf');
pngFile = fullfile(figDir,'verification_summary.png');

exportgraphics(figOut,pdfFile, ...
    'ContentType','vector');

exportgraphics(figOut,pngFile, ...
    'Resolution',400);

fprintf('\nVerification figure written to:\n');
fprintf('  %s\n',pdfFile);
fprintf('  %s\n',pngFile);

fprintf('\nVerification diagnostics:\n');
% fprintf('  Conservative max relative drift: %.3e\n', ...
%     max(abs(A.conservative.energy/A.conservative.energy(1)-1)));

fprintf('  Analytical max displacement error: %.3e m\n', ...
    B.max_error);

fprintf('  Analytical relative max error: %.3e\n', ...
    B.relative_error);

fprintf('  Manufactured fitted order should be approximately 2.01.\n');

end


%% ========================================================================
% LOCAL FUNCTIONS
% ========================================================================

function ax = primary_axes(fig)
% Return the principal plotting axes from a source figure.

axs = findobj(fig,'Type','axes');

if isempty(axs)
    error('Source figure contains no axes.');
end

% Exclude legend/colorbar-like axes if MATLAB represents them as axes.
keep = true(size(axs));

for i = 1:numel(axs)
    tag = string(axs(i).Tag);

    if contains(lower(tag),'legend') || ...
       contains(lower(tag),'colorbar')
        keep(i) = false;
    end
end

axs = axs(keep);

if isempty(axs)
    error('Could not identify plotting axes.');
end

% Choose the axes containing the most graphical children.
nChildren = arrayfun(@(a)numel(a.Children),axs);
[~,idx] = max(nChildren);

ax = axs(idx);

end


function copy_axes(src,dst)
% Copy plotted content and basic formatting from one axes to another.

hold(dst,'on');

children = flipud(src.Children);

for i = 1:numel(children)
    try
        copyobj(children(i),dst);
    catch
        % Ignore unsupported annotations.
    end
end

hold(dst,'off');

dst.XScale = src.XScale;
dst.YScale = src.YScale;

dst.XLim = src.XLim;
dst.YLim = src.YLim;

if ~isempty(src.XTick)
    dst.XTick = src.XTick;
end

if ~isempty(src.YTick)
    dst.YTick = src.YTick;
end

% Preserve labels when useful.
try
    dst.XLabel.String = src.XLabel.String;
    dst.XLabel.Interpreter = src.XLabel.Interpreter;
catch
end

try
    dst.YLabel.String = src.YLabel.String;
    dst.YLabel.Interpreter = src.YLabel.Interpreter;
catch
end

end


function make_legend_if_possible(ax)
% Create legend only if copied lines carry meaningful DisplayName values.

objects = findobj(ax,'-property','DisplayName');

names = strings(0);
handles = gobjects(0);

for i = 1:numel(objects)
    name = string(objects(i).DisplayName);

    if strlength(name) > 0 && ...
       ~startsWith(name,"_")
        names(end+1) = name; %#ok<AGROW>
        handles(end+1) = objects(i); %#ok<AGROW>
    end
end

if ~isempty(handles)
    legend(ax,flip(handles),flip(names), ...
        'Location','best', ...
        'Box','off');
end

end