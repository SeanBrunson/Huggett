# File that contains functions to create a grid of state vector combinations.
# These functions are from QuantEcon:

function gridmake!(out, arrays::Union{AbstractVector,AbstractMatrix}...)
    lens = Int[size(e, 1) for e in arrays]

    n = sum(_i -> size(_i, 2), arrays)
    l = prod(lens)
    @assert size(out) == (l, n)

    reverse!(lens)
    repititions = cumprod(vcat(1, lens[1:end-1]))
    reverse!(repititions)
    reverse!(lens)  # put lens back in correct order

    col_base = 0

    for i in 1:length(arrays)
        arr = arrays[i]
        ncol = size(arr, 2)
        outer = repititions[i]
        inner = floor(Int, l / (outer * lens[i]))
        for col_plus in 1:ncol
            row = 0
            for _1 in 1:outer, ix in 1:lens[i], _2 in 1:inner
                out[row+=1, col_base+col_plus] = arr[ix, col_plus]
            end
        end
        col_base += ncol
    end
    
    return out
end

@generated function gridmake(arrays::AbstractArray...)
    T = reduce(promote_type, eltype(a) for a in arrays)
    quote
        l = 1
        n = 0
        for arr in arrays
            l *= size(arr, 1)
            n += size(arr, 2)
        end
        out = Matrix{$T}(undef, l, n)
        gridmake!(out, arrays...)
        out
    end
end

function gridmake(t::Tuple)
    all(map(x -> isa(x, Integer), t)) ||
        error("gridmake(::Tuple) only valid when all elements are integers")
    gridmake(map(x->1:x, t)...)::Matrix{Int}
end
