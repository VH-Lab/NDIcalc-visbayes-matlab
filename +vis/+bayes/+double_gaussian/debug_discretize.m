function hist_index = debug_discretize(oi,di,cv,dcv,oi_bins,di_bins,cv_bins,dcv_bins)

oi_index = discretize(oi,oi_bins);
di_index = discretize(di,di_bins);
cv_index = discretize(cv,cv_bins);
dcv_index = discretize(dcv,dcv_bins);

oi_index(isnan(oi_index)) = numel(oi_bins)+1;

hist_index = sub2ind(1+[numel(oi_bins) numel(di_bins) numel(cv_bins) numel(dcv_bins)],oi_index,di_index,cv_index,dcv_index);


