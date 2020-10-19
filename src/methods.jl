
# TODO should drop_metadata be delete_metadata

const modules = Module[]
const GLOBAL_METADATA    = gensym(:metadata)

"""
    GlobalMetadata <: AbstractDict{UInt,Dict{Symbol,Any}}

Stores metadata for instances of types at the module level. It has restricted support
for dictionary methods to ensure that references aren't unintentionally 
"""
struct GlobalMetadata <: AbstractDict{UInt,MDict}
    data::IdDict{UInt,MDict}

    function GlobalMetadata(m::Module)
        if !isdefined(m, GLOBAL_METADATA)
            Core.eval(m, :(const $GLOBAL_METADATA = $(new(IdDict{UInt,MDict}()))))
            push!(modules, m)
        end
        return metadata(m)
    end
end

data(m::GlobalMetadata) = getfield(m, :data)

Base.get(m::GlobalMetadata, k::UInt, @nospecialize(default)) = get(data(m), k, default)

Base.get!(m::GlobalMetadata, k::UInt, @nospecialize(default)) = get!(data(m), k, default)

Base.isempty(m::GlobalMetadata) = isempty(data(m))

Base.getindex(x::GlobalMetadata, k::UInt) = getindex(data(x), k)

Base.setindex!(x::GlobalMetadata, v::MDict, k::UInt) = setindex!(data(x), v, k)

Base.length(m::GlobalMetadata) = length(data(m))

Base.keys(m::GlobalMetadata) = keys(data(m))

Base.iterate(m::GlobalMetadata) = iterate(data(m))
Base.iterate(m::GlobalMetadata, state) = iterate(data(m), state)


"""
    NoMetadata

Internal type for the `Metadata` package that indicates the absence of any metadata.
_DO NOT_ store metadata with the value `NoMetadata()`.
"""
struct NoMetadata end

const no_metadata = NoMetadata()

Base.show(io::IO, ::NoMetadata) = print(io, "no_metadata")

Base.haskey(::NoMetadata, @nospecialize(k)) = false

function showdictlines(io::IO, m, suppress)
    print(io, summary(m))
    for (k, v) in m
        if !in(k, suppress)
            print(io, "\n    ", k, ": ")
            print(IOContext(io, :compact => true), v)
        else
            print(io, "\n    ", k, ": <suppressed>")
        end
    end
end

"""
    metadata(x[, k; dim])

Returns metadata from `x`. If `k` is specified then the metadata value paired to
`k` is returned. If `dim` is specified then the operation is performed for metadata
specific to dimension `dim`.
"""
function metadata(x::T; dim=nothing, kwargs...) where {T}
    if parent_type(T) <: T
        return no_metadata
    else
        return metadata(parent(x); dim=dim, kwargs...)
    end
end
function metadata(x::LinearIndices; dim=nothing, kwargs...)
    if dim === nothing
        return no_metadata
    else
        return metadata(x.indices[dim]; kwargs...)
    end
end
function metadata(x::CartesianIndices; dim=nothing, kwargs...)
    if dim === nothing
        return no_metadata
    else
        return metadata(x.indices[dim])
    end
end
function metadata(x::AbstractDict; dim=nothing, kwargs...)
    if dim === nothing
        return x
    else
        return no_metadata
    end
end
function metadata(x::NamedTuple; dim=nothing, kwargs...)
    if dim === nothing
        return x
    else
        return no_metadata
    end
end
function metadata(m::Module; dim=nothing, kwargs...)
    if dim === nothing
        if isdefined(m, GLOBAL_METADATA)
            return getfield(m, GLOBAL_METADATA)::GlobalMetadata
        else
            return GlobalMetadata(m)
        end
    else
        return no_metadata
    end
end

@inline function metadata(x, k; dim=nothing)
    if metadata_type(x; dim=dim) <: AbstractDict
        return getindex(metadata(x; dim=dim), k)
    else
        return getproperty(metadata(x; dim=dim), k)
    end
end

"""
    metadata!(x, k, val[; dim])

Set `x`'s metadata paired to `k` to `val`. If `dim` is specified then the metadata
corresponding to that dimension is mutated.
"""
@inline function metadata!(x, k, val; dim=nothing)
    if metadata_type(x; dim=dim) <: AbstractDict
        return setindex!(metadata(x; dim=dim), val, k)
    else
        return setproperty!(metadata(x; dim=dim), k, val)
    end
end

"""
    metadata_type(x[, dim]) -> Type

Returns the type of the metadata of `x`. If `dim` is specified then returns type
of metadata associated with dimension `dim`.
"""
function metadata_type(x; dim=nothing)
    if dim === nothing
        return metadata_type(typeof(x))
    else
        return metadata_type(typeof(x); dim=dim)
    end
end
@inline function metadata_type(::Type{T}; dim=nothing) where {T}
    if parent_type(T) <: T
        return NoMetadata
    else
        if dim === nothing
            return metadata_type(parent_type(T))
        else
            return metadata_type(parent_type(T); dim=dim)
        end
    end
end

metadata_type(::Type{T}; dim=nothing) where {T<:AbstractDict} = T
metadata_type(::Type{T}; dim=nothing) where {T<:NamedTuple} = T
function metadata_type(::Type{CartesianIndices{N,R}}; dim=nothing) where {N,R}
    if dim === nothing
        return NoMetadata
    else
        return metadata_type(R.parameters[dim])
    end
end

function metadata_type(::Type{LinearIndices{N,R}}; dim=nothing) where {N,R}
    if dim === nothing
        return NoMetadata
    else
        return metadata_type(R.parameters[dim])
    end
end

metadata_type(::Type{T}; dim=nothing) where {T<:Module} = GlobalMetadata

"""
    has_metadata(x[, k; dim]) -> Bool

Returns true if `x` has metadata. If `k` is specified then checks for the existence
of a metadata paired to `k`. If `dim` is specified then this checks the metadata at
the corresponding dimension.
"""
has_metadata(x; dim=nothing) = !(metadata_type(x; dim=dim) <: NoMetadata)
@inline function has_metadata(x, k; dim=nothing)
    if has_metadata(x; dim=dim)
        m = metadata(x; dim=dim)
        if m isa AbstractDict
            return haskey(m, k)
        else
            return hasproperty(m, k)
        end
    else
        return false
    end
end

"""
    attach_metadata(x, metadata)

Generic method for attaching metadata to `x`.
"""
function attach_metadata(x::AbstractArray, m::METADATA_TYPES=MDict())
    return MetaArray(x, m)
end
function attach_metadata(x::AbstractRange, m::METADATA_TYPES=MDict())
    if known_step(x) === oneunit(eltype(x))
        return MetaUnitRange(x, m)
    else
        return MetaRange(x, m)
    end
end
attach_metadata(x::IO, m::METADATA_TYPES=MDict()) = MetaIO(x, m)
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
@inline function metadata_keys(x; dim=nothing)
    if metadata_type(x; dim=dim) <: AbstractDict
        return keys(metadata(x; dim=dim))
    else
        return fieldnames(metadata_type(x; dim=dim))
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

function combine_metadata(x, y, dst)
    return _combine_meta(MetadataPropagation(x), MetadataPropagation(y), x, y, dst)
end

function _combine_meta(px::DropMetadata, py::MetadataPropagation, x, y, dst)
    return propagate_metadata(py, y, dst)
end

function _combine_meta(px::MetadataPropagation, py::DropMetadata, x, y, dst)
    return propagate_metadata(px, x, dst)
end

_combine_meta(::DropMetadata, ::DropMetadata, x, y, dst) = dst

function _combine_meta(px::CopyMetadata, py::CopyMetadata, x, y, dst)
    return attach_metadata(append!(deepcopy(metadata(x)), metadata(y)), dst)
end

function _combine_meta(px::ShareMetadata, py::CopyMetadata, x, y, dst)
    return attach_metadata(append!(deepcopy(metadata(y)), metadata(x)), dst)
end

function _combine_meta(px::CopyMetadata, py::ShareMetadata, x, y, dst)
    return attach_metadata(append!(deepcopy(metadata(x)), metadata(y)), dst)
end

# TODO need to consider what should happen here because non mutating functions
# will mutate metadata if both combine and share
function _combine_meta(px::ShareMetadata, py::ShareMetadata, x, y, dst)
    return attach_metadata(append!(metadata(x), metadata(y)), dst)
end

macro defproperties(T)
    quote
        @inline function Base.getproperty(x::$T, k::Symbol)
            if hasproperty(parent(x), k)
                return getproperty(parent(x), k)
            else
                return Metadata.metadata(x, k)
            end
        end

        @inline function Base.setproperty!(x::$T, k::Symbol, val)
            if hasproperty(parent(x), k)
                return setproperty!(parent(x), k, val)
            else
                return Metadata.metadata!(x, k, val)
            end
        end

        @inline Base.propertynames(x::$T) = Metadata.metadata_keys(x)
    end
end

"""
    metadata_summary([io], x)

Creates summary readout of metadata for `x`.
"""
metadata_summary(x) = metadata_summary(stdout, x)
function metadata_summary(io::IO, x)
    print(io, "$(lpad(Char(0x2022), 3)) metadata:")
    for k in metadata_keys(x)
        println(io)
        print(io, "     ")
        print(io, "$k")
        print(io, " = ")
        print(io, metadata(x, k))
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
    return meta
end
function attach_global_metadata(x, meta, m::Module)
    gm = MDict()
    for (k,v) in pairs(meta)
        gm[k] = v
    end
    return attach_global_metadata(x, gm, m)
end

"""
    global_metadata(x, m::Module)
    global_metadata(x, k::Symbol, m::Module)

Retreive metadata associated with the object id of `x` (`objectid(x)`) in stored in the
global metadata of module `m`. If the key `k` is specified only the value associated with
that key is returned.
"""
global_metadata(x, m::Module) = get(metadata(m), objectid(x), no_metadata)
global_metadata(x, k::Symbol, m::Module) = getindex(global_metadata(x, m), k)

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
    return esc(:(Metadata.attach_global_metadata($x, $meta, @__MODULE__)))
end

"""
    @metadata(x[, k])

Retreive metadata associated with the object id of `x` (`objectid(x)`) in the current
module's global metadata. If the key `k` is specified only the value associated with
that key is returned.
"""
macro metadata(x)
    return esc(:(Metadata.global_metadata($(x), @__MODULE__)))
end

macro metadata(x, k)
    return esc(:(Metadata.global_metadata($(x), $(k), @__MODULE__)))
end

"""
    @metadata!(x, k, val)

Set the value of `x`'s global metadata associated with the key `k` to `val`.
"""
macro metadata!(x, k, val)
    return esc(:(Metadata.global_metadata!($x, $k, $val, @__MODULE__)))
end

"""
    @has_metadata(x) -> Bool
    @has_metadata(x, k) -> Bool

Does `x` have metadata stored in the curren modules' global metadata? Checks for the
presenece of the key `k` if specified.
"""
macro has_metadata(x)
    return esc(:(Metadata.global_metadata($x, @__MODULE__) !== Metadata.no_metadata))
end
macro has_metadata(x, k)
    return esc(:(haskey(Metadata.global_metadata($x, @__MODULE__), $k)))
end

"""
    @share_metadata(src, dst) -> @attach_metadata(@metadata(src), dst)

Shares the metadata from `src` by attaching it to `dst`. This assumes that metadata
for `src` is stored in a global dictionary (i.e. not part of `src`'s structure) and
attaches it to `dst` through a global reference within the module.

See also: [`@copy_metadata`](@ref), [`share_metadata`](@ref)
"""
macro share_metadata(src, dst)
    return esc(:(Metadata.attach_global_metadata($dst, Metadata.global_metadata($src, @__MODULE__), @__MODULE__)))
end

"""
    @copy_metadata(src, dst) -> attach_metadata(dst, copy(metadata(src)))


Copies the metadata from `src` by attaching it to `dst`. This assumes that metadata
for `src` is stored in a global dictionary (i.e. not part of `src`'s structure) and
attaches a new copy to `dst` through a global reference within the module.

See also: [`@share_metadata`](@ref), [`copy_metadata`](@ref)
"""
macro copy_metadata(src, dst)
    return esc(:(Metadata.attach_global_metadata($dst, deepcopy(Metadata.metadata($src)), @__MODULE__)))
end

