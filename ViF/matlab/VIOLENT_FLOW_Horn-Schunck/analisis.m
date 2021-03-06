

function [acc, sd, auc, fpr, tpr, model] =  analisis(data_fights, data_nofights)

    [a, b] = size(data_fights);
    [c, d] = size(data_nofights);

    X               = [data_fights; data_nofights];

    Y_fights    = ones(a,1);
    Y_nofights  = zeros(c,1);
    %Y_nofights  = Y_nofights-1;

    %Y_fights = cell(a, 1);
    %Y_fights(:) = {'fights'};
    %Y_nofights = cell(c, 1);
    %Y_nofights(:) = {'nofights'};

    Y = [Y_fights; Y_nofights];


    k=10;

    %YPerFold = cell(k,1);                   %Guarda el Y de cada fold
    %scorePerFold = cell(k,1);               %Guarda la salida del clasificador por cada fold

    cvFolds = crossvalind('Kfold', Y, k);   %# get indices of 10-fold CV

    cp = classperf(Y); 

    CorrectR = [];
    AUC_array = [];

    Y_all = [];
    pred_all = []; 

    models = cell(k);

    for i = 1:k                                  %# for each fold
        testIdx = (cvFolds == i);                %# get indices of test instances
        trainIdx = ~testIdx;                     %# get indices training instances

        options.MaxIter = 1000000;
        svmModel = svmtrain(X(trainIdx,:), Y(trainIdx), 'Options', options, 'kernel_function', 'polynomial', 'polyorder', 2);
        %svmModel = svmtrain(X(trainIdx,:), Y(trainIdx), 'Options', options);
        models{i} = svmModel;
        %svmModel = svmtrain(X(trainIdx,:), Y(trainIdx));

        %# test using test instances
        pred = svmclassify(svmModel, X(testIdx,:));

        %YPerFold{i} = Y(testIdx,:);
        %scorePerFold{i} = pred;

        Y_all = [ Y_all; Y(testIdx,:) ]; %guardamos todos los Y
        pred_all = [ pred_all; pred ]; %guardamos todas las pedicciones de los modelos

        CorrectR  = [ CorrectR;  sum(Y(testIdx,:) == pred) / length(Y(testIdx,:)) ];
        %CorrectR  = [ CorrectR;  sum(  strcmp( Y(testIdx,:), pred )   ) / length(Y(testIdx,:)) ];

        classperf(cp, pred, testIdx); % se incluye esto xq se quiere validar que classperf.corectrate es lo mismo que nuestro corerct rate calculado

    end

    %[FPR, TPR, Thr, AUC, OPTROCPT]  = perfcurve(Y(testIdx,:), pred, 1);
    %[FPR, TPR, Thr, AUC, OPTROCPT]  = perfcurve(Y_all, pred_all, 1); %procesamos, esto genera un AUC igual al accuracy

    %buscamos el mejor modelo para procsar el auc y roc
    [max_acc, idx] = max(CorrectR);
    max_model = models{idx};
    testIdx = (cvFolds == idx);  
    pred = svmclassify(max_model, X(testIdx,:));
    [FPR, TPR, Thr, AUC, OPTROCPT]  = perfcurve(Y(testIdx,:), pred, 1);
    %pred = svmclassify(max_model, X);
    %[FPR, TPR, Thr, AUC, OPTROCPT]  = perfcurve(Y, pred, 1);
    %plot(FPR, TPR);
    %xlabel('False positive rate'); ylabel('True positive rate')
    %title('ROC for classification SVM')

    auc = AUC;
    acc = mean(CorrectR);
    %acc = max_acc;
    sd = std(CorrectR);
    fpr = FPR;
    tpr = TPR;
    model = max_model;
    %acc_cp = cp.CorrectRate

end

