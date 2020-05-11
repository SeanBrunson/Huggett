# Main file to replicate Huggett (1996) paper.
# Results try to match Table 3, row 3 of uncertain lifetimes section.

using Plots
using Distributed
addprocs(4)

# Setup location of the files (replace path_name with the path to the Huggett folder):
@everywhere main_dir = "path_name/Huggett/"
@everywhere location_code = string(main_dir, "src/Huggett.jl")
@everywhere location_parameters = string(main_dir, "parameters/")
@everywhere include(location_code)

# Setup parameter combo:
parameter_iteration = 1

# Find the equilibrium:
@time K, Tr = Huggett.compute_equilibrium(K=150.0, Tr=4.0, max_iteration=40, tolerance=1e-5, parameter_iteration=parameter_iteration, location_parameters=location_parameters)

# Prepare parameters with the new equilibrium values:
df_parameters, st, interp_type = Huggett.prepare_parameters(parameter_iteration, location_parameters)
parameters = Huggett.initialize_parameters(K, Tr, df_parameters, st, interp_type)

# Rerun the model and simulate:
arrays = Huggett.run_huggett(parameters)
df = Huggett.simulate(arrays, 10000, parameters)

# Compute KY ratio (Huggett's value was 3.4):
Y = Huggett.compute_production_output(parameters.Production.A, parameters.Production.K, parameters.Production.L, parameters.Production.α)
ky_ratio = parameters.Production.K / Y

# Compute transfer wealth ratio (Huggett's value was 0.84):
transfer_wealth = Huggett.compute_agg_transfer(df, parameters)

# Compute Gini (Huggett's value is 0.69):
wealth_gini = Huggett.compute_gini(df.a_prime)

# Compute percentage of wealth in the top 1%, 5%, and 20%:
top_one = Huggett.compute_top_wealth(df.a_prime, 0.01)*100.0 # Huggett's value is 10.9%
top_five = Huggett.compute_top_wealth(df.a_prime, 0.05)*100.0 # Huggett's value is 32.9%
top_twenty = Huggett.compute_top_wealth(df.a_prime, 0.20)*100.0 # Huggett's value is 70.9%

# Compute percentage of agents with zero or negative wealth (Huggett's value is 17.0%):
zero_wealth = Huggett.compute_zero_wealth(df.a_prime)*100.0
