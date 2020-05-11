# File contains functions to examine wealth distribution coefficient:

# Function to compute Gini coefficient:
function compute_gini(x::AbstractArray)
    # Compute Gini coefficient:
    x = sort(x)
    weights = repeat([1.0 / length(x)], outer=length(x))
    p = cumsum(weights)
    nu = cumsum(weights .* x)
    n = length(nu)
    nu = nu / nu[n]

    return sum(nu[2:end] .* p[1:(n-1)]) - sum(nu[1:(n-1)] .* p[2:end])
end

# Function to compute the percentage of wealth held by the top p%:
function compute_top_wealth(x::AbstractArray, percentage::Float64)
    # Get total value of x:
    x_total = sum(x)

    # Get top percentage of x:
    x_subset = x[x .>= quantile(x, 1.0 - percentage)]

    return sum(x_subset) / x_total
end

# Function to compute the percentage of individuals with zero or negative wealth:
function compute_zero_wealth(x::AbstractArray)
    # Get length of x:
    n = length(x)

    # Subset x to zero or negative values:
    x_subset = x[x .<= 1e-8]

    return length(x_subset) / n
end
