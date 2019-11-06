function [ax1,ax2, coefs] = printConfByResp(project_params, subjects, ROI_label, ROI_name)

p=project_params;
load(fullfile(p.raw_dir,'subject_details.mat'));

%add nice things to path
addpath('D:\Documents\software\cbrewer') %for color
addpath('D:\Documents\software\sigstar') %for significance
[cb] = cbrewer('qual','Set1',10,'pchip');
cb_dis = cbrewer('div','PRGn',18,'pchip');
cb_det = cbrewer('div','RdBu',18,'pchip');
cb_dis = cb_dis([2:7,12:17],:);
cb_det = cb_det([2:7,12:17],:);
mappingcb = cbrewer('div','BrBG',3);


A_num_trials = nan(35,6);
C_num_trials = nan(35,6);
Y_num_trials = nan(35,6);
N_num_trials = nan(35,6);

i=1;
%% get trial count
for i_s = subjects
    
    rTPJ = load(fullfile(p.stats_dir,...
        'DM200',['sub-',subj{i_s}.scanid],'rTPJ.mat'));
    
    %bidirectional confidence
    conf = rTPJ.confidence_vec;
    conf(rTPJ.response_vec==0)=-conf(rTPJ.response_vec==0)+1;
    conf(rTPJ.response_vec==3)=-conf(rTPJ.response_vec==3)+1;
    bi_conf = conf+6;
    
    for rating = 1:6
        
        A_num_trials(i,rating)=...
            sum(rTPJ.confidence_vec==rating & rTPJ.detection_vec==0 & rTPJ.response_vec==3);
        
        C_num_trials(i,rating)=...
            sum(rTPJ.confidence_vec==rating & rTPJ.detection_vec==0 & rTPJ.response_vec==1);
        
        Y_num_trials(i,rating)=...
            sum(rTPJ.confidence_vec==rating & rTPJ.detection_vec==1 & rTPJ.response_vec==1);
        
        N_num_trials(i,rating)=...
            sum(rTPJ.confidence_vec==rating & rTPJ.detection_vec==1 & rTPJ.response_vec==0);
    end
    i=i+1;
    
end

%% get betas
ROI_betas = load(fullfile(p.stats_dir,'DM431555','group',ROI_label));

%% get standard errors

for i=1:6
    A_standard_error(i) = nanstd(ROI_betas.conf_A(:,i))/sqrt(sum(~isnan(ROI_betas.conf_A(:,i))));
    C_standard_error(i) = nanstd(ROI_betas.conf_C(:,i))/sqrt(sum(~isnan(ROI_betas.conf_C(:,i))));
    Y_standard_error(i) = nanstd(ROI_betas.conf_Y(:,i))/sqrt(sum(~isnan(ROI_betas.conf_Y(:,i))));
    N_standard_error(i) = nanstd(ROI_betas.conf_N(:,i))/sqrt(sum(~isnan(ROI_betas.conf_N(:,i))));
end


%% plot
figure('visible','off');
ax1=subplot(1,2,1); hold on;
title('detection');
errorbar(1:6, nanmean(ROI_betas.conf_Y),Y_standard_error,'-k');
errorbar(0.2+(1:6), nanmean(ROI_betas.conf_N),N_standard_error,'-k');
yes_points = scatter(1:6,nanmean(ROI_betas.conf_Y),5*nanmean(Y_num_trials)'+1,cb(2,:),...
    'filled','MarkerEdgeColor','k');
no_points = scatter(0.2+(1:6),nanmean(ROI_betas.conf_N),5*nanmean(N_num_trials)'+1,cb(1,:),...
    'filled','MarkerEdgeColor','k');

%for overlap:
scatter(1:6,nanmean(ROI_betas.conf_Y),5*nanmean(Y_num_trials)'+1,cb(2,:),...
    'filled','MarkerEdgeColor','k','MarkerFaceAlpha',0.5);
scatter(0.2+(1:6),nanmean(ROI_betas.conf_N),5*nanmean(N_num_trials)'+1,'k');

xlim([0,7]);
% ylim([-0.5, 1.2]);
xticks(1:6);
% xtickangle(45);
set(gca,'ytick',[0,1]);
ylabel(sprintf('mean \\beta in the %s',ROI_name));
legend([yes_points,no_points],'yes','no')
xlabel('confidence');

ax2=subplot(1,2,2); hold on;
title('discrimination');
errorbar(1:6, nanmean(ROI_betas.conf_C),C_standard_error,'-k')
errorbar(0.2+(1:6), nanmean(ROI_betas.conf_A),A_standard_error,'-k')
CW_points = scatter(1:6,nanmean(ROI_betas.conf_C),5*nanmean(C_num_trials)'+1,cb(3,:),...
    'filled','MarkerEdgeColor','k');
CCW_points = scatter(0.2+(1:6),nanmean(ROI_betas.conf_A),5*nanmean(A_num_trials)'+1,cb(4,:),...
    'filled','MarkerEdgeColor','k');
% %for overlap:
scatter(1:6,nanmean(ROI_betas.conf_C),5*nanmean(C_num_trials)'+1,cb(3,:),...
    'filled','MarkerEdgeColor','k','MarkerFaceAlpha',0.5);
scatter(0.2+(1:6),nanmean(ROI_betas.conf_A),5*nanmean(A_num_trials)'+1,'k');

xlim([0,7]);
% ylim([-0.5, 1.2]);
xticks(1:6);
% xtickangle(45);
set(gca,'ytick',[0,1]);
ylabel(sprintf('mean \\beta in the %s',ROI_name));
legend([CW_points,CCW_points],'CW','CCW')
xlabel('confidence');

set(gca,'ytick',[]);
linkaxes([ax1,ax2],'y')
set(gca,'YColor','none')

% fig = gcf;
% fig.PaperUnits = 'inches';
% set(fig,'PaperPositionMode','auto');
% print(sprintf('figures/%s_conf',ROI_label),'-dpng','-r1200');
% print(sprintf('figures/%s_conf_300dpi',ROI_label),'-dpng','-r300');

coefs = nan(35,3,4); %subjects, degrees, responses: YNAC
ROI_conf_betas = cat(3,ROI_betas.conf_Y, ROI_betas.conf_N, ROI_betas.conf_A, ROI_betas.conf_C);

for i_s = 1:35
    for i_r = 1:4
        confidence_levels=1:6;
        beta_values = ROI_conf_betas(i_s,:,i_r);
        confidence_levels(isnan(beta_values))=[];
        if numel(confidence_levels)>3
            beta_values(isnan(beta_values))=[];
            coefs(i_s,:,i_r) = polyfit(confidence_levels-mean(confidence_levels),...
                beta_values-mean(beta_values),2);
        end
    end
end


end


