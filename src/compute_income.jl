# File to compute total income for an agent:

# Function to compute total income:
function compute_income(shocks_idio::Float64, current_age::Int64, retirement_age::Int64, education::String)
    """
    Parameters
    ----------
    shocks_idio::Float64
        Idiosyncratic shock component of income
    current_age::Int64
        Current age of individual to determine the deterministic part
    retirement_age::Int64
        Retirement age of individual
    education::String
        Education level of the individual

    Returns
    -------
    income::Float64
        Income
    """

    if current_age >= retirement_age
        age = retirement_age - 1
        deter = compute_income_age(age, education)
        inc = exp(shocks_idio + deter + log(get_retirement_lambda(education)))
    else
        deter = compute_income_age(current_age, education)
        inc = exp(shocks_idio + deter)
    end

    return inc
end

# Function to compute age dependent log income.
# Comes from Cocco, Gomes, and Maenhout (RFS 2005) because I do not have the
# ybar used in Hugget (JME 1996):
function compute_income_age(age::Int64, education::String)
    """
    Parameters
    ----------
    age::Int64
        Age of individual.
    education::String
        Education level of the individual.

    Returns
    -------
    value::Float64
        Income of individual at given age.
    """

    if education == "college"
        value = -4.3148 + 2.3831 + 0.3194*age - 0.0577*(age^2)/10 + 0.0033*(age^3)/100
    elseif education == "high"
        value = -2.1700 + 2.7004 + 0.1682*age - 0.0323*(age^2)/10 + 0.0020*(age^3)/100
    else
        value = -2.1361 + 2.6275 + 0.1684*age - 0.0353*(age^2)/10 + 0.0023*(age^3)/100
    end

    return value
end

# Function that gets the value to shift income after retirement age.
# Comes from Cocco, Gomes, and Maenhout (RFS 2005):
function get_retirement_lambda(education::String="college")
    """
    Parameters
    ----------
    education::String
        Education level of the individual.
        Defaults to "college".

    Returns
    -------
    value::Float64
        Replacement value that shifts income after retirement age
    """

    if education == "college"
        return 0.938873
    elseif education == "high"
        return 0.68212
    else
        return 0.88983
    end
end
