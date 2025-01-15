include("moments.jl")

function multiple_starts(n::Int64, sc_active::Bool, home_prod::Bool, max_iter::Int64=200)
    Min_y = 1e15*ones(n)
    if sc_active
        nmoms = 4 
    else 
        nmoms = 2
    end
    Min_x = zeros(n,nmoms)

    for i in 1:n
        N = rand(1:100)
        A_m = Float64(rand(1:N))
        A_f = Float64(rand(1:N))
        sc_south = 0.001
        sc_north = Float64(rand(1:20))
        # To avoid eta_m + eta_f > 1
        total = rand()
        eta_m = rand(Uniform(0.001, total - 0.001))
        eta_f = total - eta_m
        if sc_active
            if home_prod
                init = [A_m, A_f, sc_north, sc_south]
                η_m, η_f = 1/3, 1/3
            else
                init = [eta_m, eta_f, sc_north, sc_south]
                A_m, A_f = 1., 1.
            end
        else
            if home_prod
                init = [A_m, A_f]
            else
                init = [eta_m, eta_f]
            end
        end
        optim_f = guess -> optim_func(guess, sc_active, home_prod)
        # init = [0.4674, 0.00393, 9.92663, 0.04971]
        opt = optimize(optim_f, init, NelderMead(), Optim.Options(iterations=max_iter, show_trace=true, show_every=1))
        Min_y[i] = opt.minimum
        Min_x[i,:] = opt.minimizer
        @show i    
    end
    return Min_x, Min_y
end

function optimum_w_optimal_weights(n::Int64, sc_active::Bool, home_prod::Bool, max_iter::Int64=200)
    Min_x, Min_y = multiple_starts(n, sc_active, home_prod, max_iter);
    idx = findall(==(minimum(Min_y)), Min_y)
    x_min = Min_x[idx,:]
    prim, smm_params = Initialize(vec(x_min), sc_active, home_prod);
    emp_mean_dict, emp_var_dict, time_alloc_mean_dict, time_alloc_var_dict = gen_moments(prim, smm_params, sc_active);
    var_vec = vcat(time_alloc_var_dict["work"], emp_var_dict["North"], emp_var_dict["South"])
    optim_f = guess -> optim_func_w_optimal_weights(guess, var_vec, sc_active, home_prod)
    opt = optimize(optim_f, vec(x_min), NelderMead(), Optim.Options(iterations=max_iter, show_trace=true, show_every=1))
    Min_x_f, Min_y_f = opt.minimizer, opt.minimum
    return Min_x_f, Min_y_f
end

# Save the results in a dictionary
res = Dict()
for sc in [true, false], home in [true]
    Min_x_f, Min_y_f = optimum_w_optimal_weights(20, sc, home, 200)
    res[(sc, home)] = (Min_x_f, Min_y_f)
end

using Dates 
ts = Dates.format(now(), "yyyy_mm_dd_HH_MM")
fname = "results_mu_$ts.jls"
# Output to a file
open(fname, "w+") do f
    serialize(f, res)
end


