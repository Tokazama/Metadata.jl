
using ArrayInterface
using Aqua
using Documenter
using Metadata
using Test

using ArrayInterface: parent_type, StaticInt
using Metadata: MetaArray, NoMetadata, no_metadata, GlobalMetadata


Aqua.test_all(Metadata)

@test isempty(detect_ambiguities(Metadata, Base))

@testset "methods" begin
    io = IOBuffer()
    show(io, Metadata.no_metadata)
    @test String(take!(io)) == "no_metadata"
    @test metadata_type(Dict{Symbol,Any}) <: NoMetadata
    @test @inferred(metadata(Main)) isa GlobalMetadata
    x = rand(4)
    m = metadata(Main)
    @test isempty(m)
    get!(m, objectid(x), Dict{Symbol,Any}())
    @test !isempty(m)
    @test first(keys(m)) == objectid(x)
    @test m[objectid(x)] == Dict{Symbol,Any}()
    @test length(m) == 1
    p, state = iterate(m)
    @test p == (objectid(x) => Dict{Symbol,Any}())
    @test iterate(m, state) === nothing
end

@testset "MetaStruct" begin
    x = Metadata.MetaStruct(2, (m1 =1, m2=[1, 2]))
    m = (m1 =1, m2=[1, 2])
    y = Metadata.MetaStruct((m1 =1, m2=[1, 2]), m)
    @test eltype(x) <: Int
    @test @inferred(copy(x)) == 2
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

@testset "MetaArray" begin
    include("MetaArray.jl")
end

@testset "MetaUnitRange" begin
    x = 1:10
    mx = Metadata.test_wrapper(Metadata.MetaUnitRange, x)
    @test mx[1] == 1
    @test mx[1:2] == [1, 2]
    @test metadata(mx[1:2]) == metadata(mx)
    @test @inferred(first(x)) == first(mx)
    @test @inferred(step(x)) == step(mx)
    @test @inferred(last(x)) == last(mx)
    @test @inferred(length(mx)) == length(x)
    @test ArrayInterface.known_first(mx) === ArrayInterface.known_first(x)
    @test ArrayInterface.known_last(mx) === ArrayInterface.known_last(x)
    @test ArrayInterface.known_step(mx) === ArrayInterface.known_step(x)
    @test mx[1:2:10] == x[1:2:10]
    @test mx[:] == x[:]
    @test eltype(Metadata.MetaUnitRange{UInt}(1:10, nothing)) <: UInt
    Metadata.test_wrapper(Metadata.MetaUnitRange, 1:10)
end

@testset "MetaIO" begin
    io = IOBuffer()
    mio = Metadata.test_wrapper(Metadata.MetaIO, io)

    @test position(mio) == 0
    @test !isreadonly(mio)
    @test isreadable(mio)
    @test iswritable(mio)
    @test isopen(mio)
    @test !ismarked(mio)

    s = sizeof(Int)
    write(mio, 1)
    @test position(mio) == s
    seek(mio, 0)
    @test read(mio, Int) == 1
    seek(mio, 0)
    write(mio, [1, 2])
    write(mio, view([1 , 2], :))
    write(mio, [1,2]')
    seek(mio, 0)
    @test read!(mio, Vector{Int}(undef, 2)) == [1, 2]
    skip(mio, s)
    @test position(mio) == 3s
    mark(mio)
    @test ismarked(mio)
    seek(mio, 0)
    @test reset(mio) == 3s
    @test position(mio) == 3s
    mark(mio)
    @test ismarked(mio)
    unmark(mio)
    @test !ismarked(mio)
    seekend(mio)
    @test eof(mio)
    close(mio)
    @test !isopen(mio)
end

@testset "GlobalMetadata" begin
    x = ones(2, 2)
    meta = (x = 1, y = 2)
    @attach_metadata(x, meta)
    @test @metadata(x, :x) == 1
    @test @metadata(x, :y) == 2

    struct MyType{X}
        x::X
    end

    x = MyType(ones(2,2))
    GC.gc()
    @test @metadata(x) == Metadata.no_metadata  # test finalizer

    @test metadata_type(Main) <: Metadata.GlobalMetadata
    @attach_metadata(x, meta)
    @test @metadata(x, :x) == 1
    @test @metadata(x, :y) == 2
    x = MyType(1)
    GC.gc()
    @test @metadata(x) == Metadata.no_metadata  # test finalizer on nested mutables
    @test_logs(
        (:warn, "Cannot create finalizer for MyType{$Int}. Global dictionary must be manually deleted."),
        @attach_metadata(x, meta)
    )
    @test @metadata(x, :x) == 1
    @test @metadata(x, :y) == 2
end

#=
m = (x = 1, y = 2, suppress= [:x])
io = IOBuffer()
Metadata.metadata_summary(io, m)
@test String(take!(io)) == "  • metadata:\n     x = <suppressed>\n     y = 2"

m = (x = 1, y = 2)
io = IOBuffer()
Metadata.metadata_summary(io, m)
@test String(take!(io)) == "  • metadata:\n     x = 1\n     y = 2"
=#

#=
mx = attach_metadata(ones(2,2), (x = 1, y = 2, suppress= [:x]))
io = IOBuffer()
show(io, mx)
str = String(take!(io))
@test String(take!(io)) == "  • metadata:\n     x = <suppressed>\n     y = 2"
=#

#=
if VERSION > v"1.6" && sizeof(Int) === 8
    @testset "docs" begin
        doctest(Metadata)
    end
end
=#

