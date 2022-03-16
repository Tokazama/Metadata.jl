
"""
    MetaUnitRange(x::AbstractUnitRange, meta)

Type for storing metadata alongside a anything that is subtype of `AbstractUnitRange`.

## Examples

```jldoctest
julia> using Metadata

julia> Metadata.MetaUnitRange(1:2, (m1 =1, m2=[1, 2]))
attach_metadata(1:2, ::NamedTuple{(:m1, :m2), Tuple{Int64, Vector{Int64}}})
  • metadata:
     m1 = 1
     m2 = [1, 2]

```
"""
struct MetaUnitRange{T,P<:AbstractUnitRange{T},M} <: AbstractUnitRange{T}
    parent::P
    metadata::M

    MetaUnitRange{T,P,M}(p::P, m::M) where {T,P,M} = new{T,P,M}(p, m)
    function MetaUnitRange{T}(p::AbstractRange, m) where {T}
        if eltype(p) <: T
            return MetaUnitRange{T,typeof(p),typeof(m)}(p, m)
        else
            return MetaUnitRange{T}(AbstractUnitRange{T}(p), m)
        end
    end

    MetaUnitRange(p::AbstractRange, m) = MetaUnitRange{eltype(p)}(p, m)
end

metadata_type(::Type{<:MetaUnitRange{<:Any,<:Any,M}}) where {M} = M

ArrayInterface.parent_type(::Type{<:MetaUnitRange{<:Any,P,<:Any}}) where {P} = P

Base.first(x::MetaUnitRange) = first(parent(x))
Base.last(x::MetaUnitRange) = last(parent(x))
Base.length(x::MetaUnitRange) = length(parent(x))


ArrayInterface.known_first(::Type{T}) where {T<:MetaUnitRange} = known_first(parent_type(T))

ArrayInterface.known_last(::Type{T}) where {T<:MetaUnitRange} = known_last(parent_type(T))

Base.getindex(r::MetaUnitRange, ::Colon) = copy(r)
@propagate_inbounds Base.getindex(r::MetaUnitRange, i::Integer) = parent(r)[i]
@propagate_inbounds Base.getindex(r::MetaUnitRange, i) = propagate_metadata(r, parent(r)[i])
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::AbstractVector{T}) where T<:Integer
    MetaArray(getindex(parent(r), s), metadata(r))
end
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::StepRange{T}) where T<:Integer
    MetaArray(getindex(parent(r), s), metadata(r))
end
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::AbstractUnitRange{T}) where {T<:Integer}
    MetaUnitRange(getindex(parent(r), s), metadata(r))
end

