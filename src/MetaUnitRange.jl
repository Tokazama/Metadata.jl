
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

ArrayInterface.parent_type(::Type{<:MetaUnitRange{<:Any,P,<:Any}}) where {P} = P

@_define_function_no_prop(Base, first, MetaUnitRange)
@_define_function_no_prop(Base, step, MetaUnitRange)
@_define_function_no_prop(Base, last, MetaUnitRange)
@_define_function_no_prop(Base, length, MetaUnitRange)

Base.@propagate_inbounds Base.getindex(r::MetaUnitRange, i::Integer) = parent(r)[i]

ArrayInterface.known_first(::Type{T}) where {T<:MetaUnitRange} = known_first(parent_type(T))

ArrayInterface.known_last(::Type{T}) where {T<:MetaUnitRange} = known_last(parent_type(T))

@propagate_inbounds Base.getindex(r::MetaUnitRange, i) = propagate_metadata(r, parent(r)[i])

function Base.show(io::IO, m::MIME"text/plain", x::MetaUnitRange)
    if haskey(io, :compact)
        show(io, parent(x))
    else
        print(io, "attach_metadata(")
        print(io, parent(x))
        print(io, ", ", Metadata.showarg_metadata(x), ")\n")
        Metadata.metadata_summary(io, x)
    end
end

@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::StepRange{T}) where T<:Integer
    return propagate_metadata(r, getindex(parent(r), s))
end
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::AbstractUnitRange{T}) where {T<:Integer}
    return propagate_metadata(r, getindex(parent(r), s))
end

Base.getindex(r::MetaUnitRange, ::Colon) = copy(r)

Base.copy(x::MetaUnitRange) = copy_metadata(x, copy(parent(x)))

