
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

Base.eltype(::Type{T}) where {T<:MetaStruct} = eltype(parent_type(T))

Base.copy(x::MetaStruct) = propagate_metadata(x, deepcopy(parent(x)))

@unwrap 1 Base.:(==)(x::MetaStruct, y::MetaStruct)
@unwrap 2 Base.:(==)(x::Any, y::MetaStruct)
@unwrap 1 Base.:(==)(x::MetaStruct, y::Any)
@unwrap 2 Base.:(==)(x::Missing, y::MetaStruct)
@unwrap 1 Base.:(==)(x::MetaStruct, y::Missing)
@unwrap 2 Base.:(==)(x::WeakRef, y::MetaStruct)
@unwrap 1 Base.:(==)(x::MetaStruct, y::WeakRef)

