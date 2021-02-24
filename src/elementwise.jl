
"""
    ElementwiseMetaArray

Array with metadata attached to each element.
"""
struct ElementwiseMetaArray{T,N,P<:AbstractArray{T,N},M,D} <: AbstractArray2{T,N}
    parent::P
    metadata::M
    defaults::D

    function ElementwiseMetaArray{T,N,P,M,D}(parent::P, metadata::M, defaults::D) where {T,N,P,M,D}
        len = length(parent)
        for (_, v) in metadata
            eachindex(parent, v)
        end
        return new{T,N,P,M}(parent, metadata)
    end

    function ElementwiseMetaArray(parent::P, metadata::M, ::Nothing) where {P,M}
        len = length(parent)
        for (_, v) in metadata
            eachindex(parent, v)
        end
        return new{eltype(P),ndims(P),P,M,Nothing}(parent, metadata, nothing)
    end

    function ElementwiseMetaArray(parent::P, metadata::M, defaults::D) where {P,M,D}
        len = length(parent)
        dkeys = keys(defaults)
        inds = eachindex(IndexLinear(), parent)
        if can_change_size(P)
            for (k, v) in metadata
                if eachindex(IndexLinear(), v) != inds
                    error("Metadata at key $k does not match each parent index $inds, got $(eachindex(IndexLinear(), v))")
                end
                if !can_change_size(v)
                    error("cannot change size of metadata at key $k, got $v")
                end
                if !(typeof(defaults[k]) <: eltype(v))
                    error("Expected eltype of metedata corresponding to key $k to be $(eltype(v)), got $(typeof(defaults[k]))")
                end
            end
            return new{eltype(P),ndims(P),P,M,D}(parent, metadata, nothing)
        else
            error("cannot change size of $x but received default values for changing size of $x")
        end
    end
    function ElementwiseMetaArray(parent::P, metadata::M, ::Nothing) where {P,M}
        len = length(parent)
        inds = eachindex(IndexLinear(), parent)
        for (_, v) in metadata
            if eachindex(IndexLinear(), v) != inds
                error("Metadata at key $k does not match each parent index $inds, got $(eachindex(IndexLinear(), v))")
            end
        end
        return new{eltype(P),ndims(P),P,M,Nothing}(parent, metadata, nothing)
    end

    function ElementwiseMetaArray(parent::P, metadata::M)
        return ElementwiseMetaArray(parent, metadata, nothing)
    end
end

ArrayInterface.can_change_size(::Type{<:ElementwiseMetaArray{T,N,P,M,Nothing}}) where {T,N,P,M} = false
ArrayInterface.can_change_size(::Type{<:ElementwiseMetaArray{T,N,P,M,D}}) where {T,N,P,M,D} = true
ArrayInterface.parent_type(::Type{<:ElementwiseMetaArray{T,N,P}}) where {T,N,P} = P

Base.parent(A::ElementwiseMetaArray) = getfield(A, :parent)

function metadata_type(::Type{<:ElementwiseMetaArray{T,N,P,M}}; dim=nothing) where {T,N,P,M}
    if dim === nothing
        return M
    else
        return metadata_type(P; dim=dim)
    end
end

@inline function metadata(A::ElementwiseMetaArray; dim=nothing)
    if dim === nothing
        return getfield(A, :metadata)
    else
        return metadata(parent(A); dim=dim)
    end
end

# TODO provide default meta for elwise stuff
function Base.push!(x::ElementwiseMetaArray, item)
    if can_change_size(x)
        _push!(metadata(item), x, item)
        push!(parent(x), item)
    else
        error("cannot change size of $x")
    end
    return x
end

function _push!(::NoMetadata, x, item)
    m = metadata(x)
    for (k,v) in m
        push!(v, copy(x.defaults[k]))
    end
end

function _push!(mitem, x, item)
    m = metadata(x)
    for (k,v) in m
        push!(v, copy(mitem[k]))
    end
end

function Base.pushfirst!(x::ElementwiseMetaArray, item; metadata)
    if can_change_size(x)
        _pushfirst!(metadata(item), x, item)
        pushfirst!(parent(x), item)
    else
        error("cannot change size of $x")
    end
    return x
end

function _pushfirst!(::NoMetadata, x, item)
    m = metadata(x)
    for (k,v) in m
        pushfirst!(v, copy(x.defaults[k]))
    end
end

function _pushfirst!(mitem, x, item)
    m = metadata(x)
    for (k,v) in m
        pushfirst!(v, copy(mitem[k]))
    end
end

function Base.append!(x::ElementwiseMetaArray, y)
    if can_change_size(x)
        _append!(metadata(y), x, y)
        append!(parent(x), y)
    else
        error("cannot change size of $x")
    end
    return x
end

function _append!(::NoMetadata, x, y)
    m = metadata(x)
    len = length(x)
    for (k,v) in m
        append!(v, fill(x.defaults[k], len))
    end
end
function _append!(my, x, y)
    m = metadata(x)
    len = length(x)
    for (k,v) in m
        append!(v, my[k])
    end
end

function Base.prepend!(x::ElementwiseMetaArray, y)
    if can_change_size(x)
        _prepend!(metadata(y), x, y)
        append!(parent(x), y)
    else
        error("cannot change size of $x")
    end
    return x
end

function _prepend!(::NoMetadata, x, y)
    m = metadata(x)
    len = length(x)
    for (k,v) in m
        prepend!(v, fill(x.defaults[k], len))
    end
end
function _prepend!(my, x, y)
    m = metadata(x)
    len = length(x)
    for (k,v) in m
        prepend!(v, my[k])
    end
end

# TODO function Base.reverse!(x::ElementwiseMetaArray) end

# TODO function drop_metadata(x::ElementwiseMetaArray) end

#=
struct AdjacencyList{T,L<:AbstractVector{<:AbstractVector{T}}} <: AbstractGraph{T}
    list::L
end

@inline function metadata_keys(x::ElementwiseMetaArray; dim=dim)
    if metadata_type(x; dim=dim) <: AbstractDict
        return metadata_keys(first(parent(x)))
    else
        return fieldnames(metadata_type(x))
    end
end

const MetaAdjacencyList{T,M} = AdjacencyList{T,Vector{ElementwiseMetaArray{T,1,Vector{Tuple{T,M}}}}}
=#

