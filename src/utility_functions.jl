# File that contains utility functions and its derivatives:

# Function to compute the utility of an agent given consumption level and relative
# risk aversion:
function compute_utility(c::Float64, σ::Float64)
    """
    Parameters
    ----------
    c::Float64
        Consumption
    σ::Float64
        Relative risk aversion

    Returns
    -------
    utility::Float64
        Utility value
    """

    if c <= 0.0
        return -1.0e15
    else
        return (c^(1.0 - σ)) / (1.0 - σ)
    end
end

# Function to compute the derivative of the utility of an agent given
# consumption level and relative risk aversion:
function compute_utility_derivative(c::Float64, σ::Float64)
    """
    Parameters
    ----------
    c::Float64
        Consumption
    σ::Float64
        Relative risk aversion

    Returns
    -------
    utility_derivative::Float64
        Utility derivative value
    """

    if c <= 0.0
        return -1.0e15
    else
        return c^(-σ)
    end
end
