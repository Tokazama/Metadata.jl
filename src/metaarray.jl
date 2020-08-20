
"""
    MetaArray(parent::AbstractArray, metadata)

Custom `AbstractArray` object to store an `AbstractArray` `parent` as well as
some `metadata`.
"""
struct MetaArray{T, N, M, A<:AbstractArray} <: AbstractArray{T, N}
    parent::A
    metadata::M

    MetaArray(v::AbstractArray{T,N}, m::M) where {T,N,M} = new{T,N,M,typeof(v)}(v, m)

    function MetaArray(v::AbstractArray; metadata=nothing, kwargs...)
        return MetaArray(v, _construct_meta(metadata, values(kwargs)))
    end
end

metadata(A::MetaArray) = getfield(A, :metadata)
metadata_type(::Type{MetaArray{T,N,M,A}}) where {T,N,M,A} = M

Base.parent(A::MetaArray) = getfield(A, :parent)

Base.size(s::MetaArray) = Base.size(parent(s))

Base.axes(s::MetaArray) = Base.axes(parent(s))

Base.IndexStyle(T::Type{<:MetaArray}) = IndexStyle(parent_type(T))

ArrayInterface.parent_type(::Type{MetaArray{T,M,N,A}}) where {T,M,N,A} = A

"""
    MetaVector{T, M, S<:AbstractArray}

Type for storing metadata alongside a vector.
"""
const MetaVector{T, M, S<:AbstractArray} = MetaArray{T, 1, M, S}

MetaVector(v::AbstractVector, n = ()) = MetaArray(v, n)

@propagate_inbounds function Base.getindex(A::MetaArray{T}, args...) where {T}
    return _getindex(A, getindex(parent(A), args...))
end

_getindex(A::MetaArray{T}, val::T) where {T} = val
_getindex(A::MetaArray{T}, val) where {T} = maybe_propagate_metadata(A, val)

@propagate_inbounds function Base.setindex!(A::MetaArray, val, args...)
    return setindex!(parent(A), val, args...)
end

Base.copy(A::MetaArray) = copy_metadata(A, copy(parent(A)))

#function Base.show(io::IO, ::MIME"text/plain", A::MetaArray) end

function Base.show(io::IO, ::MIME"text/plain", X::MetaArray)
    if isempty(X) && (get(io, :compact, false) || X isa Vector)
        return show(io, X)
    end
    # 0) show summary before setting :compact
    summary(io, X)
    isempty(X) && return
    Base.show_circular(io, X) && return

    # 1) compute new IOContext
    if !haskey(io, :compact) && length(axes(X, 2)) > 1
        io = IOContext(io, :compact => true)
    end
    if get(io, :limit, false) && eltype(X) === Method
        # override usual show method for Vector{Method}: don't abbreviate long lists
        io = IOContext(io, :limit => false)
    end

    if get(io, :limit, false) && Base.displaysize(io)[1]-4 <= 0
        return print(io, " …")
    else
        println(io)
    end

    # 2) update typeinfo
    #
    # it must come after printing the summary, which can exploit :typeinfo itself
    # (e.g. views)
    # we assume this function is always called from top-level, i.e. that it's not nested
    # within another "show" method; hence we always print the summary, without
    # checking for current :typeinfo (this could be changed in the future)
    io = IOContext(io, :typeinfo => eltype(X))

    # 2) show actual content
    recur_io = IOContext(io, :SHOWN_SET => X)
    Base.print_array(recur_io, X)
end

function Base.similar(x::MetaArray, t::Type, dims)
    return Metadata.share_metadata(x, similar(parent(x), t, dims))
end

function Base.similar(
    x::MetaArray,
    t::Type,
    dims::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo}}}
)

    return Metadata.maybe_propagate_metadata(x, similar(parent(x), t, dims))
end

function Base.similar(x::MetaArray, t::Type=eltype(x), dims::Tuple{Vararg{Int64}}=size(x))
    return Metadata.maybe_propagate_metadata(A, similar(parent(x), t, dims))
end

function Base.similar(x::MetaArray, t::Type, dims::Union{Integer,AbstractUnitRange}...)
    return Metadata.maybe_propagate_metadata(x, similar(parent(x), t, dims))
end

