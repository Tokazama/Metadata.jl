# TODO incorporate this stuff in docs
# * we consider these metadata unless they specifically overload a metadata_type method
# * the main API can be accomplished by defining `metadata` and `metadata_type` 

"""
    NoMetadata

Internal type for the `Metadata` package that indicates the absence of any metadata.
_DO NOT_ store metadata with the value `NoMetadata()`.
"""
struct NoMetadata end
const no_metadata = NoMetadata()
Base.show(io::IO, ::NoMetadata) = print(io, "no_metadata")


"""
    metadata(x[, k::Symbol; dim])

Returns metadata from `x`. If `k` is specified then the metadata value paired to
`k` is returned. If `dim` is specified then the operation is performed for metadata
specific to dimension `dim`.
"""
metadata(x; dim=nothing) = _metadata(x, dim)
_metadata(x, ::Val{dim}) where {dim} = _metadata(x, dim)
_metadata(x, dim) = metadata(axes(x, dim))
@inline function _metadata(x::X, ::Nothing) where {X}
    if parent_type(X) <: X  
        return no_metadata
    else
        # although `X` doesn't explicitly have metadata, it does have a parent structure
        # that may have metadata.
        return metadata(parent(x))
    end
end
metadata(x::AbstractDict{Symbol}) = x
metadata(x::NamedTuple) = x

metadata(x, k::Symbol; dim=nothing) = _metadata(x, k, dim)
_metadata(x, k::Symbol, ::Val{dim}) where {dim} = _metadata(x, k, dim)
_metadata(x, k::Symbol, dim) = metadata(axes(x, dim), k)
@inline function _metadata(x, k::Symbol, ::Nothing)
    if metadata_type(x) <: AbstractDict
        return getindex(metadata(x), k)
    else
        return getproperty(metadata(x), k)
    end
end

"""
    metadata_type(x[, k::Symbol]) -> Type

Returns the type of the metadata of `x`. If `k` present then attempts to find the
type of the metadata paired to `k`.
"""
metadata_type(::T) where {T} = metadata_type(T)
metadata_type(::Type{T}) where {T<:AbstractDict} = T
metadata_type(::Type{T}) where {T<:NamedTuple} = T
function metadata_type(::Type{A}) where {A<:AbstractArray}
    if parent_type(A) <: A
        return NoMetadata
    else
        return metadata_type(parent_type(A))
    end
end

metadata_type(x, k::Symbol) = metadata_type(metadata_type(x), k)
metadata_type(::Type{T}, k::Symbol) where {T} = fieldtype(T, k)
metadata_type(::Type{T}, k::Symbol) where {T<:AbstractDict} = valtype(T)

"""
    MetadataPropagation(::Type{T}) -> Union{Drop,Copy,Share}

When metadata of type `T` is attached to something should the same in memory instance
be attached or a deep copy of the metadata?
"""
abstract type MetadataPropagation end

struct DropMetadata <: MetadataPropagation end

struct CopyMetadata <: MetadataPropagation end

struct ShareMetadata <: MetadataPropagation end

MetadataPropagation(x) = MetadataPropagation(typeof(x))
MetadataPropagation(::Type{T}) where {T} = MetadataPropagation(metadata_type(T))
MetadataPropagation(::Type{<:AbstractDict}) = ShareMetadata()
MetadataPropagation(::Type{<:NamedTuple}) = ShareMetadata()
MetadataPropagation(::Type{NoMetadata}) = DropMetadata()

function maybe_propagate_metadata(src, dst)
    return maybe_propagate_metadata(MetadataPropagation(src), src, dst)
end
maybe_propagate_metadata(::DropMetadata, src, dst) = dst
maybe_propagate_metadata(::ShareMetadata, src, dst) = share_metadata(src, dst)
maybe_propagate_metadata(::CopyMetadata, src, dst) = copy_metadata(src, dst)

#= TODO
+(x, y) needs to have a way of combining metadata and incorporating the propagation
info for each type

function combine_metadata(x::AbstractUnitRange, y::AbstractUnitRange)
    return combine_metadata(metadata(x), metadata(y))
end
combine_metadata(x, y)
combine_metadata(::Nothing, ::Nothing) = nothing
combine_metadata(::Nothing, y) = y
combine_metadata(x, ::Nothing) = x
combine_metadata(x, y) = merge(x, y)
=#

"""
    has_metadata(x) -> Bool

Returns true if `x` has metadata.
"""
has_metadata(x) = has_metadata(typeof(x))
has_metadata(::Type{T}) where {T} = !(metadata_type(T) <: NoMetadata)

"""
    has_metadata(x, k) -> Bool

Returns true if `x` has metadata with a mapping for `k`.
"""
@inline function has_metadata(x::X, k::Symbol) where {X}
    if metadata_type(X) <: AbstractDict
        return haskey(metadata(x), k)
    else
        return hasproperty(metadata(x), k)
    end
end

"""
    attach_metadata(x, metadata)

Generic method for attaching metadata to `x`.
"""
attach_metadata(m) = Fix2(attach_metadata, m)

"""
    share_metadata(src, dst) -> attach_metadata(dst, metadata(src))

Shares the metadata from `src` by attaching it to `dst`.
The returned instance will have properties that are synchronized with `src` (i.e.
modifying one's metadata will effect the other's metadata).

See also: [`copy_metadata`](@ref).
"""
share_metadata(src, dst) = attach_metadata(dst, metadata(src))

"""
    copy_metadata(src, dst) -> attach_metadata(dst, copy(metadata(src)))

Copies the the metadata from `src` and attaches it to `dst`. Note that this method
specifically calls `deepcopy` on the metadata of `src` to ensure that changing the
metadata of `dst` does not affect the metadata of `src`.

See also: [`share_metadata`](@ref).
"""
copy_metadata(src, dst) = attach_metadata(dst, deepcopy(metadata(src)))

"""
    drop_metadata(x)

Returns `x` without metadata attached.
"""
drop_metadata(x) = parent(x)

"""
    axis_meta(x)

Returns metadata (i.e. not keys or indices) associated with each axis of the array `x`.
"""
axis_meta(x::AbstractArray) = map(metadata, axes(x))

"""
    axis_metaproperty(x, i, meta_key)

Return the metadata of `x` paired to `meta_key` at axis `i`.
"""
axis_metaproperty(x, i, meta_key::Symbol) = _metaproperty(axis_meta(x, i), meta_key)

"""
    axis_setmeta!(x, meta_key, val)

Set the metadata of `x` paired to `meta_key` at axis `i`.
"""
axis_setmeta!(x, i, meta_key::Symbol, val) = _setmeta!(axis_meta(x, i), meta_key, val)

"""
    has_axis_metaproperty(x, dim, meta_key)

Returns true if `x` has a property in its metadata structure paired to `meta_key` stored
at the axis corresponding to `dim`.
"""
has_axis_metaproperty(x, i, meta_key::Symbol) = _has_metaproperty(axis_meta(x, i), meta_key)

##
### keys
###
known_keys(x) = known_keys(typeof(x))
known_keys(::Type{T}) where {T} = nothing
known_keys(::Type{NamedTuple{L,T}}) where {L,T} = L

# when keys are known at compile time
known_metadata_keys(x) = known_metadata_keys(typeof(x))
known_metadata_keys(::Type{T}) where {T} = known_keys(metadata_type(T))

# This allows dictionaries's keys to be treated like property names
@inline function metadata_keys(x)
    if metadata_type(x) <: NoMetadata
        return propertynames(x)
    else
        return metadata_keys(metadata(x))
    end
end
metadata_keys(x::AbstractDict) = keys(x)
metadata_keys(x::NamedTuple{L}) where {L} = L

macro metadata_properties(T)
    quote
        @inline function Base.getproperty(x::$T, k::Symbol)
            if hasproperty(parent(x), k)
                return getproperty(parent(x), k)
            else
                return Metadata.metadata!(x, k, val)
            end
        end

        @inline function Base.setproperty!(x::$T, k::Symbol, val)
            if hasproperty(parent(x), k)
                return setproperty!(parent(x), k, val)
            else
                return Metadata.metadata!(x, k, val)
            end
        end
        @inline Base.propertynames(x::$T) = Metadata.metadata_keys(x)
    end
end

function metadata_summary(x)
    str = "  • metadata:\n"
    for k in metadata_keys(x)
        str *= "    - $k : $(metadata(x, k))\n"
    end
    return str
end

"""
    @defsummary(T[, fxn])

Defines the following methods for `T`:
```julia
Base.summary(x::T) = summary(parent(x)) * "\n" * Metadata.metadata_summary(x)
Base.summary(io::IO, x::T) = print(io, summary(x))
```

If `fxn` is specified then:
```julia
Base.summary(x::T) = summary(parent(x)) * "\n" * fxn(x)
```
"""
macro defsummary(T, fxn)
    esc(quote
        Base.summary(x::$T) = summary(parent(x)) * "\n" * $fxn(x)
        Base.summary(io::IO, x::$T) = print(io, summary(x))
    end)
end

macro defsummary(T)
    quote
        return @defsummary($T, Metadata.metadata_summary)
    end
end

