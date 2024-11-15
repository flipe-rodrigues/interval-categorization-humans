%% initialization
% close all;
clear;
clc;

%% path settings
root_path = fullfile(dropboxdir,...
    'data','fr','humans','vmu24');
bhv_path = fullfile(root_path,'behavior');
mouse_path = fullfile(root_path,'mouse trajectories');
gaped_path = fullfile(root_path,'gaped');

%% directory settings
gaped_image_dir = dir([gaped_path,filesep,'*.png']);
gaped_score_dir = dir([gaped_path,filesep,'*.txt']);
n_images = numel(gaped_image_dir);

%% parse GAPED images & scores
image_names = arrayfun(@(x) x.name(1:end-4),gaped_image_dir,...
    'uniformoutput',false);
type_set = {...
    ...'TlN',...
    ...'Horse',...
    ...'Zebra',...
    ...'d',...
    'da',...
    'dn',...
    ...'N',...
    ...'NH',...
    ...'NL',...
    ...'PH',...
    ...'PL',...
    ...'w',...
    'wn',...
    'wa',...
    };
n_types = numel(type_set);

%% color settings
bg_clr = [1,1,1] * .05;
fg_clr = 1 - bg_clr;
type_clrs = summer(n_types);

%% figure & axes initialization

% figure settings
figure(...
    'name','VMU24 - Grand average',...
    'numbertitle','off',...
    'inverthardcopy','off',...
    'windowstyle','docked',...
    'color',bg_clr);

% axes settings
n_rows = 1;
n_cols = 3;
n_sps = n_rows * n_cols;
sps = gobjects(n_sps,1);
for ii = 1 : n_sps
    sps(ii) = subplot(n_rows,n_cols,ii);
end
set(sps,...
    'xlimspec','tight',...
    'ylimspec','tight',...
    'zlimspec','tight',...
    'nextplot','add',...
    'tickdir','out',...
    'color','none',...
    'layer','top',...
    'box','off',...
    'ticklength',[1,1]*.025,...
    'linewidth',.5,...
    'fontsize',12,...
    'xcolor',fg_clr,...
    'ycolor',fg_clr,...
    'zcolor',fg_clr,...
    'plotboxaspectratio',[1,1,1]);
set(sps,...
    'xlim',[0,2.4]+[-1,1]*.05,...
    'xtick',linspace(0,2.4,5),...
    'ylim',ylim(sps(1))+[-1,1]*range(ylim(sps(1)))*.05,...
    'ytick',linspace(0,1,3));

% axes labels
xlabel(sps(1),'Interval time (s)');
xlabel(sps(2),'Interval time (s)');
xlabel(sps(3),'Interval time (s)');
ylabel(sps(1),'Proportion of long choices');
ylabel(sps(2),'Reaction time (s)');
ylabel(sps(3),'Movement time (s)');

%%% psignifit settings
warning('off');

% psychometric fit settings
fitopt = struct();
fitopt.expType = 'YesNo';
fitopt.sigmoidName = 'logistic';
fitopt.estimateType = 'MAP';
fitopt.confP = [.95,.9,.68];
fitopt.borders = [0,1;0,1;0,.5;0,.5;0,0];
fitopt.fixedPars = [nan,nan,nan,nan,0];
fitopt.stepN = [60,60,20,20,20];

% psychometric plot settings
plotopt = struct();
plotopt.markersize = 8.5;
plotopt.linewidth = 1.5;
plotopt.gradeclrs = false;
plotopt.patchci = false;
plotopt.plotdata = false;
plotopt.normalizemarkersize = true;

%% directory settings
bhv_dir = dir([bhv_path,filesep,'*.csv']);
n_subjects = numel(bhv_dir);
title(sps(2),sprintf('N = %i',n_subjects),...
    'color',fg_clr);

%% utility function handles
getimagestat = @(I,S) ...
    arrayfun(@(x)S(ismember(image_names,x)),I,...
    'uniformoutput',true);

%% pool data across subjects

% preallocation
subject_stimuli = cell(n_subjects,1);
subject_choices = cell(n_subjects,1);
subject_reactions = cell(n_subjects,1);
subject_movements = cell(n_subjects,1);
subject_valence = cell(n_subjects,1);
subject_arousal = cell(n_subjects,1);
subject_clusters = cell(n_subjects,1);
subject_types = cell(n_subjects,1);

% iterate through subjects
for ss = 1 : n_subjects
    
    %% load behavioral data
    bhv_dir = dir([bhv_path,filesep,'*.csv']);
    bhv_file = fullfile(bhv_dir(ss).folder,bhv_dir(ss).name);
    bhv = readtable(bhv_file);
    
    % parse meta data
    substrs = strsplit(bhv_dir(ss).name,'_');
    subject_name = substrs{1};
    subject_age = substrs{2};
    subject_handedness = substrs{3};
    session_date =  strjoin(substrs(6:end-1),'_');
    
    %% parse behavioral data
    n_trials = size(bhv,1);
    drawn_stimuli = bhv.stimulus;
    reaction_time = bhv.reactionTime;
    movement_time = bhv.movementTime;
    choice_long = bhv.choiceLong;
    choice_correct = bhv.choiceCorrect;
    drawn_images = bhv.image;
    image_types = cell(n_trials,1);
    for tt = 1 : n_trials
        type_idcs = find(cellfun(@(x)contains(drawn_images{tt},x),type_set));
        if isempty(type_idcs)
            image_types{tt} = '';
        else
            image_types{tt} = type_set{type_idcs(1)};
        end
    end
    image_types = categorical(image_types,type_set);
    valid_flags = ...
        ~isundefined(image_types) & ...
        ~isnan(choice_long) & ...
        ismember(choice_long,[0,1]);
    
    %% store current subject data
    subject_stimuli{ss} = drawn_stimuli(valid_flags);
    subject_choices{ss} = choice_long(valid_flags);
    subject_reactions{ss} = reaction_time(valid_flags);
    subject_movements{ss} = movement_time(valid_flags);
%     subject_valence{ss} = getimagestat(drawn_images(valid_flags),image_valence);
%     subject_arousal{ss} = getimagestat(drawn_images(valid_flags),image_arousal);
%     subject_clusters{ss} = getimagestat(drawn_images(valid_flags),image_clusters);
    subject_types{ss} = image_types(valid_flags); % getimagestat(drawn_images(valid_flags),image_types);
end

%% pool across subjects
pool_stimuli = vertcat(subject_stimuli{:});
pool_choices = vertcat(subject_choices{:});
pool_reactions = vertcat(subject_reactions{:});
pool_movements = vertcat(subject_movements{:});
pool_valence = vertcat(subject_valence{:});
pool_arousal = vertcat(subject_arousal{:});
pool_clusters = vertcat(subject_clusters{:});
pool_types = vertcat(subject_types{:});

%% stimulus settings
stimulus_set = unique(pool_stimuli);
boundary = mean(stimulus_set);
n_stimuli = numel(stimulus_set);

% flag correct choices
correct_flags = pool_choices == (pool_stimuli > boundary);

%% TYPES

% iterate through image types
for kk = 1 : n_types
    
    %%
    type_flags = pool_types == type_set(kk);
    
    % preallocation
    psy = struct();
    rt = struct();
    mt = struct();
    
    % iterate through stimuli
    for ii = 1 : n_stimuli
        stimulus_flags = pool_stimuli == stimulus_set(ii);
        trial_flags = ...
            type_flags & ...
            stimulus_flags;
        
        % choice data
        psy.x(ii,1) = stimulus_set(ii)/3;
        psy.y(ii,1) = sum(pool_choices(trial_flags));
        psy.n(ii,1) = sum(trial_flags);
        psy.err(ii,1) = ...
            std(pool_choices(trial_flags)) / sqrt(sum(trial_flags));
        
        % reaction time data
        rt.med(ii,1) = median(pool_reactions(trial_flags & correct_flags));
        rt.iqr(ii,:) = ...
            quantile(pool_reactions(trial_flags & correct_flags),[.25,.75]) - ...
            median(pool_reactions(trial_flags & correct_flags));
        
        % movement time data
        mt.med(ii,1) = median(pool_movements(trial_flags & correct_flags));
        mt.iqr(ii,:) = ...
            quantile(pool_movements(trial_flags & correct_flags),[.25,.75]) - ...
            median(pool_movements(trial_flags & correct_flags));
    end
    
    % fit psychometric function
    psy.fit = psignifit([psy.x,psy.y,psy.n],fitopt);
    
    %% plot psychometric performance
%     plotopt.parent = sps(1);
%     plotopt.datafaceclr = type_clrs(kk,:);
%     plotopt.dataedgeclr = type_clrs(kk,:);
%     plotopt.fitclr = type_clrs(kk,:);
%     plotopt.plotdata = true;
%     plotopt.linewidth = 1.5;
%     plotopt.linestyle = '-';
%     plotopt.gradeclrs = false;
%     plotpsy(psy,psy.fit,plotopt);
    errorbar(sps(1),stimulus_set,psy.y./psy.n,psy.err,...
        'color',type_clrs(kk,:),...
        'marker','none',...
        'linewidth',.5,...
        'linestyle','none',...
        'capsize',0,...
        'handlevisibility','off');
    plot(sps(1),stimulus_set,psy.y./psy.n,...
        'color',type_clrs(kk,:),...
        'marker','o',...
        'markeredgecolor',bg_clr,...
        'markerfacecolor',type_clrs(kk,:),...
        'markersize',7.5,...
        'linewidth',1.5);

    % plot reference lines
    plot(sps(1),...
        xlim(sps(1)),[1,1]*.5,':',...
        'color',fg_clr,...
        'handlevisibility','off');
    plot(sps(1),...
        [1,1]*mean(xlim(sps(1))),ylim(sps(1)),':',...
        'color',fg_clr,...
        'handlevisibility','off');
    
    %% plot average reaction times
    errorbar(sps(2),stimulus_set,rt.med,...
        rt.iqr(:,1),...
        rt.iqr(:,2),...
        'color',type_clrs(kk,:),...
        'marker','none',...
        'linewidth',.5,...
        'linestyle','none',...
        'capsize',0,...
        'handlevisibility','off');
    plot(sps(2),stimulus_set,rt.med,...
        'color',type_clrs(kk,:),...
        'marker','o',...
        'markeredgecolor',bg_clr,...
        'markerfacecolor',type_clrs(kk,:),...
        'markersize',7.5,...
        'linewidth',1.5,...
        'linestyle','-');
    
    %% plot average movement times
    errorbar(sps(3),stimulus_set,mt.med,...
        mt.iqr(:,1),...
        mt.iqr(:,2),...
        'color',type_clrs(kk,:),...
        'marker','none',...
        'linewidth',.5,...
        'linestyle','none',...
        'capsize',0,...
        'handlevisibility','off');
    plot(sps(3),stimulus_set,mt.med,...
        'color',type_clrs(kk,:),...
        'marker','o',...
        'markeredgecolor',bg_clr,...
        'markerfacecolor',type_clrs(kk,:),...
        'markersize',7.5,...
        'linewidth',1.5,...
        'linestyle','-');
end

%% legends
legend(sps(1),type_set,...
    'color','none',...
    'textcolor',fg_clr,...
    'edgecolor',fg_clr,...
    'location','southeast');