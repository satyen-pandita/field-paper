include("moments.jl");

prim, smm_params = Initialize(Min_x_f_A,  true, true)

gen_means(prim, smm_params, true)


prim, smm_params = Initialize(Min_x_f_eta,  true, false);
gen_means(prim, smm_params, true)




# Results with modified utility 

# res = Dict(false => ([0.122717, 71.3624], 4.08059), true  => ([0.0201509, 19.4524, 5.81422, 0.0453233], 3.6617))

# Results without modified utility
# res = Dict(true => ([0.00230059, 384.294, 17.5517, 0.0233759], 3.77918), false  => ([0.0137712, 2163.6], 4.13795))



<<<<<<< modified-utility

=======
>>>>>>> main
# Let's take average wm, wf. 
Am = 1.0
Af = collect(range(0.01, 10.0, length=100))
Us = zeros(length(Af))
wm = 125.0
wf = 102.0
hh_type = HH_Type(wm, wf, 0.0, 0.0)
for (j, af) in enumerate(Af) 
    prim, smm_params = Initialize([Am, af], false, true)
    actions = action_set(prim, smm_params)
    probs = prob_actions_hh(prim, smm_params, hh_type)
<<<<<<< modified-utility
    # What is the average utility  
    u_avg = sum([probs[i]*u(prim, smm_params, hh_type, c(prim, wm*actions[i][1] + wf*actions[i][2], H(prim, smm_params, actions[i][5], actions[i][6], wm*actions[i][1] + wf*actions[i][2])), 
                actions[i][3], actions[i][4], actions[i][6], H(prim, smm_params, actions[i][5], actions[i][6], wm*actions[i][1] + wf*actions[i][2])) for i in eachindex(actions)]) 
=======
    # What is the average utility 
    # utils = 
    u_avg = sum([u(prim, smm_params, hh_type, c(prim, wm*actions[i][1] + wf*actions[i][2], H(prim, smm_params, actions[i][5], actions[i][6], wm*actions[i][1] + wf*actions[i][2])), actions[i][3], actions[i][4], actions[i][6])*probs[i] for i in eachindex(actions)]) 
>>>>>>> main
    Us[j] = u_avg
end
# Derivative of Us w.r.t Af
Dus = diff(Us)./diff(Af) 

using Plots
<<<<<<< modified-utility
# savefig("utility.png")
=======
plot(Af, Us, label="Utility", xlabel="Af/Am", ylabel="Utility", title="Utility vs Af/Am")
plot!(Af[1:end-1], Dus, label="Derivative of Utility")
savefig("utility.png")

>>>>>>> main
