
using ArrayInterface
using Aqua
using Documenter
using Metadata
using Test

using ArrayInterface: parent_type
using Metadata: MetaArray, no_metadata, GlobalMetadata


Aqua.test_all(Metadata)

@test isempty(detect_ambiguities(Metadata, Base))

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
    y = Metadata.MetaStruct((m1 =1, m2=[1, 2]), (m1 =1, m2=[1, 2]))
    @test eltype(x) <: Int
    @test @inferred(copy(x)) === 2
    @test @inferred(copy(y)) == y
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
    @test @inferred(!has_metadata(parent(mx), :m1))
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

    @testset "constructors" begin
        m = Dict{Symbol,Int}(:x=>1,:y=>2)
        x = @inferred(Metadata.MetaArray{Int,2,Dict{Symbol,Any},Array{Int,2}}(undef, (2,2), metadata=m))
        y = @inferred(Metadata.MetaArray{Int,2}(undef, (2,2); metadata=m))
        x[:] = 1:4
        y[:] = 1:4
        @test x == y == [1 3; 2 4]

        @test metadata_type(Metadata.MetaArray{Int,2,Dict{Symbol,Any},Array{Int,2}}(parent(x), m)) <: Dict{Symbol,Any}
        @test metadata_type(Metadata.MetaArray{Float64,2,Dict{Symbol,Any},Array{Int,2}}(parent(x), m)) <: Dict{Symbol,Any}

        @test eltype(@inferred(Metadata.MetaArray{Float64,2,Dict{Symbol,Any}}([1 3; 2 4], meta))) <: Float64
        @test eltype(@inferred(Metadata.MetaArray{Float64,2}([1 3; 2 4], meta))) <: Float64
        @test eltype(@inferred(Metadata.MetaArray{Float64}([1 3; 2 4], meta))) <: Float64
        @test metadata(copy(x)) == metadata(x)
        @test metadata(copy(x)) !== metadata(x)
    end
end

@testset "MetaRange" begin
    x = 1:1:10
    mx = Metadata.test_wrapper(Metadata.MetaRange, x)
    @test mx[1] == 1
    @test mx[1:2] == [1, 2]
    @test metadata(mx[1:2]) == metadata(mx)
    @test mx[:] == x[:]
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
    @test_throws ArgumentError Metadata.MetaUnitRange(1:3:10, nothing)
    Metadata.test_wrapper(Metadata.MetaUnitRange, 1:10)
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
    mio = Metadata.test_wrapper(Metadata.MetaIO, io)

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
end

#=
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
=#

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

    @attach_metadata(x, meta)
    @test @metadata(x, :x) == 1
    @test @metadata(x, :y) == 2
    x = MyType(1)
    GC.gc()
    @test @metadata(x) == Metadata.no_metadata  # test finalizer on nested mutables
    @test_logs(
        (:warn, "Cannot create finalizer for MyType{Int64}. Global dictionary must be manually deleted."),
        @attach_metadata(x, meta)
    )
    @test @metadata(x, :x) == 1
    @test @metadata(x, :y) == 2
end

if VERSION < v"1.6"
    @testset "docs" begin
        doctest(Metadata)
    end
end

