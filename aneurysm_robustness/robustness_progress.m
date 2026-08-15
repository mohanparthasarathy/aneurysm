function progress = robustness_progress(profile)
%ROBUSTNESS_PROGRESS Show completed, failed, and pending case counts.

if nargin < 1, profile = 'paper'; end
r = robustness_settings(profile);
cases = robustness_case_table(r);
state = strings(height(cases),1);

for i = 1:height(cases)
    folder = fullfile(r.case_dir,cases.case_id(i));
    statusFile = fullfile(folder,'status.mat');
    if ~isfile(statusFile)
        state(i) = "pending";
    else
        S = load(statusFile,'status');
        state(i) = string(S.status);
    end
end

progress = cases;
progress.status = state;
disp(groupsummary(progress,{'stage_id','status'}));
fprintf('Completed: %d / %d\n',sum(state=="success"),height(cases));
fprintf('Failed:    %d\n',sum(state=="failed"));
fprintf('Pending:   %d\n',sum(state=="pending"));
end
