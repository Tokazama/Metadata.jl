
using ArrayInterface
using Aqua
using Documenter
using Metadata
using Test

using ArrayInterface: parent_type, StaticInt
using Metadata: MetaArray, no_data

Aqua.test_all(Metadata)

@test isempty(detect_ambiguities(Metadata, Base))

@testset "interface" begin
    io = IOBuffer()
    show(io, Metadata.no_data)
    @test String(take!(io)) == "no_data"
end

#=
@testset "MetaStruct" begin
    x = Metadata.MetaStruct(2, (m1 =1, m2=[1, 2]))
    m = (m1 =1, m2=[1, 2])
    y = Metadata.MetaStruct((m1 =1, m2=[1, 2]), m)
    @test eltype(x) <: Int
    @test @inferred(copy(x)) === 2
    @test @inferred(copy(y)) == y
    @test @inferred(metadata_type(y)) <: typeof(m)
    @test @inferred(has_metadata(y, :m1))
    @test @inferred(Metadata.metadata_keys(y)) === keys(m)
    @test Metadata.metadata_keys(1 => 2) === propertynames(1 => 2)

    mutable struct MutableType
        field::Int
    end
    x = Metadata.MetaStruct(MutableType(1), Dict{String,Any}())
    x."m1" = 1
    @test getproperty(x, "m1") == 1
    x.field = 2
    @test getproperty(x, :field) == 2
end
=#

@testset "MetaTuple" begin
    include("MetaTuple.jl")
end

@testset "MetaArray" begin
    include("MetaArray.jl")
end

@testset "MetaUnitRange" begin
    include("MetaUnitRange.jl")
end

#=
@testset "LinearIndices/CartesianIndices" begin
    meta = Dict{Symbol,Any}(:m1 => 1, :m2 => [1, 2])
    x = LinearIndices((Metadata.MetaUnitRange(1:10, meta),1:10))
    @test @inferred(metadata(x)) == no_data 
    @test metadata(x, dim=1) == meta
    @test metadata(x, dim=StaticInt(1)) == meta
    @test metadata(x, :m1, dim=1) == 1
    @test metadata(x, :m1, dim=StaticInt(1)) == 1
    metadata!(x, :m1, 2, dim=1)
    @test metadata(x, :m1, dim=1) == 2
    @test @inferred(metadata(x)) == Metadata.no_data
    @test @inferred(has_metadata(x, dim=1))
    @test @inferred(!has_metadata(x))

    meta = (m1 =1, m2=[1, 2])
    x = CartesianIndices((Metadata.MetaUnitRange(1:10, meta),1:10))
    @test @inferred(metadata(x)) == no_data 
    @test metadata(x, dim=1) == meta
    @test metadata(x, dim=StaticInt(1)) == meta
    @test metadata(x) == Metadata.no_data
    @test @inferred(has_metadata(x, dim=1))
    @test @inferred(!has_metadata(x))
end

@testset "MetaArray(LinearIndices)" begin
    meta = (m1 =1, m2=[1, 2])
    x = attach_metadata(LinearIndices((Metadata.MetaUnitRange(1:10, meta),1:10)), meta)
    @test metadata(x, dim=1) == meta
    @test has_metadata(x, dim=1)
end
=#

@testset "MetaIO" begin
    include("MetaIO.jl")
end

m = (x = 1, y = 2, suppress= [:x])
io = IOBuffer()
Metadata.metadata_summary(io, m)
@test String(take!(io)) == "  • metadata:\n     x = <suppressed>\n     y = 2"

m = (x = 1, y = 2)
io = IOBuffer()
Metadata.metadata_summary(io, m)
@test String(take!(io)) == "  • metadata:\n     x = 1\n     y = 2"

#=
mx = attach_metadata(ones(2,2), (x = 1, y = 2, suppress= [:x]))
io = IOBuffer()
show(io, mx)
str = String(take!(io))
@test String(take!(io)) == "  • metadata:\n     x = <suppressed>\n     y = 2"
=#

if VERSION > v"1.6" && sizeof(Int) === 8
    @testset "docs" begin
        doctest(Metadata)
    end
end

