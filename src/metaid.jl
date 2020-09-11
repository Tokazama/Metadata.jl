
"""
    MetaStruct(p, m)

Binds a parent instance (`p`) to some metadata (`m`). `MetaStruct` is the generic type
constructed when `attach_metadata(p, m)` is called.

See also: [`attach_metadata`](@ref), [`attach_eachmeta`](@ref)
"""
struct MetaStruct{P,M}
    parent::P
    metadata::M
end

Base.parent(m::MetaStruct) = getfield(m, :parent)

ArrayInterface.parent_type(::Type{MetaStruct{P,M}}) where {P,M} = P

function unsafe_attach_eachmeta(x::AbstractVector, m::NamedTuple{L}, i::Int) where {L}
    return MetaStruct(
        x,
        NamedTuple{L}(ntuple(i -> @inbounds(m[L[i]][index]), Val(length(L))))
    )
end

# TODO `eachindex` should change to `ArrayInterface.indices`
function attach_eachmeta(x::AbstractVector, m::NamedTuple)
    return map(i -> unsafe_attach_eachmeta(@inbounds(x[i]), m, i), eachindex(p, m...))
end

const modules = Module[]
const MDict = Dict{Symbol,Any}
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

"""
    MetaID(m::Module=Main, data=Dict{Symbol,Any}()) <: AbstractDict{Symbol,Any}

Points to a dictionary stored within a module `m`. This is intended to be constructed
internally when attaching metadata to some new instance. Therefore, it is generally
considered _unsafe_ for users to independently construct this.

# Developr notes

`MetaID` requires that the initial module assigned to it does not change and that
there is a unique `objectid` for each instance. This is accomplished by making `MetaID`
an immutable structure

"""
struct MetaID <: AbstractDict{Symbol,Any}
    parent_module::Module
    suppressed_fields::Vector{Symbol}

    function MetaID(@nospecialize(m)=Main, @nospecialize(data)=MDict())
        ret = new(m, Symbol[])
        gm = GlobalMetadata(m)
        gm[ret] = data
        return ret
    end
end

parent_module(x::MetaID) = getfield(x, :parent_module)

# TODO document supressed_fields
suppressed_fields(x::MetaID) = getfield(x, :suppressed_fields)

# TODO document supressed_fields!
supressed_fields!(x::MetaID, s::Symbol) = push!(suppressed_fields(x), s)
supressed_fields!(x::MetaID, s::AbstractArray{Symbol}) = append!(suppressed_fields(x), s)

Base.setproperty!(x::MetaID, k::Symbol, @nospecialize(val)) = setindex!(metadata(x), val, k)
Base.getproperty(x::MetaID, k::Symbol) = getindex(metadata(x), k)
Base.propertynames(m::MetaID) = Tuple(keys(m))

Base.empty!(m::MetaID) = empty!(metadata(m))

Base.get(m::MetaID, k::Symbol, @nospecialize(default)) = get(metadata(m), k, default)
Base.get(m::GlobalMetadata, k::UInt, @nospecialize(default)) = get(data(m), k, default)

Base.get!(m::MetaID, k::Symbol, @nospecialize(default)) = get!(metadata(m), k, default)
Base.get!(m::GlobalMetadata, k::UInt, @nospecialize(default)) = get!(data(m), k, default)

Base.in(k::Symbol, m::MetaID) = in(k, propname(m))

Base.pop!(m::MetaID, k::Symbol) = pop!(metadata(m), k)
Base.pop!(m::MetaID, k::Symbol, @nospecialize(default)) = pop!(metadata(m), k, default)

Base.isempty(m::MetaID) = isempty(metadata(m))
Base.isempty(m::GlobalMetadata) = isempty(data(m))

Base.delete!(m::MetaID, s::Symbol) = delete!(metadata(m), k)

Base.getindex(x::MetaID, s::Symbol) = getindex(metadata(x), s)
Base.getindex(x::GlobalMetadata, k::UInt) = getindex(data(x), k)
Base.getindex(x::GlobalMetadata, k::MetaID) = getindex(data(x), objectid(k))

Base.setindex!(x::MetaID, @nospecialize(val), s::Symbol) = setindex!(metadata(x), val, s)
Base.setindex!(x::GlobalMetadata, v::MDict, k::UInt) = setindex!(data(x), v, k)
Base.setindex!(x::GlobalMetadata, v::MDict, k::MetaID) = setindex!(x, v, objectid(k))

Base.length(m::MetaID) = length(metadata(m))
Base.length(m::GlobalMetadata) = length(data(m))

Base.getkey(m::MetaID, k::Symbol, @nospecialize(default)) = getkey(metadata(m), k, default)

Base.keys(m::MetaID) = keys(metadata(m))
Base.keys(m::GlobalMetadata) = keys(data(m))

Base.iterate(m::GlobalMetadata) = iterate(data(m))
Base.iterate(m::GlobalMetadata, state) = iterate(data(m), state)
Base.iterate(m::MetaID) = iterate(metadata(m))
Base.iterate(m::MetaID, state) = iterate(metadata(m), state)

Base.show(io::IO, m::MetaID) = showdictlines(io, m, suppressed_fields(m))
Base.show(io::IO, ::MIME"text/plain", m::MetaID) = showdictlines(io, m, suppressed_fields(m))
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

