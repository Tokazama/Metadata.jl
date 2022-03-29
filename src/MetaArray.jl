
function _construct_meta(meta::AbstractDict{Symbol}, kwargs::NamedTuple)
    for (k, v) in pairs(kwargs)
        meta[k] = v
    end
    return meta
end

function _construct_meta(meta, kwargs::NamedTuple)
    if isempty(kwargs)
        return meta
    else
        error("Cannot assign key word arguments to metadata of type $(typeof(meta))")
    end
end

"""
    MetaArray(parent::AbstractArray, metadata)

Custom `AbstractArray` object to store an `AbstractArray` `parent` as well as
some `metadata`.

## Examples

```jldoctest
julia> using Metadata

julia> Metadata.MetaArray(ones(2,2), metadata=(m1 =1, m2=[1, 2]))
2×2 attach_metadata(::Matrix{Float64}, ::NamedTuple{(:m1, :m2), Tuple{Int64, Vector{Int64}}}
  • metadata:
     m1 = 1
     m2 = [1, 2]
)
 1.0  1.0
 1.0  1.0

```
"""
struct MetaArray{T, N, M, A<:AbstractArray} <: ArrayInterface.AbstractArray2{T, N}
    parent::A
    metadata::M

    MetaArray{T,N,M,A}(a::A, m::M) where {T,N,M,A} = new{T,N,M,A}(a, m)
    MetaArray{T,N,M,A}(a::A, m) where {T,N,M,A} = new{T,N,M,A}(a, M(m))
    MetaArray{T,N,M,A}(a, m::M) where {T,N,M,A} = MetaArray{T,N,M,A}(A(a), m)
    MetaArray{T,N,M,A}(a, m) where {T,N,M,A} = MetaArray{T,N,M,A}(A(a), M(m))
    function MetaArray{T,N,M,A}(a::AbstractArray; metadata=Dict{Symbol,Any}(), kwargs...) where {T,N,M,A}
        return MetaArray{T,N,M,A}(a, _construct_meta(metadata, values(kwargs)))
    end

    function MetaArray{T,N,M,A}(args...; metadata=Dict{Symbol,Any}(), kwargs...) where {T,N,M,A}
        return MetaArray{T,N,M,A}(A(args...); metadata=metadata, kwargs...)
    end

    ###
    ### MetaArray{T,N,M}
    ###
    function MetaArray{T,N,M}(x::AbstractArray, m::M) where {T,N,M}
        if eltype(x) <: T
            return MetaArray{T,N,M,typeof(x)}(x, m)
        else
            return MetaArray{T,N,M}(convert(AbstractArray{T}, x), m)
        end
    end

    ###
    ### MetArray{T,N}
    ###
    MetaArray{T,N}(a::AbstractArray, m::M) where {T,N,M} = MetaArray{T,N,M}(a, m)
    function MetaArray{T,N}(a::AbstractArray; metadata=Dict{Symbol,Any}(), kwargs...) where {T,N}
        return MetaArray{T,N}(a, _construct_meta(metadata, values(kwargs)))
    end
    function MetaArray{T,N}(args...; metadata=Dict{Symbol,Any}(), kwargs...) where {T,N}
        return MetaArray{T,N}(Array{T,N}(args...); metadata=metadata, kwargs...)
    end

    ###
    ### MetArray{T}
    ###
    function MetaArray{T}(args...; metadata=Dict{Symbol,Any}(), kwargs...) where {T}
        return MetaArray{T}(Array{T}(args...); metadata=metadata, kwargs...)
    end
    MetaArray{T}(a::AbstractArray, m::M) where {T,M} = MetaArray{T,ndims(a)}(a, m)
    function MetaArray{T}(a::AbstractArray; metadata=Dict{Symbol,Any}(), kwargs...) where {T}
        return MetaArray{T,ndims(a)}(a; metadata=metadata, kwargs...)
    end

    ###
    ### MetaArray
    ###
    MetaArray(v::AbstractArray{T,N}, m::M) where {T,N,M} = new{T,N,M,typeof(v)}(v, m)
    function MetaArray(a::AbstractArray; metadata=Dict{Symbol,Any}(), kwargs...)
        return MetaArray{eltype(a)}(a; metadata=metadata, kwargs...)
    end
end

ArrayInterface.parent_type(::Type{MetaArray{T,M,N,A}}) where {T,M,N,A} = A
@inline function metadata_type(::Type{T}; dim=nothing) where {M,A,T<:MetaArray{<:Any,<:Any,M,A}}
    if dim === nothing
        return M
    else
        return metadata_type(A; dim=dim)
    end
end

@unwrap Base.axes(x::MetaArray)

@unwrap Base.size(x::MetaArray)

@unwrap Base.strides(x::MetaArray)

@unwrap Base.length(x::MetaArray)

@unwrap Base.eachindex(x::MetaArray)

@unwrap Base.firstindex(x::MetaArray)

@unwrap Base.lastindex(x::MetaArray)

@unwrap Base.first(x::MetaArray)

@unwrap Base.step(x::MetaArray)

@unwrap Base.last(x::MetaArray)

@unwrap Base.dataids(x::MetaArray)

@unwrap Base.isreal(x::MetaArray)

@unwrap Base.iszero(x::MetaArray)

@unwrap ArrayInterface.axes(x::MetaArray)

@unwrap ArrayInterface.strides(x::MetaArray)

@unwrap ArrayInterface.offsets(x::MetaArray)

@unwrap ArrayInterface.size(x::MetaArray)

Base.copy(A::MetaArray) = copy_metadata(A, copy(parent(A)))
function Base.similar(x::MetaArray, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    return Metadata.share_metadata(x, similar(parent(x), T, dims))
end

function Base.similar(
    x::MetaArray,
    ::Type{T},
    dims::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo}}}
) where {T}

    return Metadata.propagate_metadata(x, similar(parent(x), T, dims))
end
function Base.similar(x::MetaArray, ::Type{T}, dims::Tuple{Integer, Vararg{Integer}}) where {T}
    return Metadata.propagate_metadata(x, similar(parent(x), T, dims))
end

function ArrayInterface.defines_strides(::Type{T}) where {T<:MetaArray}
    return ArrayInterface.defines_strides(parent_type(T))
end

@propagate_inbounds function Base.getindex(A::MetaArray{T}, args...) where {T}
    return _getindex(A, getindex(parent(A), args...))
end

_getindex(A::MetaArray{T}, val::T) where {T} = val
_getindex(A::MetaArray{T}, val) where {T} = propagate_metadata(A, val)

