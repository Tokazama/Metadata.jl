
_eltype_is_parent_eltype(::Type{T}, ::Type{V}) where {T,V} = V <: eltype(parent_type(T))

"""
    ElementwiseMetaArray

Array with metadata at each element.
"""
struct ElementwiseMetaArray{T,N,P<:AbstractArray{Tuple{T,<:Any},N}} <: AbstractArray{T,N}
    parent::P
end

ArrayInterface.parent_type(::Type{ElementwiseMetaArray{T,N,P}}) where {T,N,P} = P
Base.parent(A::ElementwiseMetaArray) = getfield(A, :parent)

function metadata_type(::Type{T}) where {T<:ElementwiseMetaArray}
    return eltype(parent_type(T)).parameters[2]
end

@inline function metadata_keys(x::ElementwiseMetaArray{T,N,P}) where {T,N,P}
    ks = knonw_keys(metadata_type(x))
    if ks === nothing
        # if metadata is not known parametrically (e.g., NamedTuple{L}) then we
        # need to get the keys from the metadata at any given element
        return keys(first(parent(x)))
    else
        return ks
    end
end

@propagate_inbounds function Base.getindex(A::ElementwiseMetaArray{T}, args...) where {T}
    return _reconstruct_elementwise_array(A, getindex(parent(A), args...))
end

@inline function _elwise_getindex(A::ElementwiseMetaArray, val)
    if _eltype_is_parent_eltype(typeof(A), typeof(val))
        return first(val)
    else
        return ElementwiseMetaArray(val)
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

@propagate_inbounds function Base.getindex(x::MetaView, args...)
    return _meta_getindex(x, getindex(parent(x), args...))
end

@inline function _meta_getindex(A::MetaView{L,T}, val) where {L,T}
    if _eltype_is_parent_eltype(typeof(A), typeof(val))
        return metadata(last(val), L)
    else
        return MetaView{L,T}(val)
    end
end

@inline function metadata(A::ElementwiseMetaArray)
    ks = metadata_keys(A)
    return _metadata(ks, map(k -> metadata(k, k), ks))
end

_el_metadata(ks::Tuple, vs::Tuple) = NamedTuple{ks,typeof(vs)}(vs)

function _el_metadata(ks, vs)
    d = Dict{Symbol,eltype(vs)}()
    for (k_i,v_i) in pair(ks,vs)
        d[k_i] = v_i
    end
    return d
end

metadata(A::ElementwiseMetaArray, k::Symbol) = MetaView{k}(parent(A))

