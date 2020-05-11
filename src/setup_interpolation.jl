# File contains functions to setup interpolation procedures and hold the
# interpolated arrays:

# Collection to hold value interpolation functions:
struct ValueInterp{V1<:AbstractArray}
    itp_value_func::V1
end

# Collection to hold value interpolation function holder arrays:
struct ValueInterpArrays{V1<:AbstractArray}
    itp_holder_array::V1
end

# Function to setup interpolated future value function for all state variables
# at a given age:
function setup_interp(t::Int64, parameters::Parameters, value_agent::SharedArray)
    # Setup holder array to house all interpolating functions (y_idio):
    itp_holder_size = (parameters.GridSizes.size_idio)
    itp_holder_array = Array{Interpolations.GriddedInterpolation}(undef, itp_holder_size)

    # Setup grids for interpolations:
    grid_a = parameters.Grids.grid_a

    # Calculate the interpolating function:
    for index_idio_y = 1:itp_holder_size[1]
        itp_holder_array[index_idio_y] = interpolate((grid_a,), value_agent[:, index_idio_y, t+1], parameters.InterpType)
    end

    return itp_holder_array
end

# Function to get the correct interpolating function given education or bequest motive
# background.
# Only need this if I do a cross-section of different education or bequest types:
function get_interp(individual_type::Int64, parameters::Parameters, itp_holder_array::Array{Interpolations.GriddedInterpolation})
    # Get index value for discrete, deterministic values (individual_type):
    index_individual_type = Int(individual_type)

    # Get interpolation functions:
    itp_value_func = itp_holder_array[:]

    return ValueInterp(itp_value_func)
end

# Functions for bounds checking for the interpolation functions:
function bound_check_a(a::Float64, parameters::Parameters)
    return clamp(a, parameters.Grids.grid_a[1], parameters.Grids.grid_a[end])
end
