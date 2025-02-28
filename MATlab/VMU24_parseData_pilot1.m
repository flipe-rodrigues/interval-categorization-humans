%% initialization
close all;
clear;
clc;

%% path settings
pilot = 'pilot i';
root_path = fullfile(dropboxdir,...
    'data','fr','humans','vmu24');
gaped_path = fullfile(root_path,'gaped');
data_path = fullfile(root_path,'data',pilot);

%% parse image data
gaped_image_dir = dir([gaped_path,filesep,'*.png']);
n_images = numel(gaped_image_dir);
image_names = arrayfun(@(x) x.name(1:end-4),gaped_image_dir,...
    'uniformoutput',false);

% preallocation
image_ids = cell(n_images,1);
image_types = cell(n_images,1);
image_valence = nan(n_images,1);
image_arousal = nan(n_images,1);

% iterate through images
for ii = 1 : n_images
    image_name = image_names{ii};
    uscore_idcs = regexp(image_name,'_');
    image_ids{ii} = image_name(uscore_idcs(4)+1:end);
    image_metadata = strsplit(image_name,'_');
    image_types{ii} = lower(image_metadata{1});
    try
        image_valence(ii) = eval(strrep(image_metadata{2},'-','.'));
    catch
        image_valence(ii) = nan;
    end
    try
        image_arousal(ii) = eval(strrep(image_metadata{4},'-','.'));
    catch
        image_arousal(ii) = nan;
    end
end

% parse image types;
image_types = categorical(image_types);
type_set = unique(image_types);
n_types = numel(type_set);

%% parse cohort data
data_dir = dir(data_path);
data_dir = data_dir(3:end);
cohorts = lower(string(vertcat(data_dir.name)));
n_cohorts = numel(data_dir);

%% utility function handles
getimagestat = @(I,S) ...
    arrayfun(@(x)S(ismember(image_ids,x)),I,...
    'uniformoutput',true);
getimagestat2 = @(I,S) ...
    arrayfun(@(x)S(ismember(image_ids,x)),I,...
    'uniformoutput',false);

%% parse & pool data across cohorts and subjects

% iterate through cohorts
for ii = 1 : n_cohorts

    % parse subject data
    bhv_path = fullfile(data_path,cohorts{ii},'behavior');
    bhv_dir = dir([bhv_path,filesep,'*.csv']);
    n_subjects = numel(bhv_dir);

    % iterate through subjects
    for ss = 1 : n_subjects
        progressreport(ss,n_subjects,sprintf('%i/%i',ii,n_cohorts));

        %% load behavioral data
        bhv_file = fullfile(bhv_dir(ss).folder,bhv_dir(ss).name);
        bhv = readtable(bhv_file);

        % parse meta data
        substrs = strsplit(bhv_dir(ss).name,'_');
        subject_task = string(substrs{1}(1:4));
        subject_name = lower(string(substrs{1}(5:end)));
        subject_age = substrs{2};
        subject_handedness = substrs{3};
        session_date =  strjoin(substrs(7:end-1),'_');
        
        % parse task interface
        if contains(subject_task,'m','ignorecase',true)
            interface = "mouse";
        elseif contains(subject_task,'k','ignorecase',true)
            interface = "keyboard";
        end

        % parse task contingency
        if contains(subject_task,'sl','ignorecase',true)
            contingency = "leftshort";
        elseif contains(subject_task,'ls','ignorecase',true)
            contingency = "leftlong";
        end

        %% parse behavioral data
        bhv = bhv(33:end,:);
        n_trials = size(bhv,1);
        trial_idcs = (1 : n_trials)';
        drawn_stimuli = bhv.stimulus;
        choice_premature = bhv.choiceLeft == -1;
        choice_left = bhv.choiceLeft;
        choice_long = bhv.choiceLong;
        choice_correct = bhv.choiceCorrect;
        reaction_time = bhv.reactionTime;
        movement_time = bhv.movementTime;
        choice_time = reaction_time + movement_time;
        drawn_images = bhv.image;
        iti = bhv.interTrialInterval;

        %% convert to table
        variant_table = table(...
            repmat(interface,n_trials,1),...
            repmat(contingency,n_trials,1),...
            'VariableNames',{'interface','contingency'});
        stimulus_table = table(...
            drawn_stimuli,...
            getimagestat(drawn_images,image_types),...
            getimagestat(drawn_images,image_valence),...
            getimagestat(drawn_images,image_arousal),...
            'variablenames',{'duration','category','valence','arousal'});
        choice_table = table(...
            choice_premature,...
            choice_left,...
            choice_long,...
            choice_correct,...
            choice_time,...
            'variablenames',{'premature','left','long','correct','delay'});
        subject_table = table(...
            repmat(cohorts(ii),n_trials,1),...
            variant_table,...
            repmat(subject_name,n_trials,1),...
            stimulus_table,...
            choice_table,...
            iti,...
            'variablenames',{'cohort','variant','subject','stimulus','choice','iti'});

        %%
        % for pp = 1 : n_trials
        %     if ~ismember(drawn_images(pp),image_ids)
        %         drawn_images(pp)
        %         break;
        %     end
        % end

        %% append pooled data table
        if ss == 1
            cohort_table = subject_table;
        else
            cohort_table = [cohort_table; subject_table];
        end
    end

    %% append pooled data table
    if ii == 1
        bhv_table = cohort_table;
    else
        bhv_table = [bhv_table; cohort_table];
    end
end

%% convert to categorical
bhv_table.cohort = categorical(bhv_table.cohort);
bhv_table.variant.interface = categorical(bhv_table.variant.interface);
bhv_table.variant.contingency = categorical(bhv_table.variant.contingency);
bhv_table.subject = categorical(bhv_table.subject);
bhv_table.stimulus.category = categorical(bhv_table.stimulus.category);

%% save data
save_filename = 'bhv';
save([save_filename,'.mat'],'bhv_table');
writetable(splitvars(bhv_table),[save_filename,'.csv']);
return;
%%

% parse stimuli
duration_set = unique(bhv_table.stimulus.duration);
n_durations = numel(duration_set);

% preallocation
psy = struct();

prev_choice = [nan;bhv_table.choice.long(1:end-1)];
prev_stim = [nan;bhv_table.stimulus.duration(1:end-1)]; % > mean(duration_set);
prev_iti = [nan;bhv_table.iti(1:end-1)];
prev = prev_stim; % (prev_choice * 2 - 1) .* prev_stim;
prev_set = unique(prev(~isnan(prev)));
n_prevset = numel(prev_set);

figure;
hold on;
set(gca,'colororder',cool(n_prevset));

%
for kk = 1 : n_prevset
    prev_flags = prev == prev_set(kk);

    % iterate through stimulus durations
    for ii = 1 : n_durations
        stimulus_flags = bhv_table.stimulus.duration == duration_set(ii);
        trial_flags = ...
            prev_flags & ...
            ...bhv_table.cohort == 'VMU' & ...
            ~[false;bhv_table.choice.premature(1:end-1)] & ...
            ~bhv_table.choice.premature & ...
            stimulus_flags;

        % choice data
        psy.x(ii,1) = duration_set(ii);
        psy.y(ii,1) = sum(bhv_table.choice.long(trial_flags));
        psy.n(ii,1) = sum(trial_flags);
        psy.err(ii,1) = ...
            std(bhv_table.choice.long(trial_flags)) / sqrt(sum(trial_flags));
    end

    plot(psy.x,psy.y./psy.n,...
        'marker','.',...
        'markersize',25)
end