include("moments.jl")

# Parameter values obtained. 
res = deserialize("results_mu_2025_01_20_19_06.jls")
x_min_sc = res[true, true][1]

#### Everything equal
x = copy(x_min_sc);
sc_active = false
# Mute stigma cost 
# Make wages equal South males 
prim, smm_params = Initialize(x, true, true)
prim.MM["North"] = copy(prim.MM["South"])
prim.MF = copy(prim.MM)
e_b_n, e_b_s = zeros(2), zeros(2)
for i in 1:50
    dict = gen_means(prim, smm_params, sc_active)
    ne, se = dict[1]["North"], dict[1]["South"]
    e_b_n .+= ne/50  
    e_b_s .+= se/50
    # nt, wt = dict[2]["no_work"], dict[2]["work"]
    # println(ne, se, nt, wt)
end
e_b_n, e_b_s

### Add gender gap only -- men and women have southern wage
x = copy(x_min_sc)
prim, smm_params = Initialize(x, true, true)
# Mute stigma cost 
sc_active = false 
# prim, smm_params = Initialize(x, sc_active)
prim.MM["North"] = copy(prim.MM["South"])
prim.MF["North"] = copy(prim.MF["South"])
e_gw_n, e_gw_s = zeros(2), zeros(2)
for i in 1:50
    dict = gen_means(prim, smm_params, sc_active)
    ne, se = dict[1]["North"], dict[1]["South"]
    e_gw_n .+= ne/50  
    e_gw_s .+= se/50
end
e_gw_n-e_b_n, e_gw_s-e_b_s

### Add regional gap -- men and women have their own wages 
x = copy(x_min_sc)
# Mute stigma cost 
sc_active = false 
prim, smm_params = Initialize(x, true, true)

e_gw_rw_n, e_gw_rw_s = zeros(2), zeros(2)
for i in 1:50
    dict = gen_means(prim, smm_params, sc_active)
    ne, se = dict[1]["North"], dict[1]["South"]
    e_gw_rw_n .+= ne/50  
    e_gw_rw_s .+= se/50
end

e_gw_rw_n-e_gw_n, e_gw_rw_s-e_gw_s

### Add stigma
x = copy(x_min_sc)
sc_active = true
prim, smm_params = Initialize(x, true, true)
e_gw_rw_st_n, e_gw_rw_st_s = zeros(2), zeros(2)
for i in 1:50 
    dict = gen_means(prim, smm_params, sc_active)     
    ne, se = dict[1]["North"], dict[1]["South"]
    e_gw_rw_st_n .+= ne/50
    e_gw_rw_st_s .+= se/50
end

e_gw_rw_st_n-e_gw_rw_n, e_gw_rw_st_s-e_gw_rw_s