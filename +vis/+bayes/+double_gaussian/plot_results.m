function plot_results(output_struct)
% PLOT_RESULTS - plot the results of double gaussian Bayesian parameter estimation
% 
% PLOT_RESULTS(OUTPUT_STRUCT)
%
% 
%
%
%


 % marginals
figure;

marg = sort(fieldnames(output_struct.marginal_likelihoods));

for i=1:5,
    subplot(4,3,i);
    s = getfield(output_struct.marginal_likelihoods,marg{i});
    plot(s.values,s.likelihoods);
    ylabel('Likelihood');
    xlabel(marg{i});
    box off;
end;

v = {'oi','di','cv','dir_cv'};

for i=1:4,
    subplot(4,3,6+i);
    s = getfield(output_struct.descriptors,v{i});
    plot(s.values,s.likelihoods);
    ylabel('Likelihood');
    xlabel(v{i},'interp','none');
    box off;
end;


