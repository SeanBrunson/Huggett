# File that contains some helper functions:

# Function to convert time to age:
function convert_t(t::Int64, start_age::Int64)
    return t + start_age - 1
end

# Collection to hold state combos:
struct Combos{V1<:Float64, V2<:Int64}
    a::V1 # Current asset holdings
    y::V1 # Current income
    ssb::V1 # Current social security benefit
    current_survival::V1 # Probability of survival to next period
    current_idio_y::V2 # Index value of idiosyncratic income shock
    age::V2 # Age of agent
end

# Function to parse state combos and get the grid values:
function parse_combos(state::Array{Int64}, parameters::Parameters)
    # Find current age of individual:
    age = convert_t(state[end], parameters.Demographic.start_age)

    # Get beginning of period assets:
    a = parameters.Grids.grid_a[state[1]]

    # Get index values for current idiosyncratic shock to income:
    current_idio_y = state[2]

    # Get idiosyncratic shocks to income:
    shocks_idio = parameters.IncomeShocks.shocks_idio_income[current_idio_y]

    # Get income value:
    y = compute_income(shocks_idio, age, parameters.Demographic.JR, parameters.Education)

    # Get social security benefit:
    ssb = parameters.Tax.ssb[state[end]]

    # Get current probability to survive to the next age:
    current_survival = parameters.Demographic.st[state[end]]

    return Combos(a, y, ssb, current_survival, current_idio_y, age)
end
