# TODO incorporate this stuff in docs
# * we consider NamedTuple, AbstractDict metadata unless they specifically overload
#   a metadata_type method.

"""
    NoMetadata

Internal type for the `Metadata` package that indicates the absence of any metadata.
_DO NOT_ store metadata with the value `NoMetadata()`.
"""
struct NoMetadata end
const no_metadata = NoMetadata()
Base.show(io::IO, ::NoMetadata) = print(io, "no_metadata")


"""
    metadata(x[, k; dim])

Returns metadata from `x`. If `k` is specified then the metadata value paired to
`k` is returned. If `dim` is specified then the operation is performed for metadata
specific to dimension `dim`.
"""
metadata(x; dim=nothing) = _metadata(x, dim)
function metadata(x::LinearIndices; dim=nothing)
    if dim === nothing
        return no_metadata
    else
        return metadata(x.indices[dim])
    end
end
function metadata(x::CartesianIndices; dim=nothing)
    if dim === nothing
        return no_metadata
    else
        return metadata(x.indices[dim])
    end
end
_metadata(x, ::Val{dim}) where {dim} = _metadata(x, dim)
function _metadata(x::X, dim) where {X}
    if parent_type(X) <: X
        return no_metadata
    else
        return metadata(parent(x); dim=dim)
    end
end
function _metadata(x::X, ::Nothing) where {X}
    if parent_type(X) <: X  
        return no_metadata
    else
        # although `X` doesn't explicitly have metadata, it does have a parent
        # structure that may have metadata.
        return metadata(parent(x))
    end
end
metadata(x::AbstractDict{Symbol}) = x
metadata(x::NamedTuple) = x

metadata(x, k; dim=nothing) = _metadata(x, k, dim)
_metadata(x, k, ::Val{dim}) where {dim} = _metadata(x, k, dim)
_metadata(x, k, dim) = metadata(metadata(x, dim), k)
@inline function _metadata(x, k, ::Nothing)
    if metadata_type(x) <: AbstractDict
        return getindex(metadata(x), k)
    else
        return getproperty(metadata(x), k)
    end
end

"""
    metadata!(x, k, val[; dim])

Set `x`'s metadata paired to `k` to `val`. If `dim` is specified then the metadata
corresponding to that dimension is mutated.
"""
metadata!(x, k, val; dim=nothing) = _metadata!(x, k, val, dim)
_metadata!(x, k, val, ::Val{dim}) where {dim} = _metadata!(x, k, val, dim)
_metadata!(x, k, val, dim) = _metadata!(axes(x, dim), k, val, nothing)
function _metadata!(x, k, val, ::Nothing)
    if metadata_type(x) <: AbstractDict
        return setindex!(metadata(x), val, k)
    else
        return setproperty!(metadata(x), k, val)
    end
end

"""
    metadata_type(x[, dim]) -> Type

Returns the type of the metadata of `x`. If `dim` is specified then returns type
of metadata associated with dimension `dim`.
"""
function metadata_type(x; dim=nothing)
    if dim === nothing
        return metadata_type(typeof(x))
    else
        return metadata_type(x, dim)
    end
end
metadata_type(::Type{T}) where {T<:AbstractDict} = T
metadata_type(::Type{T}) where {T<:NamedTuple} = T
function metadata_type(::Type{T}) where {T}
    if parent_type(T) <: T
        return NoMetadata
    else
        return metadata_type(parent_type(T))
    end
end
metadata_type(x, dim) = metadata_type(typeof(x), dim)
metadata_type(x, ::Val{dim}) where {dim} = 
metadata_type(::Type{T}, ::Val{dim}) where {T, dim} = metadata_type(T, dim)
function metadata_type(::Type{T}, dim) where {T}
    if parent_type(T) <: T
        return no_metadata
    else
        return metadata_type(parent_type(T), dim)
    end
end
function metadata_type(::Type{CartesianIndices{N,R}}, dim) where {N,R}
    return metadata_type(R.parameters[dim])
end

function metadata_type(::Type{LinearIndices{N,R}}, dim) where {N,R}
    return metadata_type(R.parameters[dim])
end




# TODO metadata_type(x; dim)

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
    has_metadata(x[, k; dim]) -> Bool

Returns true if `x` has metadata. If `k` is specified then checks for the existence
of a metadata paired to `k`. If `dim` is specified then this checks the metadata at
the corresponding dimension.
"""
has_metadata(x; dim=nothing) = _has_metadata(x, dim)
_has_metadata(x, ::Nothing) = !(metadata_type(x) isa NoMetadata)
_has_metadata(x, ::Val{dim}) where {dim} = has_metadata(x; dim=dim)
_has_metadata(x, dim) = !(metadata_type(x, dim) isa NoMetadata)

has_metadata(x, k; dim=nothing) = _has_metadata(x, k, dim)
_has_metadata(x, k, ::Val{dim}) where {dim} = has_metadata(x, k; dim=dim)
_has_metadata(x, k, dim) = has_metadata(metadata(x; dim=dim), k)
@inline function _has_metadata(x, k, ::Nothing)
    if has_metadata(x)
        if metadata_type(x) <: AbstractDict
            return haskey(metadata(x), k)
        else
            return hasproperty(metadata(x), k)
        end
    else
        return false
    end
end

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
    known_keys(::Type{T}) where {T}

Returns the keys of `T` if they are known at compile time. Otherwise, returns nothing.
"""
known_keys(x) = known_keys(typeof(x))
known_keys(::Type{T}) where {T} = nothing
known_keys(::Type{NamedTuple{L,T}}) where {L,T} = L

# when keys are known at compile time
known_metadata_keys(x) = known_metadata_keys(typeof(x))
known_metadata_keys(::Type{T}) where {T} = known_keys(metadata_type(T))

# This allows dictionaries's keys to be treated like property names
@inline function metadata_keys(x)
    if metadata_type(x) <: NoMetadata return propertynames(x)
    else
        return metadata_keys(metadata(x))
    end
end
metadata_keys(x::AbstractDict) = keys(x)
metadata_keys(x::NamedTuple{L}) where {L} = L


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

macro defproperties(T)
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

"""
    metadata_summary(x; left_pad::Int=0, l1=lpad(`•`, 3), l2=lpad('-', 5))

Creates summary readout of metadata for `x`.
"""
function metadata_summary(
    x;
    left_pad::Int=0,
    l1=lpad(Char(0x2022), 3),
    l2=lpad(Char(0x002d), 5),
)

    str = lpad("$l1 metadata:", left_pad)
    for k in metadata_keys(x)
        str *= "\n"
        str *= lpad("$l2 $k = $(metadata(x, k))", left_pad)
    end
    return str
end

# this is a currently informal way of changing how showarg displays metadata in
# the argument list. If someone makes a metadata type that's long or complex they
# may want to overload this.
#
# - used within Base.showarg for MetaArray
showarg_metadata(x) = "::$(metadata_type(x))"

