# File to setup state variables for dynamic programming problem:

# Function to setup all state variable combinations for a given age:
function setup_state_combos(t::Int64, parameters::Parameters)
    # Beginning state combos for an agent at a given age t (a, y_idio):
    state_combos = gridmake(1:parameters.GridSizes.size_a, 1:parameters.GridSizes.size_idio, t:t)

    return state_combos
end
