# File contains functions to setup arrays and hold the arrays:

# Collection to hold value arrays:
struct ValueArrays{V1<:AbstractArray}
    value_agent::V1
end

# Collection to hold decision arrays:
struct DecisionArrays{V1<:AbstractArray}
    consumption::V1
    asset::V1
end

# Collection to hold all arrays:
struct AnswerArrays{V1<:ValueArrays, V2<:DecisionArrays}
    VA::V1
    DA::V2
end

# Function to setup arrays:
function setup_arrays(parameters::Parameters)
    # Setup size of arrays for individual entering as homeowner (a, y_idio, life):
    total_states = (parameters.GridSizes.size_a, parameters.GridSizes.size_idio, parameters.Demographic.life)

    # Value array:
    value_agent = SharedArray{Float64,length(total_states)}(total_states)
    value_agent .= -1e15

    # Put into value array structure:
    value_arrays = ValueArrays(value_agent)

    # Decision arrays for choices:
    decision_arrays = DecisionArrays(deepcopy(value_agent), deepcopy(value_agent))

    return AnswerArrays(value_arrays, decision_arrays)
end
