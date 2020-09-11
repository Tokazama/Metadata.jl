using ArrayInterface
using Test
using Metadata
using Documenter

using ArrayInterface: parent_type
using Metadata: MetaArray


include("metaid.jl")

@testset "MetaArray" begin
    @testset "constructors" begin
        x = ones(4, 4);
        xview = view(x, :, :)
        meta = (m1 =1, m2=[1, 2]);
        mx = attach_metadata(meta)(x);
        mxview = attach_metadata(meta)(xview)
        @test parent_type(mx) <: typeof(x)
        @test parent_type(mxview) <: typeof(xview)
        @test typeof(mx)(xview, meta) isa typeof(mx)
    end

    x = ones(4, 4);
    meta = (m1 =1, m2=[1, 2]);
    mx = attach_metadata(meta)(x);

    @test metadata(mx) == meta
    @test has_metadata(mx)
    @test has_metadata(mx, :m1)
    @test metadata(mx, :m1) == 1
    @test Metadata.metadata_keys(mx) == (:m1, :m2)
    @test mx[1] == 1
    @test mx[1:2] == [1, 1]
    @test metadata(mx[1:2]) == metadata(mx)
    @test metadata_type(mx) <: NamedTuple
    @test !has_metadata(mx, dim=1)

    meta = Dict(:m1 => 1, :m2 => [1,2])
    mx = attach_metadata(x, meta);
    @test metadata(mx) == meta
    @test has_metadata(mx)
    @test has_metadata(mx, :m1)
    @test metadata(mx, :m1) == 1
    # Currently Dict doesn't preserve order so we just check for presence of keys
    @test in(:m1, Metadata.metadata_keys(mx))
    @test in(:m2, Metadata.metadata_keys(mx))
    @test mx[1] == 1
    @test mx[1:2] == [1, 1]
    @test metadata(mx[1:2]) == metadata(mx)
    @test metadata_type(mx) <: AbstractDict

    @test IndexStyle(typeof(mx)) isa IndexLinear
    @test size(mx) == (4, 4)
    @test axes(mx) == (1:4, 1:4)
end

@testset "MetaRange" begin
    x = 1:1:10
    meta = (m1 =1, m2=[1, 2])
    mx = attach_metadata(x, meta)
    @test metadata(mx) == meta
    @test metadata(mx, :m1) == 1
    @test Metadata.metadata_keys(mx) == (:m1, :m2)
    @test mx[1] == 1
    @test mx[1:2] == [1, 2]
    @test metadata(mx[1:2]) == metadata(mx)
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
end

@testset "LinearIndices/CartesianIndices" begin
    meta = (m1 =1, m2=[1, 2])
    x = LinearIndices((Metadata.MetaUnitRange(1:10, meta),1:10))
    @test metadata(x, dim=1) == meta
    @test has_metadata(x, dim=1)
    @test !has_metadata(x)

    meta = (m1 =1, m2=[1, 2])
    x = CartesianIndices((Metadata.MetaUnitRange(1:10, meta),1:10))
    @test metadata(x, dim=1) == meta
    @test has_metadata(x, dim=1)
    @test !has_metadata(x)
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

    write(mio, 1)
    @test position(mio) == 8
    seek(mio, 0)
    @test read(mio, Int) == 1

    #=
Base.seek(@nospecialize(s::MetaIO), n::Integer) = seek(parent(s), n)
Base.skip(@nospecialize(s::MetaIO), n::Integer) = skip(parent(s), n)
Base.eof(@nospecialize(s::MetaIO)) = eof(parent(s))
Base.stat(@nospecialize(s::MetaIO)) = stat(parent(s))
Base.close(@nospecialize(s::MetaIO)) = close(parent(s))
Base.isopen(@nospecialize(s::MetaIO)) = isopen(parent(s))
Base.ismarked(@nospecialize(s::MetaIO)) = ismarked(parent(s))
Base.mark(@nospecialize(s::MetaIO)) = mark(parent(s))
Base.unmark(@nospecialize(s::MetaIO)) = unmark(parent(s))
Base.reset(@nospecialize(s::MetaIO)) = reset(parent(s))
Base.seekend(@nospecialize(s::MetaIO)) = seekend(parent(s))
=#

end

@testset "docs" begin
    doctest(Metadata)
end

