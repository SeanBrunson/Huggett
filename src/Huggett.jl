module Huggett

using CSV, DataFrames, Distributions, Distributed, Interpolations, LinearAlgebra, Optim, Random, SharedArrays, Statistics
export

# gridmake:
gridmake, gridmake!,

# rouwenhorst:
rouwenhorst,

# compute_income:
compute_income, compute_income_age, get_retirement_lambda,

# compute_gini:
compute_gini, compute_top_wealth, compute_zero_wealth,

# production_functions:
compute_production_output, compute_labor_input, compute_wage, compute_rf,

# utility_function:
compute_utility, compute_utility_derivative,

# setup_parameters:
Grids, GridSizes, IncomeShocks, Demographic, Production, Tax, Parameters, get_stationary_chain, get_μt, setup_asset_grid, setup_income_shocks, setup_production, setup_parameters, prepare_parameters, initialize_parameters,

# setup_state_combos:
setup_state_combos,

# setup_arrays:
ValueArrays, DecisionArrays, AnswerArrays, setup_arrays,

# budget_constraints:
compute_consumption,

# helper_functions:
convert_t, Combos, parse_combos,

# setup_interpolation:
ValueInterp, ValueInterpArrays, setup_interp, get_interp, bound_check_a,

# max_value_func:
compute_terminal_value, compute_next_value, get_exp_future, maximize_agent,

# run_huggett:
run_huggett, solve_all!, solve_agent,

# simulate:
MCSample, draw_mc_shock, setup_idio_shocks, setup_initial_distribution, update_distribution, SimChoiceInterp, SimInterpFuncs, setup_interp_sim, setup_choice_interp, get_interp_sim, find_opt_choice, sim_individual!, loop_individual!, simulate,

# compute_equilibrium:
clear_consumption, compute_asset_value, clear_asset, clear_labor, compute_new_transfers, compute_agg_transfer, compute_equilibrium

# File names:
include("gridmake.jl")
include("rouwenhorst.jl")
include("compute_income.jl")
include("compute_gini.jl")
include("production_functions.jl")
include("utility_functions.jl")
include("setup_parameters.jl")
include("setup_state_combos.jl")
include("setup_arrays.jl")
include("budget_constraint.jl")
include("helper_functions.jl")
include("setup_interpolation.jl")
include("max_value_func.jl")
include("run_huggett.jl")
include("simulate.jl")
include("compute_equilibrium.jl")

end
