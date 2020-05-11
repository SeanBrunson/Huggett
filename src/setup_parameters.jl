# File contains functions to setup parameters and hold the parameters:

# Collection of grids:
struct Grids{V1<:AbstractVector, V2<:Float64}
    min_a::V2 # Minimum net asset holding value
    max_a::V2 # Maximum net asset holding value
    curve_a::V2 # Curvature for the net asset holding grid
    grid_a::V1 # Net asset holding grid
end

# Collection of grid sizes:
struct GridSizes{V1<:Int64}
    size_a::V1 # Net asset holding grid size
    size_idio::V1 # Idiosyncratic income state grid size
end

# Collection of income shock variables:
struct IncomeShocks{V1<:AbstractArray, V2<:AbstractVector, V3<:Float64, V4<:String}
    prob_idio_income::V1 # Idiosyncratic state probability matrix (Markov)
    shocks_idio_income::V2 # Idiosyncratic income shocks
    ρ::V3 # Regression towards the mean income (This is gamma in the paper)
    σ_ϵ::V3 # Standard deviation for the income shock
    inc_shock_method::V4 # The method to discretize the income shocks
end

# Collection of demographic and preference parameters:
struct Demographic{V1<:Int64, V2<:Float64, V3<:AbstractVector}
    J::V1 # Terminal age of agent (This is N in the paper)
    JR::V1 # Retirement age of agent
    start_age::V1 # Starting age of agent
    life::V1 # Length of life of agent (J - start_age + 1)
    σ::V2 # Relative risk aversion
    β::V2 # Time discount factor
    n::V2 # Population growth rate
    st::V3 # Conditional probability of surviving another period
end

# Collection of production parameters:
struct Production{V1<:Float64}
    A::V1 # Technology level
    K::V1 # Capital (Endogenous)
    L::V1 # Labor
    α::V1 # Capital's share of output
    δ::V1 # Capital depreciation rate
    r::V1 # Risk-free interest rate (Set equal to first order condition)
    w::V1 # Wage (Set equal to first order condition)
end

# Collection of tax variables:
struct Tax{V1<:Float64, V2<:AbstractVector}
    τ::V1 # Flat capital and income tax rate
    θ::V1 # Flat social security income tax rate
    G::V1 # Government consumption
    Tr::V1 # Lump sum transfer
    ssb::V2 # Social security benefit (This is b in the paper)
end

# Collection to hold all parameters:
struct Parameters{V1<:Grids, V2<:GridSizes, V3<:IncomeShocks, V4<:Demographic, V5<:Production, V6<:Tax, V7<:Gridded, V8<:String}
    Grids::V1
    GridSizes::V2
    IncomeShocks::V3
    Demographic::V4
    Production::V5
    Tax::V6
    InterpType::V7
    Education::V8
end

# Function to get the stationary distribution of Markov chain:
function get_stationary_chain(P::Array{Float64})
    n = size(P, 1)
    a = (zeros(n, n) + I) - P
    a = vcat(a', ones(n)')
    b = zeros(n+1)
    b[end] = 1
    return a \ b
end

# Function to get the fraction of the population at age t:
function get_μt(st::AbstractVector, n::Float64)
    # Setup initial distribution:
    μt = ones(length(st))

    # Loop through and adjust:
    for i in 2:length(st)
        μt[i] = (st[i-1] * μt[i-1]) / (1.0 + n)
    end

    # Normalize so that μt is equal to one:
    μt = μt / sum(μt)

    return μt
end

# Function to setup asset grid:
function setup_asset_grid(min_a::Float64, max_a::Float64, size_a::Int64, curve_a::Float64, size_idio::Int64)
    # Create net asset holding grid:
    grid_a = ((range(0, stop=size_a, length=size_a) / size_a) .^ curve_a) * (max_a - min_a) .+ min_a
    grid_a[1] = min_a
    grid_a[end] = max_a

    # Put all grids in Grids structure:
    grids = Grids(min_a, max_a, curve_a, grid_a)

    # Put all grid sizes in GridSizes structure:
    grid_sizes = GridSizes(size_a, size_idio)

    return grids, grid_sizes
end

# Function to setup income shocks:
function setup_income_shocks(size_idio::Int64, ρ::Float64, σ_ϵ::Float64, inc_shock_method::String)
    # Idiosyncratic shocks and probability given income type:
    if inc_shock_method == "rouwenhorst"
        prob_idio_income, shocks_idio = rouwenhorst(size_idio, ρ, σ_ϵ)
    elseif inc_shock_method == "tauchen"
        prob_idio_income, shocks_idio = tauchen(size_idio, ρ, σ_ϵ)
    else
        error("inc_type is wrong")
    end

    # Put all income shock parameters in IncomeShocks structure:
    income_shocks = IncomeShocks(prob_idio_income, shocks_idio, ρ, σ_ϵ, inc_shock_method)

    return income_shocks
end

# Function to setup production:
function setup_production(A::Float64, K::Float64, L::Float64, α::Float64, δ::Float64)
    # Compute risk-free rate:
    r = compute_rf(A, K, L, α, δ)

    # Compute wage rate:
    w = compute_wage(A, K, L, α)

    # Put all production parameters in Production structure:
    production = Production(A, K, L, α, δ, r, w)

    return production
end

# Function to setup parameters:
function setup_parameters(; min_a::Float64, max_a::Float64, size_a::Int64, curve_a::Float64, τ::Float64, θ::Float64, Tr::Float64, size_idio::Int64, ρ::Float64, σ_ϵ::Float64, inc_shock_method::String, J::Int64, JR::Int64, start_age::Int64, σ::Float64, β::Float64, n::Float64, st::AbstractVector, A::Float64, K::Float64, α::Float64, δ::Float64, interp_type::Gridded{Linear}, education::String)

    # Setup grids:
    grids, grid_sizes = setup_asset_grid(min_a, max_a, size_a, curve_a, size_idio)

    # Setup income shocks:
    income_shocks = setup_income_shocks(size_idio, ρ, σ_ϵ, inc_shock_method)

    # Setup demographic parameters:
    demographic = Demographic(J, JR, start_age, J - start_age + 1, σ, β, n, st)

    # Setup production parameters:
    L = compute_labor_input(income_shocks.shocks_idio_income, income_shocks.prob_idio_income, start_age, JR, J, demographic.life, education, st, n)
    production = setup_production(A, K, L, α, δ)

    # Calculate the measure of retired individuals in the economy:
    μt_retire = get_μt(st, n)[(JR - start_age + 1):end]

    # Calculate social security benefit:
    ssb = θ*production.w*production.L / sum(μt_retire)
    ssb = ssb * ones(demographic.life)
    ssb[1:(JR - start_age)] .= 0.0

    # Calculate government budget:
    G = τ * (production.r*production.K + production.w*production.L)

    # Setup tax parameters:
    tax = Tax(τ, θ, G, Tr, ssb)

    # Setup final parameters:
    parameters = Parameters(grids, grid_sizes, income_shocks, demographic, production, tax, interp_type, education)

    return parameters
end

# Function to prepare parameters:
function prepare_parameters(parameter_iteration::Int64, location_parameters::String)
    # Read in parameters:
    df_parameters = CSV.read(string(location_parameters, "parameters.csv"), skipto=parameter_iteration + 1, limit=1)

    # Read in death probabilities:
    st = CSV.read(string(location_parameters, "death_probability_age.csv"), skipto=df_parameters.start_age[1]+2, limit=df_parameters.J[1]-df_parameters.start_age[1]+1)
    st.survival_probability = 1.0 .- st.death_probability

    # Setup interpolation type:
    interp_type = Interpolations.Gridded(Interpolations.Linear())

    return df_parameters, st, interp_type
end

# Function to initialize parameters:
function initialize_parameters(K::Float64, Tr::Float64, df_parameters::DataFrame, st::DataFrame, interp_type::Gridded{Linear})
    return setup_parameters(min_a=Float64(df_parameters.min_a[1]), max_a=Float64(df_parameters.max_a[1]), size_a=df_parameters.size_a[1], curve_a=Float64(df_parameters.curve_a[1]), τ=df_parameters.tau[1], θ=df_parameters.theta[1], Tr=Tr, size_idio=df_parameters.size_idio[1], ρ=df_parameters.rho[1], σ_ϵ=df_parameters.sigma_epsilon[1], inc_shock_method=df_parameters.inc_shock_method[1], J=df_parameters.J[1], JR=df_parameters.JR[1], start_age=df_parameters.start_age[1], σ=df_parameters.sigma[1], β=df_parameters.beta[1], n=df_parameters.n[1], st=st.survival_probability, A=df_parameters.A[1], K=K, α=df_parameters.alpha[1], δ=df_parameters.delta[1], interp_type=interp_type, education=df_parameters.education[1])
end
