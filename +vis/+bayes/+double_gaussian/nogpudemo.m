function [output_struct,lik,debug] = nogpudemo()

rsp_values = logspace(log10(0.1),log10(40),40);
rp_values = logspace(log10(0.1),log10(150),100);
alpha_values = 0:0.05:1;
thetap_values = 0:1:359;
sig_values = 10:5:90;

noise_model = [1.3549 1.9182 0.5461];

angles = [ 0:30:360-30 ];
P = [ 0.5 10 5 45 30 ];
resps = vis.oridir.doublegaussianfunc(angles,P);

param_grid = struct('Rsp',rsp_values,...
    'Rp',rp_values,...
    'Alpha',alpha_values,...
    'Op',thetap_values,...
    'Sig',sig_values);

resp_struct = struct('angles',angles(:),...
    'mean_responses',resps(:),...
    'num_trials',5*ones(size(resps(:))));

[output_struct,lik] = vis.bayes.double_gaussian.grid_proportional_noise(param_grid, resp_struct, noise_model);



