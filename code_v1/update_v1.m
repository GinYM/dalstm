function [result,store_idx] = update_v1(gm,data_source,data_target)
csp_per_class=3;
result=gm;
n = 162;
num_select = 162;
acc = 0;
total = 0;

isVis = zeros(1,n*2);

flag = false;


for i = 1:160
    disp(['Processing ' num2str(i)])
    tmp_var = 0;
    label_idx = 0;
    best_mean1 = 0;
    best_mean2 = 0;
    
    %% train a LDA
    if flag == true
        trainY = [(-1)*ones(n,1); ones(n,1)];
        [W,B,class_means] = lda_train_reg(Xproj_tmp(1:324,:), trainY, 0);
        [X_LDA predicted_y_class1] = lda_apply(Xproj_tmp(324+i,:), W, B);
        if predicted_y_class1 == 1 && X_LDA>0.005
            continue;
        end
    end
    
    %% update covariance matrix
    result_tmp = result;
    C_new = cov(data_target{floor((i-1)/n)+1}{mod((i-1),n)+1}')/trace(cov(data_target{floor((i-1)/n)+1}{mod((i-1),n)+1}'));
    result_tmp{1} = result_tmp{1}*num_select/(num_select+1) + C_new/(num_select+1);
    for j = (i+1):n*2
        if isVis(j) == 1
            continue;
        end

        C_new = cov(data_target{floor((j-1)/n)+1}{mod((j-1),n)+1}')/trace(cov(data_target{floor((j-1)/n)+1}{mod((j-1),n)+1}'));
        result_tmp_1 = result_tmp;
        result_tmp_1{2} = result_tmp{2}*num_select/(num_select+1) + C_new/(num_select+1);
        
        %% calculate CSP using new general matrix
        [ csp_coeff,all_coeff] = csp_analysis(data_source,9,csp_per_class, 0,result_tmp_1); % actually don't need data_source
        [ data_source_filter ] = csp_filtering(data_source, csp_coeff);
        [data_target_filter] = csp_filtering(data_target,csp_coeff);
        data_source_log{1} = log_norm_BP(data_source_filter{1}); 
        data_source_log{2} = log_norm_BP(data_source_filter{2});
        data_target_log{1} = log_norm_BP(data_target_filter{1}); 
        data_target_log{2} = log_norm_BP(data_target_filter{2});

        %% SA
        X = zeros(0,6);
        Y = zeros(0,1);
        maLabeled = zeros(0,1,'logical');
        for idx = 1:2
        for ii = 1:size(data_source_log{idx},2)
            X = [X;data_source_log{idx}{ii}'];
            Y = [Y;idx];
            maLabeled = [maLabeled;true];
        end
        end

        for idx = 1:2
        for ii = 1:size(data_target_log{1},2)
            X = [X;data_target_log{idx}{ii}'];
            Y = [Y;idx];
            maLabeled = [maLabeled;false];
        end
        end
        param = []; param.pcaCoef = 2;
        [Xproj,transMdl] = ftTrans_sa(X,maLabeled,Y(maLabeled),maLabeled,param);
        mean1 = mean(X(1:n*2,:));
        mean2 = mean(X(2*n+1:end,:));
        mean_dif = sum(abs(mean1-mean2));
        
        %% 6 is the threshold
        if  mean_dif > 6
            continue;
        end
        
        %% the mean also should not be too large. (Not present in the algorithm)
        if sum(abs(mean2)) > 20 || sum(abs(mean1)) > 20
            continue;
        end
        
        %% select the largest variance
        var_t1 = mean(var(Xproj(n*2+1:end,:)));
        if(var_t1>tmp_var )
            flag = true;
            Xproj_tmp = Xproj;
            best_mean1 = mean1;
            best_mean2 = mean2;
            tmp_var = var_t1;
            label_idx = j;
            mean_pre = mean_dif;
        end
        %idx_all(j) = ~idx_all(j);
        
    end
    
    %% already selecting two trials, updating covariance matrix
    if tmp_var ~=0
        C_new = cov(data_target{floor((i-1)/n)+1}{mod((i-1),n)+1}')/trace(cov(data_target{floor((i-1)/n)+1}{mod((i-1),n)+1}'));
        result{1} = result{1}*num_select/(1+num_select) + C_new/(1+num_select);
        C_new = cov(data_target{floor((label_idx-1)/n)+1}{mod((label_idx-1),n)+1}')/trace(cov(data_target{floor((label_idx-1)/n)+1}{mod((label_idx-1),n)+1}'));
        result{2} = result{2}*num_select/(1+num_select) + C_new/(1+num_select);
        %idx_all(label_idx) = ~idx_all(label_idx);
        %var2 = tmp_var;
        isVis(label_idx) = 1;
        disp(['First ' num2str(i) ' Second: ' num2str(label_idx) ' Var: ' num2str(tmp_var) ' Mean1: ' num2str(sum(abs(best_mean1))) ' Mean2: ' num2str(sum(abs(best_mean2)))]);
        total = total+1;
        store_idx(total,1) = i;
        store_idx(total,2) = label_idx;
        if(label_idx>162)
            acc = acc+1;
        end
    end
    
    %disp(['var2: ' num2str(var2)]);
    
end

%% show result for selecting accuracy
[ csp_coeff,all_coeff] = csp_analysis(data_source,9,csp_per_class, 0,result); % actually don't need data_source
[ data_source_filter ] = csp_filtering(data_source, csp_coeff);
[data_target_filter] = csp_filtering(data_target,csp_coeff);
data_source_log{1} = log_norm_BP(data_source_filter{1}); 
data_source_log{2} = log_norm_BP(data_source_filter{2});
data_target_log{1} = log_norm_BP(data_target_filter{1}); 
data_target_log{2} = log_norm_BP(data_target_filter{2});
%% SA
X = zeros(0,6);
Y = zeros(0,1);
maLabeled = zeros(0,1,'logical');
for idx = 1:2
    for ii = 1:size(data_source_log{idx},2)
        X = [X;data_source_log{idx}{ii}'];
        Y = [Y;idx];
        maLabeled = [maLabeled;true];
    end
end

for idx = 1:2
    for ii = 1:size(data_target_log{1},2)
        X = [X;data_target_log{idx}{ii}'];
        Y = [Y;idx];
        maLabeled = [maLabeled;false];
    end
end
param = []; param.pcaCoef = 2;
[Xproj,transMdl] = ftTrans_sa(X,maLabeled,Y(maLabeled),maLabeled,param);

mean1 = mean(X(1:n*2,:));
mean2 = mean(X(2*n+1:end,:));
disp(['Mean1: ' num2str(sum(abs(mean1))) ' Mean2: ' num2str(sum(abs(mean2)))]);
disp(['Acc: ' num2str(acc/total) ' Total: ' num2str(total)]);

%% uncomment the following codes to visualize the features

% figure
% plot(1:n,X(1:n,1),'r*');
% hold on
% plot(1:n,X(n+1:n*2,1),'k*')
% hold on
% plot(n+1:n*2,X(n*2+1:n*3,1),'bo')
% hold on
% plot(n+1:n*2,X(n*3+1:n*4,1),'go');
% title(['Trial1']);
% 
% 
% figure
% plot(1:n,Xproj(1:n,1),'r*');
% hold on
% plot(1:n,Xproj(n+1:n*2,1),'k*')
% hold on
% plot(n+1:n*2,Xproj(n*2+1:n*3,1),'bo')
% hold on
% plot(n+1:n*2,Xproj(n*3+1:n*4,1),'go');
% title(['Trial2']);
