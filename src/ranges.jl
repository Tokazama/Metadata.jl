
"""
    MetaRange(x::AbstractRange, meta)

Type for storing metadata alongside a range.
"""
struct MetaRange{T,P<:AbstractRange{T},M} <: AbstractRange{T}
    parent::P
    metadata::M
end

ArrayInterface.parent_type(::Type{<:MetaRange{<:Any,P,<:Any}}) where {P} = P
metadata_type(::Type{<:MetaRange{<:Any,<:Any,M}}) where {M} = M

"""
    MetaUnitRange(x::AbstractUnitRange, meta)

Type for storing metadata alongside a anything that is subtype of `AbstractUnitRange`.
"""
struct MetaUnitRange{T,P<:AbstractRange{T},M} <: AbstractUnitRange{T}
    parent::P
    metadata::M

    function MetaUnitRange{T,P,M}(p::P, m::M) where {T,P,M}
        if known_step(p) === oneunit(T)
            return new{T,P,M}(p, m)
        else
            throw(ArgumentError("step must be 1, got $(step(r))"))
        end
    end
end

ArrayInterface.parent_type(::Type{<:MetaUnitRange{<:Any,P,<:Any}}) where {P} = P
metadata_type(::Type{<:MetaUnitRange{<:Any,<:Any,M}}) where {M} = M

for T in (MetaRange, MetaUnitRange)
    @eval begin
        metadata(r::$T) = getfield(r, :metadata)

        Base.parent(r::$T) = getfield(r, :parent)

        Base.first(r::$T) = first(parent(r))

        Base.step(r::$T) = step(parent(r))

        Base.last(r::$T) = last(parent(r))

        ArrayInterface.known_first(::Type{T}) where {T<:$T} = known_first(parent_type(T))

        ArrayInterface.known_last(::Type{T}) where {T<:$T} = known_last(parent_type(T))

        ArrayInterface.known_step(::Type{T}) where {T<:$T} = known_step(parent_type(T))

        Base.@propagate_inbounds function Base.getindex(r::$T, i::Integer)
            return getindex(parent(r), i)
        end

        Base.length(r::$T) = length(parent(r))

        Base.@propagate_inbounds function Base.getindex(r::$T, inds)
           subr = getindex(parent(r), inds)
           if subr isa AbstractRange
               return maybe_propagate_metadata(r, subr)
           else
               return subr
           end
        end
    end
end

###
### Fixes ambiguities
###
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::StepRange{T}) where T<:Integer
    return maybe_propagate_metadata(r, getindex(parent(r), s))
end
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::AbstractUnitRange{T}) where {T<:Integer}
    return maybe_propagate_metadata(r, getindex(parent(r), s))
end
Base.getindex(r::MetaRange, ::Colon) = copy(r)
Base.getindex(r::MetaUnitRange, ::Colon) = copy(r)

