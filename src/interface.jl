
"""
    Meta(key, data)

Dedicated type for associating metadata with `key`. This is used to selectively reach
metadata using `Metadata.getmeta(x, key, d)`. `key` must be of a singleton type.

!!! warning 
    This is experimental and may change without warning
"""
struct Meta{K,P}
    parent::P

    global _Meta(@nospecialize(k), @nospecialize(p)) = new{k,typeof(p)}(p)
end

ArrayInterface.parent_type(@nospecialize T::Type{<:Meta}) = T.parameters[2]

Base.parent(@nospecialize x::Meta) = getfield(x, 1)

function Base.show(io::IO, ::MIME"text/plain", @nospecialize(x::Meta))
    print(io, "Meta(", metakey(x), ", ", parent(x), ")")
end

"""
    Metadata.rmkey(m::Meta) -> parent(m)
    Metadata.rmkey(m) -> m

Returns the the metadata key associated bound to `m`, if `m` is `Meta`. This is only
intended for internal use.

!!! warning
    This is experimental and may change without warning
"""
rmkey(@nospecialize x::Meta) = parent(x)
rmkey(@nospecialize x) = x

"""
    Metadata.metakey(m)

Returns the key associated withe the metadata `m`. The only way to attach a key to
metadata is through `Meta(key, m)`.

!!! warning
    This is experimental and may change without warning
"""
metakey(@nospecialize x::Meta) = metakey(typeof(x))
metakey(@nospecialize T::Type{<:Meta}) = T.parameters[1]

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
`unsafe_attach_metadata` is subsequently used to quickly bind the two without and further
checks.

# Extended help

In general, it is not advised to define new `attach_metadata` methods. Instead,
unique types for binding `x` to metadata should define a new `unsafe_attach_metadata`
method. For example, attaching metadata to `AbstractArray` types by defining a unique method
for `unsafe_attach_metadata(x::AbstractArray, m)`.

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

!!! warning
    This is experimentaland may change without warning
"""
checkmeta(x, m) = checkmeta(Bool, x, m) || throw(ArgumentError("data $x and metadata $m are incompatible."))
checkmeta(::Type{Bool}, x, m) = true

"""
    unsafe_attach_metadata(x, m)

Attaches metadata `m` to `x` without checking for compatability. New types for wrapping
binding metadata to `x` should usually  define a unique `unsafe_attach_metadata` method.

See also [`attach_metadata`](@ref)
"""
unsafe_attach_metadata(x, m) = _MetaStruct(x, m)
unsafe_attach_metadata(@nospecialize(x::MetaStruct), ::NoMetadata) = _MetaStruct(x, m)
unsafe_attach_metadata(@nospecialize(x::MetaStruct), @nospecialize(m)) = _MetaStruct(x, m)

"""
    properties(x)

Returns properties associated with bound to `x`.
"""
properties(@nospecialize(x)) = metadata(x)

