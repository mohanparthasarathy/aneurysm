function summary = run_structural_identifiability(p,s)
%RUN_STRUCTURAL_IDENTIFIABILITY Compare information across data protocols.

free_mask = [true true true];
rows = {};
details = struct();

fprintf('\n=== Local identifiability analysis ===\n');
for i = 1:numel(s.protocols)
    protocol = s.protocols(i);
    data = build_inverse_protocol(protocol,p,s,0,0,s.random_seed+i);
    a = local_identifiability_analysis(data,free_mask,s);
    details.(protocol.name) = a;

    row.protocol = protocol.name;
    row.n_experiments = numel(protocol.pressure_mmHg);
    row.rank = a.rank;
    row.condition_number = a.condition_number;
    row.sigma_max = a.singular_values(1);
    row.sigma_min = a.singular_values(end);
    row.corr_K_R = a.correlation(1,2);
    row.corr_K_A = a.correlation(1,3);
    row.corr_R_A = a.correlation(2,3);
    rows{end+1} = row; %#ok<AGROW>

    fprintf('  %-18s rank=%d, cond=%.3e, sigma_min=%.3e\n', ...
        protocol.name,a.rank,a.condition_number,a.singular_values(end));
end

summary = struct2table(vertcat(rows{:}));
writetable(summary,fullfile(s.output_dir, ...
    'local_identifiability_summary.csv'));
save(fullfile(s.output_dir,'local_identifiability_details.mat'), ...
    'details','summary');

if s.make_figures
    figure('Color','w');
    hold on;
    for i = 1:numel(s.protocols)
        a = details.(s.protocols(i).name);
        semilogy(1:numel(a.singular_values),a.singular_values,'o-', ...
            'LineWidth',1.4);
    end
    xlabel('singular-value index');
    ylabel('singular value of normalized sensitivity matrix');
    legend({s.protocols.name},'Location','best','Interpreter','none');
    title('Local identifiability by measurement protocol');
    grid on;
    saveas(gcf,fullfile(s.output_dir,'identifiability_singular_values.png'));
end
end
