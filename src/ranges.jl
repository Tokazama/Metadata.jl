
"""
    MetaRange(x::AbstractRange, meta)

Type for storing metadata alongside a range.


## Examples

```jldoctest
julia> using Metadata

julia> Metadata.MetaRange(1:1:2, (m1 =1, m2=[1, 2]))
attach_metadata(1:1:2, ::NamedTuple{(:m1, :m2), Tuple{Int64, Vector{Int64}}})
  • metadata:
     m1 = 1
     m2 = [1, 2]

```
"""
struct MetaRange{T,P<:AbstractRange{T},M} <: AbstractRange{T}
    parent::P
    metadata::M
end

Base.parent(r::MetaRange) = getfield(r, :parent)
ArrayInterface.parent_type(::Type{<:MetaRange{<:Any,P,<:Any}}) where {P} = P
@inline function metadata_type(::Type{T}; dim=nothing) where {R,M,T<:MetaRange{<:Any,R,M}}
    if dim === nothing
        return M
    else
        return metadata_type(R; dim=dim)
    end
end

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
struct MetaUnitRange{T,P<:AbstractRange{T},M} <: AbstractUnitRange{T}
    parent::P
    metadata::M

    function MetaUnitRange{T,P,M}(p::P, m::M) where {T,P,M}
        if known_step(P) === oneunit(T)
            return new{T,P,M}(p, m)
        else
            throw(ArgumentError("step must be 1, got $(step(p))"))
        end
    end

    function MetaUnitRange{T}(p::AbstractRange, m) where {T}
        if eltype(p) <: T
            return MetaUnitRange{T,typeof(p),typeof(m)}(p, m)
        else
            return MetaUnitRange{T}(AbstractUnitRange{T}(p), m)
        end
    end

    MetaUnitRange(p::AbstractRange, m) = MetaUnitRange{eltype(p)}(p, m)
end

Base.parent(r::MetaUnitRange) = getfield(r, :parent)
ArrayInterface.parent_type(::Type{<:MetaUnitRange{<:Any,P,<:Any}}) where {P} = P
@inline function metadata_type(::Type{T}; dim=nothing) where {R,M,T<:MetaUnitRange{<:Any,R,M}}
    if dim === nothing
        return M
    else
        return metadata_type(R; dim=dim)
    end
end


@_define_function_no_prop(Base, first, MetaRange)
@_define_function_no_prop(Base, step, MetaRange)
@_define_function_no_prop(Base, last, MetaRange)
@_define_function_no_prop(Base, length, MetaRange)
@_define_function_no_prop(Base, first, MetaUnitRange)
@_define_function_no_prop(Base, step, MetaUnitRange)
@_define_function_no_prop(Base, last, MetaUnitRange)
@_define_function_no_prop(Base, length, MetaUnitRange)

Base.@propagate_inbounds function Base.getindex(@nospecialize(r::MetaUnitRange), i::Integer)
    return getindex(parent(r), i)
end

Base.@propagate_inbounds function Base.getindex(@nospecialize(r::MetaRange), i::Integer)
    return getindex(parent(r), i)
end

for T in (MetaRange, MetaUnitRange)
    @eval begin
        ArrayInterface.known_first(::Type{T}) where {T<:$T} = known_first(parent_type(T))

        ArrayInterface.known_last(::Type{T}) where {T<:$T} = known_last(parent_type(T))

        ArrayInterface.known_step(::Type{T}) where {T<:$T} = known_step(parent_type(T))

        Base.@propagate_inbounds function Base.getindex(r::$T, inds)
            return propagate_metadata(r, getindex(parent(r), inds))
        end
        function Base.show(io::IO, m::MIME"text/plain", x::$T)

            if haskey(io, :compact)
                show(io, parent(x))
            else
                print(io, "attach_metadata(")
                print(io, parent(x))
                print(io, ", ", Metadata.showarg_metadata(x), ")\n")
                Metadata.metadata_summary(io, x)
            end
        end
    end
end

###
### Fixes ambiguities
###
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::StepRange{T}) where T<:Integer
    return propagate_metadata(r, getindex(parent(r), s))
end
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::AbstractUnitRange{T}) where {T<:Integer}
    return propagate_metadata(r, getindex(parent(r), s))
end
Base.getindex(r::MetaRange, ::Colon) = copy(r)
Base.getindex(r::MetaUnitRange, ::Colon) = copy(r)

Base.copy(x::MetaUnitRange) = copy_metadata(x, copy(parent(x)))
Base.copy(x::MetaRange) = copy_metadata(x, copy(parent(x)))

