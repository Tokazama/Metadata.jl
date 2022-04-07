
"""
    metadata(x)

Returns metadata associated with `x`
"""
metadata(x) = no_metadata

"""
    metadata_type(::Type{T})

Returns the type of the metadata associated with `x`.
"""
metadata_type(x) = metadata_type(typeof(x))
metadata_type(T::DataType) = NoMetadata

"""
    has_metadata(x)::Bool

Returns `true` if `x` has metadata.
"""
@inline has_metadata(x) = !(metadata_type(x) <: NoMetadata)

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

struct GetMeta{K,D}
    key::K
    default::D
end

@inline (g::GetMeta)(x) = _getmeta(metadata(x), getfield(g, 1), getfield(g, 2))

"""
    getmeta(x, key, default)

Return the metadata associated with `key`, or return `default` if `key` is not found.
"""
@inline getmeta(x, k, default) = GetMeta(k, default)(x)
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
        m[k] = out
    end
    return out
end

"""
    has_metadata(x, k)::Bool

Returns `true` if metadata associated with `x` has the key `k`.
"""
has_metadata(x, k) = haskey(metadata(x), k)

"""
    attach_metadata(x, m)

Generic method for attaching metadata `m` to data `x`. This method acts as an intermediate
step where compatability between `x` and `m` is checked using `checkmeta`.
`unsafe_attach_metadata` is subsequently used to quickly bind the two without and further checks.

See also: [`unsafe_attach_metadata`](@ref), [`checkmeta`](@ref)
"""
function attach_metadata(x, m)
    checkmeta(x, m)
    unsafe_attach_metadata(x, m)
end
attach_metadata(x, ::NoMetadata) = x
attach_metadata(m) = Base.Fix2(attach_metadata, m)

"""
    checkmeta([Type{Bool}], x, m)

Checks if the metadata `m` is compatible with `x`. If `Bool` is not included then an error
is throw on failure.
"""
checkmeta(x, m) = checkmeta(Bool, x, m) || throw(ArgumentError("data $x and metadata $m are incompatible."))
checkmeta(::Type{Bool}, x, m) = true

"""
    unsafe_attach_metadata(x, m)

Attaches metadata `m` to `x` without checking for compatability. New types for wrapping
binding metadata to `x` should usually  define a unique `unsafe_attach_metadata` method.

See also [`attach_metadata`](@ref)
"""
unsafe_attach_metadata

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

        Metadata.metadata(@nospecialize(x::$T)) = getfield(x, 2)

        Base.getproperty(x::$T, k::String) = getproperty(x, Symbol(k))
        @inline function Base.getproperty(x::$T, k::Symbol)
            if hasproperty(parent(x), k)
                return getproperty(parent(x), k)
            else
                return metadata(x)[k]
            end
        end

        Base.setproperty!(x::$T, k::String, v) = setproperty!(x, Symbol(k), v)
        @inline function Base.setproperty!(x::$T, k::Symbol, v)
            if hasproperty(parent(x), k)
                return setproperty!(parent(x), k, v)
            else
                return metadata(x)[k] = v
            end
        end
        @inline Base.propertynames(x::$T) = keys(metadata(x))
    end)
end

