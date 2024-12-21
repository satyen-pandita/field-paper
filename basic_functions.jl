# Consumption Function 
function c(prim::Primitives, I::Float64, H::Float64)
    @unpack_Primitives prim 
    if I < 0 || H < 0 
        return -1.0
    end
    # if H < 0
    return (((1-ψ)*I)^ω + H^ω)^(1/ω)
end

# Home Production function 
function H(prim::Primitives, smm_params::smm_parameters, 
           hp_m::Float64, hp_f::Float64, I::Float64)
    @unpack_Primitives prim 
    @unpack_smm_parameters smm_params
    male = A_m*hp_m
    female = A_f*hp_f
    # if male < 0
    #     male = 0
    # end
    # if female < 0 
    #     female = 0
    # end
    if I < 0 
        return -1.0
    end
    return ψ*I*((male)^ϕ + (female)^ϕ)^(1/ϕ)
end

function u(prim::Primitives, smm_params::smm_parameters, hh_type::HH_Type,
            cons::Float64, lm::Float64, lf::Float64, hp_f::Float64)
    @unpack_Primitives prim
    @unpack_smm_parameters smm_params
    @unpack_HH_Type hh_type
    # Any time spent outside leisure and home production 
    # imposes a cost on the HH. I assume job search and work happens
    # outside the house. No work-from-home or  search online.job 
    if cons < 0 
        return -1e10 
    end
    out_time = (1.0-lf-hp_f)
    # I need to impose stigma cost by picking it up 
    # from the HH Type now. 
    # sc = sc_south
    # if north == 1
    #     sc = sc_north  
    # end
    return (1-η_m-η_f)*log(cons) + η_m*log(lm) + η_f*log(lf) - sc*(out_time>0)
    # return ((1-η_m-η_f)/(1-σ_c))*cons^(1-σ_c) + (η_m/(1-σl_m))*lm^(1-σl_m) + (η_f/(1-σl_f))*lf^(1-σl_f) - sc*(out_time > 0)
end

# Set of all possible actions 
# that a HH chooses from. 
function action_set(prim::Primitives, smm_params::smm_parameters)
    @unpack_Primitives prim
    @unpack_smm_parameters smm_params
    # Possible actions depend on whether the agent is working/not-working
    N = N_l^2 + 2*Nl_work*N_l + Nl_work^2
    # Dm, Df, Lm, Lf, Hpm, Hpf
    # The ordering here will be: Dm,Df = [0,0], [0,1], [1,0], [1,1]
    actions = [zeros(6) for _ in 1:N];
    # leisure = collect(range(0.0, 1.0, N_l));
    Dm = [0.0, 1.0]
    Df = [0.0, 1.0]
    i = 1
    # Enumerate all actions: (Dm, Df, Lm, Lf, Hpm, Hpf)
    for dm in Dm, df in Df
        nl_m = (dm == 1)*Nl_work  + (dm == 0)*N_l
        nl_f = (df == 1)*Nl_work  + (df == 0)*N_l
        leisure_m = collect(range(0.0, 1.0-dm*h, nl_m))
        leisure_f = collect(range(0.0, 1.0-df*h, nl_f))
        for lm in leisure_m, lf in leisure_f
            actions[i] = [dm, df, lm, lf, 1.0-dm*h-lm, 1.0-df*h-lf]
            i += 1
        end
    end
    return actions 
end

# Added a new comment here

function HH_types(prim::Primitives, smm_params::smm_parameters, 
                  sc_active::Bool)
    @unpack_Primitives prim 
    @unpack_smm_parameters smm_params

    if sc_active
        north_sc_types = [0.0, sc_north, 1_000_000]
        south_sc_types = [0.0, sc_south, 1_000_000]
    else 
        north_sc_types = 0.0 
        south_sc_types = 0.0 
    end

    wage_types = vec(Iterators.product(wage_grids[1], wage_grids[2]) |> collect);
    
    north_hh_types = vec(Iterators.product(wage_grids[1], wage_grids[2], 1.0, north_sc_types) |> collect);
    south_hh_types = vec(Iterators.product(wage_grids[1], wage_grids[2], 0.0, south_sc_types) |> collect);

    return wage_types, north_hh_types, south_hh_types
end