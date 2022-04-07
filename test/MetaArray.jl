x = ones(4, 4);
xview = view(x, :, :)
meta = (m1 =1, m2=[1, 2]);
mx = attach_metadata(meta)(x);
mxview = attach_metadata(meta)(xview)
@test @inferred(parent_type(mx)) <: typeof(x)
@test @inferred(parent_type(mxview)) <: typeof(xview)
#@test @inferred(typeof(mx)(xview, meta)) isa typeof(mx)
@test mxview.indices === xview.indices
@test ArrayInterface.defines_strides(typeof(mx))

# permutedims
@test metadata(mx') == metadata(permutedims(mx))

mvx = attach_metadata(xview, (m1 = 1, m2 = [1, 2]))
@test mvx.m1 == 1
@test mvx.m2 == [1, 2]

x = ones(4, 4);
meta = (m1 =1, m2=[1, 2]);
mx = attach_metadata(meta)(x);

@test metadata(similar(mx, eltype(mx), size(mx))) == meta
@test metadata(similar(mx, eltype(mx), axes(mx))) == meta

@test @inferred(metadata(mx)) == meta

@test @inferred(metadata(parent(mx))) === no_metadata
@test @inferred(has_metadata(mx))
@test @inferred(has_metadata(mx, :m1))
@test @inferred(!has_metadata(parent(mx), :m1))
@test getmeta(mx, :m1, 3) == 1
@test mx[1] == 1
@test mx[1:2] == [1, 1]
@test metadata(mx[1:2]) == metadata(mx)
@test @inferred(metadata_type(view(parent(mx), :, :))) <: Metadata.NoMetadata
@test @inferred(metadata_type(mx)) <: NamedTuple

meta = Dict(:m1 => 1, :m2 => [1,2])
mx = attach_metadata(x, meta);
@test @inferred(parent_type(typeof(mx))) <: typeof(x)
@test @inferred(metadata(mx)) == meta
@test @inferred(has_metadata(mx))
@test @inferred(has_metadata(mx, :m1))
@test getmeta(mx, :m1, 4) == 1
@test getmeta(mx, :m4, 4) == 4
@test getmeta(ndims, x, :m4) == 2
@test getmeta!(mx, :m4, 4) == 4
@test getmeta!(ndims, mx, :m5) == 2
@test getmeta!(ndims, mx, :m5) == 2
# Currently Dict doesn't preserve order so we just check for presence of keys
@test in(:m1, propertynames(mx))
@test in(:m2, propertynames(mx))
@test mx[1] == 1
@test mx[1:2] == [1, 1]
@test @inferred(metadata(mx[1:2])) == metadata(mx)
@test @inferred(metadata_type(mx)) <: AbstractDict
# test getmeta/getmeta!

@test IndexStyle(typeof(mx)) isa IndexLinear
@test @inferred(size(mx)) == (4, 4)
@test @inferred(axes(mx)) == (1:4, 1:4)
mx.m1 = 2
@test mx.m1 == 2

#=
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
=#

