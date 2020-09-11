
@testset "MetaID" begin
    m = Metadata.MetaID()
    @test metadata(Main) == getproperty(Main, Metadata.GLOBAL_METADATA)

    @test Metadata.parent_module(m) == Main
    @test metadata_type(m) <: valtype(Metadata.GlobalMetadata)
    @test metadata(m) == valtype(Metadata.GlobalMetadata)()
    m.x = 1
    @test m.x == 1
    @test get(m, :x, 2) == 1
    @test get(m, :y, 2) == 2
    @test get!(m, :y, 2) == 2
    @test m.y == 2
    for k in propertynames(m)
        @test k in (:x, :y)
    end
    for k in keys(m)
        @test k in (:x, :y)
    end

    @test length(m) == 2
    @test length(metadata(Main)) == 1
    @test metadata_type(Main) <: Metadata.GlobalMetadata
    @test !isempty(m)
    empty!(m)
    @test isempty(m)

    @test metadata(Main) == getproperty(Main, Metadata.GLOBAL_METADATA)
end

