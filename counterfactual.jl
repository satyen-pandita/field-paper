include("moments.jl")

# Parameter values obtained. 
x_min_sc = [0.4674, 0.00393, 9.92663, 0.04971]

#### Everything equal: Only leisure wts difference
x = copy(x_min_sc);
# Mute stigma cost 
sc_active = false 
# Make wages equal South males 
prim, smm_params = Initialize(x, sc_active)
prim.MM["North"] = copy(prim.MM["South"])
prim.MF = copy(prim.MM)
e_b, t_b = gen_means(prim, smm_params,sc_active)

### Add gender gap only -- men and women have southern wage
x = copy(x_min_sc)
prim, smm_params = Initialize(x, sc_active)
# Mute stigma cost 
sc_active = false 
prim, smm_params = Initialize(x, sc_active)
prim.MM["North"] = copy(prim.MM["South"])
prim.MF["North"] = copy(prim.MF["South"])
e_gw, t_gw = gen_means(prim, smm_params, sc_active)
e_gw["North"] .- e_b["North"]
e_gw["South"] .- e_b["South"]

### Add regional gap -- men and women have their own wages 
x = copy(x_min_sc)
# Mute stigma cost 
sc_active = false 
prim, smm_params = Initialize(x, sc_active)

e_gw_rw, t_gw_rw = gen_means(prim, smm_params, sc_active)
e_gw_rw["North"] .- e_gw["North"]
e_gw_rw["South"] .- e_gw["South"]

### Add only sc = ∞ stigma costs 
x = copy(x_min_sc)
sc_active = true 
prim, smm_params = Initialize(x, sc_active)
prim.HH_wts_stigma = Dict("North" => [0.80, 0.0, 0.20], "South" => [0.70, 0.0, 0.30])
e_sc_i, t_sc_i = gen_means(prim, smm_params, sc_active)
e_sc_i["North"] .- e_gw_rw["North"]
e_sc_i["South"] .- e_gw_rw["South"]
### Add stigma cost 
x = copy(x_min_sc)
# Mute stigma cost 
sc_active = true 
prim, smm_params = Initialize(x, sc_active)
e_f, t_f = gen_means(prim, smm_params, sc_active)
e_f["North"] .- e_gw_rw["North"]
e_f["South"] .- e_gw_rw["South"]

