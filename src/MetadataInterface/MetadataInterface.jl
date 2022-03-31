module MetadataInterface
@doc let path = joinpath(dirname(@__DIR__), "MetadataInterface", "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end MetadataInterface

using ArrayInterface
using ArrayInterface: parent_type
using Static

export
    Attribute,
    attach_metadata,
    all_attr,
    attr,
    attribute,
    metadata,
    is_attr,
    rawdata,
    strip_attr

"""
    NoMetadata

Internal type for the `Metadata` package that indicates the absence of any metadata.
_DO NOT_ store metadata with the value `NoMetadata()`.
"""
struct NoMetadata <: AbstractDict{Symbol,Any} end

const no_metadata = NoMetadata()

Base.keys(::NoMetadata) = ()
Base.values(::NoMetadata) = ()
Base.iterate(::NoMetadata, states...) = nothing
Base.haskey(::NoMetadata, @nospecialize(k)) = false
Base.get(::NoMetadata, @nospecialize(k), default) = default
Base.get(f::Union{Type,Function}, ::NoMetadata, @nospecialize(k)) = f()

"""
    MetaStruct(p, m)

Binds a parent instance (`p`) to some metadata (`m`). `MetaStruct` is the generic type
constructed when `attach_metadata(p, m)` is called.

See also: [`attach_metadata`](@ref), [`attach_eachmeta`](@ref)
"""
struct MetaStruct{P,M}
    parent::P
    metadata::M

    global _MetaStruct(p::P, m::M) where {P,M} = new{P,M}(p, m)
end

Base.parent(x::MetaStruct) = getfield(x, :parent)
ArrayInterface.parent_type(::Type{<:MetaStruct{P}}) where {P} = P

"""
    metadata_type(::Type{T})

Returns the type of the metadata that `T` is bound to. If no metadata is bound to `T` then
`NoMetadata` is returned. This only looks for metadata immediately bound by `T`. Therefore,
nested metadata will no be returned.
"""
metadata_type(@nospecialize(x)) = metadata_type(typeof(x))
metadata_type(::Type{T}) where {T} = NoMetadata
metadata_type(::Type{<:MetaStruct{<:Any,M}}) where {M} = M

"""
    metadata(x)

Returns the metadata associated with `x`. Falls back to `Metadat.no_metadata`.
"""
@inline metadata(x) = no_metadat
metadata(@nospecialize x::MetaStruct) = getfield(x, 2)

"""
    hasmeta(::Type{T})::StaticBool

Returns `True()` if `T` has metadata bound to it.
"""
@inline hasmeta(::Type{T}) where {T} = metadata_type(T) <: NoMetadata ? False() : True()

"""
    rawdata(x)

Returns raw data by recursively calling `parent`.
"""
@inline rawdata(x::X) where {X} = _rawdata(parent(x), x)
rawdata(::X, y::Y) where {X,Y} = rawdata(y)
_rawdata(::X, x::X) where {X} = x

"""
    MetadataException(msg)
    MetadataException(parent, metadata)

Exception thrown when `parent` and `metadata` are not compatible. This is often thrown when
failing [`checkmeta`](@ref).
"""
struct MetadataException
    msg::String

    MetadataString(msg::String) = new(msg)
    MetadataException() = MetadataException("")
    function MetadataException(@nospecialize(p), @nospecialize(m))
        "cannot attach metadata $(m) to $(p). See `checkmeta`."
    end
end
Base.showerror(io::IO, e::MetadataException) = print(io, "MetadataException: ", e.msg)

"""
    Attribute{A}(m)

Type level declaration that the metadata `m` is associated with any data it's bound to
through the attribute `A`. Note that `m` cannot be another isntance of `Attribute` at any
level.
"""
struct Attribute{A,P}
    parent::P

    function Attribute{A,D}(d::D) where {A,D<:Attribute}
        throw(ArgumentError("Wrapping an instance of `Attribute` in another `Attribute` is dissallowed."))
    end
    Attribute{A,D}(d::D) where {A,D} = new{A,D}(d)
    Attribute{A}(d::D) where {A,D} = Attribute{A,D}(d)
end

Base.parent(a::Attribute) = getfield(a, 1)

# `remattr(a)`: ensures that `a` is not wrapped in an instance of `Attribute`
remattr(a::Attribute) = parent(a)
remattr(@nospecialize(a)) = a

"""
    check_meta([Type{Bool}], x, m)

Checks if the metadata `m` is compatible with `x`. If `Bool` is not included then an error
is throw on failure.
"""
check_meta(x, m) = check_meta(Bool, x, m) || throw(MetadataException(x, m))
check_meta(::Type{Bool}, x, m) = true

"""
    unsafe_attach_metadata(x, m)

Attaches metadata `m` to `x` without checking for compatability.
"""
unsafe_attach_metadata(x, m) = _MetaStruct(x, m)
@inline function unsafe_attach_metadata(x::Attribute{A}, m) where {A}
    Attribute{A}(unsafe_attach_metadata(getfield(x, 1), m))
end

"""
    attach_metadata(x, metadata)

Generic method for attaching metadata to `x`.
"""
@inline function attach_metadata(x::Attribute{A}, m) where {A}
    Attribute{A}(attach_metadata(getfield(x, 1), m))
end
attach_metadata(x::Attribute, ::NoMetadata) = x
attach_metadata(x, ::NoMetadata) = x
function attach_metadata(x, m)
    check_meta(x, m)
    unsafe_attach_metadata(x, m)
end

"""
    properties(x)

Returns a dictionary of properties properties associated with `x`.
"""
properties(x) = attr(x, properties, no_metadata)

"""
    annotation(x)

Returns the annotation associated with `x`.
"""
function annotation(x)
    attr(x, properties, no_metadata)
end

"""
    attribute(::Type{M})

Returns the attribute associated with metadata of type `M`.
"""
@inline attribute(@nospecialize(m)) = attribute(typeof(m))
attribute(::Type{M}) where {M} = _attribute(parent_type(M), M)
_attribute(::Type{X}, ::Type{X}) where {X} = metadata
_attribute(::Type{X}, ::Type{Y}) where {X,Y} = attribute(Y)
# avoid specializing on `pairs(::NamedTuple)
attribute(@nospecialize M::Type{<:Base.Pairs}) = properties
attribute(M::Type{<:AbstractDict}) = properties
attribute(M::Type{<:AbstractString}) = annotation
attribute(::Type{Symbol}) = annotation
attribute(@nospecialize M::Type{<:StaticSymbol}) = annotation
attribute(::Type{<:Attribute{A}}) where {A} = A

"""
    is_attr(::Type{M}, a)::Union{True,False}

Returns `True()` if the metadata type `M` corresponds to the attribute `a`. Otherwise
returns `False()`.
"""
@inline is_attr(@nospecialize(x), a::A) where {A} = is_attr(typeof(x), a)
is_attr(::Type{NoMetadata}, ::Any) = False()
@inline function is_attr(::Type{M}, a::A) where {M,A}
    if isa(attribute(M), a)
        return True()
    else
        return False()
    end
end

"""
    has_attr(::Type{T}, attr)::StaticBool

Where `T` is a type that binds metadata to data, returns `True()` if metadata at any nested
level associated with `attr`. Otherwise returns `False`.
"""
@inline has_attr(::Type{T}, a::A) where {T,A} = _has_attr(is_attr(metadata_type(T), a), T, parent_type(T), a)
_has_attr(::False, ::Type{X}, ::Type{X}, a::A) where {X,A} = False()
@inline _has_attr(::False, ::Type{X}, ::Type{Y}, a::A) where {X,Y,A} = has_attr(Y, a)

"""
    attr(x, a, default)

Returns the metadata bound to `x` that corresponds to the attribute `a`. If `x` doesn't have
an attribute corresponding to `a` then `default` is returned.
"""
@inline attr(x::X, a::A, d) where {X,A} = _attr(is_attr(metadata_type(X), a), x, a, d)
@inline _attr(::True, x::X, a::A, d) where {X,A} = remattr(metadata(x))
@inline _attr(::False, x::X, a::A, d) where {X,A} = __attr(has_attr(x, a), x, a, d)
@inline __attr(::True, x::X, a::A, d) where {X,A} = attr(parent(x), a, d)
__attr(::False, x::X, a::A, d) where {X,A} = d

"""
    attr(x, a)

Returns the metadata bound to `x` that corresponds to the attribute `a`. If `x` doesn't have
an attribute corresponding to `a` then an error is thrown.
"""
@inline function attr(x::X, a::A) where {X,A}
    out = attr(x, a, no_metadata)
    out !== no_metadata && return out
    errmsg(x, a) = error("No metadata in $x is associated with the attribute $a.")
    errmsg(x, a)
end

"""
    all_attr(x, a)::Tuple

Returns a tuple of all metadata bound to `x` that corresponds to the attribute `a`.
"""
@inline function all_attr(x::X, a::A) where {X,A}
    _all_attr(is_attr(metadata_type(X), a), has_attr(parent_type(X), a), x, a)
end
@inline _all_attr(::False, ::False, x::X, a::A) where {X,A} = ()
@inline _all_attr(::False, ::True, x::X, a::A) where {X,A} = all_attr(parent(x), a)
@inline _all_attr(::True, ::False, x::X, a::A) where {X,A} = (remattr(metadata(x)), )
@inline _all_attr(::True, ::True, x::X, a::A) where {X,A} = (remattr(metadata(x)), all_attr(parent(x), a)...)

"""
    strip_attr(x, a) -> (data, metadata)

Returns `x` stripped of metadata associated with the attribute `a`. If no metadata is
associated with `a` then `(x, Metadtaa.no_metadata)` is returned. Only the most superficial
metadata associated with the attribute is stripped. If other metadata is more deeply  nested
within `x` and is associated with the attribute it is not removed.
"""
@inline strip_attr(x::X, a::A) where {X,A} = _strip_attr(is_attr(metadata_type(X), a), x, a)
@inline _strip_attr(::True, x::X, a::A) where {X,A} = parent(x), remattr(metadata(x))
@inline _strip_attr(::False, x::X, a::A) where {X,A} = __strip_attr(has_attr(parent_type(X), a), x, a)
@inline function __strip_attr(::True, x::X, a::A) where {X,A}
    _reconstruct_stripped(strip_attr(parent(x), a), metadat(x))
end
# `MNested` corresponds to the metadat that was associated with the attribute but we don't
# want to strip off the metadata `m` that didn't correspond to the attribute.
@inline function _reconstruct_stripped(xm::Tuple{X,MNested}, m::M) where {X,MNested,M}
    unsafe_attach_metadata(getfield(xm, 1), m), getfield(xm, 2)
end

# FIXME this will strip out parent types innapropriately for things like `SubArray`
"""
    strip_meta(x) -> (parent(x), metadata(x))

Returns the data and metadata associated with `x`.
"""
function strip_meta(x::X) where {X}
    if parent_type(X) <: X
        return (x, no_metadata)
    else
        return (parent(x), metadata(x))
    end
end

function strip_all_meta(x)
    p, m = strip_meta(x)
    if p === x
        return (x, (m,))
    else
        d, ms = strip_all_meta(p)
        return (d, (m, ms...))
    end
end

function print_meta(io::IO, @nospecialize(x), pad::String="")
    p, m = strip_all_meta(x)
    println(io, p)
    _print_meta(io, m, lpad(pad, 3))
end
function _print_meta(io, @nospecialize(m::Tuple), pad::String)
    for m_i in m
        if m_i !== no_metadata
            a = attribute(m_i)
            if a !== metadata
                print(io, pad)
                print(io, "attribute: ")
                print(io, a)
            end
            md, msub = strip_all_meta(remattr(m_i))
            println(io)
            print(io, pad)
            print(io, "metdata: ")
            print(io, md)
            _print_meta(io, msub, lpad(pad, 3))
        end
    end
end


end
