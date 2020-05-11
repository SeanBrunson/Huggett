# File contains main functions for the value function optimization:

# Function to compute age J (terminal) value for all possible state variables:
function compute_terminal_value(a_prime::Float64, combos::Combos, parameters::Parameters)
    # Bound check a_prime:
    a_prime = bound_check_a(a_prime, parameters)

    # Find consumption:
    c = compute_consumption(a_prime, combos.a, combos.y, combos.ssb, parameters)

    # Find utility value:
    u = compute_utility(c, parameters.Demographic.σ)

    # Return final value:
    value = u

    return value
end

# Function to calculate non-terminal expected future value for all individuals:
function compute_next_value(a_prime::Float64, combos::Combos, parameters::Parameters, value_itp::ValueInterp)
    # Bound check a_prime:
    a_prime = bound_check_a(a_prime, parameters)

    # Find consumption:
    c = compute_consumption(a_prime, combos.a, combos.y, combos.ssb, parameters)

    # Get expected future value:
    expectation = get_exp_future(a_prime, combos.age, combos.current_idio_y, parameters, value_itp)

    # Find utility value:
    u = compute_utility(c, parameters.Demographic.σ)

    # Return final value:
    value = u + parameters.Demographic.β*combos.current_survival*expectation

    return value
end

# Function to get future value expectation:
function get_exp_future(a_prime::Float64, age::Int64, current_idio_y::Int64, parameters::Parameters, value_itp::ValueInterp)
    # Calculate expected future value:
    expectation = 0.0

    # Check to see if in or going in to retirement:
    if (age + 1) >= parameters.Demographic.JR
        # Get expected future value:
        expectation += value_itp.itp_value_func[current_idio_y](a_prime)
    else
        for future_idio_y = 1:parameters.GridSizes.size_idio
            # Get expected future value:
            exp_value_itp = value_itp.itp_value_func[future_idio_y](a_prime)

            # Get joint probability and expected future value:
            joint_probability = parameters.IncomeShocks.prob_idio_income[current_idio_y, future_idio_y]
            expectation += joint_probability*exp_value_itp
        end
    end

    return expectation
end

# Function to find maximized agent value and policy:
function maximize_agent(combos::Combos, parameters::Parameters, value_itp::ValueInterp; terminal::Bool)
    # Setup initial value and policy results:
    value_result = Array{Float64}(undef, 1)
    value_result[1] = -1.0e15
    policy_result = zeros(2)

    # Find maximum possible consumption value from budget constraint.
    # (Either borrow/save nothing at age J or borrow the max):
    if terminal == false
        c_max = compute_consumption(parameters.Grids.min_a, combos.a, combos.y, combos.ssb, parameters)
    else
        c_max = compute_consumption(0.0, combos.a, combos.y, combos.ssb, parameters)
    end

    # Check to make sure c_max is positive:
    if c_max < 0.0
        return vcat(value_result, policy_result)
    end

    if terminal == false
        # Find max of objective to find optimal savings and consumption:
        obj_non_terminal(a_prime) = -compute_next_value(a_prime, combos, parameters, value_itp)
        res = optimize(obj_non_terminal, parameters.Grids.min_a, min(c_max, parameters.Grids.max_a))
    else
        # Find max of objective to find optimal terminal savings and consumption:
        obj_terminal(a_prime) = -compute_terminal_value(a_prime, combos, parameters)
        res = optimize(obj_terminal, 0.0, min(c_max, parameters.Grids.max_a))
    end

    # Get optimal results:
    a_prime = Optim.minimizer(res)
    c = compute_consumption(a_prime, combos.a, combos.y, combos.ssb, parameters)
    policy_result = [c, a_prime]

    return vcat(-Optim.minimum(res), policy_result)
end
