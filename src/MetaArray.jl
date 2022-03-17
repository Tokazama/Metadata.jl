
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
struct MetaArray{T,N,A<:AbstractArray{T,N},M} <: AbstractArray{T, N}
    parent::A
    metadata::M

    MetaArray{T,N,A,M}(a::AbstractArray{T,N}, m) where {T,N,A,M} = new{T,N,A,M}(a, m)
    MetaArray{T,N,A,M}(a::AbstractArray) where {T,N,A,M} = MetaArray{T,N,A,M}(a, M())
    function MetaArray{T,N,A,M}(::UndefInitializer, dims::Tuple) where {T,N,A,M}
        MetaArray{T,N,A,M}(A(undef, dims))
    end

    ### MetaArray{T,N,A}
    MetaArray{T,N,A}(a::AbstractArray{T,N}, m::M) where {T,N,A,M} = MetaArray{T,N,A,M}(a, m)
    MetaArray{T,N,A}(a::MetaArray{T,N,A}) where {T,N,A} = a
    function MetaArray{T,N,A}(a::MetaArray) where {T,N,A}
        MetaArray{T,N,A}(A(parent(a)), metadata(a))
    end

    ### MetaArray{T,N}
    MetaArray{T,N}(a::AbstractArray{T,N}, m) where {T,N} = MetaArray{T,N,typeof(a)}(a, m)
    MetaArray{T,N}(a::AbstractArray, m) where {T,N} = MetaArray{T,N}(AbstractArray{T,N}(a), m)
    MetaArray{T,N}(a::AbstractArray) where {T,N} = MetaArray{T,N}(a, Dict{Symbol,Any}())
    MetaArray{T,N}(::UndefInitializer, dims::Tuple) where {T,N} = MetaArray{T,N}(Array{T,N}(undef, dims))
    MetaArray{T,N}(a::MetaArray) where {T,N} = AbstractArray{T,N}(parent(a))
    MetaArray{T,N}(a::MetaArray{T,N}) where {T,N} = a

    ### MetaArray{T}
    MetaArray{T}(a::AbstractArray{T,N}, m) where {T,N} = MetaArray{T,N}(a, m)
    MetaArray{T}(a::AbstractArray, m) where {T} = MetaArray{T}(AbstractArray{T}(a), m)
    MetaArray{T}(a::AbstractArray) where {T} = MetaArray{T}(a, Dict{Symbol,Any}())
    MetaArray{T}(::UndefInitializer, dims::Tuple) where {T} = MetaArray{T}(Array{T}(undef, dims))
    MetaArray{T}(a::MetaArray) where {T} = bstractArray{T}(parent(a))
    MetaArray{T}(a::MetaArray{T}) where {T} = a

    ### MetaArray
    MetaArray(p::AbstractArray{T}, m) where {T} = MetaArray{T}(p, m)
    MetaArray(a::AbstractArray) = MetaArray(a, Dict{Symbol,Any}())
    MetaArray(a::MetaArray) = a
end

const MetaVector{T,A,M} = MetaArray{T,1,A,M}
const MetaMatrix{T,A,M} = MetaArray{T,2,A,M}

ArrayInterface.parent_type(::Type{<:MetaArray{<:Any,<:Any,A}}) where {A} = A

metadata_type(::Type{<:MetaArray{<:Any,<:Any,<:Any,M}}) where {M} = M

ArrayInterface.can_change_size(::Type{MetaArray{<:Any,<:Any,P,M}}) where {P,M} = can_change_size(P)

Base.AbstractArray{T}(x::MetaArray{T}) where {T} = x
Base.AbstractArray{T}(x::MetaArray) where {T} = MetaArray(AbstractArray{T}(parent(x)), metadata(x))
Base.AbstractArray{T,N}(x::MetaArray{T,N}) where {T,N} = x
Base.AbstractArray{T,N}(x::MetaArray) where {T,N} = MetaArray(AbstractArray{T,N}(parent(x)), metadata(x))

Base.IndexStyle(::Type{T}) where {T<:MetaArray} = IndexStyle(parent_type(T))

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

function ArrayInterface.defines_strides(::Type{T}) where {T<:MetaArray}
    ArrayInterface.defines_strides(parent_type(T))
end
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

for f in [:size, :length, :axes, :eachindex, :firstindex, :lastindex, :first, :last,
    :step, :dataids, :isreal, :iszero, :strides]
    eval(:(Base.$(f)(x::MetaArray) = Base.$f(getfield(x, :parent))))
end

for f in [:prevind, :nextind,]
    @eval function Base.$(f)(x::MetaArray{<:Any,N}, i::CartesianIndex{N}) where {N}
        Base.$f(getfield(x, :parent), i)
    end
end

for f in [:first, :last, :pointer, :isassigned, :nextind, :prevind]
    eval(:(Base.$(f)(x::MetaArray, n::Integer) = Base.$f(getfield(x, :parent), n)))
end

for f in [:axes, :size, :stride]
    eval(:(Base.$(f)(x::MetaArray, dim) = Base.$f(getfield(x, :parent), to_dims(x, dim))))
    eval(:(Base.$(f)(x::MetaArray, dim::Integer) = Base.$f(getfield(x, :parent), dim)))
end

for f in [:adjoint, :permutedims]
    @eval begin
        function Base.$(f)(x::MetaVector)
            attach_metadata(adjoint(getfield(x, :parent)), permute_metadata(getfield(x, :metadata)))
        end
        function Base.$(f)(x::MetaMatrix)
            attach_metadata(adjoint(getfield(x, :parent)), permute_metadata(getfield(x, :metadata)))
        end
    end
end

for f in [:cumsum, :cumprod, :sort]
    @eval begin
        function Base.$(f)(A::MetaArray{T}; dims, kwargs...) where {T}
            attach_metadata($(f)(getfield(A, :parent); dims=to_dims(A, dims), kwargs...), propagate_metadata(getfield(A, :metadata)))
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

function Base.similar(x::MetaArray, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    attach_metadata(similar(getfield(x, :parent), T, dims), similar_metadata(getfield(x, :metadata), dims))
end
function Base.similar(x::MetaArray, ::Type{T}, dims::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo}}} ) where {T}
    attach_metadata(similar(getfield(x, :parent), T, dims), similar_metadata(getfield(x, :metadata), dims))
end
function Base.similar(x::MetaArray, ::Type{T}, dims::Tuple{Integer, Vararg{Integer}}) where {T}
    attach_metadata(similar(getfield(x, :parent), T, dims), similar_metadata(getfield(x, :metadata), dims))
end

Base.map(f, A::MetaArray) = attach_metadata(map(f, parent(A)), propagate_metadata(metadata(A)))

Base.:(==)(x::MetaArray, y::MetaArray) = parent(x) == parent(y)
Base.:(==)(x::MetaArray, y::AbstractArray) = parent(x) == y
Base.:(==)(x::AbstractArray, y::MetaArray) = x == parent(y)

Base.isequal(x::MetaArray, y::MetaArray) = isequal(parent(x), parent(y))
Base.isequal(x::MetaArray, y::AbstractArray) = isequal(parent(x), y)
Base.isequal(x::AbstractArray, y::MetaArray) = isequal(x, parent(y))

Base.isapprox(x::MetaArray, y::MetaArray; kwargs...) = isapprox(parent(x), parent(y); kwargs...)
Base.isapprox(x::MetaArray, y::AbstractArray; kwargs...) = isapprox(parent(x), y; kwargs...)
Base.isapprox(x::AbstractArray, y::MetaArray; kwargs...) = isapprox(x, parent(y); kwargs...)

