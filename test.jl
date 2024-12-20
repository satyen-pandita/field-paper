include("moments.jl");


for sc in [true, false], home in [true, false]
    x,y = res[(sc, home)]
    prim, smm_params = Initialize(x, sc, home)
    @show sc, home
    println(gen_means(prim, smm_params, sc))
end

x,y = res[(true, true)]
prim, smm_params = Initialize(x, true, true)
gen_means(prim, smm_params,true)


x,y = res[(false, true)]
prim, smm_params = Initialize(x, false, true)
gen_means(prim, smm_params,false)
