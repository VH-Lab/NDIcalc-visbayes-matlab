function lik = nakarushton_gpudemo()


r100_values = 1:150;
c50_values = 0.05:0.05:1;
n_values = 0:0.1:6;
s_values = 1:0.1:2; % derived from 1.7 boundary in Peirce 2007
noise_model = single([ 0.25 0.73 5]);

contrasts = [ 0:0.1:10 ];
resps = 10 .*contrasts./(0.5+contrasts);

funcName = 'nakaRushtonProportionalNoiseLog';
here = which('vis.bayes.naka_rushton.nakarushton_gpudemo');
[parent,me] = fileparts(here);
kernel = fileread(fullfile(parent,'nakarushtonproportionalnoise.mtl'));


lik = zeros(numel(r100_values)*numel(c50_values)*numel(n_values)*numel(s_values),1,'single');
contrast_and_response = single([numel(contrasts) ; contrasts(:); resps(:)]);
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
bufferAnswers = MetalBuffer(device,answers);

MetalCallKernel(funcName,{bufferLik,bufferContrastAndResponse,bufferGrid,bufferNoiseModel,bufferAnswers},kernel);

lik = single(bufferLik);
lik = reshape(lik,numel(r100_values),numel(c50_values),numel(n_values),numel(s_values));


