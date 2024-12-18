include("moments.jl");

res = deserialize("results_20_wo_nowork.jls");

idx = findall(==(minimum(res["Y"])), res["Y"])
y_min = res["Y"][idx]
x_min = res["X"][idx,:]
sc_active = false 
prim, smm_params = Initialize(vec(x_min), sc_active);

# x_min = [0.516637, 0.0005]
# Obtain var-covar matrix: 
emp_mean_dict, emp_var_dict, time_alloc_mean_dict, time_alloc_var_dict = gen_moments(prim, smm_params, sc_active);
var_vec = vcat(time_alloc_var_dict["work"], emp_var_dict["North"], emp_var_dict["South"])
optim_f = guess -> optim_func_w_optimal_weights(guess, var_vec, sc_active)
opt = optimize(optim_f, vec(x_min), NelderMead(), Optim.Options(show_trace=true, show_every=1, iterations=250))

x_min = [0.246653, 0.011957]
prim, smm_params = Initialize(x_min, sc_active)
gen_means(prim, smm_params, sc_active)


sc_active=true
idx = findall(==(minimum(res["Y_sc"])), res["Y_sc"])
y_min_sc = res["Y_sc"][idx]
x_min_sc = res["X_sc"][idx,:]
prim, smm_params = Initialize(vec(x_min_sc), sc_active);

# Obtain var-covar matrix: 
emp_mean_dict, emp_var_dict, time_alloc_mean_dict, time_alloc_var_dict = gen_moments(prim, smm_params, sc_active);
var_vec = vcat(time_alloc_var_dict["work"], emp_var_dict["North"], emp_var_dict["South"]);
optim_f = guess -> optim_func_w_optimal_weights(guess, var_vec, sc_active)
opt = optimize(optim_f, vec(x_min), NelderMead(), Optim.Options(show_trace=true, show_every=1, iterations=250))

x_min_sc = [0.4674, 0.00393, 9.92663, 0.04971]
# x_min_sc = opt.minimizer
# x_min[1:2] = [0.250171, 0.00313]
prim, smm_params = Initialize(vec(x_min_sc), sc_active);
gen_means(prim, smm_params,sc_active)

# What if sc>0 is muted 
prim.HH_wts_stigma = Dict("North" => [0.80, 0.0, 0.20], "South" => [0.70, 0.0, 0.30])
smm_params.η_m = 1/3 
smm_params.η_f = 1/3 
gen_means(prim, smm_params,sc_active)


### 
sc_active = true 
init = [0.4674, 0.00393, 20.0, 0.0]
prim, smm_params = Initialize(init, sc_active)
gen_means(prim, smm_params, sc_active)


optim_func_w_optimal_weights()