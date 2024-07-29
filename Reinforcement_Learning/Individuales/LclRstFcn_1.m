function in = LclRstFcn_1(in)
% randomice input

% Angulo deseado
block_path = sprintf("RL_TF_SS/Desired_Voltage");
lower_bound = 3;
upper_bound = 4;
% generate random numbers
vg = (upper_bound - lower_bound)*rand + lower_bound;
in = setBlockParameter(in, block_path, Value = num2str(vg));
end