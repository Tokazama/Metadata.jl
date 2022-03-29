
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


""" propagate_metadata """
propagate_metadata(m) = m

# TODO
""" index_metadata """
index_metadata(m, inds::Tuple) = m

# TODO
""" permute_metadata """
permute_metadata(m) = m
permute_metadata(m, perm::Tuple) = m

""" similar_metadata """
similar_metadata(m, dims::Tuple) = m

#propagate_metadata(m::M, f::F, args::Tuple, kwargs::Base.Pairs) where {M,F}

