
"""
    MetaStruct(p, m)

Binds a parent instance (`p`) to some metadata (`m`). `MetaStruct` is the generic type
constructed when `attach_metadata(p, m)` is called.

See also: [`attach_metadata`](@ref), [`attach_eachmeta`](@ref)
"""
struct MetaStruct{P,M}
    parent::P
    metadata::M
end

#Base.parent(m::MetaStruct) = @inbounds(getindex(metadata(parent_module(x)), Base.objectid(x)))

Base.parent(m::MetaStruct) = getfield(m, :parent)
ArrayInterface.parent_type(::Type{MetaStruct{P,M}}) where {P,M} = P

metadata_type(::Type{T}; dim=nothing) where {P,M,T<:MetaStruct{P,M}} = M

attach_metadata(x, m::METADATA_TYPES=MDict()) = MetaStruct(x, m)

Base.eltype(::Type{T}) where {T<:MetaStruct} = eltype(parent_type(T))

function Base.show(io::IO, ::MIME"text/plain", x::MetaStruct)
    print(io, "attach_metadata($(parent(x)), ::$(metadata_type(x)))\n")
    print(io, Metadata.metadata_summary(x))
end

function MetadataPropagation(::Type{T}) where {P,M,T<:MetaStruct{P,M}}
    if P <: Number
        return DropMetadata()
    else
        return ShareMetadata()
    end
end
