
"""
    metadata(x)

Returns metadata associated with `x`
"""
metadata(x) = _metadata(parent_type(x), x)
metadata(x::AbstractDict) = x
metadata(x::NamedTuple) = x
_metadata(::Type{P}, x::T) where {P,T} = metadata(parent(x))
_metadata(::Type{T}, x::T) where {T} = no_metadata

"""
    metadata(x, k)

Returns the value associated with key `k` of `x`'s metadata.
"""
function metadata(x, k)
    out = getmeta(x, k, no_metadata)
    out === no_metadata && throw(KeyError(k))
    return out
end
function metadata(m::Module)
    if isdefined(m, GLOBAL_METADATA)
        return getfield(m, GLOBAL_METADATA)::GlobalMetadata
    else
        return GlobalMetadata(m)
    end
end

"""
    metadata!(x, k, val)

Set the value associated with key `k` of `x`'s metadata to `val`.
"""
@inline metadata!(x, k, val) = metadata!(metadata(x), k, val)
metadata!(x::AbstractDict, k, val) = setindex!(x, val, k)
metadata!(m::AbstractDict{String}, k::Symbol, val) = setindex!(m, val, String(k))
metadata!(m::AbstractDict{Symbol}, k::String, val) = setindex!(m, val, Symbol(k))

"""
    getmeta(x, key, default)

Return the metadata associated with `key`, or return `default` if `key` is not found.
"""
@inline getmeta(x, k, default) = _getmeta(metadata(x), k, default)
_getmeta(m, k, default) = get(m, k, default)
@inline _getmeta(m::AbstractDict{String}, k::Symbol, default) = get(m, String(k), default)
@inline _getmeta(m::AbstractDict{Symbol}, k::String, default) = get(m, Symbol(k), default)
@inline _getmeta(m::NamedTuple, k::String, default) = get(m, Symbol(k), default)

"""
    getmeta(f::Function, x, key)

Return the metadata associated with `key`, or return `f(x)` if `key` is not found. Note that
this behavior differs from `Base.get(::Function, x, keys)` in that `getmeta` passes `x` to
`f` as an argument (as opposed to `f()`).
"""
@inline function getmeta(f::Union{Function,Type}, x, k)
    m = getmeta(metadata(x), k, no_metadata)
    if m === no_metadata
        return f(x)
    else
        return m
    end
end

"""
    getmeta!(x, key, default)

Return the metadata associated with `key`. If `key` is not found then `default` is returned
and stored at `key`.
"""
@inline getmeta!(x, k, default) = _getmeta!(metadata(x), k, default)
_getmeta!(m, k, default) = get!(m, k, default)
@inline _getmeta!(m::AbstractDict{String}, k::Symbol, default) = get!(m, String(k), default)
@inline _getmeta!(m::AbstractDict{Symbol}, k::String, default) = get!(m, Symbol(k), default)

"""
    getmeta!(f::Function, x, key)

Return the metadata associated with `key`. If `key` is not found then `f(x)` is returned
and stored at `key`. Note that this behavior differs from `Base.get!(::Function, x, keys)` in
that `getmeta!` passes `x` to `f` as an argument (as opposed to `f()`).
"""
@inline function getmeta!(f::Function, x, k)
    m = metadata(x)
    out = get(m, k, no_metadata)
    if out === no_metadata
        out = f(x)
        metadata!(m, k, out)
    end
    return out
end

"""
    metadata_type(::Type{T})

Returns the type of the metadata associated with `x`.
"""
metadata_type(x) = metadata_type(typeof(x))
metadata_type(::Type{T}) where {T} = _metadata_type(parent_type(T), T)
_metadata_type(::Type{T}, ::Type{T}) where {T} = NoMetadata
_metadata_type(::Type{P}, ::Type{T}) where {P,T} = metadata_type(P)
metadata_type(::Type{T}) where {T<:AbstractDict} = T
metadata_type(::Type{T}) where {T<:NamedTuple} = T
metadata_type(::Type{T}) where {T<:Module} = GlobalMetadata
metadata_type(::Type{<:MetaStruct{<:Any,M}}) where {M} = M
metadata_type(::Type{<:MetaUnitRange{<:Any,<:Any,M}}) where {M} = M

"""
    has_metadata(x)::Bool

Returns `true` if `x` has metadata.
"""
has_metadata(x) = has_metadata(typeof(x))
has_metadata(::Type{T}) where {T} = _has_metadata(metadata_type(T))
_has_metadata(::Type{NoMetadata}) = false
_has_metadata(::Type{T}) where {T} = true

"""
    has_metadata(x, k)::Bool

Returns `true` if metadata associated with `x` has the key `k`.
"""
has_metadata(x, k) = haskey(metadata(x), k)

"""
    attach_metadata(x, metadata)

Generic method for attaching metadata to `x`.
"""
attach_metadata(x, m=Dict{Symbol,Any}()) = MetaStruct(x, m)
attach_metadata(x::AbstractArray, m=Dict{Symbol,Any}()) = MetaArray(x, m)
function attach_metadata(x::AbstractRange, m=Dict{Symbol,Any}())
    if known_step(x) === oneunit(eltype(x))
        return MetaUnitRange(x, m)
    else
        return MetaArray(x, m)
    end
end
attach_metadata(x::IO, m=Dict{Symbol,Any}()) = MetaIO(x, m)
attach_metadata(m::METADATA_TYPES) = Base.Fix2(attach_metadata, m)

"""
    share_metadata(src, dst) -> attach_metadata(dst, metadata(src))

Shares the metadata from `src` by attaching it to `dst`.
The returned instance will have properties that are synchronized with `src` (i.e.
modifying one's metadata will effect the other's metadata).

See also: [`copy_metadata`](@ref).
"""
share_metadata(src, dst) = attach_metadata(dst, metadata(src))

"""
    copy_metadata(src, dst) -> attach_metadata(dst, copy(metadata(src)))

Copies the the metadata from `src` and attaches it to `dst`. Note that this method
specifically calls `deepcopy` on the metadata of `src` to ensure that changing the
metadata of `dst` does not affect the metadata of `src`.

See also: [`share_metadata`](@ref).
"""
copy_metadata(src, dst) = attach_metadata(dst, deepcopy(metadata(src)))

"""
    drop_metadata(x)

Returns `x` without metadata attached.
"""
drop_metadata(x) = parent(x)

# This allows dictionaries's keys to be treated like property names
metadata_keys(x::AbstractDict) = keys(x)
metadata_keys(::NamedTuple{L}) where {L} = L
function metadata_keys(x::X) where {X}
    if has_metadata(X)
        return metadata_keys(metadata(x))
    else
        return propertynames(x)
    end
end

"""
    MetadataPropagation(::Type{T})

Returns type informing how to propagate metadata of type `T`.
See [`DropMetadata`](@ref), [`CopyMetadata`](@ref), [`ShareMetadata`](@ref).
"""
abstract type MetadataPropagation end

"""
    DropMetadata

Informs operations that may propagate metadata to insead drop it.
"""
struct DropMetadata <: MetadataPropagation end

"""
    CopyMetadata

Informs operations that may propagate metadata to attach a copy to any new instance created.
"""
struct CopyMetadata <: MetadataPropagation end

"""
    ShareMetadata

Informs operations that may propagate metadata to attach a the same metadata to
any new instance created.
"""
struct ShareMetadata <: MetadataPropagation end

MetadataPropagation(x) = MetadataPropagation(typeof(x))
MetadataPropagation(::Type{T}) where {T} = MetadataPropagation(metadata_type(T))
MetadataPropagation(::Type{T}) where {T<:AbstractDict} = ShareMetadata()
MetadataPropagation(::Type{T}) where {T<:NamedTuple} = ShareMetadata()
MetadataPropagation(::Type{T}) where {T<:NoMetadata} = DropMetadata()

function propagate_metadata(src, dst)
    return propagate_metadata(MetadataPropagation(src), src, dst)
end
propagate_metadata(::DropMetadata, src, dst) = dst
propagate_metadata(::ShareMetadata, src, dst) = share_metadata(src, dst)
propagate_metadata(::CopyMetadata, src, dst) = copy_metadata(src, dst)

function MetadataPropagation(::Type{T}) where {P,M,T<:MetaStruct{P,M}}
    if P <: Number
        return DropMetadata()
    else
        return ShareMetadata()
    end
end

"""
    metadata_summary([io], x)

Creates summary readout of metadata for `x`.
"""
metadata_summary(x) = metadata_summary(stdout, x)
function metadata_summary(io::IO, x)
    print(io, "$(lpad(Char(0x2022), 3)) metadata:")
    suppress = getmeta(x, :suppress, no_metadata)
    if suppress !== no_metadata
        suppress = metadata(x, :suppress)
        for k in metadata_keys(x)
            if k !== :suppress
                println(io)
                print(io, "     ")
                print(io, "$k")
                print(io, " = ")
                if in(k, suppress)
                    print(io, "<suppressed>")
                else
                    print(io, metadata(x, k))
                end
            end
        end
    else
        for k in metadata_keys(x)
            println(io)
            print(io, "     ")
            print(io, "$k")
            print(io, " = ")
            print(io, metadata(x, k))
        end
    end
end

# this is a currently informal way of changing how showarg displays metadata in
# the argument list. If someone makes a metadata type that's long or complex they
# may want to overload this.
#
# - used within Base.showarg for MetaArray
showarg_metadata(x) = "::$(metadata_type(x))"

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
    attach_global_metadata(x, meta, m::Module)

Attach metadata `meta` to the object id of `x` (`objectid(x)`) in global metadata of
module `m`.
"""
function attach_global_metadata(x, meta::MDict, m::Module)
    setindex!(metadata(m), meta, objectid(x))
    if _attach_global_metadata(x, x, m)
        @warn "Cannot create finalizer for $(typeof(x)). Global dictionary must be manually deleted."
    end
    return meta
end

function attach_global_metadata(x, meta, m::Module)
    gm = Dict{Symbol,Any}()
    for (k,v) in pairs(meta)
        gm[k] = v
    end
    return attach_global_metadata(x, gm, m)
end

function _attach_global_metadata(x, xfield, m::Module)
    there_is_no_finalizer = true
    if ismutable(x)
        _assign_global_metadata_finalizer(x, xfield, m)
        there_is_no_finalizer = false
    elseif isstructtype(typeof(x))
        N = fieldcount(typeof(x))
        if N !== 0
            i = 1
            while (there_is_no_finalizer && i <= N)
                there_is_no_finalizer = _assign_global_metadata_finalizer(x, getfield(xfield, i), m)
                i += 1
            end
        end
    end
    return there_is_no_finalizer
end

function _assign_global_metadata_finalizer(x, xfield, m::Module)
    if Base.ismutable(xfield)
        finalizer(xfield) do _
            @async delete_global_metadata!(x, m)
        end
        return false
    else
        return true
    end
end

delete_global_metadata!(x, m::Module) = delete!(metadata(m), objectid(x))

"""
    global_metadata(x, m::Module)
    global_metadata(x, k::Symbol, m::Module)

Retreive metadata associated with the object id of `x` (`objectid(x)`) in stored in the
global metadata of module `m`. If the key `k` is specified only the value associated with
that key is returned.
"""
global_metadata(x, m::Module) = get(metadata(m), objectid(x), no_metadata)
global_metadata(x, k, m::Module) = getindex(global_metadata(x, m), k)

"""
    global_metadata!(x, k, val, m::Module)

Set the value of `x`'s global metadata in module `m` associated with the key `k` to `val`.
"""
global_metadata!(x, k, val, m::Module) = setindex!(global_metadata(x, m), val, k)

"""
    @attach_metadata(x, meta)

Attach metadata `meta` to the object id of `x` (`objectid(x)`) in the current module's
global metadata.

See also: [`GlobalMetadata`](@ref)
"""
macro attach_metadata(x, meta)
    esc(:(Metadata.attach_global_metadata($x, $meta, @__MODULE__)))
end

"""
    @metadata(x[, k])

Retreive metadata associated with the object id of `x` (`objectid(x)`) in the current
module's global metadata. If the key `k` is specified only the value associated with
that key is returned.
"""
macro metadata(x)
    esc(:(Metadata.global_metadata($(x), @__MODULE__)))
end

macro metadata(x, k)
    esc(:(Metadata.global_metadata($(x), $(k), @__MODULE__)))
end

"""
    @metadata!(x, k, val)

Set the value of `x`'s global metadata associated with the key `k` to `val`.
"""
macro metadata!(x, k, val)
    return esc(:(Metadata.global_metadata!($x, $k, $val, @__MODULE__)))
end

"""
    @has_metadata(x)::Bool
    @has_metadata(x, k)::Bool

Does `x` have metadata stored in the curren modules' global metadata? Checks for the
presenece of the key `k` if specified.
"""
macro has_metadata(x)
    esc(:(Metadata.global_metadata($x, @__MODULE__) !== Metadata.no_metadata))
end
macro has_metadata(x, k)
    esc(:(haskey(Metadata.global_metadata($x, @__MODULE__), $k)))
end

"""
    @share_metadata(src, dst) -> @attach_metadata(@metadata(src), dst)

Shares the metadata from `src` by attaching it to `dst`. This assumes that metadata
for `src` is stored in a global dictionary (i.e. not part of `src`'s structure) and
attaches it to `dst` through a global reference within the module.

See also: [`@copy_metadata`](@ref), [`share_metadata`](@ref)
"""
macro share_metadata(src, dst)
    esc(:(Metadata.attach_global_metadata($dst, Metadata.global_metadata($src, @__MODULE__), @__MODULE__)))
end

"""
    @copy_metadata(src, dst) -> attach_metadata(dst, copy(metadata(src)))


Copies the metadata from `src` by attaching it to `dst`. This assumes that metadata
for `src` is stored in a global dictionary (i.e. not part of `src`'s structure) and
attaches a new copy to `dst` through a global reference within the module.

See also: [`@share_metadata`](@ref), [`copy_metadata`](@ref)
"""
macro copy_metadata(src, dst)
    esc(:(Metadata.attach_global_metadata($dst, deepcopy(Metadata.metadata($src)), @__MODULE__)))
end

