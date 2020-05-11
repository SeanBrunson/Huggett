# File to compute the Rouwenhorst method for an AR1 model:

function rouwenhorst(N::Int64, ρ::Float64, σ_ϵ::Float64)
    """
    Parameters
    ----------
    N::Int64
        Number of states for the Markov process.
    ρ::Float64
        Persistence of the underlying process.
    σ_ϵ::Float64
        Standard deviation for the income shock.

    Returns
    -------
    θ::Array
        Markov probability matrix.
    grid::Vector
        Vector of income shocks.
    """

    # Setup parameters:
    p = q = (1.0 + ρ) / 2.0
    σ_z = σ_ϵ / sqrt(1.0 - ρ^2)
    ψ = sqrt(N - 1.0) * σ_z

    # Setup transition matrix if N is 2:
    θ = [p (1.0 - p);
         (1.0 - q) q]

    # Setup the grid values given parameters:
    grid = collect(range(-ψ, stop=ψ, length=N))

    # Get the transition matrix:
    if N == 2
        return θ, grid
    else
        for i = 3:N
            θ_N1 = θ
            θ = p*[θ_N1 zeros(i - 1, 1); zeros(1, i)] + (1.0 - p)*[zeros(i - 1, 1) θ_N1; zeros(1, i)] + (1.0 - q)*[zeros(1, i); θ_N1 zeros(i - 1, 1)] + q*[zeros(1, i); zeros(i - 1, 1) θ_N1]
            θ[2:end-1, :] = θ[2:end-1, :] / 2.0
        end

        #Renormalize so that rows sum to 1:
        return θ ./ sum(θ, dims=2), grid
    end
end
