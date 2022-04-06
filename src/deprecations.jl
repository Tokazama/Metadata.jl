

"""
    metadata(x, k)

Returns the value associated with key `k` of `x`'s metadata.
"""
function metadata(x, k)
    out = getmeta(x, k, no_metadata)
    out === no_metadata && throw(KeyError(k))
    return out
end

"""
    metadata!(x::AbstractArray, k, val)

Set the value associated with key `k` of `x`'s metadata to `val`.
"""
@inline metadata!(x, k, val) = metadata!(metadata(x), k, val)
metadata!(x::AbstractDict, k, val) = setindex!(x, val, k)
metadata!(m::AbstractDict{String}, k::Symbol, val) = setindex!(m, val, String(k))
metadata!(m::AbstractDict{Symbol}, k::String, val) = setindex!(m, val, Symbol(k))

"""
    metadata!(x::AbstractArray, k, val; dim)

Set the value associated with key `k` of the metadata at dimension `dim` of `x` to `val`.
"""
metadata!(x::AbstractArray, k, val; dim=nothing) = metadata!(metadata(x; dim=dim), k, val)

"""
    metadata(x::AbstractArray, k; dim)

Returns the value associated with key `k` of `x`'s metadata.
"""
@inline function metadata(x::AbstractArray, k; dim=nothing)
    if dim === nothing
        if has_metadata(x)
            return metadata(metadata(x), k)
        else
            return no_metadata
        end
    else
        return metadata(metadata(x; dim=dim), k)
    end
end

