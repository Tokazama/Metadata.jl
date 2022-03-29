
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
function metadata(m::Module)
    if isdefined(m, GLOBAL_METADATA)
        return getfield(m, GLOBAL_METADATA)::GlobalMetadata
    else
        return GlobalMetadata(m)
    end
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
metadata_type(::Type{T}) where {T<:Module} = GlobalMetadata
metadata_type(::Type{MetaStruct{P,M}}) where {P,M} = M
@inline function metadata_type(::Type{T}; dim=nothing) where {M,A,T<:MetaArray{<:Any,<:Any,M,A}}
    if dim === nothing
        return M
    else
        return metadata_type(A; dim=dim)
    end
end
@inline function metadata_type(::Type{T}; dim=nothing) where {R,M,T<:MetaUnitRange{<:Any,R,M}}
    if dim === nothing
        return M
    else
        return metadata_type(R; dim=dim)
    end
end

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
attach_metadata(x, m=Dict{Symbol,Any}()) = MetaStruct(x, m)
attach_metadata(x::AbstractArray, m=Dict{Symbol,Any}()) = MetaArray(x, m)
function attach_metadata(x::AbstractRange, m=Dict{Symbol,Any}())
    if known_step(x) === oneunit(eltype(x))
        return MetaUnitRange(x, m)
    else
        return MetaArray(x, m)
    end
end
attach_metadata(x::IO, m=Dict{Symbol,Any}()) = MetaIO(x, m)
attach_metadata(m::METADATA_TYPES) = Base.Fix2(attach_metadata, m)

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
@inline function metadata_keys(x::AbstractArray; dim=nothing)
    if has_metadata(x; dim=dim)
        return metadata_keys(metadata(x; dim=dim))
    else
        return propertynames(x)
    end
end

metadata_keys(x::AbstractDict) = keys(x)
metadata_keys(::NamedTuple{L}) where {L} = L
function metadata_keys(x::X) where {X}
    if has_metadata(X)
        return metadata_keys(metadata(x))
    else
        return propertynames(x)
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
MetadataPropagation(::Type{T}) where {T<:AbstractDict} = ShareMetadata()
MetadataPropagation(::Type{T}) where {T<:NamedTuple} = ShareMetadata()
MetadataPropagation(::Type{T}) where {T<:NoMetadata} = DropMetadata()

function propagate_metadata(src, dst)
    return propagate_metadata(MetadataPropagation(src), src, dst)
end
propagate_metadata(::DropMetadata, src, dst) = dst
propagate_metadata(::ShareMetadata, src, dst) = share_metadata(src, dst)
propagate_metadata(::CopyMetadata, src, dst) = copy_metadata(src, dst)

function MetadataPropagation(::Type{T}) where {P,M,T<:MetaStruct{P,M}}
    if P <: Number
        return DropMetadata()
    else
        return ShareMetadata()
    end
end

"""
    metadata_summary([io], x)

Creates summary readout of metadata for `x`.
"""
metadata_summary(x) = metadata_summary(stdout, x)
function metadata_summary(io::IO, x)
    print(io, "$(lpad(Char(0x2022), 3)) metadata:")
    suppress = getmeta(x, :suppress, no_metadata)
    if suppress !== no_metadata
        suppress = metadata(x, :suppress)
        for k in metadata_keys(x)
            if k !== :suppress
                println(io)
                print(io, "     ")
                print(io, "$k")
                print(io, " = ")
                if in(k, suppress)
                    print(io, "<suppressed>")
                else
                    print(io, metadata(x, k))
                end
            end
        end
    else
        for k in metadata_keys(x)
            println(io)
            print(io, "     ")
            print(io, "$k")
            print(io, " = ")
            print(io, metadata(x, k))
        end
    end
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

function _construct_meta(meta, kwargs::NamedTuple)
    if isempty(kwargs)
        return meta
    else
        error("Cannot assign key word arguments to metadata of type $(typeof(meta))")
    end
end

