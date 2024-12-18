include("moments.jl")

function multiple_starts(n::Int64, sc_active)
    Min_y = 1e15*ones(n)
    if sc_active
        nmoms = 4 
    else 
        nmoms = 2
    end
    Min_x = zeros(n,nmoms)

    for i in 1:n
        N = rand(1:100)
        # A_m = Float64(rand(1:N))
        # A_f = Float64(rand(1:N))
        sc_south = 0.001
        sc_north = Float64(rand(1:20))
        eta_m = rand()
        eta_f = rand()
        # init = [A_m, A_f, 1/3, 1/3]
        if sc_active
            init = [eta_m, eta_f, sc_north, sc_south]
            # init = [A_m, A_f, eta_m, eta_f, sc_north, sc_south]
        else
            # init = [A_m, A_f]
            init = [eta_m, eta_f]
        end
        optim_f = guess -> optim_func_w(guess, sc_active)
        init = [0.4674, 0.00393, 9.92663, 0.04971]
        opt = optimize(optim_f, init, NelderMead(), Optim.Options(show_trace=true, show_every=1, iterations=200))
        Min_y[i] = opt.minimum
        Min_x[i,:] = opt.minimizer
        @show i    
    end
    return Min_x, Min_y
end

sc_active=false 
Min_x, Min_y = multiple_starts(20, sc_active);
idx = findall(==(minimum(res["Y"])), res["Y"])
y_min = res["Y"][idx]
x_min = res["X"][idx,:]
prim, smm_params = Initialize(vec(x_min), sc_active);
# Generate var-covar matrix 
emp_mean_dict, emp_var_dict, time_alloc_mean_dict, time_alloc_var_dict = gen_moments(prim, smm_params, sc_active);
var_vec = vcat(time_alloc_var_dict["work"], emp_var_dict["North"], emp_var_dict["South"])
# Use optimal weighting matrix to compute minima again 
optim_f = guess -> optim_func_w_optimal_weights(guess, var_vec, sc_active)
opt = optimize(optim_f, vec(x_min), NelderMead(), Optim.Options(show_trace=true, show_every=1, iterations=250))
Min_x, Min_y = opt.minimizer, opt.minimum


sc_active=true
Min_x_sc, Min_y_sc = multiple_starts(20, sc_active);
idx = findall(==(minimum(res["Y_sc"])), res["Y_sc"])
y_min_sc = res["Y_sc"][idx]
x_min_sc = res["X_sc"][idx,:]
prim, smm_params = Initialize(vec(x_min_sc), sc_active);
emp_mean_dict, emp_var_dict, time_alloc_mean_dict, time_alloc_var_dict = gen_moments(prim, smm_params, sc_active);
var_vec = vcat(time_alloc_var_dict["work"], emp_var_dict["North"], emp_var_dict["South"]);
optim_f = guess -> optim_func_w_optimal_weights(guess, var_vec, sc_active)
opt = optimize(optim_f, vec(x_min), NelderMead(), Optim.Options(show_trace=true, show_every=1, iterations=250))
Min_x_sc, Min_y_sc = opt.minimizer, opt.minimum



# results = Dict("X" => Min_x, "Y" => Min_y, "X_sc" => Min_x_sc, "Y_sc" => Min_y_sc)

# print(results)

# open("results.jls", "w+") do f
#     serialize(f, results)
# end


