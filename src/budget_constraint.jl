# File contains function to compute consumption from budget constraint:

# Function to compute consumption from budget constraint:
function compute_consumption(a_prime::Float64, a::Float64, y::Float64, ssb::Float64, parameters::Parameters)
    # Compute after tax net asset value:
    gross_asset = a * (1.0 + parameters.Production.r*(1.0 - parameters.Tax.τ))

    # Compute after tax income:
    after_tax_inc = (1.0 - parameters.Tax.θ - parameters.Tax.τ) * y * parameters.Production.w

    # Compute consumption:
    c = gross_asset + after_tax_inc + parameters.Tax.Tr + ssb - a_prime

    return c
end
