
function _construct_meta(meta::AbstractDict{Symbol}, kwargs::NamedTuple)
    for (k, v) in kwargs
        meta[k] = v
    end
    return meta
end
_construct_meta(meta::Nothing, kwargs::NamedTuple) = kwargs

function _construct_meta(meta, kwargs::NamedTuple)
    if isempty(kwargs)
        return meta
    else
        error("Cannot assign key word arguments to metadata of type $T")
    end
end

"""
    MetaArray(parent::AbstractArray, metadata)

Custom `AbstractArray` object to store an `AbstractArray` `parent` as well as some `metadata`.
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
attach_metadata(x::AbstractArray, m) = MetaArray(x, m)

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

###
### these are necessary because base will dispatch differently vectors, ranges, unit ranges
###

"""
    MetaRange(x::AbstractRange, meta)

Type for storing metadata alongside a range.
"""
struct MetaRange{T,P<:AbstractRange{T},M} <: AbstractRange{T}
    parent::P
    metadata::M
end

ArrayInterface.parent_type(::Type{<:MetaRange{<:Any,P,<:Any}}) where {P} = P
metadata_type(::Type{<:MetaRange{<:Any,<:Any,M}}) where {M} = M

"""
    MetaUnitRange(x::AbstractUnitRange, meta)

Type for storing metadata alongside a anything that is subtype of `AbstractUnitRange`.
"""
struct MetaUnitRange{T,P<:AbstractRange{T},M} <: AbstractUnitRange{T}
    parent::P
    metadata::M

    function MetaUnitRange{T,P,M}(p::P, m::M) where {T,P,M}
        if known_step(p) === oneunit(T)
            return new{T,P,M}(p, m)
        else
            throw(ArgumentError("step must be 1, got $(step(r))"))
        end
    end
end

ArrayInterface.parent_type(::Type{<:MetaUnitRange{<:Any,P,<:Any}}) where {P} = P
metadata_type(::Type{<:MetaUnitRange{<:Any,<:Any,M}}) where {M} = M

for T in (MetaRange, MetaUnitRange)
    @eval begin
        metadata(r::$T) = getfield(r, :metadata)

        Base.parent(r::$T) = getfield(r, :parent)

        Base.first(r::$T) = first(parent(r))

        Base.step(r::$T) = step(parent(r))

        Base.last(r::$T) = last(parent(r))

        ArrayInterface.known_first(::Type{T}) where {T<:$T} = known_first(parent_type(T))

        ArrayInterface.known_last(::Type{T}) where {T<:$T} = known_last(parent_type(T))

        ArrayInterface.known_step(::Type{T}) where {T<:$T} = known_step(parent_type(T))

        Base.@propagate_inbounds function Base.getindex(r::$T, i::Integer)
            return getindex(parent(r), i)
        end

        Base.@propagate_inbounds function Base.getindex(r::$T, inds)
           subr = getindex(parent(r), inds)
           if subr isa AbstractRange
               return maybe_propagate_metadata(r, subr)
           else
               return subr
           end
        end
    end
end

###
### Fixes ambiguities
###
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::StepRange{T}) where T<:Integer
    return maybe_propagate_metadata(r, getindex(parent(r), s))
end
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::AbstractUnitRange{T}) where {T<:Integer}
    return maybe_propagate_metadata(r, getindex(parent(r), s))
end
Base.getindex(r::MetaRange, ::Colon) = copy(r)
Base.getindex(r::MetaUnitRange, ::Colon) = copy(r)

function attach_metadata(x::AbstractRange, m)
    if known_step(x) === oneunit(eltype(x))
        return MetaUnitRange(x, m)
    else
        return MetaRange(x, m)
    end
end

