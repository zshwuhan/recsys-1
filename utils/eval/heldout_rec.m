function [eval_summary, eval_detail, elapsed] = heldout_rec(rec, mat, scoring, varargin)
% elapsed: training time and testing time.
[test, test_ratio, train_ratio, split_mode, times, seed, rec_opt] = process_options(varargin, 'test', [], ...
    'test_ratio', 0.2, 'train_ratio', -1, 'split_mode', 'un', 'times', 5, 'seed', 1);
if train_ratio<0
    train_ratio = 1 - test_ratio;
end
assert(test_ratio >0 && test_ratio <1)
assert(train_ratio >0 && train_ratio <= 1 - test_ratio)
train_ratio = min(train_ratio, 1 - test_ratio);
elapsed = zeros(1,2);
if ~isempty(test)
    % recommendation for the given dataset
    train = mat;
    tic; [P, Q] = rec(train, rec_opt{:}); elapsed(1) = toc;
    tic; eval_detail = scoring(train, test, P,  Q); elapsed(2) = toc;
    if(nnz(test)>0) % Truth condition indicates regular evaluation returning struct  
        fns = fieldnames(eval_detail);
        for f=1:length(fns)
            fieldname = fns{f};
            field_mean = eval_detail.(fieldname);
            eval_summary.(fieldname) = [field_mean; zeros(1,length(field_mean))];
        end
    else
        eval_summary = eval_detail;
    end
else
    % split mat and perform recommendation
    rng(seed);
    eval_detail = struct();
    for t=1:times
        [train, test] = split_matrix(mat, split_mode, 1-test_ratio);
        [train, ~] = split_matrix(train, split_mode, train_ratio/(1-test_ratio));
        tic; [P, Q] = rec(train, rec_opt{:}); elapsed(1) = elapsed(1) + toc/times;
        tic;
        if strcmp(split_mode, 'i')
            ind = sum(test)>0;
            metric_time = scoring(train(:,ind), test(:,ind), P,  Q(ind,:));
        else
            metric_time = scoring(train, test, P,  Q);
        end
        elapsed(2) = elapsed(2) + toc/times;
        fns = fieldnames(metric_time);
        for f=1:length(fns)
            fieldname = fns{f};
            if isfield(eval_detail, fieldname)
                %evalout.(fieldname) = evalout.(fieldname) + [metric_time.(fieldname);(metric_time.(fieldname)).^2];
                eval_detail.(fieldname) = [eval_detail.(fieldname); metric_time.(fieldname)];
            else
                %evalout.(fieldname) = [metric_time.(fieldname);(metric_time.(fieldname)).^2];
                eval_detail.(fieldname) = metric_time.(fieldname);
            end
        end
    end
    fns = fieldnames(eval_detail);
    for f=1:length(fns)
        fieldname = fns{f};
        field = eval_detail.(fieldname);
        %field_mean = field(1,:) / times;
        %field_std = sqrt(field(2,:)./times - field_mean .* field_mean);
        eval_summary.(fieldname) = [mean(field); std(field)];
    end
end

end
