
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
struct MetaArray{T, N, M, A<:AbstractArray} <: AbstractArray{T, N}
    parent::A
    metadata::M

    function MetaArray{T,N,M,A}(a::AbstractArray, meta) where {T,N,M,A}
        if a isa A
            if meta isa M
                return new{T,N,M,A}(a, meta)
            else
                return new{T,N,M,A}(a, M(meta))
            end
        else
            if meta isa M
                return new{T,N,M,A}(A(a), meta)
            else
                return new{T,N,M,A}(A(a), M(meta))
            end
        end
    end

    function MetaArray{T,N,M,A}(a::AbstractArray; metadata=MDict(), kwargs...) where {T,N,M,A}
        return MetaArray{T,N,M,A}(a, _construct_meta(metadata, values(kwargs)))
    end

    function MetaArray{T,N,M,A}(args...; metadata=MDict(), kwargs...) where {T,N,M,A}
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

    function MetaArray{T,N}(a::AbstractArray; metadata=MDict(), kwargs...) where {T,N}
        return MetaArray{T,N}(a, _construct_meta(metadata, values(kwargs)))
    end

    function MetaArray{T,N}(args...; metadata=MDict(), kwargs...) where {T,N}
        return MetaArray{T,N}(Array{T,N}(args...); metadata=metadata, kwargs...)
    end

    ###
    ### MetArray{T}
    ###
    function MetaArray{T}(args...; metadata=MDict(), kwargs...) where {T}
        return MetaArray{T}(Array{T}(args...); metadata=metadata, kwargs...)
    end

    MetaArray{T}(a::AbstractArray, m::M) where {T,M} = MetaArray{T,ndims(a)}(a, m)

    function MetaArray{T}(a::AbstractArray; metadata=MDict(), kwargs...) where {T}
        return MetaArray{T,ndims(a)}(a; metadata=metadata, kwargs...)
    end

    ###
    ### MetaArray
    ###
    MetaArray(v::AbstractArray{T,N}, m::M) where {T,N,M} = new{T,N,M,typeof(v)}(v, m)

    function MetaArray(a::AbstractArray; metadata=MDict(), kwargs...)
        return MetaArray{eltype(a)}(a; metadata=metadata, kwargs...)
    end
end

@inline function metadata_type(::Type{T}; dim=nothing) where {M,A,T<:MetaArray{<:Any,<:Any,M,A}}
    if dim === nothing
        return M
    else
        return metadata_type(A; dim=dim)
    end
end

ArrayInterface.parent_type(::Type{MetaArray{T,M,N,A}}) where {T,M,N,A} = A

Base.parent(A::MetaArray) = getfield(A, :parent)

Base.copy(A::MetaArray) = copy_metadata(A, copy(parent(A)))

function Base.show(io::IO, ::MIME"text/plain", X::MetaArray)
    summary(io, X)
    isempty(X) && return
    Base.show_circular(io, X) && return

    if !haskey(io, :compact) && length(axes(X, 2)) > 1
        io = IOContext(io, :compact => true)
    end
    if get(io, :limit, false) && eltype(X) === Method
        io = IOContext(io, :limit => false)
    end

    if get(io, :limit, false) && Base.displaysize(io)[1] - 4 <= 0
        return print(io, " …")
    else
        println(io)
    end

    io = IOContext(io, :typeinfo => eltype(X))

    recur_io = IOContext(io, :SHOWN_SET => X)
    Base.print_array(recur_io, parent(X))
end

Base.print_array(io::IO, A::MetaArray) = Base.print_array(io, parent(A))

function Base.similar(x::MetaArray, t::Type, dims)
    return Metadata.share_metadata(x, similar(parent(x), t, dims))
end

function Base.similar(
    x::MetaArray,
    t::Type,
    dims::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo}}}
)

    return Metadata.propagate_metadata(x, similar(parent(x), t, dims))
end

function Base.similar(x::MetaArray, t::Type=eltype(x), dims::Tuple{Vararg{Int64}}=size(x))
    return Metadata.propagate_metadata(A, similar(parent(x), t, dims))
end

function Base.similar(x::MetaArray, t::Type, dims::Union{Integer,AbstractUnitRange}...)
    return Metadata.propagate_metadata(x, similar(parent(x), t, dims))
end

Base.summary(io::IO, x::MetaArray) = Base.showarg(io, x, true)
function Base.showarg(io::IO, x::MetaArray, toplevel)
    if toplevel
        print(io, Base.dims2string(length.(axes(x))), " ")
    end
    print(io, "attach_metadata(")
    Base.showarg(io, parent(x), false)
    print(io, ", ", showarg_metadata(x))
    println(io)
    metadata_summary(io, x)
    print(io, "\n)")
end

@_define_function_no_prop(Base, size, MetaArray)
@_define_function_no_prop(Base, axes, MetaArray)

Base.IndexStyle(T::Type{<:MetaArray}) = IndexStyle(parent_type(T))


@propagate_inbounds function Base.getindex(A::MetaArray{T}, args...) where {T}
    return _getindex(A, getindex(parent(A), args...))
end

_getindex(A::MetaArray{T}, val::T) where {T} = val
_getindex(A::MetaArray{T}, val) where {T} = propagate_metadata(A, val)

@propagate_inbounds function Base.setindex!(A::MetaArray, val, args...)
    return setindex!(parent(A), val, args...)
end

#function Base.show(io::IO, ::MIME"text/plain", A::MetaArray) end

