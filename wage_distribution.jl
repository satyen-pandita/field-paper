using Optim 
using Distributions

function opt_func(x::Vector{Float64}, x_bar::Vector{Float64}, a::Float64)
    mu = x[1]
    s = x[2]
    d = Normal(0,1)
    z = (a-mu)/s
    v = s^2(1 - z*pdf(d, z)/(1-cdf(d,z)))
    m = mu + s*(pdf(d,z))/(1-cdf(d,z))
    @show m, sqrt(v)
    m_bar = x_bar[1]
    s_bar = x_bar[2]
    er = sqrt((m-m_bar)^2 + (sqrt(v)-s_bar)^2)
    return er
end

# Estimating a separate distribution for the North v South by Education 
X_BAR_M = Dict("North" => Dict("Col" => [115.4, 81.3], "NoCol" => [56.5, 40.4]), 
               "South" => Dict("Col" => [128.1, 90.6], "NoCol" => [64.2, 41.8]))

X_BAR_F = Dict("North" => Dict("Col" => [100.9,81.5], "NoCol" => [32.4,35.5]), 
               "South" => Dict("Col" => [105.7,80.4], "NoCol" => [36.1,32.4]))

X_BAR = Dict("Male" => X_BAR_M, "Female" => X_BAR_F)
# Estimating a separate distribution for the North v South by Education 
A_M = Dict("North" => Dict("Col" => 9.2, "NoCol" => 3.6), 
               "South" => Dict("Col" => 8.9, "NoCol" => 4.5))

A_F = Dict("North" => Dict("Col" => 7.4, "NoCol" => 3.6), 
               "South" => Dict("Col" => 8.9, "NoCol" => 3.0))

A = Dict("Male" => A_M, "Female" => A_F)

LOWER = [-Inf, 0.001]
UPPER = [Inf, Inf]

opts = Dict()


for gen in ["Male", "Female"]
    for state in ["North", "South"]
        for col in ["Col", "NoCol"]
            optFunc = x -> opt_func(x, X_BAR[gen][state][col], A[gen][state][col])
            opt = optimize(optFunc, LOWER, UPPER, X_BAR[gen][state][col], Fminbox(NelderMead()),Optim.Options(iterations=100, show_trace=true,show_every=1))
            key = gen*"_"*state*"_"*col
            opts[key] = opt.minimizer
        end
    end
end

# opt_h_col = optimize(optFunc_h_col, lower, upper, x_bar_h_col, Fminbox(NelderMead()),Optim.Options(iterations=100, show_trace=true,show_every=1))
# opt_h_nocol = optimize(optFunc_h_nocol, lower, upper, x_bar_h_nocol, Fminbox(NelderMead()),Optim.Options(iterations=100, show_trace=true,show_every=1))
# opt_w_col = optimize(optFunc_w_col, lower, upper, x_bar_w_col, Fminbox(NelderMead()),Optim.Options(iterations=100, show_trace=true,show_every=1))
# opt_w_nocol = optimize(optFunc_w_nocol, lower, upper, x_bar_w_nocol, Fminbox(NelderMead()),Optim.Options(iterations=100, show_trace=true,show_every=1))


# off_h_col, off_h_nocol, off_w_col, off_w_nocol = opt_h_col.minimizer, opt_h_nocol.minimizer, opt_w_col.minimizer, opt_w_nocol.minimizer

# @show off_h_col, off_h_nocol, off_w_col, off_w_nocol

# # In PPP US$: Divide INR by 20.22
# print("off_h_col = $(off_h_col/20.22), off_h_nocol = $(off_h_nocol/20.22), off_w_nocol=$(off_w_nocol/20.22),off_w_col=$(off_w_col/20.22)" )

# sd_h_col, sd_h_nocol, sd_w_col, sd_w_nocol = opt_h_col.minimizer[2]/20.22, opt_h_nocol.minimizer[2]/20.22, opt_w_col.minimizer[2]/20.22, opt_w_nocol.minimizer[2]/20.22
# @show sd_h_col, sd_h_nocol, sd_w_col, sd_w_nocol


# x_bar_h_col/20.22, x_bar_h_nocol/20.22, x_bar_w_col/20.22, x_bar_w_nocol/20.22