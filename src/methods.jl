
"""
    metadata!(x, k, val)

Set the value associated with key `k` of `x`'s metadata to `val`.
"""
@inline metadata!(x, k, val) = metadata!(metadata(x), k, val)
metadata!(x::AbstractDict, k, val) = setindex!(x, val, k)
metadata!(m::AbstractDict{String}, k::Symbol, val) = setindex!(m, val, String(k))
metadata!(m::AbstractDict{Symbol}, k::String, val) = setindex!(m, val, Symbol(k))

"""
    getmeta(x, key, default)

Return the metadata associated with `key`, or return `default` if `key` is not found.
"""
@inline getmeta(x, k, default) = _getmeta(metadata(x), k, default)
_getmeta(m, k, default) = get(m, k, default)
@inline _getmeta(m::AbstractDict{String}, k::Symbol, default) = get(m, String(k), default)
@inline _getmeta(m::AbstractDict{Symbol}, k::String, default) = get(m, Symbol(k), default)
@inline _getmeta(m::NamedTuple, k::String, default) = get(m, Symbol(k), default)

"""
    getmeta(f::Function, x, key)

Return the metadata associated with `key`, or return `f(x)` if `key` is not found. Note that
this behavior differs from `Base.get(::Function, x, keys)` in that `getmeta` passes `x` to
`f` as an argument (as opposed to `f()`).
"""
@inline function getmeta(f::Union{Function,Type}, x, k)
    m = getmeta(metadata(x), k, no_metadata)
    if m === no_metadata
        return f(x)
    else
        return m
    end
end

"""
    getmeta!(x, key, default)

Return the metadata associated with `key`. If `key` is not found then `default` is returned
and stored at `key`.
"""
@inline getmeta!(x, k, default) = _getmeta!(metadata(x), k, default)
_getmeta!(m, k, default) = get!(m, k, default)
@inline _getmeta!(m::AbstractDict{String}, k::Symbol, default) = get!(m, String(k), default)
@inline _getmeta!(m::AbstractDict{Symbol}, k::String, default) = get!(m, Symbol(k), default)

"""
    getmeta!(f::Function, x, key)

Return the metadata associated with `key`. If `key` is not found then `f(x)` is returned
and stored at `key`. Note that this behavior differs from `Base.get!(::Function, x, keys)` in
that `getmeta!` passes `x` to `f` as an argument (as opposed to `f()`).
"""
@inline function getmeta!(f::Function, x, k)
    m = metadata(x)
    out = get(m, k, no_metadata)
    if out === no_metadata
        out = f(x)
        metadata!(m, k, out)
    end
    return out
end

"""
    has_metadata(x, k)::Bool

Returns `true` if metadata associated with `x` has the key `k`.
"""
has_metadata(x, k) = haskey(metadata(x), k)

# This allows dictionaries's keys to be treated like property names
metadata_keys(x::AbstractDict) = keys(x)
metadata_keys(::NamedTuple{L}) where {L} = L
function metadata_keys(x::X) where {X}
    if has_metadata(X)
        return metadata_keys(metadata(x))
    else
        return propertynames(x)
    end
end

