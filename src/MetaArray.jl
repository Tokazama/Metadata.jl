
struct MetaArray{M,A,T,N} <: AbstractArray{T, N}
    parent::A
    metadata::M

    global function _MetaArray(@nospecialize(p), @nospecialize(m))
        new{typeof(m),typeof(p),eltype(p),ndims(p)}(p, m)
    end
end
@inline function Base.AbstractArray{T}(@nospecialize(x::MetaArray)) where {T}
    _MetaArray(AbstractArray{T}(parent(x)), metadata(x))
end
@inline function Base.AbstractArray{T,N}(@nospecialize(x::MetaArray)) where {T,N}
    _MetaArray(AbstractArray{T,N}(parent(x)), metadata(x))
end

const MetaVector{M,A,T} = MetaArray{M,A,T,1}

const MetaMatrix{M,A,T} = MetaArray{M,A,T,2}

Base.IndexStyle(@nospecialize T::Type{<:MetaArray}) = IndexStyle(parent_type(T))

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
    eval(:(ArrayInterface.$(f)(@nospecialize T::Type{<:MetaArray}) = ArrayInterface.$(f)(parent_type(T))))
end

Base.pointer(@nospecialize(x::MetaArray), n::Integer) = pointer(parent(x), n)

for f in [:axes, :size, :strides, :offsets]
    eval(:(ArrayInterface.$(f)(@nospecialize(x::MetaArray)) = ArrayInterface.$f(getfield(x, :parent))))
end

Base.copy(A::MetaArray) = copy_metadata(A, copy(parent(A)))
Base.map(f, @nospecialize(A::MetaArray)) = propagate_metadata(x, map(f, parent(A)), )

# similar
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

# mutating methods
for f in [:push!, :pushfirst!, :prepend!, :append!, :sizehint!, :resize!]
    @eval begin
        function Base.$(f)(@nospecialize(A::MetaArray), args...)
            can_change_size(A) || throw(MethodError($(f), (A, item)))
            Base.$(f)(getfield(A, :parent), args...)
            return A
        end
    end
end

for f in [:empty!, :pop!, :popfirst!, :popat!, :insert!, :deleteat!]
    @eval begin
        function Base.$(f)(@nospecialize(A::MetaArray), args...)
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

function LinearAlgebra.transpose(@nospecialize x::MetaVector)
    attach_metadata(transpose(parent(x)), permute_metadata(metadata(x)))
end
function Base.adjoint(@nospecialize x::MetaVector)
    attach_metadata(adjoint(parent(x)), permute_metadata(metadata(x)))
end
function Base.permutedims(@nospecialize x::MetaVector)
    attach_metadata(permutedims(parent(x)), permute_metadata(metadata(x)))
end
function LinearAlgebra.transpose(@nospecialize x::MetaMatrix)
    attach_metadata(transpose(parent(x)), permute_metadata(metadata(x)))
end
function Base.adjoint(@nospecialize x::MetaMatrix)
    attach_metadata(adjoint(parent(x)), permute_metadata(metadata(x)))
end
function Base.permutedims(@nospecialize x::MetaMatrix)
    attach_metadata(permutedims(parent(x)), permute_metadata(metadata(x)))
end
@inline function Base.permutedims(x::MetaArray{T,N}, perm::NTuple{N,Int}) where {T,N}
    attach_metadata(permutedims(parent(x), perm), permute_metadata(metadata(x), perm))
end

# Indexing
# FIXME
index_metadata(m, inds) = m
for f in [:getindex, :view]
    unsafe = Symbol(:unsafe_, f)
    @eval begin
        function Base.$(f)(@nospecialize(A::MetaArray), args...)
            inds = ArrayInterface.to_indices(A, args)
            @boundscheck checkbounds(A, inds...)
            $(unsafe)(A, inds)
        end
        function Base.$(f)(@nospecialize(A::MetaArray); kwargs...)
            inds = ArrayInterface.to_indices(A, ArrayInterface.find_all_dimnames(dimnames(A), static(keys(kwargs)), Tuple(values(kwargs)), :))
            @boundscheck checkbounds(A, inds...)
            $(unsafe)(A, inds)
        end
        @inline $(unsafe)(A, inds::Tuple{Vararg{Integer}}) = @inbounds($(f)(A, inds...))
        @inline $(unsafe)(@nospecialize(A::MetaArray), inds::Tuple{Vararg{Integer}}) = $(unsafe)(getfield(A, :parent), inds)
        @inline $(unsafe)(A, inds::Tuple{Vararg{Any}}) = @inbounds($(f)(A, inds...))
        @inline function $(unsafe)(@nospecialize(A::MetaArray), inds::Tuple{Vararg{Any}})
            attach_metadata($(unsafe)(getfield(A, :parent), inds), index_metadata(getfield(A, :metadata), inds))
        end
    end
end
function Base.setindex!(@nospecialize(A::MetaArray), vals, args...)
    inds = ArrayInterface.to_indices(A, args)
    @boundscheck checkbounds(A, inds...)
    unsafe_setindex!(getfield(A, :parent), vals, inds)
end
function Base.setindex!(@nospecialize(A::MetaArray), vals; kwargs...)
    inds = ArrayInterface.to_indices(A, ArrayInterface.find_all_dimnames(dimnames(A), static(keys(kwargs)), Tuple(values(kwargs)), :))
    @boundscheck checkbounds(A, inds...)
    unsafe_setindex!(getfield(A, :parent), vals, inds)
end
@inline unsafe_setindex!(@nospecialize(A::MetaArray), vals, inds) = unsafe_setindex!(getfield(A, :parent), vals, inds)
@inline unsafe_setindex!(A, vals, inds) = @inbounds setindex!(A, vals, inds...)

# Reducing dimensions
# FIXME reduction across all dimensions results in a single element
reduce_metadata(m, ::Colon) = no_metadata
for (mod, funs) in (
    (:Base, (:sum, :prod, :maximum, :minimum, :extrema, :argmax, :argmin)),
    (:Statistics, (:mean, :std, :var, :median)),
)
    for fun in funs
        @eval function $mod.$fun(@nospecialize(a::MetaArray); dims=:, kwargs...)
            d = ArrayInterface.to_dims(a, dims)
            attach_metadata($mod.$fun(parent(a); dims=d, kwargs...), reduce_metadata(metadata(a), d))
        end
    end
end

function Base.mapreduce(f1, f2, @nospecialize(a::MetaArray); dims=:, kwargs...)
    d = ArrayInterface.to_dim(a, dims)
    attach_metadata(mapreduce(f1, f2, parent(a); dims=d, kwargs...), reduce_metadata(metadata(a), d))
end

# 1 Arg, 2 Results
for (mod, funs) in ((:Base, (:findmax, :findmin)),)
    for fun in funs
        @eval function $mod.$fun(@nospecialize(a::MetaArray); dims=:, kwargs...)
            d = ArrayInterface.to_dims(a, dims)
            data, index = $mod.$fun(parent(a); dims=d, kwargs...)
            return (attach_metadata(data, reduce_metadata(metadata(d), d)), index)
        end
    end
end

# Reshape
reshape_metadata(m, dims) = MetadataInterface.no_metadata

function _reshape(@nospecialize(x::MetaArray), dims)
    attach_metadata(reshape(parent(x), dims), reshape_metadata(metadata(x), dims))
end
Base.reshape(@nospecialize(x::MetaVector), dim::Colon) = _reshape(x, dims)
Base.reshape(x::MetaArray{T,N}, ndims::Val{N}) where {T, N} = _reshape(x, dims)

#=
Base.reshape(x::MetaArray, dims::Int...) = _reshape(x, dims)
Base.reshape(x::MetaArray, dims::Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo}}}) = _reshape(x, dims)
Base.reshape(x::MetaVector, dims::Colon) = _reshape(x, dims)
Base.reshape(x::MetaArray, dims::Union{Int, AbstractUnitRange}...) = _reshape(x, dims)
Base.reshape(x::MetaArray, dims::Union{Colon, Int}...) = _reshape(x, dims)
Base.reshape(x::MetaArray, ndims::Val{N}) where N = _reshape(x, dims)
Base.reshape(x::MetaArray, dims::Tuple{Vararg{Union{Colon, Int}}}) = _reshape(x, dims)
Base.reshape(x::MetaArray, dims::Tuple{Vararg{Colon}}) = _reshape(x, dims)
=#

# Accumulators
function Base.accumulate(op, @nospecialize(A::MetaArray); dims=nothing, kw...)
    if dims === nothing
        return propagate_metadata(A, accumulate(op, parent(A); dims=dims, kw...))
    else
        return propagate_metadata(A, accumulate(op, parent(A); dims=to_dims(A, dims), kw...))
    end
end

# 1 Arg - no default for `dims` keyword
for (mod, funs) in ((:Base, (:cumsum, :cumprod, :sort, :sortslices)),)
    for fun in funs
        @eval function $mod.$fun(@nospecialize(a::MetaArray); dims, kwargs...)
            d = ArrayInterface.to_dims(a, dims)
            propagate_metadata(a, $mod.$fun(parent(a); dims=d, kwargs...))
        end

        # Vector case
        @eval function $mod.$fun(@nospecialize(a::MetaVector); kwargs...)
            propagate_metadata(a, $mod.$fun(parent(a); kwargs...))
        end
    end
end

