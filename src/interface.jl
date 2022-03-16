
"""
    NoMetadata

Internal type for the `Metadata` package that indicates the absence of any metadata.
_DO NOT_ store metadata with the value `NoMetadata()`.
"""
struct NoMetadata end

const no_metadata = NoMetadata()

Base.show(io::IO, ::NoMetadata) = print(io, "no_metadata")
Base.haskey(::NoMetadata, @nospecialize(k)) = false
Base.get(::NoMetadata, @nospecialize(k), default) = default

"""
    metadata(x)

Returns the metadata associated with `x`. If there is no metadata associated with `x` then
`no_metadata` is returned.
"""
metadata(x) = no_metadata

"""
    metadata_type(::Type{T})

Returns the type of the metadata associated with `x`.
"""
metadata_type(x) = metadata_type(typeof(x))
metadata_type(::Type) = NoMetadata

"""
    has_metadata(x)::Bool

Returns `true` if `x` has metadata.
"""
has_metadata(x) = Bool(_has_metadata(x))
@inline function _has_metadata(x)
    if metadata_type(x) <: NoMetadata
        False()
    else
        True()
    end
end

"""
    attach_metadata(x, metadata)

Generic method for attaching metadata to `x`.
"""
attach_metadata(x, m) = _attach_metadata(x, m)
_attach_metadata(x, ::NoMetadata) = x
_attach_metadata(x, m) = MetaStruct(x, m)
attach_metadata(x::IO, m) = MetaIO(x, m)
attach_metadata(x::IO, ::NoMetadata) = x
attach_metadata(x::AbstractUnitRange{Int}, m) = MetaUnitRange(x, m)
attach_metadata(x::AbstractUnitRange{Int}, ::NoMetadata) = x
attach_metadata(x::AbstractArray, m) = MetaArray(x, m)
attach_metadata(x::AbstractArray, ::NoMetadata) = x
attach_metadata(x::METADATA_TYPES) = Base.Fix2(attach_metadata, x)

"""
    metadata(x, k)

Returns the value associated with key `k` of `x`'s metadata.
"""
function metadata(x, key)
    out = getmeta(x, key, no_metadata)
    out === no_metadata || return out
    throw(KeyError(key))
end

""" propagate_metadata """
propagate_metadata(m) = m

# TODO
""" index_metadata """
index_metadata(m, inds::Tuple) = m

# TODO
""" permute_metadata """
permute_metadata(m) = m
permute_metadata(m, perm::Tuple) = m

""" similar_metadata """
similar_metadata(m, dims::Tuple) = m

macro _defmeta(T)
    esc(quote
        Base.parent(x::$T) = getfield(x, :parent)

        function Base.copy(x::$T)
            $T(deepcopy(getfield(x, :parent)), deepcopy(getfield(x, :metadata)))
        end

        Metadata.metadata(x::$T) = getfield(x, :metadata)

        Base.getproperty(x::$T, k::String) = Metadata.metadata(x, k)
        @inline function Base.getproperty(x::$T, k::Symbol)
            p = getfield(x, :parent)
            if hasproperty(p, k)
                return getproperty(p, k)
            else
                return Metadata.metadata(x, k)
            end
        end

        Base.setproperty!(x::$T, k::String, v) = Metadata.metadata!(x, k, v)
        @inline function Base.setproperty!(x::$T, k::Symbol, val)
            if hasproperty(parent(x), k)
                return setproperty!(parent(x), k, val)
            else
                return Metadata.metadata!(x, k, val)
            end
        end

        @inline Base.propertynames(x::$T) = Metadata.metadata_keys(x)
    end)
end

