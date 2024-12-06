function b = compare(output_struct1, output_struct2)
% COMPARE - compare the output of two Bayesian parameter estimations for doublegaussian
%
% B = COMPARE(OUTPUT_STRUCT1, OUTPUT_STRUCT2)
%
% Compare two output_struct variables from grid_proportional_noise.
%
% B is 1 if the matches are within tolerance; otherwise an error is triggered.
%

b = 1;

marg = sort(fieldnames(output_struct1.marginal_likelihoods));

for i=1:numel(marg),
	s1 = getfield(output_struct1.marginal_likelihoods,marg{i});
	s2 = getfield(output_struct2.marginal_likelihoods,marg{i});
	mx = max(s1.likelihoods(:)-s2.likelihoods(:));
	assert(mx<0.001,['Data in ' marg{i} ' exceeds tolerance (0.001): ' num2str(mx) '.']);
end;

v = {'cv','dir_cv','oi','di'};

for i=1:4,
	s1 = getfield(output_struct1.descriptors,v{i});
	s2 = getfield(output_struct2.descriptors,v{i});
	mx = max(s1.likelihoods(:) - s2.likelihoods(:));
	assert(mx<0.001,['Data in ' v{i} ' exceeds tolerance (0.001): ' num2str(mx) '.']);
end;

