
"""
    MetaUnitRange(x::AbstractUnitRange, meta)

Type for storing metadata alongside anything that is subtype of `AbstractUnitRange`. It is
not intended that this be constructed directly. `attach_metadata(::AbstractUnitRange, meta)`
should be used instead.
"""
struct MetaUnitRange{T,P<:AbstractUnitRange{T},M} <: AbstractUnitRange{T}
    parent::P
    metadata::M

    global _MetaUnitRange(@nospecialize(p), @nospecialize(m)) = new{eltype(p),typeof(p),typeof(m)}(p, m)
end

for f in [:first, :last, :length]
    eval(:(Base.$(f)(@nospecialize(x::MetaUnitRange)) = Base.$(f)(getfield(x, 1))))
end

Base.@propagate_inbounds Base.getindex(r::MetaUnitRange, i::Integer) = parent(r)[i]

ArrayInterface.known_first(::Type{T}) where {T<:MetaUnitRange} = known_first(parent_type(T))

ArrayInterface.known_last(::Type{T}) where {T<:MetaUnitRange} = known_last(parent_type(T))

@propagate_inbounds Base.getindex(r::MetaUnitRange, i) = propagate_metadata(r, parent(r)[i])

@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::StepRange{T}) where T<:Integer
    propagate_metadata(r, getindex(parent(r), s))
end
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::AbstractUnitRange{T}) where {T<:Integer}
    propagate_metadata(r, getindex(parent(r), s))
end

Base.getindex(r::MetaUnitRange, ::Colon) = copy(r)

Base.copy(x::MetaUnitRange) = copy_metadata(x, copy(parent(x)))

