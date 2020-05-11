# File that contains the main function to run the Huggett model:

# Main function to solve Huggett model:
function run_huggett(parameters::Parameters)
    # Setup arrays to hold answers:
    arrays = setup_arrays(parameters)

    # Backward induction:
    for t in parameters.Demographic.life:-1:1
        # Setup state combos for all individuals:
        state_combos_age = setup_state_combos(t, parameters)

        if t == parameters.Demographic.life
            # Setup interpolation function (just holder arrays):
            itp_holder_array = setup_interp(t-1, parameters, arrays.VA.value_agent)
            itp_holder_array = ValueInterpArrays(itp_holder_array)

            # Solve the terminal agent problem:
            @sync @distributed for row = 1:size(state_combos_age, 1)
                solve_all!(state_combos_age[row, :], parameters, arrays, itp_holder_array, terminal=true)
            end
        else
            # Setup interpolation function:
            itp_holder_array = setup_interp(t, parameters, arrays.VA.value_agent)
            itp_holder_array = ValueInterpArrays(itp_holder_array)

            # Solve the non-terminal agent problem:
            @sync @distributed for row = 1:size(state_combos_age, 1)
                solve_all!(state_combos_age[row, :], parameters, arrays, itp_holder_array, terminal=false)
            end
        end
    end

    return arrays
end

# Function to solve each living age:
function solve_all!(state::Array{Int64}, parameters::Parameters, arrays::AnswerArrays, itp_holder_array::ValueInterpArrays; terminal::Bool)
    # Parse state:
    combos = parse_combos(state, parameters)

    # Solve agent problem:
    ans_agent = solve_agent(combos, parameters, itp_holder_array, terminal=terminal)

    # Set up appropriate state value for agent:
    fixed_state = [state[1], state[2], state[3]]

    # Fill main arrays:
    arrays.VA.value_agent[fixed_state...] = ans_agent[1]
    arrays.DA.consumption[fixed_state...], arrays.DA.asset[fixed_state...] = ans_agent[2:end]

    return nothing
end

# Function to solve agent's decision:
function solve_agent(combos::Combos, parameters::Parameters, itp_holder_array::ValueInterpArrays; terminal::Bool)
    # Setup initial value and policy results:
    value_result = -1.0e15
    policy_result = zeros(2)

    # Get interpolation function:
    value_itp = get_interp(1, parameters, itp_holder_array.itp_holder_array)

    # Solve agent problem:
    values = maximize_agent(combos, parameters, value_itp, terminal=terminal)

    # Check if value is greater than previous:
    if values[1] > value_result
        value_result = values[1]
        policy_result = values[2:end]
    end

    # Return value and policy results:
    return vcat(value_result, policy_result)
end
