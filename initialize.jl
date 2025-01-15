using Pkg
Pkg.add(["SharedArrays", "Parameters", "Distributions", "Random", 
            "Serialization", "Optim", "StatsBase", "Statistics", "BenchmarkTools", "LinearAlgebra"])
using SharedArrays
using Parameters
using Distributions 
using Random
using Serialization
using Optim
using StatsBase
using Statistics
using BenchmarkTools;
using LinearAlgebra;

# Random.seed!(12345)

# Added another comment here
@with_kw mutable struct Primitives
    # externally chosen params 
    ϕ::Float64 = 0.5963
    ω::Float64 = 0.44
    ψ::Float64 = 0.39
    σl_m::Float64 = 0.9448
    σl_f::Float64 = 0.9657
    σ_c::Float64 = 0.9744
    # TUS
    # I set hrs_m = hrs_f so that 
    # any differences in home prod and leisure hrs
    # stems solely from differences in A_m, A_f 
    h::Float64 = 0.593
    hm::Float64 = 0.628
    hf::Float64 = 0.398
    # Leisure grid
    # N_l::Int64 = 30
    dl::Float64 = 0.1
    Nl_work = Int(round((1.0-h)/dl))
    N_l = Int(round(1.0/dl))
    # Wage Grid
    N_w::Int64 = 30
    # Wage Offer distribution    
    MM = Dict("North" => Dict("Col" => [112.4,52.0], "NoCol" => [54.7,26.7]), 
    "South" => Dict("Col" => [124.9,57.9], "NoCol" => [62.6,28.9]))
    MF = Dict("North" => Dict("Col" => [97.4,48.3], "NoCol" => [29.4,18.4]), 
    "South" => Dict("Col" => [102.4,49.0], "NoCol" => [34.0,19.0]))
    wage_grids = [collect(range(-50.0, 300.0, N_w)), collect(range(-50.0, 250.0, N_w))]
    wage_types = vec(Iterators.product(wage_grids[1], wage_grids[2]) |> collect);
    # dw = [350/N_w, 300/N_w]
    # Stigma Cost will now be imposed 
    # by being in North vs South.
    prop_north::Float64 = 0.51
    # (Husb, Wife) -> 00,01,10,11
    # HH_Col = [0.69, 0.07, 0.10, 0.13]
    
    # The HH distribution across education levels is almost identical
    # across North/South.  
    HH_wts_col = Dict("Col" => Dict("Col" => 0.13 , "NoCol" => 0.10), 
                  "NoCol" => Dict("Col" => 0.07, "NoCol" => 0.69))
    
    # Ordering: sc = 0, sc > 0, sc = ∞
    
    # HH_wts_stigma = Dict("North" => [0.62, 0.18, 0.20], "South" => [0.55, 0.15, 0.30])
    HH_wts_stigma = Dict("North" => [0.62, 0.18, 0.20], "South" => [1.0, 0.0, 0.0])
    
end
                           
# These parameters will be estimated using SMM
@with_kw mutable struct smm_parameters
    # Home prod params 
    A_m::Float64
    A_f::Float64
    
    # Leisure Params 
    η_m::Float64
    η_f::Float64
    
    # stigma cost params
    sc_north::Float64
    sc_south::Float64
end

@with_kw mutable struct HH_Type 
    wm::Float64 
    wf::Float64
    north::Float64 
    sc::Float64 
end


function Initialize(guess::Vector{Float64}, 
                    sc_active::Bool, home_prod::Bool=false)
    prim = Primitives()
    if sc_active
        if home_prod
            A_m, A_f, sc_north, sc_south = guess
            η_m, η_f = 1/3, 1/3
        else 
            η_m, η_f, sc_north, sc_south = guess
            A_m, A_f = 1., 1.
        end        
    else 
        if home_prod
            A_m, A_f = guess
            η_m, η_f = 1/3, 1/3
        else 
            η_m, η_f = guess
            A_m, A_f = 1.0, 1.0
        end
        sc_north = 0.0
        sc_south = 0.0
    end
    # A_m, A_f = 1.0, 1.0
    smm_params = smm_parameters(A_m, A_f, η_m, η_f, sc_north, sc_south)
    return prim, smm_params
end

