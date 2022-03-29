
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


