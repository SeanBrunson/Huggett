# File contains functions to compute equilibrium:

# Function to compute consumption market clearing:
function clear_consumption(df::DataFrame, parameters::Parameters)
    # Sum consumption and asset for each agent:
    df.total_consumption = df.c + df.a_prime

    # Get mean of total consumption by age group:
    ave_total_consumption = by(df, :age, :total_consumption => mean, sort = true)

    # Get total mean of total consumption across population:
    ave_total_consumption = sum(get_μt(parameters.Demographic.st, parameters.Demographic.n) .* ave_total_consumption.total_consumption_mean)

    # Get total production output:
    Y = compute_production_output(parameters.Production.A, parameters.Production.K, parameters.Production.L, parameters.Production.α)

    return Y + (1.0 - parameters.Production.δ)*parameters.Production.K - ave_total_consumption - parameters.Tax.G
end

# Function to compute asset market value:
function compute_asset_value(df::DataFrame, parameters::Parameters)
    # Get mean of asset by age group:
    ave_asset = by(df, :age, :a_prime => mean, sort = true)

    # Get total mean of asset across population:
    ave_asset = sum(get_μt(parameters.Demographic.st, parameters.Demographic.n) .* ave_asset.a_prime_mean)

    return ave_asset
end

# Function to compute asset market clearing:
function clear_asset(df::DataFrame, parameters::Parameters)
    # Get total mean of asset across population:
    ave_asset = compute_asset_value(df, parameters)

    return parameters.Production.K*(1.0 + parameters.Demographic.n) - ave_asset
end

# Function to compute labor market clearing:
function clear_labor(df::DataFrame, parameters::Parameters)
    # Get mean of income by age group:
    ave_inc = by(df, :age, :y => mean, sort = true)

    # Get total mean of income across population:
    ave_inc = sum(get_μt(parameters.Demographic.st, parameters.Demographic.n) .* ave_inc.y_mean)

    return parameters.Production.L - ave_inc
end

# Function to compute new transfers from accidental bequests:
function compute_new_transfers(df::DataFrame, parameters::Parameters)
    # Adjust assets to after tax:
    df.after_tax = df.a_prime * (1.0 + parameters.Production.r*(1.0 - parameters.Tax.τ))

    # Get mean of after tax asset by age group:
    ave_after_tax = by(df, :age, :after_tax => mean, sort = true)

    # Get fraction of agents dying by age:
    dying_agents = get_μt(parameters.Demographic.st, parameters.Demographic.n) .* (1.0 .- parameters.Demographic.st)

    # Get total mean of after tax asset across population:
    ave_after_tax = sum(dying_agents .* ave_after_tax.after_tax_mean)

    return ave_after_tax / (1.0 - parameters.Demographic.n)
end

# Function to compute aggregate transfer wealth ratio:
function compute_agg_transfer(df::DataFrame, parameters::Parameters)
    # Calculate the measure of individuals in the economy:
    μt = get_μt(parameters.Demographic.st, parameters.Demographic.n)

    # Calculate the aggregate transfer wealth in the economy:
    transfer_vec = zeros(length(μt))
    for t in 1:length(μt)
        transfer = 0.0
        for j in 0:(t-1)
            transfer += parameters.Tax.Tr * ((1.0 + parameters.Production.r*(1.0 - parameters.Tax.τ))^j)
        end
        transfer_vec[t] = transfer
    end

    agg_transfer_wealth = sum(μt .* transfer_vec)

    # Get mean of asset by age group:
    ave_asset = by(df, :age, :a_prime => mean, sort = true)

    # Get total mean of asset across population:
    ave_asset = sum(μt .* ave_asset.a_prime_mean)

    # Get aggregate transfer wealth ratio:
    transfer_wealth_ratio = agg_transfer_wealth / ave_asset

    return transfer_wealth_ratio
end

function compute_equilibrium(; K::Float64, Tr::Float64, max_iteration::Int64, tolerance::Float64, parameter_iteration::Int64, location_parameters::String)
    # Prepare parameters:
    df_parameters, st, interp_type = prepare_parameters(parameter_iteration, location_parameters)

    # Find equilibrium K and Tr values:
    for iteration in 1:max_iteration
        # Intialize parameters:
        parameters = initialize_parameters(K, Tr, df_parameters, st, interp_type)

        # Run the Huggett model to get value and decision arrays:
        arrays = run_huggett(parameters)

        # Simulate the model to get the stationary distribution:
        df = simulate(arrays, 10000, parameters)

        # Compute the asset value:
        asset_value = compute_asset_value(df, parameters)

        # Check market clearing conditions:
        asset_clearing = clear_asset(df, parameters)
        transfer_clearing = compute_new_transfers(df, parameters) - Tr

        # Update guesses if markets did not clear:
        if (abs(asset_clearing) <= tolerance) && (abs(transfer_clearing) <= tolerance)
            println("Market clearing found at iteration ", iteration)
            break
        elseif (iteration == max_iteration)
            println("Reached maximum iteration")
            break
        else
            K = K - 0.5*asset_clearing
            Tr = transfer_clearing + Tr
        end
    end

    return K, Tr
end
