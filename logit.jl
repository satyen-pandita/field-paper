include("initialize.jl")
include("basic_functions.jl")

# Lm_work, Lf_work, HPm_work, HPf_work, Lm_nowork, Lf_nowork, HPm_nowork, HPf_nowork, Empm_n, Empf_n, Empm_s, Empf_s
TARGET_MOMENT_3 = [0.319, 0.250, 0.052, 0.350, 0.795, 0.386, 0.120, 0.596, 0.935, 0.134, 0.959, 0.238]

# For a given HH_Type, (wm, wf, north), calculates 
# probability that hh i will choose an action j 
# enumerated as (dm, df, lm, lf, hpm, hpf) 
function prob_actions_hh(prim::Primitives, smm_params::smm_parameters,
                      hh_type::HH_Type)
    @unpack_Primitives prim
    @unpack_smm_parameters smm_params
    @unpack_HH_Type hh_type
    # All possible actions
    actions = action_set(prim, smm_params);
    nactions = length(actions);
    # For each of these actions, calculate income, home production 
    # Consumption and finally, utilities 
    incomes = [wm*actions[i][1]*hm + wf*actions[i][2]*hf for i in 1:nactions]
    homeProds = [H(prim, smm_params, actions[i][5], actions[i][6], incomes[i]) for i in 1:nactions]
    conss = [c(prim, incomes[i], homeProds[i]) for i in 1:nactions]
    utils = [u(prim, smm_params, hh_type, conss[i], 
             actions[i][3], actions[i][4], actions[i][6], homeProds[i]) for i in 1:nactions]
    # Exponentiate Utilities 
    exp_utils = [exp(util) for util in utils]
    if sum(exp_utils) == 0

        probs = zeros(nactions)
        # If all probs are 0, then return p = 1 on action where leisure is 1
        act_rest = findfirst(==([0.0,0.0,1.0,1.0,0.0,0.0]), actions)
        probs[act_rest] = 1.0
    else 

        # Find probability of each action 
        probs = [e/(sum(exp_utils)) for e in exp_utils]
    end
    return probs
end

# Draw N draws from the prob distribution obtained from prob_actions_hh for each HH
function action_idx_hh(prim::Primitives, smm_params::smm_parameters,
    hh_type::HH_Type, N::Int64=500)
    @unpack_Primitives prim
    @unpack_smm_parameters smm_params
    @unpack_HH_Type hh_type
    # All possible actions
    actions = action_set(prim, smm_params);
    nactions = length(actions);
    probs = prob_actions_hh(prim, smm_params, hh_type);
    return sort(sample(collect(range(1,nactions)), Weights(probs), N))
end

# For each HH, generates averages/variances for employment and time allocation 
function gen_mean_var_by_hh(prim::Primitives, smm_params::smm_parameters,
                            sc_active::Bool)
    @unpack_Primitives prim
    @unpack_smm_parameters smm_params
    
    wage_types, north_hh_types, south_hh_types = HH_types(prim, smm_params, sc_active)
    
    # wm, wf, north, sc
    hh_types = vcat(north_hh_types, south_hh_types)

    N_hh = length(hh_types);
    actions = action_set(prim, smm_params)
    # Stores moments for lm, lf, hpm, hpf for working HHs
    tmoms_work = [(zeros(4), zeros(4)) for _ in 1:N_hh]
    # Stores moments for lm, lf, hpm, hpf for non-working HHs
    tmoms_nowork = [(zeros(4), zeros(4)) for _ in 1:N_hh]
    # Stores moments for employment for all HHs
    moms_emp = [(zeros(2), zeros(2)) for _ in 1:N_hh]
    # Need to find the indices where both work and where both don't work
    # which are later used to subset actions 
    both_working_min = findfirst(==(1), [actions[i][1]*actions[i][2] for i in eachindex(actions)])
    both_notworking_max = findlast(==(0), [actions[i][1]+actions[i][2] for i in eachindex(actions)])
    Threads.@threads for i in 1:N_hh
        
        (wm, wf, loc, sc) = hh_types[i]
        hh = HH_Type(wm, wf, loc, sc)
        # What are the indices of actions drawn for this HH
        actions_idxs = action_idx_hh(prim, smm_params, hh)
        # What are the actions drawn for this HH
        actions_hh = actions[actions_idxs]
        # Calculate avg employment
        emp_hh = [actions_hh[j][1:2] for j in eachindex(actions_hh)]
        emp_hh = hcat(emp_hh...)
        
        m,v = mean_and_var(emp_hh, Weights(ones(eachindex(actions_hh))), 2)
        moms_emp[i] = (vec(m), vec(v))
        # Calculating time moments for working couples and not working couples 
        # Get indices where both work/don't work 
        time_hh = [actions_hh[j][3:6] for j in eachindex(actions_hh)]
        both_working_idxs = actions_idxs[actions_idxs .>= both_working_min]

        both_notworking_idxs = actions_idxs[actions_idxs .<= both_notworking_max]
        # Have to check whether it is empty or not. 
        # If there is only one index, var is vacuously 0. So including that too.
        if length(both_working_idxs) <= 1
            tmoms_work[i] = (-99*ones(4), -99*ones(4))
        else
            actions_bothworking = actions[both_working_idxs]
            time_bothwork_hh = [actions_bothworking[j][3:6] for j in eachindex(actions_bothworking)]
            time_bothwork_hh = hcat(time_bothwork_hh...)
            m,v = mean_and_var(time_bothwork_hh, Weights(ones(eachindex(actions_bothworking))), 2)
            tmoms_work[i] = (vec(m), vec(v))
        end
        if length(both_notworking_idxs) <= 1
            tmoms_nowork[i] = (-99*ones(4),-99*ones(4))
        else
            actions_bothnotworking = actions[both_notworking_idxs]
            time_bothnotwork_hh = [actions_bothnotworking[j][3:6] for j in eachindex(actions_bothnotworking)]
            time_bothnotwork_hh = hcat(time_bothnotwork_hh...)
            m,v = mean_and_var(time_bothnotwork_hh, Weights(ones(eachindex(actions_bothnotworking))), 2)
            tmoms_nowork[i] = (vec(m), vec(v))
        end        
    end
    return moms_emp, tmoms_work, tmoms_nowork
end

function gen_moments_by_hh(prim::Primitives, smm_params::smm_parameters,
                            sc_active::Bool=true)
    @unpack_Primitives prim
    @unpack_smm_parameters smm_params
    wage_types, north_hh_types, south_hh_types = HH_types(prim, smm_params, sc_active)

    # wm, wf, north, sc
    hh_types = vcat(north_hh_types, south_hh_types)

    N_hh = length(hh_types);
    actions = action_set(prim, smm_params)
    # Stores moments for lm, lf, hpm, hpf for working HHs
    tmoms_work = [(zeros(4), zeros(4)) for _ in 1:N_hh]
    # Stores moments for lm, lf, hpm, hpf for non-working HHs
    tmoms_nowork = [(zeros(4), zeros(4)) for _ in 1:N_hh]
    # Stores moments for employment for all HHs
    moms_emp = [(zeros(2), zeros(2)) for _ in 1:N_hh] 
    both_working_min = findfirst(==(1), [actions[i][1]*actions[i][2] for i in eachindex(actions)])
    both_notworking_max = findlast(==(0), [actions[i][1]+actions[i][2] for i in eachindex(actions)])
    Threads.@threads for i in 1:N_hh
        (wm, wf, loc, sc) = hh_types[i]
        hh = HH_Type(wm, wf, loc, sc)
        # What are the indices of actions drawn for this HH
        actions_idxs = action_idx_hh(prim, smm_params, hh)
        # What are the actions drawn for this HH
        actions_hh = actions[actions_idxs]
        # Calculate employment moments
        # Emp moment condition different for North and South 
        if i <= N_hh/2
            emp_mom_hh = [(actions_hh[j][1:2]-TARGET_MOMENT_3[9:10]) for j in eachindex(actions_hh)]
            emp_mom_hh = hcat(emp_mom_hh...)
            m,v = mean_and_var(emp_mom_hh, Weights(ones(eachindex(actions_hh))), 2)
        else
            emp_mom_hh = [(actions_hh[j][1:2]-TARGET_MOMENT_3[11:12]) for j in eachindex(actions_hh)]
            emp_mom_hh = hcat(emp_mom_hh...)
            m,v = mean_and_var(emp_mom_hh, Weights(ones(eachindex(actions_hh))), 2)
        end
        moms_emp[i] = (vec(m), vec(v))
        # Calculating time moments for working couples and not working couples 
        # Get indices where both work/don't work 
        time_hh = [actions_hh[j][3:6] for j in eachindex(actions_hh)]
        both_working_idxs = actions_idxs[actions_idxs .>= both_working_min]
        both_notworking_idxs = actions_idxs[actions_idxs .<= both_notworking_max]
        # Have to check whether it is empty or not 
        if length(both_working_idxs) <= 1
            tmoms_work[i] = (-99*ones(4), -99*ones(4))
        else
            actions_bothworking = actions[both_working_idxs]
            time_bothwork_hh = [(actions_bothworking[j][3:6] - TARGET_MOMENT_3[1:4]) for j in eachindex(actions_bothworking)]
            time_bothwork_hh = hcat(time_bothwork_hh...)
            m,v = mean_and_var(time_bothwork_hh, Weights(ones(eachindex(actions_bothworking))), 2)
            tmoms_work[i] = (vec(m), vec(v))
        end
        if length(both_notworking_idxs) <= 1
            tmoms_nowork[i] = (-99*ones(4),-99*ones(4))
        else
            actions_bothnotworking = actions[both_notworking_idxs]
            time_bothnotwork_hh = [(actions_bothnotworking[j][3:6] - TARGET_MOMENT_3[5:8]) for j in eachindex(actions_bothnotworking)]
            time_bothnotwork_hh = hcat(time_bothnotwork_hh...)
            m,v = mean_and_var(time_bothnotwork_hh, Weights(ones(eachindex(actions_bothnotworking))), 2)
            tmoms_nowork[i] = (vec(m), vec(v))
        end        
    end
    return moms_emp, tmoms_work, tmoms_nowork
end

