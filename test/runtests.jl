using Test
using Metadata


@testset "MetaArray" begin
    x = ones(4, 4)
    meta = (m1 =1, m2=[1, 2])
    mx = attach_metadata(x, meta)
    @test metadata(mx) == meta
    @test metadata(mx, :m1) == 1
    @test Metadata.metadata_keys(mx) == (:m1, :m2)
    @test mx[1] == 1
    @test mx[1:2] == [1, 1]
    @test metadata(mx[1:2]) == metadata(mx)
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
    mx = attach_metadata(x, meta)
    @test metadata(mx) == meta
    @test metadata(mx, :m1) == 1
    @test Metadata.metadata_keys(mx) == (:m1, :m2)
    @test mx[1] == 1
    @test mx[1:2] == [1, 2]
    @test metadata(mx[1:2]) == metadata(mx)
end


