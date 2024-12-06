function [b,errmsg,out] = nakarushton_metalcompare()
% NAKARUSHTON_GPUCAMPARE - test function comparing CPU and GPU output
%
% [B, OUT] = NAKARUSHTON_METALCOMPARE()
% 
% Compares Bayesian analysis using the CPU function 
%   vis.bayes.naka_rushton.grid_proportional_noise() and
%   vis.bayes.naka_rushton.grid_proportional_noise_metal()
%
% B is 1 if the operation is successful. Otherwise, an error is
% thrown with a description.
%
% OUT contains the local variables of the function.
%  

b = 1;
errmsg = '';
out = [];

r100_values = 1:150;
c50_values = 0.05:0.05:1;
n_values = 0:0.1:6;
s_values = 1:0.1:2; % derived from 1.7 boundary in Peirce 2007
noise_model = single([2 1.3549 1.9182 0.5461]);

if 0,
r100_values = 6;
c50_values = 0.05; % 0.25;
n_values = 0; % 1;
s_values = 1;
end;

param_grid.r100 = r100_values;
param_grid.c50 = c50_values;
param_grid.n = n_values;
param_grid.s = s_values;

contrasts = [ 0:0.1:1 ];
resps = 10 .*contrasts./(0.5+contrasts);

resp_struct.contrast = contrasts;
resp_struct.mean_responses = resps;
resp_struct.num_trials = 5*ones(size(resps));

noise_mdl = double(noise_model(2:4));

[output_struct,Lik,debuginfo] = vis.bayes.naka_rushton.grid_proportional_noise(param_grid,resp_struct,noise_mdl);

funcName = 'nakaRushtonProportionalNoiseLog';
here = which('vis.bayes.naka_rushton.nakarushton_gpudemo');
[parent,me] = fileparts(here);
kernel = fileread(fullfile(parent,'nakarushtonproportionalnoise.mtl'));

lik = zeros(numel(r100_values)*numel(c50_values)*numel(n_values)*numel(s_values),1,'single');
ContrastThreshold = zeros(numel(r100_values)*numel(c50_values)*numel(n_values)*numel(s_values),1,'single');
RelativeMaximumGain = zeros(numel(r100_values)*numel(c50_values)*numel(n_values)*numel(s_values),1,'single');
SaturationIndex = zeros(numel(r100_values)*numel(c50_values)*numel(n_values)*numel(s_values),1,'single');
contrast_and_response = single([numel(contrasts) ; contrasts(:); resps(:); resp_struct.num_trials(:)]);
grid = single([numel(r100_values);
	numel(c50_values);
	numel(n_values);
	numel(s_values);
	r100_values(:);
	c50_values(:);
	n_values(:);
	s_values(:)]);

answers = single(zeros(100,1));

metalConfig = MetalConfig;
device = MetalDevice(metalConfig.gpudevice);

bufferLik = MetalBuffer(device,lik);
bufferContrastAndResponse = MetalBuffer(device,contrast_and_response);
bufferGrid = MetalBuffer(device,grid);
bufferNoiseModel = MetalBuffer(device,noise_model);
bufferContrastThreshold = MetalBuffer(device,ContrastThreshold);
bufferRelativeMaximumGain = MetalBuffer(device,RelativeMaximumGain);
bufferSaturationIndex = MetalBuffer(device,SaturationIndex);
bufferAnswers = MetalBuffer(device,answers);

MetalCallKernel(funcName,{bufferLik,bufferContrastAndResponse,bufferGrid,bufferNoiseModel,...
	bufferContrastThreshold,bufferRelativeMaximumGain,bufferSaturationIndex,bufferAnswers},kernel);

lik = single(bufferLik);
lik = reshape(lik,numel(r100_values),numel(c50_values),numel(n_values),numel(s_values));

ContrastThreshold = reshape(single(bufferContrastThreshold),numel(r100_values),numel(c50_values),numel(n_values),numel(s_values));
RelativeMaximumGain = reshape(single(bufferRelativeMaximumGain),numel(r100_values),numel(c50_values),numel(n_values),numel(s_values));
SaturationIndex = reshape(single(bufferSaturationIndex),numel(r100_values),numel(c50_values),numel(n_values),numel(s_values));

answers = single(bufferAnswers);

if nargout > 2,
	out = vlt.data.workspace2struct();
end;

 % check 

lik_prenorm_log10 = log10(debuginfo.Lik_prenorm);
index_isfinite = find(~isinf(lik_prenorm_log10(:)) & ~isinf(lik(:)));
index_isinfinite_prenorm = find(isinf(lik_prenorm_log10(:)) & ~isinf(lik(:)));
index_isinfinite_lik = find(~isinf(lik_prenorm_log10(:)) & isinf(lik(:)));

pctchange = (lik_prenorm_log10(index_isfinite)-lik(index_isfinite))./lik_prenorm_log10(index_isfinite);

if ~max(pctchange<0.001),
    b = 0;
    errmsg = 'Likelihoods do not match.';
end;    

if ~(max(lik_prenorm_log10(index_isinfinite_lik)) < -250),
    b = 0;
    errmsg = 'Likelihoods do not match.';
end;

if ~(max(lik(index_isinfinite_prenorm)) < -50),
    b = 0;
    errmsg = 'Likelihoods do not match.';
end;

ct_thresh_max = max(abs(debuginfo.ContrastThreshold(:)-ContrastThreshold(:)));

if ct_thresh_max > 0.01,
    b = 0;
    errmsg = ['Contrast thresholds do not match.'];
end;


rmg_max = max(abs(debuginfo.RelativeMaximumGain(:)-RelativeMaximumGain(:)));

if b & ~(rmg_max<0.001), % ok
    b = 0;
    errmsg = ['RelativeMaximumGain differs.'];
end;

ind_low = find(abs(debuginfo.SaturationIndex(:)<10));
ind_high = find(abs(debuginfo.SaturationIndex(:)>=10));
sat_max_low = max(abs(debuginfo.SaturationIndex(ind_low)-SaturationIndex(ind_low)));
pctchange = (debuginfo.SaturationIndex(ind_high)-SaturationIndex(ind_high))./debuginfo.SaturationIndex(ind_high);

if ~(sat_max_low<0.001),
    b = 0;
    errmsg = ['SaturationIndex differs.'];
    return;
end;

if ~(max(abs(pctchange))<0.001),
    b = 0;
    errmsg = ['SaturationIndex differs.'];
    return;
end;

