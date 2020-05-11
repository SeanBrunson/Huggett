# File that contains production functions and its derivatives:

# Function to compute production output:
function compute_production_output(A::Float64, K::Float64, L::Float64, α::Float64)
    """
    Parameters
    ----------
    A::Float64
        Technology level
    K::Float64
        Capital
    L::Float64
        Labor
    α::Float64
        Capital's share of output

    Returns
    -------
    Y::Float64
        Production output
    """

    return A * (K^α) * (L^(1.0 - α))
end

# Function to compute labor input from market clearing (exogenous):
function compute_labor_input(shocks_idio_income::AbstractVector, prob_idio_income::AbstractArray, start_age::Int64, JR::Int64, J::Int64, life::Int64, education::String, st::AbstractVector, n::Float64)
    """
    Parameters
    ----------
    shocks_idio_income::Int64
        Idiosyncratic shocks.
    prob_idio_income::AbstractArray
        Idiosyncratic state probability matrix (Markov).
    start_age::Int64
        Starting age of agent.
    JR::Int64
        Retirement age of agent.
    J::Int64
        Terminal age of agent.
    life::Int64
        Length of life (J - start_age + 1).
    education::String
        Education level of agent.
    st::AbstractVector
        Conditional probability of surviving another period.
    n::Float64
        Population growth rate.

    Returns
    -------
    L::Float64
        Labor
    """

    # Setup array to hold income values over entire life:
    inc = zeros(length(shocks_idio_income), life)

    # Get the implied distribution from the Markov chain:
    P = get_stationary_chain(prob_idio_income)

    # Loop through each income shock and get range of income values for each age:
    for row in 1:size(inc, 1)
        inc[row, :] = compute_income.(shocks_idio_income[row], start_age:J, JR, education)
    end

    # Get the average income by age:
    inc_mean = sum(inc .* P, dims = 1)

    # Get the average income across ages:
    L = sum(get_μt(st, n) .* inc_mean')

    return L
end

# Function to compute the wage
# (i.e. the derivative of the production function with respect to labor):
function compute_wage(A::Float64, K::Float64, L::Float64, α::Float64)
    """
    Parameters
    ----------
    A::Float64
        Technology level
    K::Float64
        Capital
    L::Float64
        Labor
    α::Float64
        Capital's share of output

    Returns
    -------
    w::Float64
        Wage
    """

    return A * (1.0 - α) * (K^α) * (L^(-α))
end

# Function to compute the risk-free rate:
# (i.e. the derivative of the production function with respect to capital):
function compute_rf(A::Float64, K::Float64, L::Float64, α::Float64, δ::Float64)
    """
    Parameters
    ----------
    A::Float64
        Technology level
    K::Float64
        Capital
    L::Float64
        Labor
    α::Float64
        Capital's share of output
    δ::Float64
        Capital depreciation rate

    Returns
    -------
    r::Float64
        Risk-free interest rate
    """

    return (A * α * ((L / K)^(1.0 - α))) - δ
end
