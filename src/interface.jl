
"""
    NoData

Internal type for the `Metadata` package that indicates the absence of any metadata.
_DO NOT_ store metadata with the value `NoData()`.

!!! warning
    This is not part of the public API and may change without notice.
"""
struct NoData end

Base.keys(::NoData) = ()
Base.values(::NoData) = ()
Base.haskey(::NoData, @nospecialize(k)) = false
Base.get(::NoData, @nospecialize(k), d) = d
Base.get(f::Union{Type,Function}, ::NoData, @nospecialize(k)) = f()
Base.iterate(::NoData) = nothing
Base.in(_, ::NoData) = false

const no_data = NoData()

Base.show(io::IO, ::NoData) = show(io, MIME"text/plain"(), no_data)
Base.show(io::IO, ::MIME"text/plain", ::NoData) = print(io, "no_data")

"""
    MetadataNode(key, data)

Dedicated type for associating metadata with `key`. This is used to selectively reach
metadata using `MetadataNodedata.getmeta(x, key, d)`. `key` must be of a singleton type.

!!! warning "Experimental"
    This is experimental and may change without warning
"""
struct MetadataNode{M, P, K}
    parent::P
    metadata::M

    global _MetadataNode
    _MetadataNode(@nospecialize(k), @nospecialize(p), @nospecialize(m)) = new{typeof(m),typeof(p),k}(p, m)
    _MetadataNode(@nospecialize(k), @nospecialize(p)) = new{NoData,typeof(p),k}(p, no_data)
end
function MetadataNode(k::K, @nospecialize(p), @nospecialize(m::MetadataNode)) where {K}
    @assert Base.issingletontype(K)
    _MetadataNode(k, p, m)
end
function MetadataNode(k::K, @nospecialize(p), ::NoData) where {K}
    @assert Base.issingletontype(K)
    _MetadataNode(k, p, m)
end
function MetadataNode(k::K, @nospecialize(p)) where {K}
    @assert Base.issingletontype(K)
    _MetadataNode(k, p)
end

ArrayInterface.parent_type(@nospecialize T::Type{<:MetadataNode}) = T.parameters[2]

Base.parent(@nospecialize x::MetadataNode) = getfield(x, :parent)

"""
    Metadata.rmkey(m::MetadataNode) -> parent(m)
    Metadata.rmkey(m) -> m

Returns the the metadata key associated bound to `m`, if `m` is `MetadataNode`. This is only
intended for internal use.

!!! warning
    This is experimental and may change without warning
"""
rmkey(@nospecialize x::MetadataNode) = parent(x)
rmkey(@nospecialize x) = x

"""
    Metadata.metakey(m)

Returns the key associated withe the metadata `m`. The only way to attach a key to
metadata is through `MetadataNode(key, m)`.

!!! warning
    This is experimental and may change without warning
"""
metakey(@nospecialize x::MetadataNode) = metakey(typeof(x))
metakey(@nospecialize T::Type{<:MetadataNode}) = T.parameters[3]


"""
    MDList(first::MetadataNode, tail::Union{MDList,NoData})

Iterable list of metadata.

!!! warning "Experimental"
    This is experimental and may change without warning
"""
struct MDList{F,T}
    first::F
    tail::T

    MDList(@nospecialize(f::MetadataNode), @nospecialize(t::MDList)) = new{typeof(f),typeof(t)}(f, t)
    MDList(@nospecialize(f::MetadataNode), t::NoData) = new{typeof(f),NoData}(f, t)
end

const MDListEnd{H} = MDList{H,NoData}

Base.first(@nospecialize mdl::MDList) = getfield(mdl, :first)

Base.tail(@nospecialize mdl::MDList) = getfield(mdl, :tail)

Base.iterate(@nospecialize(mdl::MDList)) = first(mdl), tail(mdl)
@inline function Base.iterate(@nospecialize(mdl::MDList), @nospecialize(state))
    if state === no_data
        return nothing
    else
        return first(state), tail(state)
    end
end

function Base.length(@nospecialize mdl::MDList)
    t = tail(mdl)
    if t === no_data
        return 1
    else
        return 1 + length(mdl)
    end
end


"""
    metadata(x)

Returns metadata immediately bound to `x`. If no metadata is bound to `x` then
`Metadata.no_data` is returned.
"""
metadata(x) = no_data
metadata(@nospecialize x::MetadataNode) = getfield(x, :metadata)

"""
    metadata_type(::Type{T})

Returns the type of the metadata associated with `T`.
"""
metadata_type(x) = metadata_type(typeof(x))
metadata_type(T::DataType) = NoData
metadata_type(@nospecialize m::MetadataNode) = typeof(m).parameters[1]
metadata_type(@nospecialize T::Type{<:MetadataNode}) = T.parameters[1]

# This summarizes all nested metadata wrappers using only the singleton types.
# The benefits are:
#
# - The return value is agnostic to the type of any parent data (e.g.,
#   `parent(::MetaStruct)`, `parent(::MetadataNode)`, etc.), thus avoiding extra code gen.
# - Since everything is a singleton type it's easy for the compiler to completely inline
#   even deeply nested types.
#
# Once we have this type we can use it to create a map of all the metadata nodes in the type
# domain without losing information or trying to specialize anymore.
@inline layout(@nospecialize x::MetadataNode) = _MetadataNode(metakey(x), layout(parent(x)))
@inline function layout(@nospecialize x)
    m = metadata(x)
    if m !== no_data
        return _MetaStruct(layout(parent(x)), layout(m))
    elseif Base.issingletontype(typeof(x))
        return x
    else
        return no_data
    end
end

"""
    has_metadata(x)::Bool

Returns `true` if `x` has metadata.
"""
@inline has_metadata(x) = !(metadata_type(x) <: NoData)

"""
    stripmeta(x) -> (data, metadata)

Returns the the data and metadata immediately bound to `x`.
"""
@inline function stripmeta(@nospecialize x)
    if metadata_type(x) <: NoData
        return (x, no_data)
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
    m = getmeta(metadata(x), k, no_data)
    if m === no_data
        return f(x)
    else
        return m
    end
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
attach_metadata(x, ::NoData) = x
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
unsafe_attach_metadata(@nospecialize(x::MetaStruct), ::NoData) = _MetaStruct(x, m)
unsafe_attach_metadata(@nospecialize(x::MetaStruct), @nospecialize(m)) = _MetaStruct(x, m)

"""
    properties(x)

Returns properties associated with bound to `x`.
"""
properties(@nospecialize(x)) = metadata(x)


Base.show(io::IO, ::MIME"text/plain", @nospecialize(m::MetadataNode)) = printmeta(io, m, "")
Base.show(io::IO, ::MIME"text/plain", @nospecialize(m::MDList)) = printmeta(io, m, "")

# printmeta
printmeta(io::IO, m, prefix::String) = print(io, m)
@inline function printmeta(io::IO, @nospecialize(mdl::MDList), prefix::String)
    print(io, "MDList")
    N = length(mdl)
    i = 1
    @inbounds for m_i in mdl
        child_prefix = prefix
        print(io, prefix)
        if i === nm
            print(io, "└")
            child_prefix *= " " ^ (Base.textwidth("│") + Base.textwidth("─") + 1)
        else
            print(io, "├")
            child_prefix *= "│" * " " ^ (Base.textwidth("─") + 1)
        end
        print(io, "─", ' ')
        printmeta(io, m_i, child_prefix)
        i += 1
    end
end
function printmeta(io::IO, @nospecialize(m::MetadataNode), prefix::String)
    print(io, metakey(mk), " => ", parent(m))
    if !(metadata_type(m) <: NoData)
        println(io)
        printmeta(io, metadata(m), prefix)
    end
end

