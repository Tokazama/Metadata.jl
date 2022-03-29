
"""
    MetaArray(parent::AbstractArray, metadata)

Custom `AbstractArray` object to store an `AbstractArray` `parent` as well as
some `metadata`.

## Examples

```jldoctest
julia> using Metadata

julia> Metadata.MetaArray(ones(2,2), (m1 =1, m2=[1, 2]))
2×2 attach_metadata(::Matrix{Float64}, ::NamedTuple{(:m1, :m2), Tuple{Int64, Vector{Int64}}}
  • metadata:
     m1 = 1
     m2 = [1, 2]
)
 1.0  1.0
 1.0  1.0

```
"""
struct MetaArray{T,N,A<:AbstractArray{T,N},M} <: AbstractArray{T, N}
    parent::A
    metadata::M

    MetaArray{T,N,A,M}(a::AbstractArray, m) where {T,N,A,M} = new{T,N,A,M}(a, m)
    MetaArray{T,N,A,M}(a::AbstractArray) where {T,N,A,M} = MetaArray{T,N,A,M}(a, M())
    MetaArray{T,N,A,M}(::UndefInitializer, dims::Tuple, m) where {T,N,A,M} = MetaArray{T,N,A,M}(A(undef, dims), m)
    MetaArray{T,N,A,M}(::UndefInitializer, dims::Tuple) where {T,N,A,M} = MetaArray{T,N,A,M}(undef, dims, M())

    ### MetaArray{T,N,A}
    MetaArray{T,N,A}(a::AbstractArray{T,N}, m::M) where {T,N,A,M} = MetaArray{T,N,A,M}(a, m)
    MetaArray{T,N,A}(a::AbstractArray, m) where {T,N,A} = MetaArray{T,N,A}(A(a), m)
    MetaArray{T,N,A}(a::AbstractArray) where {T,N,A} = MetaArray{T,N,A}(a, Dict{Symbol,Any}())
    MetaArray{T,N,A}(a::MetaArray{T,N,A}) where {T,N,A} = a
    MetaArray{T,N,A}(a::MetaArray) where {T,N,A} = MetaArray{T,N,A}(A(parent(a)), metadata(a))

    ### MetaArray{T,N}
    MetaArray{T,N}(a::AbstractArray{T,N}, m) where {T,N} = MetaArray{T,N,typeof(a)}(a, m)
    MetaArray{T,N}(a::AbstractArray{T,N}) where {T,N} = MetaArray{T,N}(a, Dict{Symbol,Any}())
    MetaArray{T,N}(a::AbstractArray, m) where {T,N} = MetaArray{T,N}(AbstractArray{T,N}(a), m)
    MetaArray{T,N}(a::AbstractArray) where {T,N} = MetaArray{T,N}(AbstractArray{T,N}(a))
    function MetaArray{T,N}(::UndefInitializer, dims::Tuple, m) where {T,N}
        MetaArray{T,N}(Array{T,N}(undef, dims), m)
    end
    function MetaArray{T,N}(::UndefInitializer, dims::Tuple) where {T,N}
        MetaArray{T,N}(undef, dims, Dict{Symbol,Any}())
    end
    MetaArray{T,N}(a::MetaArray) where {T,N} = AbstractArray{T,N}(parent(a))
    MetaArray{T,N}(a::MetaArray{T,N}) where {T,N} = a

    ### MetaArray{T}
    MetaArray{T}(a::AbstractArray{T,N}, m) where {T,N} = MetaArray{T,N}(a, m)
    MetaArray{T}(a::AbstractArray, m) where {T} = MetaArray{T}(AbstractArray{T}(a), m)
    MetaArray{T}(a::AbstractArray) where {T} = MetaArray{T}(a, Dict{Symbol,Any}())
    function MetaArray{T}(::UndefInitializer, dims::Tuple, m) where {T}
        MetaArray{T}(Array{T}(undef, dims), m)
    end
    function MetaArray{T}(::UndefInitializer, dims::Tuple) where {T}
        MetaArray{T}(undef, dims, Dict{Symbol,Any}())
    end
    MetaArray{T}(a::MetaArray) where {T} = bstractArray{T}(parent(a))
    MetaArray{T}(a::MetaArray{T}) where {T} = a

    ### MetaArray
    MetaArray(p::AbstractArray{T}, m) where {T} = MetaArray{T}(p, m)
    MetaArray(a::AbstractArray) = MetaArray(a, Dict{Symbol,Any}())
    MetaArray(a::MetaArray) = a
end

const MetaVector{T,A,M} = MetaArray{T,1,A,M}
const MetaMatrix{T,A,M} = MetaArray{T,2,A,M}

Base.AbstractArray{T}(x::MetaArray{T}) where {T} = x
Base.AbstractArray{T}(x::MetaArray) where {T} = MetaArray(AbstractArray{T}(parent(x)), metadata(x))
Base.AbstractArray{T,N}(x::MetaArray{T,N}) where {T,N} = x
Base.AbstractArray{T,N}(x::MetaArray) where {T,N} = MetaArray(AbstractArray{T,N}(parent(x)), metadata(x))

ArrayInterface.parent_type(::Type{<:MetaArray{<:Any,<:Any,A}}) where {A} = A
@inline function metadata_type(::Type{T}; dim=nothing) where {M,A,T<:MetaArray{<:Any,<:Any,A,M}}
    if dim === nothing
        return M
    else
        return metadata_type(A; dim=dim)
    end
end

Base.IndexStyle(::Type{T}) where {T<:MetaArray} = IndexStyle(parent_type(T))

for f in [:axes, :size, :stride]
    eval(:(Base.$(f)(x::MetaArray, dim) = Base.$f(getfield(x, :parent), to_dims(x, dim))))
    eval(:(Base.$(f)(x::MetaArray, dim::Integer) = Base.$f(getfield(x, :parent), dim)))
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

@unwrap Base.pointer(x::MetaArray, n::Integer)

Base.copy(A::MetaArray) = copy_metadata(A, copy(parent(A)))

# ArrayInterface traits that just need the parent type
for f in [:can_change_size, :defines_strides, :known_size, :known_length, :axes_types,
   :known_offsets, :known_strides, :contiguous_axis, :contiguous_axis_indicator,
   :stride_rank, :contiguous_batch_size,:known_first, :known_last,:known_step]
    eval(:(ArrayInterface.$(f)(T::Type{<:MetaArray}) = ArrayInterface.$(f)(parent_type(T))))
end

for f in [:getindex, :view]
    unsafe = Symbol(:unsafe_, f)
    @eval begin
        function Base.$(f)(A::MetaArray, args...)
            inds = ArrayInterface.to_indices(A, args)
            @boundscheck checkbounds(A, inds...)
            $(unsafe)(A, inds)
        end
        function Base.$(f)(A::MetaArray; kwargs...)
            inds = ArrayInterface.to_indices(A, ArrayInterface.find_all_dimnames(dimnames(A), static(keys(kwargs)), Tuple(values(kwargs)), :))
            @boundscheck checkbounds(A, inds...)
            $(unsafe)(A, inds)
        end
        @inline $(unsafe)(A, inds::Tuple{Vararg{Integer}}) = @inbounds($(f)(getfield(A, :parent), inds...))
        @inline function $(unsafe)(A, inds::Tuple{Vararg{Any}})
            attach_metadata(@inbounds($(f)(getfield(A, :parent), inds...)), index_metadata(getfield(A, :metadata), inds))
        end
    end
end
function Base.setindex!(A::MetaArray, vals, args...)
    inds = ArrayInterface.to_indices(A, args)
    @boundscheck checkbounds(A, inds...)
    @inbounds setindex!(getfield(A, :parent), vals, inds...)
end
function Base.setindex!(A::MetaArray, vals; kwargs...)
    inds = ArrayInterface.to_indices(A, ArrayInterface.find_all_dimnames(dimnames(A), static(keys(kwargs)), Tuple(values(kwargs)), :))
    @boundscheck checkbounds(A, inds...)
    @inbounds setindex!(getfield(A, :parent), vals, inds...)
end

function Base.similar(x::MetaArray)
    attach_metadata(similar(getfield(x, :parent)), similar_metadata(getfield(x, :metadata)))
end
function Base.similar(x::MetaArray, ::Type{T}) where {T}
    attach_metadata(similar(getfield(x, :parent), T), similar_metadata(getfield(x, :metadata)))
end
function Base.similar(x::MetaArray, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    attach_metadata(similar(getfield(x, :parent), T, dims), similar_metadata(getfield(x, :metadata), dims))
end
function Base.similar(x::MetaArray, ::Type{T}, dims::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo}}} ) where {T}
    attach_metadata(similar(getfield(x, :parent), T, dims), similar_metadata(getfield(x, :metadata), dims))
end
function Base.similar(x::MetaArray, ::Type{T}, dims::Tuple{Integer, Vararg{Integer}}) where {T}
    attach_metadata(similar(getfield(x, :parent), T, dims), similar_metadata(getfield(x, :metadata), dims))
end

@unwrap Base.adjoint(x::MetaVector)

@unwrap Base.permutedims(x::MetaVector)

@unwrap Base.adjoint(x::MetaMatrix)

@unwrap Base.permutedims(x::MetaMatrix)

function Base.accumulate(op, A::MetaArray; dims=nothing, kw...)
    if dims === nothing
        return attach_metadata(accumulate(op, parent(A); dims=dims, kw...), propagate_metadata(metadata(A)))
    else
        return attach_metadata(accumulate(op, parent(A); dims=to_dims(A, dims), kw...), propagate_metadata(metadata(A)))
    end
end

@inline function Base.permutedims(x::MetaArray{T,N}, perm::NTuple{N,Int}) where {T,N}
    attach_metadata(permutedims(getfield(x, :parent)), permute_metadata(getfield(x, :metadata), perm))
end

for f in [:cumsum, :cumprod, :sort]
    @eval begin
        function Base.$(f)(A::MetaArray{T}; dims, kwargs...) where {T}
            attach_metadata($(f)(getfield(A, :parent); dims=to_dims(A, dims), kwargs...), propagate_metadata($(f), getfield(A, :metadata)))
        end
    end
end

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

