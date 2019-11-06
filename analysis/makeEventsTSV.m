function [] = makeEventsTSV(subj_id, scanner_code)
% create a TSV file with event information

fclose('all');

subj_files = dir(fullfile('..','experiment','data',[subj_id,'_session*.mat']));

det_map = containers.Map([0,1],{'N','Y'});
dis_map = containers.Map([1,3],{'C','A'});

for j = 1:length(subj_files)
    
    load(fullfile('..','experiment','data',subj_files(j).name));
    
    %% SOME SANITY CHECKS
    if sum(log.events(:,1)==0) ~= params.Nsets
        error('The numbers of planned and executed events are not identical');
    end
    
    %% WRITE TSV FILE
    
    %% initialize file
    if ~exist(fullfile('..','data','data',strcat('sub-',scanner_code),'func'),'dir')
        mkdir(fullfile('..','data','data',strcat('sub-',scanner_code),'func'))
    end
    file_path = fullfile('..','data','data',strcat('sub-',scanner_code),'func',...
        strcat('sub-',scanner_code,'_task-detectdiscrim_run-',sprintf('%02d',j),'_events.tsv'));
    if exist(file_path, 'file')==2
        delete(file_path);
    end
    fileID = fopen(file_path,'a');
    
    %field names
    fprintf(fileID, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'onset','duration',...
        'trial_type','response_time','confidence','detection','stimulus','response','key_id');
    
    %stimulus-response, A - anticlockwise, C - clockwise, Y - grating, N -
    %noise
    trial_types = {'AA','AC','CA','CC', 'NN', 'NY', 'YN', 'YY'};
    
    %% loop over events
    
    trial_counter = 0;
    for event_idx = 1:length(log.events)
        
        %is it a trial or a button press?
        if log.events(event_idx,1)==0 % trial onset
            
            trial_counter = trial_counter+1;
            
            %was this trial missed (participant failed to respond on time)?
            if isnan(log.correct(trial_counter))
                fprintf(fileID,'%.2f\t%.2f\t%s\t%s\t%s\t%d\t%d\t%s\t%s\n', ...
                    log.events(event_idx,2),... %onset in seconds
                    params.fixation_time + params.display_time...
                    + params.time_to_respond + params.time_to_conf,... %trial duration
                    'missed_trial',...
                    'n/a',...
                    'n/a',...
                    log.detection(trial_counter),...
                    (log.Wg(trial_counter)>0)*log.direction(trial_counter),...
                    'n/a',...
                    'n/a');
                
            else %not a miss
                
                % figure out the trial type
                if log.detection(trial_counter)
                    trial_type = ...
                        [det_map(ceil(log.Wg(trial_counter))), det_map(log.resp(trial_counter,2))];
                else %discrimination
                   trial_type = ...
                       [dis_map(log.direction(trial_counter)), dis_map(log.resp(trial_counter,2))];
                end
                
                fprintf(fileID, '%.2f\t%.2f\t%s\t%.2f\t%d\t%d\t%d\t%d\t%s\n', ...
                    log.events(event_idx,2),... %onset in seconds
                    params.fixation_time + params.display_time...
                    + params.time_to_respond + params.time_to_conf,... %trial duration
                    trial_type, ...
                    log.resp(trial_counter,1), ... %RT
                    log.confidence(trial_counter),...
                    log.detection(trial_counter),...
                    (log.Wg(trial_counter)>0)*log.direction(trial_counter),...
                    log.resp(trial_counter,2),...
                    'n/a');
            end
        else %button press
                    fprintf(fileID,  '%.2f\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%d\n', ...
                    log.events(event_idx,2),... %onset in seconds
                    0,... %button press is modeled as a delta function
                    'button press',...
                    'n/a',...
                    'n/a',...
                    'n/a',...
                    'n/a',...
                    'n/a',...
                    log.events(event_idx,1));
        end
    end
    fclose(fileID);
end

end