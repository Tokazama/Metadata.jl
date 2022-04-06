
"""
    metadata(x)

Returns metadata associated with `x`
"""
metadata(x) = _metadata(parent_type(x), x)
metadata(x::AbstractDict) = x
metadata(x::NamedTuple) = x
_metadata(::Type{P}, x::T) where {P,T} = metadata(parent(x))
_metadata(::Type{T}, x::T) where {T} = no_metadata

"""
    metadata(x::AbstractArray; dim)

Returns the metadata associated with dimension `dim` of `x`.
"""
function metadata(x::AbstractArray; dim=nothing)
    if dim === nothing
        return _metadata(parent_type(x), x)
    else
        return _metadata_dim(x, to_dims(x, dim))
    end
end
_metadata_dim(x, dim::Int) = metadata(axes(x, dim))
_metadata_dim(x, dim::StaticInt{D}) where {D} = metadata(axes(x, dim))
_metadata_dim(x::LinearIndices, dim::Int) = metadata(getfield(x.indices, dim))
_metadata_dim(x::LinearIndices, dim::StaticInt{D}) where {D} = metadata(getfield(x.indices, D))
_metadata_dim(x::CartesianIndices, dim::Int) = metadata(getfield(x.indices, dim))
_metadata_dim(x::CartesianIndices, dim::StaticInt{D}) where {D} = metadata(getfield(x.indices, D))

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
    metadata_type(::Type{<:AbstractArray}; dim)::Type

Returns the type of the metadata of `x`. If `dim` is specified then returns type of
metadata associated with dimension `dim`.
"""
metadata_type(x::AbstractArray; dim=nothing) = metadata_type(typeof(x); dim=dim)
@inline function metadata_type(::Type{T}; dim=nothing) where {T<:AbstractArray}
    if dim === nothing
        return _metadata_type(parent_type(T), T)
    else
        return _metadata_dim_type(T, to_dims(T, dim))
    end
end
_metadata_type(::Type{T}, ::Type{T}) where {T} = NoMetadata
_metadata_type(::Type{P}, ::Type{T}) where {P,T} = metadata_type(P)
_metadata_dim_type(::Type{T}, dim) where {T} = metadata_type(axes_types(T, dim))

"""
    stripmeta(x) -> (data, metadata)

Returns the the data and metadata immediately bound to `x`.
"""
@inline function stripmeta(x)
    if metadata_type(x) <: NoMetadata
        return (x, no_metadata)
    else
        return (parent(x), metadata(x))
    end
end

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
    metadata_type(::Type{T})

Returns the type of the metadata associated with `x`.
"""
metadata_type(x) = metadata_type(typeof(x))
metadata_type(::Type{T}) where {T} = _metadata_type(parent_type(T), T)
metadata_type(::Type{T}) where {T<:AbstractDict} = T
metadata_type(::Type{T}) where {T<:NamedTuple} = T

"""
    has_metadata(x)::Bool

Returns `true` if `x` has metadata.
"""
has_metadata(x) = has_metadata(typeof(x))
has_metadata(::Type{T}) where {T} = _has_metadata(metadata_type(T))
_has_metadata(::Type{NoMetadata}) = false
_has_metadata(::Type{T}) where {T} = true

"""
    has_metadata(x::AbstractArray; dim)::Bool

Returns `true` if `x` has metadata associated with dimension `dim`.
"""
has_metadata(x::AbstractArray; dim=nothing) = has_metadata(typeof(x); dim=dim)
function has_metadata(::Type{T}; dim=nothing) where {T<:AbstractArray}
    if dim === nothing
        return _has_metadata(metadata_type(T))
    else
        return _has_metadata(metadata_type(T; dim=dim))
    end
end

"""
    has_metadata(x, k)::Bool

Returns `true` if metadata associated with `x` has the key `k`.
"""
has_metadata(x, k) = haskey(metadata(x), k)

"""
    has_metadata(x::AbstractArray, k; dim)::Bool

Returns `true` if metadata associated with dimension `dim` of `x` has the key `k`.
"""
has_metadata(x::AbstractArray, k; dim=nothing) = haskey(metadata(x; dim=dim), k)

"""
    attach_metadata(x, metadata)

Generic method for attaching metadata to `x`.
"""
function attach_metadata(x, m=Dict{Symbol,Any}())
    if m === no_metadata
        return x
    else
        return MetaStruct(x, m)
    end
end
attach_metadata(x::AbstractArray, m=Dict{Symbol,Any}()) = MetaArray(x, m)
attach_metadata(x::AbstractUnitRange, m=Dict{Symbol,Any}()) = MetaUnitRange(x, m)
attach_metadata(x::IO, m=Dict{Symbol,Any}()) = MetaIO(x, m)
attach_metadata(m::METADATA_TYPES) = Base.Fix2(attach_metadata, m)

## macro utilities
argexpr(e::Symbol) = e
function argexpr(e::Expr)
    if e.head === :(::)
        return argexpr(e.args[1])
    elseif e.head === :macrocall
        return argexpr(e.args[3])
    else
        return e
    end
end

macro unwrap(e::Expr)
    _unwrap(2, e)
end
macro unwrap(pos::Int, e::Expr)
    _unwrap(pos + 1, e)
end

function _unwrap(pos::Int, e::Expr)
    if e.head === :macrocall
        call_expr = e.args[3]
        mcall = e.args[1]
        mline = e.args[2]
    else  # e.head === :call
        call_expr = e.args
        mcall = nothing
        mline = nothing
    end

    body = Expr(:block, Expr(:call, call_expr[1]))
    body_call = body.args[1]
    thunk = Expr(:call, call_expr[1])
    for i in 2:length(call_expr)
        if i === pos
            p = gensym(:parent)
            push!(thunk.args, :(@nospecialize($(call_expr[i]))))
            pushfirst!(body.args, Expr(:(=), p, :(parent($(argexpr(call_expr[i]))))))
            push!(body_call.args, p)
        else
            push!(thunk.args, call_expr[i])
            push!(body_call.args, argexpr(call_expr[i]))
        end
    end
    body = Expr(:block, body)
    if mcall !== nothing
        return esc(Expr(:macrocall, mcall, mline, Expr(:(=), thunk, body)))
    else
        return esc(Expr(:(=), thunk, body))
    end
end

macro defproperties(T)
    esc(quote
        Base.parent(@nospecialize x::$T) = getfield(x, 1)

        Metadata.stripmeta(@nospecialize x::$T) = (getfield(x, 1), getfield(x, 2))

        @inline function Metadata.metadata(@nospecialize(x::$T); dim=nothing, kwargs...)
            if dim === nothing
                return getfield(x, 2)
            else
                return metadata(parent(x); dim=dim)
            end
        end

        Base.getproperty(x::$T, k::String) = Metadata.metadata(x, k)
        @inline function Base.getproperty(x::$T, k::Symbol)
            if hasproperty(parent(x), k)
                return getproperty(parent(x), k)
            else
                return Metadata.metadata(x, k)
            end
        end

        Base.setproperty!(x::$T, k::String, v) = Metadata.metadata!(x, k, v)
        @inline function Base.setproperty!(x::$T, k::Symbol, val)
            if hasproperty(parent(x), k)
                return setproperty!(parent(x), k, val)
            else
                return Metadata.metadata!(x, k, val)
            end
        end

        @inline Base.propertynames(x::$T) = Metadata.metadata_keys(x)
    end)
end
