%% initialization
clear;
clc;

%% load data
data_file = 'bhv';
data_path = fullfile(pwd,[data_file,'.mat']);
load(data_path);

%%
selection_flags = ...
    bhv_table.cohort == 'vmu' & ...
    ...bhv_table.variant.interface == 'keyboard' & ...
    ~ismember(bhv_table.subject,{'04pvn','08pvn','margarida2','paco'}) & ...
    true(height(bhv_table),1);
bhv_table = bhv_table(selection_flags,:);
n_trials = size(bhv_table,1);

%% subject selection
subjects = cellstr(unique(bhv_table.subject));
n_subjects = numel(subjects);

%% 
stimuli = bhv_table.stimulus.duration;
choices = bhv_table.choice.long;
itis = bhv_table.iti;

%%
n_cats = 3;

valence = discretize(bhv_table.stimulus.valence,n_cats);
curr_valence = valence == unique(valence(~isnan(valence)))';

arousal = discretize(bhv_table.stimulus.arousal,n_cats);
curr_arousal = arousal == unique(arousal(~isnan(arousal)))';

intensity = discretize(bhv_table.stimulus.intensity,n_cats);
curr_intensity = intensity == unique(intensity(~isnan(intensity)))';

category = bhv_table.stimulus.category;
curr_category = category == unique(category)';

%% stimulus settings
meta.stimulus.set = unique(stimuli(~isnan(stimuli)))';
meta.stimulus.labels = num2cell(meta.stimulus.set);
meta.stimulus.boundary = mean(meta.stimulus.set);
meta.stimulus.n = numel(meta.stimulus.set);

%% difficulty settings
meta.difficulty.set = unique(round(...
    abs(meta.stimulus.set - meta.stimulus.boundary),2));
meta.difficulty.labels = num2cell(meta.difficulty.set);
meta.difficulty.n = numel(meta.difficulty.set);

%% axes settings

% default properties
axesopt.default.plotboxaspectratio = [1,1,1];
axesopt.default.ticklength = [1,1] * .025;
axesopt.default.linewidth = 2;
axesopt.default.fontsize = 13;
axesopt.default.nextplot = 'add';
axesopt.default.tickdir = 'out';
axesopt.default.box = 'off';
axesopt.default.layer = 'top';

%% design matrix

% data preparation
transition_flags = bhv_table.subject ~= [bhv_table.subject(end);bhv_table.subject(1:end-1)];
curr_premature = bhv_table.choice.premature;
prev_premature = [0;curr_premature(1:end-1)];

curr_stimcat = stimuli >= meta.stimulus.boundary == [0,1];
prev_stimcat_1 = [zeros(1,size(curr_stimcat,2));curr_stimcat(1:end-1,:)];
prev_stimcat_1(transition_flags,:) = 0;

difficulties = round(abs(stimuli - meta.stimulus.boundary),2);
prev_difficulties_1 = [0;difficulties(1:end-1)];
prev_difficulties_1(transition_flags) = 0;

curr_stimuli = stimuli == meta.stimulus.set;
prev_stimuli_1 = [zeros(1,size(curr_stimuli,2));curr_stimuli(1:end-1,:)];
prev_stimuli_1(transition_flags,:) = 0;

curr_difficulty = difficulties == meta.difficulty.set;
prev_difficulty_1 = [zeros(1,meta.difficulty.n);curr_difficulty(1:end-1,:)];
prev_difficulty_1(transition_flags,:) = 0;

choicelong =  bhv_table.choice.long;
prev_choicelong_1 = [false;choicelong(1:end-1)];
prev_choicelong_1(transition_flags) = 0;

curr_choice = bhv_table.choice.long * 2 - 1;
curr_choice(curr_premature) = 0;
prev_choice_1 = [0;curr_choice(1:end-1)];
prev_choice_1(transition_flags) = 0;

prev_stimchoice_1 = prev_stimuli_1 .* prev_choice_1;

difficulty_correct = curr_difficulty & bhv_table.choice.correct;
difficulty_error = curr_difficulty & ~bhv_table.choice.correct;
curr_stim_correct = curr_stimuli & bhv_table.choice.correct;
curr_stim_error = curr_stimuli & ~bhv_table.choice.correct;

prev_stim_choicelong_1 = prev_stimuli_1 & prev_choicelong_1;
prev_stim_choiceshort_1 = prev_stimuli_1 & ~prev_choicelong_1;

prev_stimlong_choicelong_1 = prev_stimcat_1 & prev_choicelong_1;
prev_stimlong_choiceshort_1 = prev_stimcat_1 & ~prev_choicelong_1;

iti_set = unique(itis);
curr_iti = itis == iti_set';
prev_iti = [zeros(1,numel(iti_set));curr_iti(1:end-1,:)];

% construct design matrix
design_table = table(...
    ...choice_hist(:,1:end-1),...
    curr_valence,...
    curr_arousal,...
    curr_intensity,...
    curr_category,...
    prev_stim_choiceshort_1(:,1:end-2),...
    prev_stim_choicelong_1(:,3:end),...
    ...prev_stimuli_1,...
    ...prev_stimcat_1,...
    ...prev_stimlong_choiceshort_1,...
    ...prev_stimlong_choicelong_1,...
    ...prev_iti,...
    curr_stimuli...
    ...curr_temperature...
    );
design = double(design_table.Variables);
coeff_names = ['intercept',design_table.Properties.VariableNames];
n_coeffs = size(design,2) + 1;

%% trial selection
valid_flags = ...
    bhv_table.choice.delay < quantile(bhv_table.choice.delay,.99) & ...
    ~curr_premature & ...
    ~prev_premature & ...
    ~transition_flags;

%% response variable

% construct response variable
response = bhv_table.choice.long;

%% cross-validation settings
cv_k = 10;

%% GLM

% distribution selection
distro = 'binomial';

% preallocation
lambdas = nan(n_subjects,1);
yhat = nan(n_trials,1);
r2 = nan(n_subjects,1);
pvals = nan(n_subjects,1);
coeffs = nan(n_subjects,n_coeffs);

% iterate through subjects
for ss = 1 : n_subjects
    subject = subjects{ss};
    progressreport(ss,n_subjects,...
        sprintf('fitting %s (%i/%i)',subject,ss,n_subjects));

    subject_flags = bhv_table.subject == subject;
    trial_flags = ...
        valid_flags & ...
        subject_flags;
    trial_idcs = find(trial_flags);
    n_trials = numel(trial_idcs);
    
    % fit GLM
    X = design(trial_flags,:);
    y = response(trial_flags);
    [B,info] = lassoglm(X,y,distro,...
        'standardize',true,...
        'lambda',1e-1,...
        'alpha',1e-2,...
        'CV',cv_k);
    [~,null] = lassoglm(X,y(randperm(n_trials)),distro,...
        'standardize',true,...
        'lambda',1e-1,...
        'alpha',1e-2,...
        'CV',cv_k);
    
    % extract coefficients
    lambdas(ss) = info.Lambda(info.IndexMinDeviance);
    coeffs(ss,:) = [...
        info.Intercept(info.IndexMinDeviance);...
        B(:,info.IndexMinDeviance)...
        ];
    
    % store p-value
    pvals(ss) = 1 - chi2cdf(...
        info.Deviance(info.IndexMinDeviance),...
        info.DF(info.IndexMinDeviance));

    % model predictions
    yhat(trial_flags) = 1 ./ (1 + exp(-coeffs(ss,:) * ...
        [ones(sum(trial_flags),1),design(trial_flags,:)]'));
    
    % compute r-squared
    ss_tot = nansum((response(trial_flags) - nanmean(response(trial_flags))) .^ 2);
    ss_res = nansum((response(trial_flags) - yhat(trial_flags)) .^ 2);
    r2(ss) = 1 - ss_res / ss_tot;
    
    % compute pseudo-r-squared
    r2(ss) = 1 - info.Deviance / null.Deviance;
end

%% normalize by intercept
norm_coeffs = coeffs; % ./ coeffs(:,1);

%% compute r-squared
ss_tot = nansum((response - nanmean(response)) .^ 2);
ss_res = nansum((response - yhat) .^ 2);
R2 = 1 - ss_res / ss_tot
R2 = nanmean(r2)

%% figure initialization
xxticklabels = [...
    '\beta_0',...
    arrayfun(@(x)sprintf('V%s_t',x),...
        ['L','M','H'],'uniformoutput',false),...
    arrayfun(@(x)sprintf('A%s_t',x),...
        ['L','M','H'],'uniformoutput',false),...
    arrayfun(@(x)sprintf('I%s_t',x),...
        ['L','M','H'],'uniformoutput',false),...
    unique(category)',...
    arrayfun(@(x)sprintf('S_{t-1}\\times%.2f_{t-1}',x),...
        meta.stimulus.set(1:end-2),'uniformoutput',false),...
    arrayfun(@(x)sprintf('L_{t-1}\\times%.2f_{t-1}',x),...
        meta.stimulus.set(1+2:end),'uniformoutput',false),...
    arrayfun(@(x)sprintf('%.2f_t',x),...
        meta.stimulus.set,'uniformoutput',false),...
    ];
figure('name',mfilename,...
    'numbertitle','off',...
    'inverthardcopy','off',...
    'windowstyle','docked',...
    'color','w');
set(gca,axesopt.default,...
    'xlim',[1,n_coeffs]+[-1,1],...
    'xtick',1:n_coeffs,...
    'xticklabel',xxticklabels,...
    'xticklabelrotation',45,...
    'ylim',[0,1]+[-1,1]*.05,...
    'ytick',0,...[0,1],...
    'ticklabelinterpreter','tex',...
    'plotboxaspectratio',[3,1,1],...
    'clipping','off',...
    'ycolor','k');
title(sprintf('L_{t}~%s(\\phi(\\betaX))',distro));
ylabel('$\beta_i$',...
    'interpreter','latex');

%% plot fit coefficients
cla;
offset = 2;

% plot coefficient relationships
coeff_offset = 0;
for jj = 1 : numel(coeff_names)
    coeff_name = coeff_names{jj};
    if strcmpi(coeff_name,'intercept')
        coeff_size = 1;
    else
        coeff_size = size(design_table.(coeff_name),2);
    end
    coeff_idcs = (1 : coeff_size) + coeff_offset;
    coeff_offset = coeff_offset + coeff_size;
    plot(coeff_idcs,nanmean(norm_coeffs(:,coeff_idcs)),...
        'color','k',...
        'marker','none',...
        'hittest','off',...
        'linewidth',2);
    
    % iterate through subjects
    offsets = ((1:n_subjects) - n_subjects/2) * .01;
    for ss = 1 : n_subjects
        plot(coeff_idcs+offsets(ss),norm_coeffs(ss,coeff_idcs),...
            'color','k',...
            'marker','none',...
            'hittest','off',...
            'linewidth',.1);
    end
end

% iterate through coefficients
for bb = 1 : n_coeffs
    noise = randn(n_subjects,1) * .05;
    grapeplot(bb+offsets,norm_coeffs(:,bb),...
        'marker','o',...
        'markersize',7.5,...
        'markeredgecolor',[0,0,0],...
        'markerfacecolor',[1,1,1],...
        'linewidth',1,...
        'labels',cellstr(subjects));
    [~,pval] = ttest(norm_coeffs(:,bb));
    if pval < .01
        clr = 'y';
    elseif pval < .1
        clr = 'r';
    else
        clr = 'k';
    end
    plot(bb,nanmean(norm_coeffs(:,bb)),...
        'marker','o',...
        'markersize',8.5,...
        'markeredgecolor','k',...
        'markerfacecolor','k',...
        'linewidth',1.5);
end

% update axes
axis tight;
xlim([1,n_coeffs]+[-1,1]);
ylim(ylim+[-1,1]*.05*range(ylim));

% zero line
p = plot(xlim,[0,0],'--k',...
    'hittest','off');
uistack(p,'bottom');

% iterate through coefficients
for bb = 1 : n_coeffs
    p = plot([1,1]*bb,ylim,':k',...
        'hittest','off');
    uistack(p,'bottom');
end

% iterate through subjects
subject_idx = 1;
for ss = 1 : n_subjects
    subject = subjects{ss};
    if isnan(r2(ss))
        continue;
    end
    xpos = .033 + .075 * (3 - mod(subject_idx,4));
    ypos = 1 - .033 * (subject_idx + mod(subject_idx,4)) / 4;
    text(xpos,ypos,sprintf('pseudo R^{2}_{%s}=%.2f',subject,r2(ss)),...
        'fontsize',8,...
        'horizontalalignment','left',...
        'verticalalignment','bottom',...
        'units','normalized');
    subject_idx = subject_idx + 1;
end