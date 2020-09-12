
"""
    ElementwiseMetaArray

Array with metadata attached to each element.
"""
struct ElementwiseMetaArray{T,N,P<:AbstractArray{<:MetaStruct{T},N}} <: AbstractArray{T,N}
    parent::P

    function ElementwiseMetaArray(x::AbstractArray{T,N}) where {T,N}
        if has_metadata(T)
            return new{parent_type(T),N,typeof(x)}(x)
        else
            throw(ArgumentError("eltype of array does not have metadata: got $T."))
        end
    end

    function ElementwiseMetaArray(x::AbstractArray, m)
        return ElementwiseMetaArray(attach_eachmeta(x, m))
    end
end

ArrayInterface.parent_type(::Type{ElementwiseMetaArray{T,N,P}}) where {T,N,P} = P

Base.parent(A::ElementwiseMetaArray) = getfield(A, :parent)

function metadata_type(::Type{T}; dim=nothing) where {T<:ElementwiseMetaArray}
    if dim === nothing
        return metadata_type(eltype(parent_type(T)))
    else
        return metadata_type(parent_type(T); dim=dim)
    end
end

@inline function metadata_keys(x::ElementwiseMetaArray; dim=dim)
    if metadata_type(x; dim=dim) <: AbstractDict
        return metadata_keys(first(parent(x)))
    else
        return fieldnames(metadata_type(x))
    end
end

@propagate_inbounds function Base.getindex(A::ElementwiseMetaArray{T}, args...) where {T}
    val = getindex(parent(A), args...)
    if val isa eltype(parent_type(A))
        return parent(val)
    else
        return ElementwiseMetaArray(val)
    end
end

# TODO how should setindex! work with metadata?
@propagate_inbounds function Base.setindex!(A::ElementwiseMetaArray, val, args...)
    return setindex!(parent(A), val, args...)
end

"""
    MetaView{L}

A view of an array of metadata bound elements whose elements are paired to the key `L`.
"""
struct MetaView{L,T,N,P<:AbstractArray{<:Any,N}} <: AbstractArray{T,N}
    parent::P

    function MetaView{L}(x::AbstractArray{T,N}) where {L,T,N}
        if has_metadata(T)
            return new{L,fieldtype(metadata_type(T), L),N,typeof(x)}(x)
        else
            throw(ArgumentError("eltype of array does not have metadata: got $T."))
        end
    end
end

ArrayInterface.parent_type(::Type{MetaView{L,T,N,P}}) where {L,T,N,P} = P

Base.parent(x::MetaView) = getfield(x, :parent)

@propagate_inbounds function Base.getindex(x::MetaView{L,T}, args...) where {L,T}
    val = getindex(parent(x), args...)
    if val isa eltype(parent_type(x))
        return metadata(val, L)
    else
        return MetaView{L}(val)
    end
end

@inline function metadata(A::ElementwiseMetaArray; dim=nothing)
    if dim === nothing
        if metadata_type(A) isa AbstractDict
            return Dict(map(k -> metadata(A, k), metadata_keys(A))...)
        else
            ks = fieldnames(metadata_type(A))
            return NamedTuple{ks}(map(k -> metadata(A, k), ks))
        end
    else
        return metadata(parent(A); dim=dim)
    end
end

@inline function metadata(A::ElementwiseMetaArray, k::Symbol; dim=nothing)
    if dim === nothing
        return MetaView{k}(parent(A))
    else
        return metadata(parent(A), k; dim=dim)
    end
end

function unsafe_attach_eachmeta(x::AbstractVector, m::NamedTuple{L}, i::Int) where {L}
    return MetaStruct(
        @inbounds(x[i]),
        NamedTuple{L}(ntuple(index -> @inbounds(m[L[index]][i]), Val(length(L))))
    )
end

# TODO `eachindex` should change to `ArrayInterface.indices`
function attach_eachmeta(x::AbstractVector, m::NamedTuple)
    return ElementwiseMetaArray(map(i -> unsafe_attach_eachmeta(x, m, i), eachindex(x, m...)))
end

@_define_single_function_no_prop(Base, size, ElementwiseMetaArray)
@_define_single_function_no_prop(Base, size, MetaView)
@_define_single_function_no_prop(Base, axes, ElementwiseMetaArray)
@_define_single_function_no_prop(Base, axes, MetaView)


# TODO function drop_metadata(x::ElementwiseMetaArray) end

#=
struct AdjacencyList{T,L<:AbstractVector{<:AbstractVector{T}}} <: AbstractGraph{T}
    list::L
end

const MetaAdjacencyList{T,M} = AdjacencyList{T,Vector{ElementwiseMetaArray{T,1,Vector{Tuple{T,M}}}}}
=#

