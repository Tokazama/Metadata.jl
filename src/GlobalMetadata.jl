
# TODO should drop_metadata be delete_metadata?

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
            Core.eval(m, :(const $GLOBAL_METADATA = $(new(IdDict{UInt,Dict{Symbol,Any}}()))))
            push!(modules, m)
        end
        return metadata(m)
    end
end

metadata_type(::Type{Module}) = GlobalMetadata

data(m::GlobalMetadata) = getfield(m, :data)

Base.get(m::GlobalMetadata, k::UInt, @nospecialize(default)) = get(data(m), k, default)

Base.get!(m::GlobalMetadata, k::UInt, @nospecialize(default)) = get!(data(m), k, default)

Base.isempty(m::GlobalMetadata) = isempty(data(m))

Base.getindex(x::GlobalMetadata, k::UInt) = getindex(data(x), k)

Base.setindex!(x::GlobalMetadata, v::MDict, k::UInt) = setindex!(data(x), v, k)

Base.length(m::GlobalMetadata) = length(data(m))

Base.keys(m::GlobalMetadata) = keys(data(m))

Base.delete!(m::GlobalMetadata, k::UInt) = delete!(data(m), k)

Base.iterate(m::GlobalMetadata) = iterate(data(m))
Base.iterate(m::GlobalMetadata, state) = iterate(data(m), state)

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
    @has_metadata(x)::Bool
    @has_metadata(x, k)::Bool

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

