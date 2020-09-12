
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
function metadata(x::T; dim=nothing) where {T}
    if parent_type(T) <: T
        return no_metadata
    else
        return metadata(parent(x); dim=dim)
    end
end
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
function metadata(x::AbstractDict; dim=nothing)
    if dim === nothing
        return x
    else
        return no_metadata
    end
end
function metadata(x::NamedTuple; dim=nothing)
    if dim === nothing
        return x
    else
        return no_metadata
    end
end
function metadata(m::Module; dim=nothing)
    if dim === nothing
        if isdefined(m, GLOBAL_METADATA)
            return getfield(m, GLOBAL_METADATA)::GlobalMetadata
        else
            return GlobalMetadata(m)
        end
    else
        return no_metadata
    end
end
function metadata(x::MetaID; dim=nothing)
    if dim === nothing
        # This is known to be inbounds because MetaID cannot be constructed without also
        # assigning a dictionary to `objectid(x)` in the parent module's global metadata dict
        return @inbounds(getindex(metadata(parent_module(x)), Base.objectid(x)))
    else
        return no_metadata
    end
end

@inline function metadata(x, k; dim=nothing)
    if metadata_type(x; dim=dim) <: AbstractDict
        return getindex(metadata(x; dim=dim), k)
    else
        return getproperty(metadata(x; dim=dim), k)
    end
end


"""
    metadata!(x, k, val[; dim])

Set `x`'s metadata paired to `k` to `val`. If `dim` is specified then the metadata
corresponding to that dimension is mutated.
"""
@inline function metadata!(x, k, val; dim=nothing)
    if metadata_type(x; dim=dim) <: AbstractDict
        return setindex!(metadata(x; dim=dim), val, k)
    else
        return setproperty!(metadata(x; dim=dim), k, val)
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
        return metadata_type(typeof(x); dim=dim)
    end
end
@inline function metadata_type(::Type{T}; dim=nothing) where {T}
    if parent_type(T) <: T
        return NoMetadata
    else
        if dim === nothing
            return metadata_type(parent_type(T))
        else
            return metadata_type(parent_type(T); dim=dim)
        end
    end
end

metadata_type(::Type{T}; dim=nothing) where {T<:AbstractDict} = T
metadata_type(::Type{T}; dim=nothing) where {T<:NamedTuple} = T
function metadata_type(::Type{CartesianIndices{N,R}}; dim=nothing) where {N,R}
    if dim === nothing
        return NoMetadata
    else
        return metadata_type(R.parameters[dim])
    end
end

function metadata_type(::Type{LinearIndices{N,R}}; dim=nothing) where {N,R}
    if dim === nothing
        return NoMetadata
    else
        return metadata_type(R.parameters[dim])
    end
end

metadata_type(::Type{T}; dim=nothing) where {P,M,T<:MetaStruct{P,M}} = M
metadata_type(::Type{T}; dim=nothing) where {T<:Module} = GlobalMetadata
metadata_type(::Type{T}; dim=nothing) where {T<:MetaID} = valtype(GlobalMetadata)

"""
    has_metadata(x[, k; dim]) -> Bool

Returns true if `x` has metadata. If `k` is specified then checks for the existence
of a metadata paired to `k`. If `dim` is specified then this checks the metadata at
the corresponding dimension.
"""
has_metadata(x; dim=nothing) = !(metadata_type(x; dim=dim) <: NoMetadata)
@inline function has_metadata(x, k; dim=nothing)
    if has_metadata(x; dim=dim)
        m = metadata(x; dim=dim)
        if m isa AbstractDict
            return haskey(m, k)
        else
            return hasproperty(m, k)
        end
    else
        return false
    end
end

"""
    attach_metadata(x, metadata)

Generic method for attaching metadata to `x`.
"""
attach_metadata(x, m::METADATA_TYPES=Main) = MetaStruct(x, m)
attach_metadata(x::AbstractArray, m::METADATA_TYPES=Main) = MetaArray(x, _maybe_metaid(m))
function attach_metadata(x::AbstractRange, m::METADATA_TYPES=Main)
    if known_step(x) === oneunit(eltype(x))
        return MetaUnitRange(x, _maybe_metaid(m))
    else
        return MetaRange(x, _maybe_metaid(m))
    end
end
attach_metadata(x::IO, m::METADATA_TYPES=Main) = MetaIO(x, _maybe_metaid(m))

attach_metadata(m::METADATA_TYPES) = Base.Fix2(attach_metadata, _maybe_metaid(m))


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

# This allows dictionaries's keys to be treated like property names
@inline function metadata_keys(x; dim=nothing)
    if metadata_type(x; dim=dim) <: AbstractDict
        return keys(metadata(x; dim=dim))
    else
        return fieldnames(metadata_type(x; dim=dim))
    end
end

"""
    MetadataPropagation(::Type{T})

Returns type informing how to propagate metadata of type `T`.
See [`DropMetadata`](@ref), [`CopyMetadata`](@ref), [`ShareMetadata`](@ref).
"""
abstract type MetadataPropagation end

"""
    DropMetadata

Informs operations that may propagate metadata to insead drop it.
"""
struct DropMetadata <: MetadataPropagation end

"""
    CopyMetadata

Informs operations that may propagate metadata to attach a copy to any new instance created.
"""
struct CopyMetadata <: MetadataPropagation end

"""
    ShareMetadata

Informs operations that may propagate metadata to attach a the same metadata to
any new instance created.
"""
struct ShareMetadata <: MetadataPropagation end

MetadataPropagation(x) = MetadataPropagation(typeof(x))
MetadataPropagation(::Type{T}) where {T} = MetadataPropagation(metadata_type(T))
MetadataPropagation(::Type{<:AbstractDict}) = ShareMetadata()
MetadataPropagation(::Type{<:NamedTuple}) = ShareMetadata()
MetadataPropagation(::Type{NoMetadata}) = DropMetadata()

function propagate_metadata(src, dst)
    return propagate_metadata(MetadataPropagation(src), src, dst)
end
propagate_metadata(::DropMetadata, src, dst) = dst
propagate_metadata(::ShareMetadata, src, dst) = share_metadata(src, dst)
propagate_metadata(::CopyMetadata, src, dst) = copy_metadata(src, dst)

function combine_metadata(x, y, dst)
    return _combine_meta(MetadataPropagation(x), MetadataPropagation(y), x, y, dst)
end

function _combine_meta(px::DropMetadata, py::MetadataPropagation, x, y, dst)
    return propagate_metadata(py, y, dst)
end

function _combine_meta(px::MetadataPropagation, py::DropMetadata, x, y, dst)
    return propagate_metadata(px, x, dst)
end

_combine_meta(px::DropMetadata, py::DropMetadata, x, y, dst) = dst

function _combine_meta(px::CopyMetadata, py::CopyMetadata, x, y, dst)
    return attach_metadata(append!(deepcopy(metadata(x)), metadata(y)), dst)
end

function _combine_meta(px::ShareMetadata, py::CopyMetadata, x, y, dst)
    return attach_metadata(append!(deepcopy(metadata(y)), metadata(x)), dst)
end

function _combine_meta(px::CopyMetadata, py::ShareMetadata, x, y, dst)
    return attach_metadata(append!(deepcopy(metadata(x)), metadata(y)), dst)
end

# TODO need to consider what should happen here because non mutating functions
# will mutate metadata if both combine and share
function _combine_meta(px::ShareMetadata, py::ShareMetadata, x, y, dst)
    return attach_metadata(append!(metadata(x), metadata(y)), dst)
end

macro defproperties(T)
    quote
        @inline function Base.getproperty(x::$T, k::Symbol)
            if hasproperty(parent(x), k)
                return getproperty(parent(x), k)
            else
                return Metadata.metadata(x, k)
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

function _construct_meta(meta::AbstractDict{Symbol}, kwargs::NamedTuple)
    for (k, v) in pairs(kwargs)
        meta[k] = v
    end
    return meta
end

_construct_meta(m::Module, kwargs::NamedTuple) = _construct_meta(MetaID(m), kwargs)

function _construct_meta(meta, kwargs::NamedTuple)
    if isempty(kwargs)
        return meta
    else
        error("Cannot assign key word arguments to metadata of type $(typeof(meta))")
    end
end
