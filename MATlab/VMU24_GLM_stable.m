%% initialization
clear;
clc;

%% load data
data_file = 'bhv';
data_path = fullfile(pwd,[data_file,'.mat']);
load(data_path);
n_trials = size(bhv_table,1);

%% subject selection
subjects = cellstr(unique(bhv_table.subject));
n_subjects = numel(subjects);

%% 
stimuli = bhv_table.stimulus.duration;
choices = bhv_table.choice.long;

% %% design matrix
% 
% % number of trials to look back
% k = 1;
% 
% %
% x_stimulus = [nan; stimuli(1:end-1)];
% x_choice = [nan; choices(1:end-1)];
% 
% %
% padded_stimulus = [zeros(k - 1,1); x_stimulus];
% padded_choice = [zeros(k - 1,1); x_choice];
% 
% %
% X_stimulus = hankel(padded_stimulus(1 : end - k + 1), x_stimulus(end - k + 1 : end));
% X_choice = hankel(padded_choice(1 : end - k + 1), x_choice(end - k + 1 : end));
% 
% %
% X_stimulus = stimuli == i_set';
% X_choice = choices == t_set';
% 
% % interactions
% X_interaction = choices .* stimuli == unique(choices(valid_flags) .* stimuli(valid_flags))';
% 
% % trial history
% X_i1_p = prev_i1 == i_set';
% X_i2_p = prev_i2 == i_set';
% X_t1_p = prev_t1 == t_set';
% X_t2_p = prev_t2 == t_set';
% 
% X_c_p = [nan; choice(1:end-1)];
% X_c_p2 = [nan; X_c_p(1:end-1)];
% 
% X_t1t2_p = [nan;t1t2(1:end-1)] == t1t2_set';
% X_i1i2_p = [nan;i1i2(1:end-1)] == i1i2_set';
% 
% X_i1_p2 = [nan;prev_i1(1:end-1)] == i_set';
% X_i2_p2 = [nan;prev_i2(1:end-1)] == i_set';
% X_t1_p2 = [nan;prev_t1(1:end-1)] == t_set';
% X_t2_p2 = [nan;prev_t2(1:end-1)] == t_set';
% 
% trial_kernel = expkernel('mu',5,'binwidth',1);
% i_hist = conv(-prev_i1+prev_i2,trial_kernel.pdf,'same');
% t_hist = conv(-prev_t1+prev_t2,trial_kernel.pdf,'same');
% 
% %
% design_table = table(...X_i1,X_i2,X_t1,X_t2,X_c,X_r,...
%     X_stimulus,X_i1_p,...
%     X_i2,X_i2_p,...
%     X_choice,X_t1_p,X_t1_p2,...
%     X_t2,X_t2_p,X_t2_p2,...
%     X_i1i2,...
%     X_t1t2...,X_t1i1_t,X_t2i2_t...
%     ...X_i1_p,X_i2_p,X_t1_p,X_t2_p,...
%     ...i_hist,t_hist,...
%     ...X_t1t2_p,X_i1i2_p,...
%     ...X_i1_p2,X_i2_p2,X_t1_p2,X_t2_p2,...
%     ...X_c,..._p,X_c_p2,...
%     ...X_r...
%     );
% design = double(design_table.Variables);
% coeff_names = ['intercept',design_table.Properties.VariableNames];
% n_coeffs = size(design,2) + 1;
% 
% %% feature normalization
% 
% % z-scoring
% mus = nanmean(design,1);
% sigs = nanstd(design,0,1);
% zdesign = (design - mus) ./ sigs;
% 
% %% response variable
% 
% % construct response variable
% response = choice;
% 
% %% trial selection
% trial_flags = ...
%     ...i1 == i_set(i1_mode_idx) & ...
%     ...subject_ids == 3 & ...
%     valid_flags;
% design(~trial_flags,:) = nan;
% zdesign(~trial_flags,:) = nan;
% response(~trial_flags) = nan;
% n_trials = size(design,1);
% 
% %% GLM
% 
% % distribution selection
% distro = 'binomial';
% 
% % fit GLM
% [B,mdlinfo] = lassoglm(...
%     zdesign,response,distro,...
%     'standardize',true,...
%     'lambda',1e-1,...
%     'alpha',1e-2,...
%     'CV',10);
% [~,nullinfo] = lassoglm(...
%     zdesign*0,response,distro,...
%     'standardize',true,...
%     'lambda',1e-1,...
%     'alpha',1e-2,...
%     'CV',10);
% 
% % extract coefficients~
% coeffs = [...
%     mdlinfo.Intercept(mdlinfo.IndexMinDeviance);...
%     B(:,mdlinfo.IndexMinDeviance)...
%     ];
% 
% % no regularization
% % mdl = fitglm(zdesign,response,...
% %     'distribution',distro);
% % coeffs = mdl.Coefficients.Estimate;
% 
% % compute pseudo r-squared
% pseudo_r2 = (nullinfo.Deviance - mdlinfo.Deviance) / nullinfo.Deviance;
% pseudo_stimuli = [ones(n_trials,1),zdesign] * coeffs;
% 
% %% figure initialization
% xxticklabels = [...
%     '\beta_0',...
%     arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{2}(3:end)),x),i_set','uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{3}(3:end)),x),i_set','uniformoutput',false),...
%     arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{4}(3:end)),x),i_set','uniformoutput',false),...
%     arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{6}(3:end)),x),t_set','uniformoutput',false),...
%     arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{9}(3:end)),x),t_set','uniformoutput',false),...
%     arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{12}(3:end)),x),i1i2_set','uniformoutput',false),...
%     arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{13}(3:end)),x),t1t2_set','uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s_{t-%i}',upper(coeff_names{end-1}(3:end)),x),k:-1:0+1,'uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s_{t-%i}',upper(coeff_names{end}(3:end)),x),k:-1:0+1,'uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s_{t-%i}',upper(coeff_names{2}(3:end)),x),k-1:-1:0,'uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s_{t-%i}',upper(coeff_names{3}(3:end)),x),k-1:-1:0,'uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s_{t-%i}',upper(coeff_names{4}(3:end)),x),k-1:-1:0,'uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s_{t-%i}',upper(coeff_names{5}(3:end)),x),k-1:-1:0,'uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s_{t-%i}',upper(coeff_names{6}(3:end)),x),k:-1:0+1,'uniformoutput',false),...
%     ...arrayfun(@(x)sprintf('%s_{t-%i}',upper(coeff_names{7}(3:end)),x),k:-1:0+1,'uniformoutput',false),...
%     ];
% fig = figure('name',mfilename,...
%     'windowstate','maximized',...
%     'numbertitle','off',...
%     'inverthardcopy','off',...
%     'color','w');
% set(gca,axesopt.default,...
%     'xlim',[1,n_coeffs]+[-1,1],...
%     'xtick',1:n_coeffs,...
%     'xticklabel',xxticklabels,...
%     'xticklabelrotation',45,...
%     'ylim',[0,1]+[-1,1]*.05,...
%     'ytick',0,...[0,1],...
%     'ticklabelinterpreter','tex',...
%     'plotboxaspectratio',[3,1,1],...
%     'clipping','off',...
%     'ycolor','k');
% title(sprintf('%s>%s~Binomial(\\phi(\\betaX))',s2_lbl,s1_lbl));
% xlabel('X');
% ylabel('$\beta$',...
%     'interpreter','latex');
% 
% %% plot fit coefficients
% 
% % plot coefficient relationships
% coeff_idcs_offset = 0;
% coeff_x_offset = 0;
% for jj = 1 : numel(coeff_names)
%     coeff_name = coeff_names{jj};
%     if jj > 1
%         prev_coeff_name = coeff_names{jj-1};
%     end
%     if strcmpi(coeff_name,'intercept')
%         coeff_size = 1;
%     else
%         coeff_size = size(design_table.(coeff_name),2);
%     end
%     coeff_idcs = (1 : coeff_size) + coeff_idcs_offset;
%     coeff_idcs_offset = coeff_idcs_offset + coeff_size;
%     if jj > 1 && contains(coeff_name,prev_coeff_name)
%         coeff_x_offset = coeff_x_offset + coeff_size;
% %         markersize = markersize * .75;
%         color = color + [1,1,1] * .45;
%     else
%         markersize = 8.5;
%         color = [0,0,0];
%     end
%     coeff_x = coeff_idcs - coeff_x_offset;
%     p = plot(coeff_x,coeffs(coeff_idcs),...
%         'color',color,...
%         'marker','o',...
%         'markersize',markersize,...
%         'markeredgecolor',color,...
%         'markerfacecolor','w',...
%         'linewidth',1.5);
%     if jj > 1 && contains(coeff_name,prev_coeff_name)
%         uistack(p,'bottom');
%     end
% end
% 
% % update axes
% axis tight;
% xlim(xlim+[-1,1]*.99);
% ylim(ylim+[-1,1]*.05*range(ylim));
% 
% % zero line
% p = plot(xlim,[0,0],'--k',...
%     'hittest','off');
% uistack(p,'bottom');
% 
% % iterate through coefficients
% for bb = 1 : max(xlim) - 1
%     p = plot([1,1]*bb,ylim,':k',...
%         'hittest','off');
%     uistack(p,'bottom');
% end
% 
% % r-squared annotation
% text(.95,.05,sprintf('pseudo-R^{2} = %.2f',pseudo_r2),...
%     'fontsize',12,...
%     'color','k',...
%     'horizontalalignment','right',...
%     'verticalalignment','bottom',...
%     'units','normalized');
% 
% return;

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

stim_long = stimuli >= meta.stimulus.boundary;
curr_stim_long = stim_long * 2 - 1;
prev_stim_long = [0;curr_stim_long(1:end-1)];
prev_stim_long(transition_flags) = 0;

difficulties = round(abs(stimuli - meta.stimulus.boundary),2);
prev_difficulties_1 = [0;difficulties(1:end-1)];
prev_difficulties_1(transition_flags) = 0;

curr_stimuli = stimuli == meta.stimulus.set;
prev_stimuli_1 = [zeros(1,meta.stimulus.n);curr_stimuli(1:end-1,:)];
prev_stimuli_1(transition_flags,:) = 0;
prev_stimuli_2 = [zeros(1,meta.stimulus.n);prev_stimuli_1(1:end-1,:)];
prev_stimuli_2(transition_flags,:) = 0;

curr_difficulty = difficulties == meta.difficulty.set;
prev_difficulty_1 = [zeros(1,meta.difficulty.n);curr_difficulty(1:end-1,:)];
prev_difficulty_1(transition_flags,:) = 0;

choicelong =  bhv_table.choice.long;
prev_choicelong_1 = [false;choicelong(1:end-1)];
prev_choicelong_1(transition_flags) = 0;
prev_choicelong_2 = [false;prev_choicelong_1(1:end-1)];
prev_choicelong_2(transition_flags) = 0;

curr_choice = bhv_table.choice.long * 2 - 1;
curr_choice(curr_premature) = 0;
prev_choice_1 = [0;curr_choice(1:end-1)];
prev_choice_1(transition_flags) = 0;
prev_choice_2 = [0;prev_choice_1(1:end-1)];
prev_choice_2(transition_flags) = 0;
prev_choice_3 = [0;prev_choice_2(1:end-1)];
prev_choice_3(transition_flags) = 0;
choice_hist = [prev_choice_3,prev_choice_2,prev_choice_1,curr_choice];

curr_premature = bhv_table.choice.premature; % * 2 - 1;
prev_premature_1 = [0;curr_premature(1:end-1)];
prev_premature_1(transition_flags) = 0;
prev_premature_2 = [0;prev_premature_1(1:end-1)];
prev_premature_2(transition_flags) = 0;
premature_hist = [prev_premature_2,prev_premature_1];

prev_stimchoice_1 = prev_stimuli_1 .* prev_choice_1;
prev_stimchoice_2 = prev_stimuli_2 .* prev_choice_2;

difficulty_correct = curr_difficulty & bhv_table.choice.correct;
difficulty_error = curr_difficulty & ~bhv_table.choice.correct;
curr_stim_correct = curr_stimuli & bhv_table.choice.correct;
curr_stim_error = curr_stimuli & ~bhv_table.choice.correct;

prev_stim_choicelong_1 = prev_stimuli_1 & prev_choicelong_1;
prev_stim_choiceshort_1 = prev_stimuli_1 & ~prev_choicelong_1;

% construct design matrix
design_table = table(...
    ...premature_hist,...
    choice_hist(:,1:end-1),...
    ...bhv_table.stimulus.category == {'negative','neutral','positive'},...unique(bhv_table.stimulus.category)',...
    ...prev_stim_choiceshort_1(:,1:end-1),...
    ...prev_stim_choicelong_1(:,2:end),...
    prev_stimuli_1,...
    curr_stimuli...
    ...curr_temperature...
    );
design = design_table.Variables;
coeff_names = ['intercept',design_table.Properties.VariableNames];
n_coeffs = size(design,2) + 1;

%% trial selection
valid_flags = ...
    ~curr_premature & ...
    ~prev_premature & ...
    ~transition_flags;

%% feature normalization

% preallocation
zdesign = nan(n_trials,n_coeffs - 1);
mus = nan(n_subjects,n_coeffs - 1);
sigs = nan(n_subjects,n_coeffs - 1);

% iterate through subjects
for aa = 1 : n_subjects
    subject = subjects{aa};
    subject_flags = bhv_table.subject == subject;
    trial_flags = ...
        valid_flags & ...
        subject_flags;
    
    % z-scoring
    mus(aa,:) = nanmean(design(trial_flags,:));
    sigs(aa,:) = 1; %nanstd(design(trial_flags,:));
    zdesign(trial_flags,:) = ...
        (design(trial_flags,:) - mus(aa,:)) ./ sigs(aa,:);
end

% fix nans
zdesign(isnan(zdesign)) = 0;

%% response variable

% construct response variable
response = bhv_table.choice.long;

%% cross-validation settings
cv_k = 100;

%% GLM

% distribution selection
distro = 'binomial';

% preallocation
n_coeffs = size(design,2) + 1;
lambdas = nan(n_subjects,1);
yhat = nan(n_trials,1);
r2 = nan(n_subjects,1);
pvals = nan(n_subjects,1);
coeffs = nan(n_subjects,n_coeffs);

% iterate through subjects
for aa = 1 : n_subjects
    subject = subjects{aa};
    progressreport(aa,n_subjects,...
        sprintf('fitting %s (%i/%i)',subject,aa,n_subjects));

    subject_flags = bhv_table.subject == subject;
    trial_flags = ...
        valid_flags & ...
        subject_flags;
    trial_idcs = find(trial_flags);
    n_trials = numel(trial_idcs);
    
    % fit GLM
    X = zdesign(trial_flags,:);
    y = response(trial_flags);
    [B,info] = lassoglm(X,y,distro,...
        'standardize',true,...
        'lambda',1e-1,...
        'alpha',1e-2,...
        'CV',10);
    [~,null] = lassoglm(X,y(randperm(n_trials)),distro,...
        'standardize',true,...
        'lambda',1e-1,...
        'alpha',1e-2,...
        'CV',10);
    
    % extract coefficients
    lambdas(aa) = info.Lambda(info.IndexMinDeviance);
    coeffs(aa,:) = [...
        info.Intercept(info.IndexMinDeviance);...
        B(:,info.IndexMinDeviance)...
        ];
    
    % store p-value
    pvals(aa) = 1 - chi2cdf(...
        info.Deviance(info.IndexMinDeviance),...
        info.DF(info.IndexMinDeviance));
    
%     % cross-validation
%     b = nan(cv_k,n_coeffs);
%     cv_partition = cvpartition(n_trials,'kfold',cv_k);
%     for ii = 1 : cv_k
%         cv_flags = training(cv_partition,ii);
%         cv_trial_idcs = trial_idcs(cv_flags);
%         [b(ii,2:end),info] = lassoglm(...
%             zdesign(cv_trial_idcs,:),...
%             response(cv_trial_idcs),distro,...
%             'standardize',true,...
%             'lambda',1e-1,...
%             'alpha',1e-2);
%         b(ii,1) = info.Intercept;
%     end
% 
%     % extract coefficients
%     coeffs(aa,:) = nanmean(b,1);

    % model predictions
    yhat(trial_flags) = 1 ./ (1 + exp(-coeffs(aa,:) * ...
        [ones(sum(trial_flags),1),zdesign(trial_flags,:)]'));
    
    % compute r-squared
    ss_tot = nansum((response(trial_flags) - nanmean(response(trial_flags))) .^ 2);
    ss_res = nansum((response(trial_flags) - yhat(trial_flags)) .^ 2);
    r2(aa) = 1 - ss_res / ss_tot;
    
    % compute pseudo-r-squared
    r2(aa) = 1 - info.Deviance / null.Deviance;
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
    ...'T_{t}',...
    ...'RR_{t}',...
    'B_{t-2}',...
    'B_{t-1}',...
    '[C-E]_{t-3}',...
    '[C-E]_{t-2}',...
    '[C-E]_{t-1}',...
    '[L-S]_{t-3}',...
    '[L-S]_{t-2}',...
    '[L-S]_{t-1}',...
    arrayfun(@(x)sprintf('S_{t-1}\\times%.2f_{t-1}',x),...
        meta.stimulus.set(1:end-1),'uniformoutput',false),...
    arrayfun(@(x)sprintf('L_{t-1}\\times%.2f_{t-1}',x),...
        meta.stimulus.set(1+1:end),'uniformoutput',false),...
    arrayfun(@(x)sprintf('%.2f_t',x),...
        meta.stimulus.set,'uniformoutput',false),...
    ];
figure('name',mfilename,...
    'numbertitle','off',...
    'inverthardcopy','off',...
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
    for aa = 1 : n_subjects
        plot(coeff_idcs+offsets(aa),norm_coeffs(aa,coeff_idcs),...
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
for aa = 1 : n_subjects
    subject = subjects{aa};
    if isnan(r2(aa))
        continue;
    end
    xpos = .033 + .15 * (1 - mod(subject_idx,2));
    ypos = .033 * (subject_idx + mod(subject_idx,2)) / 2;
    text(xpos,ypos,sprintf('pseudo R^{2}_{%s}=%.2f',subject,r2(aa)),...
        'fontsize',12,...
        'horizontalalignment','left',...
        'verticalalignment','bottom',...
        'units','normalized');
    subject_idx = subject_idx + 1;
end