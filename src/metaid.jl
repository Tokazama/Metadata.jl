
const modules = Module[]
const GLOBAL_METADATA    = gensym(:metadata)
const GLOBAL_METADATA_TYPE = IdDict{UInt,Dict{Symbol,Any}}

function module_metadata(m::Module)
    if isdefined(m, GLOBAL_METADATA)
        return getfield(m, GLOBAL_METADATA)::GLOBAL_METADATA_TYPE
    else
        return GLOBAL_METADATA_TYPE()
    end
end

function initmeta!(@nospecialize(m))
    if !isdefined(m, GLOBAL_METADATA)
        Core.eval(m, :(const $GLOBAL_METADATA = $(GLOBAL_METADATA_TYPE())))
        push!(modules, m)
    end
    return nothing
end

function initmeta!(
    @nospecialize(m),
    @nospecialize(obj),
    @nospecialize(data),
)

    initmeta!(m)
    setindex!(module_metadata(m), data, Base.objectid(obj))
    return nothing
end


###
###
###
#    MetaID
#
# Dedicated global ID for attaching global metadata to a particular type instance.
#
# We need this to have a unique objectid, but it can't be mutable or else the module could
# be changed making it unsafe to assume it has been initialized

mutable struct EmptyMutable end

struct MetaID <: AbstractDict{Symbol,Any}
    m::Module
    e::EmptyMutable

    function MetaID(m::Module=Main, data=Dict{Symbol,Any}())
        ret = new(m, EmptyMutable())
        initmeta!(m, ret, data)
        return ret
    end
end

parent_module(x::MetaID) = getfield(x, :m)
function metadata(x::MetaID)
    return @inbounds(getindex(module_metadata(parent_module(x)), Base.objectid(x)))
end

Base.setproperty!(x::MetaID, k::Symbol, val) = setindex!(metadata(x), val, k)
Base.getproperty(x::MetaID, k::Symbol) = getindex(metadata(x), k)

Base.empty!(m::MetaID) = empty!(metadata(m))

Base.get(m::MetaID, k::Symbol, default) = get(metadata(m), k, default)

Base.get!(m::MetaID, k, default) = get!(metadata(m), k, default)

# TODO
#Base.in(k, m::MetaID) = in(k, propname(m))

#Base.pop!(m::MetaID, k) = pop!(metadata(m), k)

#Base.pop!(m::MetaID, k, default) = pop!(metadata(m), k, default)

Base.isempty(m::MetaID) = isempty(metadata(m))

Base.delete!(m::MetaID, k) = delete!(metadata(m), k)

@inline Base.getindex(x::MetaID, s::Symbol) = getindex(metadata(x), s)

@inline function Base.setindex!(x::MetaID, val, s::Symbol)
    return setindex!(metadata(x), val, s)
end

Base.length(m::MetaID) = length(metadata(m))

Base.getkey(m::MetaID, k, default) = getkey(metadata(m), k, default)

Base.keys(m::MetaID) = keys(metadata(m))

Base.propertynames(m::MetaID) = Tuple(keys(m))

suppress(m::MetaID) = get(m, :suppress, ())

Base.iterate(m::MetaID) = iterate(metadata(m))

Base.iterate(m::MetaID, state) = iterate(metadata(m), state)

Base.show(io::IO, m::MetaID) = showdictlines(io, m, suppress(m))
Base.show(io::IO, ::MIME"text/plain", m::MetaID) = showdictlines(io, m, suppress(m))
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

_maybe_metaid(m::NamedTuple) = m
_maybe_metaid(m::AbstractDict) = m
_maybe_metaid(m::Module) = MetaID(m)

