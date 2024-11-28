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


%% trial selection
transition_flags = bhv_table.subject ~= [bhv_table.subject(end);bhv_table.subject(1:end-1)];
curr_premature = bhv_table.choice.premature;
prev_premature = [0;curr_premature(1:end-1)];
valid_flags = ...
    ~curr_premature & ...
    ~prev_premature & ...
    ~transition_flags;

%% design matrix

% number of trials to look back
k = 1;

%
stimuli = bhv_table.stimulus.duration;
choices = bhv_table.choice.long;

stimulus_set = unique(stimuli);
choice_set = unique(choices);

%
prev_stimuli = [nan; stimuli(1:end-1)];
prev_choices = [nan; choices(1:end-1)];

%
X_s = stimuli == stimulus_set';
X_c = choices == choice_set';

% interactions
X_i = choices .* stimuli == unique(choices(valid_flags) .* stimuli(valid_flags))';

% trial history
X_s_prev = prev_stimuli == stimulus_set';
X_c_prev = prev_choices == choice_set';

%
design_table = table(...
    X_c_prev,...
    X_s_prev,...
    X_s...
    );
design = double(design_table.Variables);
coeff_names = ['intercept',design_table.Properties.VariableNames];
n_coeffs = size(design,2) + 1;

%% feature normalization

% z-scoring
mus = nanmean(design,1);
sigs = nanstd(design,0,1);
zdesign = (design - mus) ./ sigs;

%% response variable

% construct response variable
response = choices;

%% trial selection
trial_flags = ...
    ...i1 == i_set(i1_mode_idx) & ...
    ...subject_ids == 3 & ...
    valid_flags;
design(~trial_flags,:) = nan;
zdesign(~trial_flags,:) = nan;
response(~trial_flags) = nan;
n_trials = size(design,1);

%% GLM

% distribution selection
distro = 'binomial';

% fit GLM
[B,mdlinfo] = lassoglm(...
    zdesign,response,distro,...
    'standardize',true,...
    'lambda',1e-1,...
    'alpha',1e-2,...
    'CV',10);
[~,nullinfo] = lassoglm(...
    zdesign*0,response,distro,...
    'standardize',true,...
    'lambda',1e-1,...
    'alpha',1e-2,...
    'CV',10);

% extract coefficients~
coeffs = [...
    mdlinfo.Intercept(mdlinfo.IndexMinDeviance);...
    B(:,mdlinfo.IndexMinDeviance)...
    ];

% no regularization
% mdl = fitglm(zdesign,response,...
%     'distribution',distro);
% coeffs = mdl.Coefficients.Estimate;

% compute pseudo r-squared
pseudo_r2 = (nullinfo.Deviance - mdlinfo.Deviance) / nullinfo.Deviance;
pseudo_stimuli = [ones(n_trials,1),zdesign] * coeffs;

%% figure initialization
xxticklabels = [...
    '\beta_0',...
    arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{2}(3:end)),x),stimulus_set','uniformoutput',false),...
    arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{3}(3:end)),x),choice_set','uniformoutput',false),...
    arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{4}(3:end)),x),stimulus_set','uniformoutput',false),...
    arrayfun(@(x)sprintf('%s=%i',upper(coeff_names{5}(3:end)),x),choice_set','uniformoutput',false),...
    ];
fig = figure('name',mfilename,...
    'windowstate','maximized',...
    'numbertitle','off',...
    'inverthardcopy','off',...
    'color','w');
set(gca,...
    'nextplot','add',...
    'tickdir','out',...
    'fontsize',12,...
    'linewidth',2,...
    'layer','top',...
    'xcolor','k',...
    'ycolor','k',...
    'xlim',[1,n_coeffs]+[-1,1],...
    'xtick',1:n_coeffs,...
    'xticklabel',xxticklabels,...
    'xticklabelrotation',45,...
    'ylim',[0,1]+[-1,1]*.05,...
    'ytick',0,...[0,1],...
    'ticklabelinterpreter','tex',...
    'plotboxaspectratio',[3,1,1],...
    'clipping','off');
title(sprintf('%s>%s~Binomial(\\phi(\\betaX))',s2_lbl,s1_lbl));
xlabel('X');
ylabel('$\beta$',...
    'interpreter','latex');

%% plot fit coefficients

% plot coefficient relationships
coeff_idcs_offset = 0;
coeff_x_offset = 0;
for jj = 1 : numel(coeff_names)
    coeff_name = coeff_names{jj};
    if jj > 1
        prev_coeff_name = coeff_names{jj-1};
    end
    if strcmpi(coeff_name,'intercept')
        coeff_size = 1;
    else
        coeff_size = size(design_table.(coeff_name),2);
    end
    coeff_idcs = (1 : coeff_size) + coeff_idcs_offset;
    coeff_idcs_offset = coeff_idcs_offset + coeff_size;
    if jj > 1 && contains(coeff_name,prev_coeff_name)
        coeff_x_offset = coeff_x_offset + coeff_size;
        %         markersize = markersize * .75;
        color = color + [1,1,1] * .45;
    else
        markersize = 8.5;
        color = [0,0,0];
    end
    coeff_x = coeff_idcs - coeff_x_offset;
    p = plot(coeff_x,coeffs(coeff_idcs),...
        'color',color,...
        'marker','o',...
        'markersize',markersize,...
        'markeredgecolor',color,...
        'markerfacecolor','w',...
        'linewidth',1.5);
    if jj > 1 && contains(coeff_name,prev_coeff_name)
        uistack(p,'bottom');
    end
end

% update axes
axis tight;
xlim(xlim+[-1,1]*.99);
ylim(ylim+[-1,1]*.05*range(ylim));

% zero line
p = plot(xlim,[0,0],'--k',...
    'hittest','off');
uistack(p,'bottom');

% iterate through coefficients
for bb = 1 : max(xlim) - 1
    p = plot([1,1]*bb,ylim,':k',...
        'hittest','off');
    uistack(p,'bottom');
end

% r-squared annotation
text(.95,.05,sprintf('pseudo-R^{2} = %.2f',pseudo_r2),...
    'fontsize',12,...
    'color','k',...
    'horizontalalignment','right',...
    'verticalalignment','bottom',...
    'units','normalized');