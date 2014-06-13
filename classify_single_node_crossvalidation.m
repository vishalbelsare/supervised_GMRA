function [total_errors, std_errors] = classify_single_node_crossvalidation( Data_GWT, Labels_train, Opts )

%
% IN:
%   Data_train_GWT  : GWT of training data
%   Labels_train    : labels of training data. Row vector.
%   Opts:
%       Opts            : structure contaning the following fields:
%                           [Classifier]     : function handle to classifier. Default: LDA_train.
%                           current_node_idx : index at which to train the classifier
%                           [COMBINED]       : whether to use only scaling function subspace (=0) or also wavelet subspace (=1). Default: 0.
%
% OUT:
%   trained_classifier : classifier
%

if ~isfield(Opts,'Classifier') || isempty(Opts.Classifier),     Opts.Classifier = @LDA_traintest;   end;
if ~isfield(Opts,'COMBINED')   || isempty(Opts.COMBINED),       Opts.COMBINED   = 0;                end;

if ~Opts.COMBINED %|| current_node_idx == length(GWT.cp),
    coeffs = cat(1, Data_GWT.CelScalCoeffs{Data_GWT.Cel_cpidx == Opts.current_node_idx})';
else
    coeffs = cat(2, cat(1, Data_GWT.CelScalCoeffs{Data_GWT.Cel_cpidx == Opts.current_node_idx}), cat(1,Data_GWT.CelWavCoeffs{Data_GWT.Cel_cpidx == Opts.current_node_idx}))';
end
dataLabels = Labels_train(Data_GWT.PointsInNet{Opts.current_node_idx});

node_pts  = length(dataLabels);
node_cats = length(unique(dataLabels));

if (node_cats>1) && (node_pts>node_cats) && size(Data_GWT,1)>0
    % Perform crossvalidation
    cp = cvpartition(dataLabels,'k',10);
    opts = statset('UseParallel','never');                                                     % Matlab parallel CV is buggy. What a piece of junk.
    if isequal(Opts.Classifier, @LOL_traintest)
        %         task = {};
        %         task.LOL_alg = Opts.LOL_alg;
        %         %         task.ntrain = cp.TrainSize(1);
        %         task.ntrain = size(coeffs, 1);
        %         ks=unique(floor(logspace(0,log10(task.ntrain),task.ntrain)));
        size(coeffs,1)
	[task, ks] = set_task_LOL(Opts, size(coeffs,1));
        ks
	Opts.task = task;
        % run the crossval for all ks
        for i = 1:length(ks)
            disp('displaying the k')
            ks(i)
            Opts.task.ks = ks(i);
            classf = @(xtrain, ytrain,xtest)(Opts.Classifier(xtrain',ytrain',xtest',[],Opts));
            cvMCR = crossval('mcr',coeffs',dataLabels','predfun', classf,'partition',cp,'Options',opts);
            total_errors_ks(i)    = cvMCR*length(dataLabels)
        end
        disp('total_errors_ks')
        total_errors_ks
        [total_errors, min_ks] = min(total_errors_ks)
    else
        classf = @(xtrain, ytrain,xtest)(Opts.Classifier(xtrain',ytrain',xtest',[],Opts));
        cvMCR = crossval('mcr',coeffs',dataLabels','predfun', classf,'partition',cp,'Options',opts);
        total_errors   = cvMCR*length(dataLabels);
    end
    std_errors      = 0;
else
    total_errors = Inf;
    std_errors   = Inf;
end;

return;
