include("logit.jl")

#= 

This file evaluates simulated moments to be matched with data moments later. 
Moments needed: 
1. Mean leisure, m & f
2. Mean Home Prod., m & f 
3. Employment rates
4. HH Distributions
=# 

function HH_weights(prim::Primitives, smm_params::smm_parameters,
                    sc_active::Bool)
    #=
    Each individual is indexed by their wage and stigma cost. This wage comes from a different
    distribution depending on whether you are college educated, or not, 
    and whether you are from the North/South. 
    `logit.jl` already gives me optimal choices for each wage type and location type. 
        In this function, I calculate their appropriate weight: 
            P(wm,wf|loc)*P(sc|loc) = P(wm|loc,em)*P(wf|loc,ef)*P(em,ef|loc)*P(sc|loc). 
    =#
    @unpack_Primitives prim 
    @unpack_smm_parameters smm_params
    
    wage_types, north_hh_types, south_hh_types = HH_types(prim, smm_params, sc_active)

    nw = length(wage_types)
    # no. of HHs in North/South: same length for both
    N_HH = length(north_hh_types)
    HH_wts = Dict("North" => zeros(N_HH), "South" => zeros(N_HH))
    # This will store HH weights for All India
    HH_wts_arr = zeros(2*N_HH)
    for loc in ["North", "South"]
        # For a given location, what are the HH weights 
        # for each (wm,wf) 
        wage_wt_loc = zeros(nw)
        # In a given location, fix education type of man and woman 
        for em in ["Col", "NoCol"], ef in ["Col", "NoCol"]
            mm, sm = MM[loc][em]
            mf, sf = MF[loc][ef]
            # What are the weights associated with each wage 
            # given education types and location 
            wage_wts_m = pdf.(Normal(mm,sm), wage_grids[1])
            wage_wts_f = pdf.(Normal(mf,sf), wage_grids[2])
            wage_wt_tuples = vec(Iterators.product(wage_wts_m, wage_wts_f) |> collect)
            # This contains: P(wm|em,loc)*P(wf|ef,loc)
            wage_wts = [wt[1]*wt[2] for wt in wage_wt_tuples]
            # P(wm,wf|loc) = ∑_{em,ef} P(wm,wf|em,ef,loc)*P(em,ef|loc)
            #              = ∑_{em,ef} P(wm|em,loc)*P(wf|ef,loc)*P(em,ef|loc)
            hh_wt = HH_wts_col[em][ef].*wage_wts
            wage_wt_loc += hh_wt
        end
        # wage_wt_loc: contains wage weights for each type of wage couple 
        # 3 types of SC HHs - 0, sc, ∞
        # vcat(wage_wt_loc*sc_weight)
        if sc_active
            HH_wts[loc] = vcat(wage_wt_loc*HH_wts_stigma[loc][1],
                                wage_wt_loc*HH_wts_stigma[loc][2],
                                wage_wt_loc*HH_wts_stigma[loc][3])
        else
            HH_wts[loc] = wage_wt_loc
        end
    end
    HH_wts_arr[1:N_HH] = prop_north.*HH_wts["North"]
    HH_wts_arr[N_HH+1:2*N_HH] = (1-prop_north).*HH_wts["South"]
    return HH_wts, HH_wts_arr
end

# Calculates Mean and Variance of the moment conditions
function gen_moments(prim::Primitives, smm_params::smm_parameters,
                     sc_active::Bool)
    @unpack_Primitives prim 
    @unpack_smm_parameters smm_params
    
    wage_types, north_hh_types, south_hh_types = HH_types(prim, smm_params, sc_active)

    # Number of HHs on each side of the border 
    N_HH = length(north_hh_types)
    # HH weights by location, and w/o location 
    hh_wts_dict, hh_wts_arr = HH_weights(prim, smm_params, sc_active);
    # Moment conditions by wage type/HH type 
    moms_emp, tmoms_work, tmoms_nowork = gen_moments_by_hh(prim, smm_params, sc_active)
    
    ## Aggregating employment moments weighing each by their HH weight
    # Dicts contain (mean, var) from moms_emp for North and South 
    mean_emp_dict = Dict("North" => [moms_emp[i][1] for i in 1:N_HH], "South" => [moms_emp[i][1] for i in N_HH+1:2*N_HH])
    var_emp_dict = Dict("North" => [moms_emp[i][2] for i in 1:N_HH], "South" => [moms_emp[i][2] for i in N_HH+1:2*N_HH])
    
    # Store the final results 
    emp_mean_dict = Dict("North" => zeros(2), "South" => zeros(2))
    emp_var_dict = Dict("North" => zeros(2), "South" => zeros(2))

    for loc in ["North", "South"]
        # mean, and variance of mean 
        m,v_m = mean_and_var(hcat(mean_emp_dict[loc]...), Weights(hh_wts_dict[loc]),2)
        emp_mean_dict[loc] = vec(m) 
        emp_var_dict[loc] .+= vec(v_m) 
        # mean of variance 
        m_v = mean(var_emp_dict[loc], Weights(hh_wts_dict[loc]))
        emp_var_dict[loc] .+= m_v  
    end
    ## Aggregating time allocation moments weighing each by their HH weight 
    # First I need to drop those HHs where I have moments = -99. Essentially, 
    # there were wage tuples (HHs) where I did not observe ever both working 
    # or both not work. Ex: P(both work|wm<0,wf<0) = 0.
    w_miss_idx = findall(y -> all(==(-99), y), [tmoms_work[i][1] for i in eachindex(tmoms_work)])
    nw_miss_idx = findall(y -> all(==(-99), y), [tmoms_nowork[i][1] for i in eachindex(tmoms_nowork)])
    # Use only the remaining 
    w_idx = setdiff(eachindex(tmoms_work), w_miss_idx)
    nw_idx = setdiff(eachindex(tmoms_nowork), nw_miss_idx)
    # Stores time alloc. m,v weighted by wage weights.
    time_alloc_mean_dict = Dict("work" => zeros(4), "no_work" => zeros(4))
    time_alloc_var_dict = Dict("work" => zeros(4), "no_work" => zeros(4))

    
    ## For when both work 
    # Need only moments (and weights) where they are not -99
    m_w_arr = [tmoms_work[i][1] for i in w_idx]
    m_w, v_w = mean_and_var(hcat(m_w_arr...), Weights(hh_wts_arr[w_idx]),2)
    time_alloc_mean_dict["work"] = vec(m_w) 
    time_alloc_var_dict["work"] .+= vec(v_w)
    m_vw = mean([tmoms_work[i][2] for i in w_idx], Weights(hh_wts_arr[w_idx])) 
    time_alloc_var_dict["work"] .+= m_vw

    ## For when both don't work 
    # Need only moments (and weights) where they are not -99
    m_nw_arr = [tmoms_nowork[i][1] for i in nw_idx]
    m_n, v_n = mean_and_var(hcat(m_nw_arr...), Weights(hh_wts_arr[nw_idx]),2)
    time_alloc_mean_dict["no_work"] = vec(m_n) 
    time_alloc_var_dict["no_work"] .+= vec(v_n)
    m_vn = mean([tmoms_nowork[i][2] for i in nw_idx], Weights(hh_wts_arr[nw_idx]))
    time_alloc_var_dict["no_work"] .+= m_vn
    return emp_mean_dict, emp_var_dict, time_alloc_mean_dict, time_alloc_var_dict
end


function gen_means(prim::Primitives, smm_params::smm_parameters, sc_active::Bool)
    @unpack_Primitives prim 
    @unpack_smm_parameters smm_params
    # HH weights 
    hh_wts_dict, hh_wts_arr = HH_weights(prim, smm_params, sc_active)
    wage_types, north_hh_types, south_hh_types = HH_types(prim, smm_params, sc_active)
    # nwage_hh = length(wage_types)
    N_HH = length(north_hh_types)
    moms_emp, tmoms_work, tmoms_nowork = gen_mean_var_by_hh(prim, smm_params, sc_active)
    # Store final employment means 
    emp = Dict("North" => zeros(2), "South" => zeros(2))
    # Dict containing mean from moms_emp for North and South 
    mean_emp_dict = Dict("North" => [moms_emp[i][1] for i in 1:N_HH], "South" => [moms_emp[i][1] for i in N_HH+1:2*N_HH])
    for loc in ["North", "South"]
        emp[loc] = mean(mean_emp_dict[loc], Weights(hh_wts_dict[loc]))
    end    
    # Store finall time allocation 
    time_alloc = Dict("work" => zeros(4), "no_work" => zeros(4))

    # Removing (as before) indices that have -99 in them.
    w_miss_idx = findall(y -> all(==(-99), y), [tmoms_work[i][1] for i in eachindex(tmoms_work)])
    nw_miss_idx = findall(y -> all(==(-99), y), [tmoms_nowork[i][1] for i in eachindex(tmoms_nowork)])
    # Use only the remaining 
    w_idx = setdiff(eachindex(tmoms_work), w_miss_idx)
    nw_idx = setdiff(eachindex(tmoms_nowork), nw_miss_idx)
    m_w_arr = [tmoms_work[i][1] for i in w_idx]
    m_nw_arr = [tmoms_nowork[i][1] for i in nw_idx]
    time_alloc["work"] = mean(m_w_arr, Weights(hh_wts_arr[w_idx]))
    time_alloc["no_work"] = mean(m_nw_arr, Weights(hh_wts_arr[nw_idx]))
    return emp, time_alloc
end


function optim_func(guess::Vector{Float64}, 
                    sc_active::Bool, home_prod::Bool, eta_vec::Vector{Float64})
    if minimum(guess) < 0 
        return 1e15
    end
    prim, smm_params = Initialize(guess, sc_active, home_prod, eta_vec)
    emp_mean_dict, emp_var_dict, time_alloc_mean_dict, time_alloc_var_dict = gen_moments(prim, smm_params, sc_active);    
    mean_vec = vcat(time_alloc_mean_dict["work"], emp_mean_dict["North"], emp_mean_dict["South"])
    err = sum(mean_vec.^2)
    return err
end

function optim_func_w_optimal_weights(guess::Vector{Float64}, var::Vector{Float64}, 
                                      sc_active::Bool, home_prod::Bool, eta_vec::Vector{Float64})
    if minimum(guess) < 0 
        return 1e15
    end
    prim, smm_params = Initialize(guess, sc_active, home_prod, eta_vec)
    emp_mean_dict, emp_var_dict, time_alloc_mean_dict, time_alloc_var_dict = gen_moments(prim, smm_params, sc_active);
    
    mean_vec = vcat(time_alloc_mean_dict["work"], emp_mean_dict["North"], emp_mean_dict["South"])
    err = sum(1 ./var.*mean_vec.^2)
    return err 
end

#=
function HH_dist(prim::Primitives, smm_params::smm_parameters)
    @unpack_Primitives prim 
    @unpack_smm_parameters smm_params
    # HH weights 
    hh_wts_dict, hh_wts_arr = HH_weights(prim, smm_params)
    nwage_hh = length(wage_types)
    moms_emp, tmoms_work, tmoms_nowork = gen_mean_var_by_wage(prim, smm_params)


end

# TODO: NEEDS UPDATIONS - AM I THINKING ABOUT ELASTICITY RIGHT?
function lab_e(prim::Primitives, smm_params::smm_parameters, 
               init_guess::Vector{Float64}, sc_active::Bool, n_iter::Int64=30; male, loc)
    emp_i_dict, time_alloc_i_dict = gen_means(prim, smm_params)
    # emp_f = 0.0 
    e = zeros(n_iter) 
    prim, smm_params = Initialize(init_guess, sc_active)
    if male
        emp_i = emp_i_dict[loc][1] 
        Threads.@threads for i in 1:n_iter
            prim.MM[loc]["Col"][1] += 0.01*prim.MM[loc]["Col"][1]
            prim.MM[loc]["NoCol"][1] += 0.01*prim.MM[loc]["NoCol"][1]                
            emp_f_dict, time_alloc_f_dict = gen_means(prim, smm_params)
            emp_f = emp_f_dict[loc][1]
            e[i] = ((emp_f-emp_i)/(emp_i))*100
            # @show emp_i
            prim, smm_params = Initialize(init_guess, sc_active)
        end 
    else 
        emp_i = emp_i_dict[loc][2]
        Threads.@threads for i in 1:n_iter
            prim.MF[loc]["Col"][1] += 0.01*prim.MF[loc]["Col"][1]
            prim.MF[loc]["NoCol"][1] += 0.01*prim.MF[loc]["NoCol"][1] 
            emp_f_dict, time_alloc_f_dict = gen_means(prim, smm_params)
            emp_f = emp_f_dict[loc][2]
            e[i] = ((emp_f-emp_i)/(emp_i))*100
            # @show emp_i
            prim, smm_params = Initialize(init_guess, sc_active)
        end
    end
    return e
end

=#
