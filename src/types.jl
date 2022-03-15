
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
Base.getindex(::NoMetadata, @nospecialize(k)) = no_metadata
Base.getproperty(::NoMetadata, ::Symbol) = no_metadata

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

Base.eltype(::Type{T}) where {T<:MetaStruct} = eltype(parent_type(T))

function Base.show(io::IO, ::MIME"text/plain", x::MetaStruct)
    print(io, "attach_metadata($(parent(x)), ::$(metadata_type(x)))\n")
    Metadata.metadata_summary(io, x)
end

Base.copy(x::MetaStruct) = propagate_metadata(x, deepcopy(parent(x)))

@_define_function_no_prop(Base,  ==, MetaStruct, MetaStruct)
@_define_function_no_prop_first(Base,  ==, MetaStruct, Any)
@_define_function_no_prop_last(Base,  ==, Any, MetaStruct)
@_define_function_no_prop_first(Base,  ==, MetaStruct, Missing)
@_define_function_no_prop_last(Base,  ==, Missing, MetaStruct)
@_define_function_no_prop_first(Base,  ==, MetaStruct, WeakRef)
@_define_function_no_prop_last(Base,  ==, WeakRef, MetaStruct)

"""
    MetaUnitRange(x::AbstractUnitRange, meta)

Type for storing metadata alongside a anything that is subtype of `AbstractUnitRange`.

## Examples

```jldoctest
julia> using Metadata

julia> Metadata.MetaUnitRange(1:2, (m1 =1, m2=[1, 2]))
attach_metadata(1:2, ::NamedTuple{(:m1, :m2), Tuple{Int64, Vector{Int64}}})
  • metadata:
     m1 = 1
     m2 = [1, 2]

```
"""
struct MetaUnitRange{T,P<:AbstractUnitRange{T},M} <: AbstractUnitRange{T}
    parent::P
    metadata::M

    MetaUnitRange{T,P,M}(p::P, m::M) where {T,P,M} = new{T,P,M}(p, m)
    function MetaUnitRange{T}(p::AbstractRange, m) where {T}
        if eltype(p) <: T
            return MetaUnitRange{T,typeof(p),typeof(m)}(p, m)
        else
            return MetaUnitRange{T}(AbstractUnitRange{T}(p), m)
        end
    end

    MetaUnitRange(p::AbstractRange, m) = MetaUnitRange{eltype(p)}(p, m)
end

Base.parent(r::MetaUnitRange) = getfield(r, :parent)
ArrayInterface.parent_type(::Type{<:MetaUnitRange{<:Any,P,<:Any}}) where {P} = P

@_define_function_no_prop(Base, first, MetaUnitRange)
@_define_function_no_prop(Base, step, MetaUnitRange)
@_define_function_no_prop(Base, last, MetaUnitRange)
@_define_function_no_prop(Base, length, MetaUnitRange)

Base.@propagate_inbounds Base.getindex(r::MetaUnitRange, i::Integer) = parent(r)[i]

ArrayInterface.known_first(::Type{T}) where {T<:MetaUnitRange} = known_first(parent_type(T))

ArrayInterface.known_last(::Type{T}) where {T<:MetaUnitRange} = known_last(parent_type(T))

@propagate_inbounds Base.getindex(r::MetaUnitRange, i) = propagate_metadata(r, parent(r)[i])

function Base.show(io::IO, m::MIME"text/plain", x::MetaUnitRange)
    if haskey(io, :compact)
        show(io, parent(x))
    else
        print(io, "attach_metadata(")
        print(io, parent(x))
        print(io, ", ", Metadata.showarg_metadata(x), ")\n")
        Metadata.metadata_summary(io, x)
    end
end

@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::StepRange{T}) where T<:Integer
    return propagate_metadata(r, getindex(parent(r), s))
end
@propagate_inbounds function Base.getindex(r::MetaUnitRange, s::AbstractUnitRange{T}) where {T<:Integer}
    return propagate_metadata(r, getindex(parent(r), s))
end

Base.getindex(r::MetaUnitRange, ::Colon) = copy(r)

Base.copy(x::MetaUnitRange) = copy_metadata(x, copy(parent(x)))

"""
    MetaIO(io, meta)

Type for storing metadata alongside subtypes of `IO`.
"""
struct MetaIO{T<:IO,M} <: IO
    parent::T
    metadata::M
end

Base.parent(x::MetaIO) = getfield(x, :parent)
ArrayInterface.parent_type(::Type{T}) where {IOType,T<:MetaIO{IOType}} = IOType

@_define_function_no_prop(Base, isreadonly, MetaIO)
@_define_function_no_prop(Base, isreadable, MetaIO)
@_define_function_no_prop(Base, iswritable, MetaIO)
@_define_function_no_prop(Base, stat, MetaIO)
@_define_function_no_prop(Base, eof, MetaIO)
@_define_function_no_prop(Base, position, MetaIO)
@_define_function_no_prop(Base, close, MetaIO)
@_define_function_no_prop(Base, isopen, MetaIO)
@_define_function_no_prop(Base, ismarked, MetaIO)
@_define_function_no_prop(Base, mark, MetaIO)
@_define_function_no_prop(Base, unmark, MetaIO)
@_define_function_no_prop(Base, reset, MetaIO)
@_define_function_no_prop(Base, seekend, MetaIO)

@_define_function_no_prop_first(Base, skip, MetaIO, Integer)
@_define_function_no_prop_first(Base, seek, MetaIO, Integer)
@_define_function_no_prop_first(Base, read, MetaIO, Integer)
@_define_function_no_prop_first(Base, read!, MetaIO, Ref)
@_define_function_no_prop_first(Base, read!, MetaIO, AbstractArray)
@_define_function_no_prop_first(Base, read!,  MetaIO, Array{UInt8})
@_define_function_no_prop_first(Base, read!,  MetaIO, BitArray)

@_define_function_no_prop_first(Base, write, MetaIO, Array)
@_define_function_no_prop_first(Base, write, MetaIO, AbstractArray)
@_define_function_no_prop_first(Base, write, MetaIO, BitArray)
@_define_function_no_prop_first(Base, write, MetaIO, Base.CodeUnits)
@_define_function_no_prop_first(Base, write, MetaIO, Union{Float16, Float32, Float64, Int128, Int16, Int32, Int64, UInt128, UInt16, UInt32, UInt64})


#Base.read(@nospecialize(s::MetaIO), n::Int) = read(parent(s), n)

function Base.write(@nospecialize(s::MetaIO), x::SubArray{T,N,P,I,L} where L where I where P<:Array) where {T, N}
    return write(parent(s), x)
end

@inline metadata_type(::Type{T}) where {IOT,M,T<:MetaIO{IOT,M}} = M

