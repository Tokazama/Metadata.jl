using ArrayInterface
using Test
using Metadata
using Documenter

using ArrayInterface: parent_type
using Metadata: MetaArray, no_metadata, GlobalMetadata


@test isempty(detect_ambiguities(Metadata, Base))

include("metaid.jl")

@testset "methods" begin
    io = IOBuffer()
    show(io, Metadata.no_metadata)
    @test String(take!(io)) == "no_metadata"
    @test metadata_type(Dict{Symbol,Any}) <: Dict{Symbol,Any}
    @test metadata_type(NamedTuple{(),Tuple{}}) <: NamedTuple{(),Tuple{}}
    @test Metadata.MetadataPropagation(Metadata.NoMetadata) == Metadata.DropMetadata()
    @test @inferred(metadata(Dict{Symbol,Any}())) == Dict{Symbol,Any}()
    @test @inferred(metadata(Dict{Symbol,Any}(); dim=1)) == no_metadata
    @test @inferred(metadata((x =1,))) == (x =1,)
    @test @inferred(metadata((x =1,); dim=1)) == no_metadata
    @test @inferred(metadata(Main)) isa GlobalMetadata
    @test @inferred(metadata(Main; dim=1)) == no_metadata
end

@testset "MetaArray" begin
    x = ones(4, 4);
    xview = view(x, :, :)
    meta = (m1 =1, m2=[1, 2]);
    mx = attach_metadata(meta)(x);
    mxview = attach_metadata(meta)(xview)
    @test @inferred(parent_type(mx)) <: typeof(x)
    @test @inferred(parent_type(mxview)) <: typeof(xview)
    @test @inferred(typeof(mx)(xview, meta)) isa typeof(mx)

    mx = attach_metadata(x)
    mvx = typeof(mx)(xview; m1 = 1, m2 = [1, 2])
    @test mvx isa typeof(mx)
    @test mvx.m1 == 1
    @test mvx.m2 == [1, 2]

    m = Metadata.MetaArray{Int}(undef, (2,2))
    m[:] = 1:4
    @test m == [1 3; 2 4]

    x = ones(4, 4);
    meta = (m1 =1, m2=[1, 2]);
    mx = attach_metadata(meta)(x);

    @test @inferred(metadata(mx)) == meta
    @test @inferred(has_metadata(mx))
    @test @inferred(has_metadata(mx, :m1))
    @test metadata(mx, :m1) == 1
    @test Metadata.metadata_keys(mx) == (:m1, :m2)
    @test mx[1] == 1
    @test mx[1:2] == [1, 1]
    @test metadata(mx[1:2]) == metadata(mx)
    @test @inferred(metadata_type(mx)) <: NamedTuple
    @test @inferred(!has_metadata(mx, dim=1))

    meta = Dict(:m1 => 1, :m2 => [1,2])
    mx = attach_metadata(x, meta);
    @test @inferred(parent_type(typeof(mx))) <: typeof(x)
    @test @inferred(metadata(mx)) == meta
    @test @inferred(has_metadata(mx))
    @test @inferred(has_metadata(mx, :m1))
    @test metadata(mx, :m1) == 1
    # Currently Dict doesn't preserve order so we just check for presence of keys
    @test in(:m1, Metadata.metadata_keys(mx))
    @test in(:m2, Metadata.metadata_keys(mx))
    @test in(:m1, propertynames(mx))
    @test in(:m2, propertynames(mx))
    @test mx[1] == 1
    @test mx[1:2] == [1, 1]
    @test @inferred(metadata(mx[1:2])) == metadata(mx)
    @test @inferred(metadata_type(mx)) <: AbstractDict

    @test IndexStyle(typeof(mx)) isa IndexLinear
    @test @inferred(size(mx)) == (4, 4)
    @test @inferred(axes(mx)) == (1:4, 1:4)
end

@testset "MetaRange" begin
    x = 1:1:10
    meta = (m1 =1, m2=[1, 2])
    mx = attach_metadata(x, meta)
    @test parent_type(typeof(mx)) <: typeof(x)
    @test metadata(mx) == meta
    @test metadata(mx, :m1) == 1
    @test Metadata.metadata_keys(mx) == (:m1, :m2)
    @test mx[1] == 1
    @test mx[1:2] == [1, 2]
    @test metadata(mx[1:2]) == metadata(mx)
    @test mx[:] == x[:]
end

@testset "MetaUnitRange" begin
    x = 1:10
    meta = (m1 =1, m2=[1, 2])
    # TODO once new version of ArrayInterface comes out use this instead of direct constructor
    # mx = attach_metadata(x, meta)
    mx = Metadata.MetaUnitRange(x, meta)
    @test metadata(mx) == meta
    @test metadata(mx, :m1) == 1
    @test Metadata.metadata_keys(mx) == (:m1, :m2)
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
    @test_throws ArgumentError Metadata.MetaUnitRange(1:3:10, nothing)
    @test Metadata.drop_metadata(mx) === x
    @test Metadata.copy_metadata(mx, x) == mx
end

@testset "LinearIndices/CartesianIndices" begin
    meta = Dict{Symbol,Any}(:m1 => 1, :m2 => [1, 2])
    x = LinearIndices((Metadata.MetaUnitRange(1:10, meta),1:10))
    @test @inferred(metadata(x)) == no_metadata 
    @test metadata(x, dim=1) == meta
    @test metadata(x, :m1, dim=1) == 1
    metadata!(x, :m1, 2, dim=1)
    @test metadata(x, :m1, dim=1) == 2
    @test @inferred(metadata(x)) == Metadata.no_metadata
    @test @inferred(has_metadata(x, dim=1))
    @test @inferred(!has_metadata(x))

    meta = (m1 =1, m2=[1, 2])
    x = CartesianIndices((Metadata.MetaUnitRange(1:10, meta),1:10))
    @test @inferred(metadata(x)) == no_metadata 
    @test metadata(x, dim=1) == meta
    @test metadata(x) == Metadata.no_metadata
    @test @inferred(has_metadata(x, dim=1))
    @test @inferred(!has_metadata(x))
end

@testset "MetaArray(LinearIndices)" begin
    meta = (m1 =1, m2=[1, 2])
    x = attach_metadata(LinearIndices((Metadata.MetaUnitRange(1:10, meta),1:10)), meta)
    @test metadata(x, dim=1) == meta
    @test has_metadata(x, dim=1)
end

@testset "MetaIO" begin
    io = IOBuffer()
    mio = attach_metadata(io)
    @test position(mio) == 0
    @test !isreadonly(mio)
    @test isreadable(mio)
    @test iswritable(mio)
    @test isopen(mio)
    @test !ismarked(mio)

    write(mio, 1)
    @test position(mio) == 8
    seek(mio, 0)
    @test read(mio, Int) == 1
    seek(mio, 0)
    write(mio, [1, 2])
    write(mio, view([1 , 2], :))
    write(mio, [1,2]')
    seek(mio, 0)
    @test read!(mio, Vector{Int}(undef, 2)) == [1, 2]
    skip(mio, 8)
    @test position(mio) == 24
    mark(mio)
    @test ismarked(mio)
    seek(mio, 0)
    @test reset(mio) == 24
    @test position(mio) == 24
    mark(mio)
    @test ismarked(mio)
    unmark(mio)
    @test !ismarked(mio)
    seekend(mio)
    @test eof(mio)
    close(mio)
    @test !isopen(mio)
    @test metadata(mio) isa Metadata.MetaID
end

@testset "ElementwiseMetaArray" begin
    x = [1, 2, 3]
    meta = (weight = [1.0, 2.0, 3.0],)

    mx = attach_eachmeta(x, meta)
    @test mx[1] === 1
    @test mx[2] === 2
    @test mx[3] === 3
    @test mx[1:2][2] === 2
    @test metadata(mx) == meta
    @test metadata(mx; dim=1) == no_metadata

    mxview = mx.weight;
    @test mxview[1] === 1.0
    @test mxview[2] === 2.0
    @test mxview[3] === 3.0
    @test mxview[1:2][2] === 2.0
end

@testset "docs" begin
    doctest(Metadata)
end
