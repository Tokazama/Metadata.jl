
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

const MetaVector{T,M,A} = MetaArray{T,1,M,A}
const MetaMatrix{T,M,A} = MetaArray{T,2,M,A}

Base.IndexStyle(::Type{T}) where {T<:MetaArray} = IndexStyle(parent_type(T))

ArrayInterface.parent_type(::Type{MetaArray{T,M,N,A}}) where {T,M,N,A} = A
@inline function metadata_type(::Type{T}; dim=nothing) where {M,A,T<:MetaArray{<:Any,<:Any,M,A}}
    if dim === nothing
        return M
    else
        return metadata_type(A; dim=dim)
    end
end

for f in [:axes, :size, :strides, :length, :eachindex, :firstindex, :lastindex, :first, :step,
    :last, :dataids, :isreal, :iszero]
    eval(:(Base.$(f)(@nospecialize(x::MetaArray)) = Base.$(f)(getfield(x, 1))))
end

for f in [:axes, :size, :stride]
    eval(:(Base.$(f)(@nospecialize(x::MetaArray), dim) = Base.$f(getfield(x, 1), to_dims(x, dim))))
    eval(:(Base.$(f)(@nospecialize(x::MetaArray), dim::Integer) = Base.$f(getfield(x, 1), dim)))
end

# ArrayInterface traits that just need the parent type
for f in [:can_change_size, :defines_strides, :known_size, :known_length, :axes_types,
   :known_offsets, :known_strides, :contiguous_axis, :contiguous_axis_indicator,
   :stride_rank, :contiguous_batch_size,:known_first, :known_last, :known_step]
    eval(:(ArrayInterface.$(f)(T::Type{<:MetaArray}) = ArrayInterface.$(f)(parent_type(T))))
end

Base.pointer(x::MetaArray, n::Integer) = pointer(parent(x), n)

for f in [:axes, :size, :strides, :offsets]
    eval(:(ArrayInterface.$(f)(x::MetaArray) = ArrayInterface.$f(getfield(x, :parent))))
end

Base.copy(A::MetaArray) = copy_metadata(A, copy(parent(A)))

Base.similar(x::MetaArray) = propagate_metadata(x, similar(parent(x)))
Base.similar(x::MetaArray, ::Type{T}) where {T} = propagate_metadata(x, similar(parent(x), T))
function Base.similar(x::MetaArray, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    propagate_metadata(x, similar(parent(x), T, dims))
end
function Base.similar(x::MetaArray, ::Type{T}, dims::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo}}} ) where {T}
    propagate_metadata(x, similar(parent(x), T, dims))
end
function Base.similar(x::MetaArray, ::Type{T}, dims::Tuple{Integer, Vararg{Integer}}) where {T}
    propagate_metadata(x, similar(parent(x), T, dims))
end
@propagate_inbounds function Base.getindex(A::MetaArray{T}, args...) where {T}
    _getindex(A, getindex(parent(A), args...))
end

_getindex(A::MetaArray{T}, val::T) where {T} = val
_getindex(A::MetaArray{T}, val) where {T} = propagate_metadata(A, val)

# mutating methods
for f in [:push!, :pushfirst!, :prepend!, :append!, :sizehint!, :resize!]
    @eval begin
        function Base.$(f)(A::MetaArray, args...)
            can_change_size(A) || throw(MethodError($(f), (A, item)))
            Base.$(f)(getfield(A, :parent), args...)
            return A
        end
    end
end

for f in [:empty!, :pop!, :popfirst!, :popat!, :insert!, :deleteat!]
    @eval begin
        function Base.$(f)(A::MetaArray, args...)
            can_change_size(A) || throw(MethodError($f, (A,)))
            $(f)(getfield(A, :parent), args...)
            return A
        end
    end
end

# permuting dimensions

# FIXME currently this doesn't do anything but it should be aware of metadata tied to dimensions
permute_metadata(m) = m
permute_metadata(m, perm) = m

function LinearAlgebra.transpose(x::MetaVector)
    attach_metadata(transpose(parent(x)), permute_metadata(metadata(x)))
end
function Base.adjoint(x::MetaVector)
    attach_metadata(adjoint(parent(x)), permute_metadata(metadata(x)))
end
function Base.permutedims(x::MetaVector)
    attach_metadata(permutedims(parent(x)), permute_metadata(metadata(x)))
end
function LinearAlgebra.transpose(x::MetaMatrix)
    attach_metadata(transpose(parent(x)), permute_metadata(metadata(x)))
end
function Base.adjoint(x::MetaMatrix)
    attach_metadata(adjoint(parent(x)), permute_metadata(metadata(x)))
end
function Base.permutedims(x::MetaMatrix)
    attach_metadata(permutedims(parent(x)), permute_metadata(metadata(x)))
end
@inline function Base.permutedims(x::MetaArray{T,N}, perm::NTuple{N,Int}) where {T,N}
    attach_metadata(permutedims(parent(x), perm), permute_metadata(metadata(x), perm))
end

