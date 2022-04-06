
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
    metadata!,
    metadata_type,
    share_metadata

const METADATA_TYPES = Union{<:AbstractDict{String,Any},<:AbstractDict{Symbol,Any},<:NamedTuple}

# default dict
const MDict = Union{Dict{Symbol,Any},Dict{String,Any}}

include("NoMetadata.jl")
include("interface.jl")
include("deprecations.jl")
include("GlobalMetadata.jl")
include("MetaStruct.jl")
include("MetaDict.jl")
include("MetaTuple.jl")
include("MetaIO.jl")
include("MetaUnitRange.jl")
include("MetaArray.jl")
include("propagation.jl")
include("show.jl")

ArrayInterface.parent_type(@nospecialize T::Type{<:MetaArray}) = T.parameters[4]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaDict}) = T.parameters[3]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaUnitRange}) = T.parameters[2]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaTuple}) = T.parameters[2]
ArrayInterface.parent_type(@nospecialize T::Type{<:MetaIO}) = T.parameters[1]
@inline function metadata_type(::Type{T}; dim=nothing) where {M,A,T<:MetaArray{<:Any,<:Any,M,A}}
    if dim === nothing
        return M
    else
        return metadata_type(A; dim=dim)
    end
end

metadata_type(@nospecialize T::Type{<:MetaArray}) = T.parameters[3]
metadata_type(@nospecialize T::Type{<:MetaDict}) = T.parameters[4]
metadata_type(@nospecialize T::Type{<:MetaTuple}) = T.parameters[3]
metadata_type(@nospecialize T::Type{<:MetaUnitRange}) = T.parameters[3]
metadata_type(@nospecialize T::Type{<:MetaIO}) = T.parameters[2]

attach_metadata(@nospecialize(x::AbstractArray), m=Dict{Symbol,Any}()) = MetaArray(x, m)
attach_metadata(@nospecialize(x::AbstractUnitRange), m=Dict{Symbol,Any}()) = MetaUnitRange(x, m)
attach_metadata(@nospecialize(x::IO), m=Dict{Symbol,Any}()) = MetaIO(x, m)
attach_metadata(@nospecialize(x::Tuple), m=Dict{Symbol,Any}()) = _MetaTuple(x, m)
attach_metadata(m::METADATA_TYPES) = Base.Fix2(attach_metadata, m)

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
    metadata!(x, :m1, 1)
    @test metadata(x, :m1) == 1

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
