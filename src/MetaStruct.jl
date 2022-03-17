
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

metadata_type(::Type{<:MetaStruct{<:Any,M}}) where {M} = M

ArrayInterface.parent_type(::Type{<:MetaStruct{P}}) where {P} = P

Base.eltype(::Type{T}) where {T<:MetaStruct} = eltype(parent_type(T))

Base.:(==)(x::MetaStruct, y::MetaStruct) = parent(x) == parent(y)
Base.:(==)(x::MetaStruct{T}, y::T) where {T} = parent(x) == y
Base.:(==)(x::T, y::MetaStruct{T}) where {T} = x == parent(y)
Base.:(==)(x::MetaStruct{T}, y::Missing) where {T} = parent(x) == y
Base.:(==)(x::Missing, y::MetaStruct{T}) where {T} = x == parent(y)
Base.:(==)(x::MetaStruct{T}, y::WeakRef) where {T} = parent(x) == y
Base.:(==)(x::WeakRef, y::MetaStruct{T}) where {T} = x == parent(y)
