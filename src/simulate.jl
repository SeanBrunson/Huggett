# File contains functions to simulate the economy:

# Structure to hold Markov chains:
struct MCSample{V1<:AbstractVector, V2<:AbstractVector}
    p::V1
    P::V2
end

# Function to simulate Markov chains:
function MCSample(P::AbstractVector)
    p = cumsum(P)
    return MCSample{typeof(p), typeof(P)}(p, P)
end

function draw_mc_shock(p::Array{Float64})
    return searchsortedfirst(p, rand())
end

draw_mc_shock(p::Array{Float64}, periods::Int64) = Int[draw_mc_shock(p) for i=1:periods]

# Function to simulate random idiosyncratic shocks:
function setup_idio_shocks(previous_shock::Array{Float64}, age::Array{Float64}, parameters::Parameters)
    P = parameters.IncomeShocks.prob_idio_income
    P_dist = [MCSample(vec(P[i, :])) for i in 1:size(P, 1)]

    state_values = 1:parameters.GridSizes.size_idio
    next_shock = zeros(size(previous_shock, 1))

    for i = 1:size(previous_shock, 1)
        #Get current age:
        current_age = convert_t(Int(age[i]), parameters.Demographic.start_age)

        # If current age is less than retirement age, then update idiosyncratic income shock:
        if current_age < parameters.Demographic.JR
            draw_shock = draw_mc_shock(P_dist[Int(previous_shock[i])].p)
            copyto!(view(next_shock, i), state_values[draw_shock])
        else
            copyto!(view(next_shock, i), previous_shock[i])
        end
    end

    return next_shock
end

# Function to setup initial distribution of individuals for simulations.
# (i.e. initial population of youngest aged agents with no assets):
function setup_initial_distribution(population::Int64, parameters::Parameters)
    # Create initial distribution:
    df = DataFrame(zeros(population * parameters.Demographic.life, 7))
    names!(df, [:id, :age, :y, :c, :wealth, :a_prime, :y_idio_shock])

    # Add id number and age for each individual:
    df.id[1:population] = 1:population
    df.age[1:population] .= 1

    # Add initial idiosyncratic shock column:
    stationary_proportion = get_stationary_chain(parameters.IncomeShocks.prob_idio_income)
    df.y_idio_shock[1:population] = wsample(1:parameters.GridSizes.size_idio, stationary_proportion, population)

    return df
end

# Function to update distribution for simulation:
function update_distribution!(t::Int64, df::DataFrame, population::Int64, parameters::Parameters)
    # Subset df to just current age t:
    df_subset = df[df.age .== t, :]

    # Update age:
    df_subset.age = df_subset.age .+ 1.0

    # Update DataFrame:
    df[(1 + t*population):(t + 1)*population, :] .= df_subset
end

# Collection of choice interpolating functions:
struct SimChoiceInterp{V1<:Interpolations.GriddedInterpolation}
    consumption::V1
    asset::V1
end

# Collection of all interpolating functions:
struct SimInterpFuncs{V1<:SimChoiceInterp}
    choices::V1
end

# Function to setup interpolating functions for simulations:
function setup_interp_sim(parameters::Parameters, decision_arrays::DecisionArrays)
    # Setup holder array to house all interpolation functions (y_idio, age):
    itp_holder_size = (parameters.GridSizes.size_idio, parameters.Demographic.life)
    itp_holder_choice = Array{SimChoiceInterp}(undef, itp_holder_size)

    # Setup grids for interpolations:
    grid_a = parameters.Grids.grid_a

    # Create grid tuple:
    tuple_grid = (grid_a, )

    #Calculate the interpolating function:
    for index_y_idio = 1:itp_holder_size[1]
        for index_t = 1:itp_holder_size[2]
            # Create index tuple:
            index_grid = (index_y_idio,)

            # Calculate interpolation values:
            itp_holder_choice[index_y_idio, index_t] = setup_choice_interp(index_t, tuple_grid, index_grid, decision_arrays, parameters)
        end
    end

    return itp_holder_choice
end

# Function to setup choice interpolating functions:
function setup_choice_interp(t::Int64, tuple_grid::NTuple, index_grid::NTuple, decision_arrays::DecisionArrays, parameters::Parameters)
    # Setup slicing vector:
    index_vector = [:, index_grid[1], t]

    # Interpolating functions:
    itp_consumption = interpolate(tuple_grid, decision_arrays.consumption[index_vector...], parameters.InterpType)
    itp_asset = interpolate(tuple_grid, decision_arrays.asset[index_vector...], parameters.InterpType)

    # Save choices to collection:
    choice_functions = SimChoiceInterp(itp_consumption, itp_asset)

    return choice_functions
end

# Function to get the correct interpolating function:
function get_interp_sim(index_age::Int64, y_idio::Float64, parameters::Parameters, itp_holder_choice::Array{SimChoiceInterp})
    # Get index values:
    index_y_idio = Int(y_idio)

    # Get interpolating functions:
    choices = itp_holder_choice[index_y_idio, index_age]

    return SimInterpFuncs(choices)
end

# Function to find the optimal choices for an agent given optimal value:
function find_opt_choice(choices::SimChoiceInterp, a::Float64, y::Float64, parameters::Parameters)
    # Determine choices:
    c = max(choices.consumption(a), 0.0)

    # Find a_prime:
    a_prime = bound_check_a(choices.asset(a), parameters)

    return [c, a_prime]
end

# Function to simulate each individual:
function sim_individual!(j::Int64, df::DataFrame, itp_holder_choice::Array{SimChoiceInterp}, parameters::Parameters)
    # Get individual's current age and state variables:
    current_age = Int(df.age[j])
    a = df[j, :a_prime]

    # Get income after shocks if under retirement:
    if convert_t(current_age, parameters.Demographic.start_age) == parameters.Demographic.JR
        y_idio = df.y_idio_shock[j]
        y = compute_income(parameters.IncomeShocks.shocks_idio_income[Int(y_idio)], convert_t(current_age, parameters.Demographic.start_age), parameters.Demographic.JR, parameters.Education)
    elseif convert_t(current_age, parameters.Demographic.start_age) > parameters.Demographic.JR
        y_idio = df.y_idio_shock[j]
        y = df.y[j]
    else
        y_idio = df.y_idio_shock[j]
        y = compute_income(parameters.IncomeShocks.shocks_idio_income[Int(y_idio)], convert_t(current_age, parameters.Demographic.start_age), parameters.Demographic.JR, parameters.Education)
    end

    # Find wealth:
    wealth = y + a

    # Find choices:
    interp_functions = get_interp_sim(current_age, y_idio, parameters, itp_holder_choice)
    choices = find_opt_choice(interp_functions.choices, a, y, parameters)

    # Update distribution:
    df.y[j] = y
    df.wealth[j] = wealth
    df.c[j], df.a_prime[j] = choices
    df.y_idio_shock[j] = y_idio

    return nothing
end

function loop_individual!(df::DataFrame, itp_holder_choice::Array{SimChoiceInterp}, current_rows::UnitRange{Int64}, parameters::Parameters)
    for j = current_rows
        sim_individual!(j, df, itp_holder_choice, parameters)
    end

    return nothing
end

# Main function to simulate:
function simulate(arrays::AnswerArrays, population::Int64, parameters::Parameters)
    # Set seed for initial random variables:
    Random.seed!(123)

    # Setup initial distribution:
    df = setup_initial_distribution(population, parameters)

    # Setup initial income individual had last period:
    for row = 1:population
        df.y[row] = compute_income(parameters.IncomeShocks.shocks_idio_income[Int(df.y_idio_shock[row])], convert_t(Int(df.age[row]) - 1, parameters.Demographic.start_age), parameters.Demographic.JR, parameters.Education)
    end

    # Setup interpolating functions:
    itp_holder_choice = setup_interp_sim(parameters, arrays.DA)

    # Loop through ages and simulate:
    for t = 1:Int(nrow(df)/population)
        # Get rows that have the current age
        current_rows = (1 + (t - 1)*population):t*population

        # Set up idiosyncratic shocks for each individual:
        df.y_idio_shock[current_rows] = setup_idio_shocks(df.y_idio_shock[current_rows], df.age[current_rows], parameters)

        # Find decisions:
        loop_individual!(df, itp_holder_choice, current_rows, parameters)

        # Update distribution:
        if t < (nrow(df)/population)
            update_distribution!(t, df, population, parameters)
        end
    end

    return df
end
