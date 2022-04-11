
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
    has_metadata,
    metadata,
    metadata_type,
    share_metadata

const METADATA_TYPES = Union{<:AbstractDict{String,Any},<:AbstractDict{Symbol,Any},<:NamedTuple}

# default dict
const MDict = Union{Dict{Symbol,Any},Dict{String,Any}}

include("NoMetadata.jl")
include("MetaStruct.jl")
include("interface.jl")
include("GlobalMetadata.jl")
include("MetaDict.jl")
include("MetaTuple.jl")
include("MetaIO.jl")
include("MetaUnitRange.jl")
include("MetaArray.jl")

const MetaNode{M,P} = Union{Meta{M,P},MetaStruct{M,P},MetaArray{M,P},MetaUnitRange{M,P},
    MetaIO{M,P},MetaTuple{M,P},MetaDict{M,P}}

include("propagation.jl")
include("show.jl")

_merge_keys(@nospecialize(x::Tuple), @nospecialize(y::Tuple)) = (x..., y...)
function _merge_keys(@nospecialize(x), @nospecialize(y))
    out = Vector{Symbol}(undef, length(x) + length(y))
    i = 1
    @inbounds for x_i in x 
        out[i] = Symbol(x_i)
        i += 1
    end
    @inbounds for y_i in y
        out[i] = Symbol(y_i)
        i += 1
    end
    return out
end

#=
    @def_meta_node MT T

* `MT`: metadata type
* `T`: type that is wrapped
=#
macro def_meta_node(MT, unsafe_constructor=nothing, T=nothing)
    blk = quote
        Base.parent(@nospecialize x::$MT) = getfield(x, :parent)
        @inline ArrayInterface.parent_type(@nospecialize T::Type{<:$MT}) = @inbounds T.parameters[2]

        Metadata.metadata(@nospecialize x::$(MT)) = getfield(x, :metadata)
        @inline Metadata.metadata_type(@nospecialize T::Type{<:$MT}) = @inbounds T.parameters[1]

        Base.getproperty(x::$MT, k::String) = getproperty(x, Symbol(k))
        @inline function Base.getproperty(x::$MT, k::Symbol)
            out = get(properties(x), k, Metadata.no_metadata)
            if out === Metadata.no_metadata
                return getproperty(parent(x), k)
            else
                return out
            end
        end
        Base.setproperty!(x::$MT, k::String, v) = setproperty!(x, Symbol(k), v)
        function Base.setproperty!(x::$MT, k::Symbol, v)
            props = properties(x)
            if haskey(props, k)
                setindex!(props, v, k)
            else
                setproperty!(parent(x), k, v)
            end
        end
        Base.propertynames(x::$MT) = keys(properties(x))
        Base.hasproperty(x::$MT, s::Symbol) = haskey(properties(x), s) || hasproperty(parent(x), s)
    end
    if T !== nothing && unsafe_constructor !== nothing
        push!(blk.args, :(Metadata.unsafe_attach_metadata(@nospecialize(x::$T), @nospecialize(m)) = $(unsafe_constructor)(x, m)))
        push!(blk.args, :(Metadata.unsafe_attach_metadata(@nospecialize(x::$T), ::Metadata.NoMetadata) = x))
    end
    esc(blk)
end

@def_meta_node MetaArray _MetaArray AbstractArray

@def_meta_node MetaDict _MetaDict Union{AbstractDict,NamedTuple}

@def_meta_node MetaUnitRange _MetaUnitRange AbstractUnitRange

@def_meta_node MetaIO _MetaIO IO

@def_meta_node MetaTuple _MetaTuple Union{Tuple,MetaTuple}

@def_meta_node MetaStruct

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
    metadata(x)[:m1] = 1
    @test getmeta(x, :m1, 3) == 1

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
