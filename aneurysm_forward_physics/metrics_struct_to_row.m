function row = metrics_struct_to_row(base, metrics)
%METRICS_STRUCT_TO_ROW Merge identifying fields and metric fields.
row = base;
names = fieldnames(metrics);
for j = 1:numel(names)
    row.(names{j}) = metrics.(names{j});
end
end
