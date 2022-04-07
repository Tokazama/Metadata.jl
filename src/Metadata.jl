
module Metadata
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end Metadata

using ArrayInterface
using ArrayInterface: parent_type, known_first, known_last, known_step, StaticInt, to_dims, axes_types
using Base: @propagate_inbounds, OneTo
using LinearAlgebra
using Statistics
using Test

export
    @attach_metadata,
    @metadata,
    @metadata!,
    @has_metadata,
    @copy_metadata,
    @share_metadata,
    attach_metadata,
    copy_metadata,
    getmeta,
    getmeta!,
    has_metadata,
    metadata,
    metadata_type,
    share_metadata

const METADATA_TYPES = Union{<:AbstractDict{String,Any},<:AbstractDict{Symbol,Any},<:NamedTuple}

# default dict
const MDict = Union{Dict{Symbol,Any},Dict{String,Any}}

include("NoMetadata.jl")
include("interface.jl")
include("GlobalMetadata.jl")
include("MetaStruct.jl")
include("MetaDict.jl")
include("MetaTuple.jl")
include("MetaIO.jl")
include("MetaUnitRange.jl")
include("MetaArray.jl")
include("propagation.jl")
include("show.jl")

ArrayInterface.parent_type(@nospecialize T::Type{<:MetaArray}) = T.parameters[3]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaDict}) = T.parameters[3]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaUnitRange}) = T.parameters[2]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaTuple}) = T.parameters[2]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaIO}) = T.parameters[1]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaStruct}) = T.parameters[1]

metadata_type(@nospecialize T::Type{<:MetaArray}) = T.parameters[4]
metadata_type(@nospecialize T::Type{<:MetaDict}) = T.parameters[4]
metadata_type(@nospecialize T::Type{<:MetaTuple}) = T.parameters[3]
metadata_type(@nospecialize T::Type{<:MetaUnitRange}) = T.parameters[3]
metadata_type(@nospecialize T::Type{<:MetaIO}) = T.parameters[2]
metadata_type(@nospecialize T::Type{<:MetaStruct}) = T.parameters[2]

unsafe_attach_metadata(x, m) = MetaStruct(x, m)
unsafe_attach_metadata(@nospecialize(x::AbstractArray), m) = _MetaArray(x, m)
unsafe_attach_metadata(@nospecialize(x::Union{Tuple,MetaTuple}), m) = _MetaTuple(x, m)
unsafe_attach_metadata(@nospecialize(x::AbstractUnitRange), m) = _MetaUnitRange(x, m)
unsafe_attach_metadata(@nospecialize(x::IO), m) = MetaIO(x, m)
unsafe_attach_metadata(@nospecialize(x::AbstractDict), m) = _MetaDict(x, m)
unsafe_attach_metadata(@nospecialize(x::NamedTuple), m) = _MetaDict(pairs(x), m)

@defproperties MetaArray

@defproperties MetaUnitRange

@defproperties MetaStruct

@defproperties MetaIO

@defproperties MetaTuple

@defproperties MetaDict

"""
    test_wrapper(::Type{WrapperType}, x::X)

Tests the metadata interface for a metadata wrapper (`WrapperType`) for binding instances
of type `X`. It returns the results of `attach_metadata(x, Dict{Symbol,Any}())` for further
testing.
"""
function test_wrapper(::Type{T}, data) where {T}
    m = Dict{Symbol,Any}()
    x = attach_metadata(data, m)
    @test x isa T

    @test metadata_type(x) <: typeof(m)
    @test metadata_type(typeof(x)) <: typeof(m)

    @test has_metadata(x)
    @test has_metadata(typeof(x))

    @test parent_type(x) <: typeof(data)
    @test parent_type(typeof(x)) <: typeof(data)
    @test parent(x) === data

    @test isempty(metadata(x))
    metadata(x)[:m1] = 1
    @test getmeta(x, :m1, 3) == 1

    y = share_metadata(x, ones(2, 2))
    @test y isa Metadata.MetaArray
    @test metadata(x) === metadata(y)

    y = copy_metadata(x, ones(2, 2))
    @test y isa Metadata.MetaArray
    @test metadata(x) == metadata(y)
    @test metadata(x) !== metadata(y)

    y = drop_metadata(x)
    @test !has_metadata(y)
    @test y == data

    empty!(metadata(x))
    return x
end

end # module
