include("moments.jl");

prim, smm_params = Initialize(Min_x_f_A,  true, true)

gen_means(prim, smm_params, true)


prim, smm_params = Initialize(Min_x_f_eta,  true, false);
gen_means(prim, smm_params, true)



