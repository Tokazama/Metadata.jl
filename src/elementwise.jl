

# as in "element metadata" not "el (the) metadata"
const ElMeta{T,L,M} = Tuple{T,NamedTuple{L,M}}

function _elmeta_type(::Type{T}, ::Type{NamedTuple{L,M}}) where {T,L,M}
    return Tuple{T,NamedTuple{L,Tuple{ntuple(i -> eltype(T.parameters[i]), Val(length(L)))...}}}
end


@inline function _meta_element(x::T, m::NamedTuple{L,M}, index::Int) where {T,L,M}
    return (x, NamedTuple{L}(ntuple(i -> @inbounds(m[L[i]][index]), Val(length(L)))))
end

"""
    ElementwiseMetaArray

Array with metadata at each element.
"""
struct ElementwiseMetaArray{T,N,P<:AbstractArray{<:ElMeta{T},N}} <: AbstractArray{T,N}
    parent::P

    function ElementwiseMetaArray(p::AbstractArray{Tuple{T,<:NamedTuple}}) where {T}
        return new{T,ndims(p),typeof(p)}(p)
    end

    function ElementwiseMetaArray(p::AbstractArray{T}, m::NamedTuple{L}) where {T,L}
        return ElementwiseMetaArray(
            map(i -> _meta_element(@inbounds(x[i]), m, i), ArrayInterface.indices((p, m...)))
        )
    end

    ElementwiseMetaArray(args::Vararg{<:ElMeta}) = ElementwiseMetaArray(collect(args))
end

ArrayInterface.parent_type(::Type{ElementwiseMetaArray{T,N,P}}) where {T,N,P} = P

Base.parent(A::ElementwiseMetaArray) = getfield(A, :parent)

function metadata_type(::Type{T}) where {T<:ElementwiseMetaArray}
    return eltype(parent_type(T)).parameters[2]
end

metadata_keys(x::ElementwiseMetaArray{T,N,P}) where {T,N,P} = _metadata_keys(eltype(P))
_metadata_keys(::Type{ElMeta{T,L,M}}) where {T,L,M} = L

@propagate_inbounds function Base.getindex(A::ElementwiseMetaArray{T}, args...) where {T}
    p = getindex(parent(A), args...)
    if p isa AbstractArray
        return ElementwiseMetaArray(val)
    else
        return first(p)
    end
end

# TODO how should setindex! work with metadata?
@propagate_inbounds function Base.setindex!(A::ElementwiseMetaArray, val, args...)
    return setindex!(parent(A), val, args...)
end


"""
    MetaView

"""
struct MetaView{L,T,N,P<:AbstractArray{Tuple{<:Any,<:Any},N}} <: AbstractArray{T,N}
    parent::P

    function MetaView{L}(x::AbstractArray{Tuple{<:Any,M}}) where {L,M}
        return MetaView{L,metadata_type(M, L),ndims(x),typeof(x)}(x)
    end
end

ArrayInterface.parent_type(::Type{MetaView{L,T,N,P}}) where {L,T,N,P} = P
Base.parent(x::MetaView) = getfield(x, :parent)

@propagate_inbounds function Base.getindex(x::MetaView{L,T}, args...) where {L,T}
    if val isa T
        return val
    else
        return MetaView{L}(val)
    end
end

@inline function metadata(A::ElementwiseMetaArray)
    ks = metadata_keys(A)
    return NamedTuple{ks}(map(k -> metadata(k, k), ks))
end

metadata(A::ElementwiseMetaArray, k::Symbol) = MetaView{k}(parent(A))

Base.getproperty(A::ElementwiseMetaArray, k::Symbol) = metadata(A, k)

Base.propertynames(A::ElementwiseMetaArray) = metadata_keys(A)

#=
struct AdjacencyList{T,L<:AbstractVector{<:AbstractVector{T}}} <: AbstractGraph{T}
    list::L
end

const MetaAdjacencyList{T,M} = AdjacencyList{T,Vector{ElementwiseMetaArray{T,1,Vector{Tuple{T,M}}}}}
=#
