
module Metadata
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end Metadata

using ArrayInterface
using ArrayInterface: parent_type, known_first, known_last, known_step, StaticInt, to_dims, axes_types
using Base: @propagate_inbounds, OneTo
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
    has_metadata,
    metadata,
    metadata!,
    metadata_type,
    share_metadata

const METADATA_TYPES = Union{<:AbstractDict{String,Any},<:AbstractDict{Symbol,Any},<:NamedTuple}

# default dict
const MDict = Union{Dict{Symbol,Any},Dict{String,Any}}

include("utils.jl")
include("metastruct.jl")
include("methods.jl")
include("metaarray.jl")
include("ranges.jl")
include("io.jl")

for T in (MetaIO, MetaStruct, MetaArray, MetaRange, MetaUnitRange)
    @eval begin
        @inline function Metadata.metadata(x::$T; dim=nothing, kwargs...)
            if dim === nothing
                return getfield(x, :metadata)
            else
                return metadata(parent(x); dim=dim)
            end
        end
    end
end

@defproperties MetaArray

@defproperties MetaRange

@defproperties MetaUnitRange

@defproperties MetaStruct

@defproperties MetaIO

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

