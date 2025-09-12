# Metadata.jl

![CI](https://github.com/Tokazama/Metadata.jl/workflows/CI/badge.svg)
[![stable-docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/Metadata.jl/stable)
[![dev-docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/Metadata.jl/dev)
[![codecov](https://codecov.io/gh/Tokazama/Metadata.jl/branch/master/graph/badge.svg?token=hx7hbIIoxE)](https://codecov.io/gh/Tokazama/Metadata.jl)

## Introduction

The term "metadata" is widely used across very different applications.
Therefore, "metadata" may translate to very different structures and implementations in code.
The `Metadata` package attempts to provide a generic interface for interacting with metadata in Julia that is agnostic to the exact type of metadata present.
This package typically assumes metadata to be a collection of values paired to `Symbol` keys (e.g., `AbstractDict{Symbol,Any}`, `NamedTuple`), but metadata that doesn't perfectly fit this criteria should still work with most methods if adhering to the basic interface.

## Attaching Metadata

The most important method to know is `attach_metadata`.
It's intended to give users a generic way of attaching metadata to any given type without worrying about the particulars what type is appropriate for binding metadata to a particular.
For example, attaching metadata to an array should produce something that can act like an array still.
Instead of requiring users to know what type is used internally (`Metadata.MetaArray`), an appropriate type is chosen by default and the method of accessing metadata is the same.
```julia
julia> using Metadata

julia> x = ones(2, 2);

julia> meta = (x = 1, y = 2);

julia> mx = attach_metadata(x, meta)
2×2 attach_metadata(::Matrix{Float64}, ::NamedTuple{(:x, :y), Tuple{Int64, Int64}}
  • metadata:
     x = 1
     y = 2
)
 1.0  1.0
 1.0  1.0

julia> mx.x
1

julia> mx.y
2

julia> attach_metadata(x, (x = 1, y = 2, suppress= [:x]))
2×2 attach_metadata(::Matrix{Float64}, ::NamedTuple{(:x, :y, :suppress), Tuple{Int64, Int64, Vector{Symbol}}}
  • metadata:
     x = <suppressed>
     y = 2
)
 1.0  1.0
 1.0  1.0

```

There are three things you should notice from the previous example:
1. The display is nearly identical to how the parent `x` would be printed. The only addition is a list of the metadata and the argument used to bind the `x` and `meta`.
2. We can access the metadata as if they were properties.
3. We can suppress the printing of any value if `metadata(x, :suppress)` returns a collection of symbols containing that value.

There are a limited number of interfaces that require special types for binding metadata.
The rest are bound to `Metadata.MetaStruct`.
```julia
julia> mr = attach_metadata(3//5, meta)
attach_metadata(3//5, ::NamedTuple{(:x, :y), Tuple{Int64, Int64}})
  • metadata:
     x = 1
     y = 2

julia> propertynames(mr)
(:x, :y)

julia> mr.num
3

julia> mr.den
5
```
Here we attached the same metadata to a rational number.
Again, our metadata is now considered the properties of `mr`, but we can still access the parent's properties.

## Creating New Metadata Types

This package creates a very minimal number of dedicated structures and creating new dedicated structures that use this interface is encouraged.
```
abstract type AbstractNoop end

struct Noop <: AbstractNoop end

struct MetaNoop{P<:AbstractNoop,M} <: AbstractNoop
    parent::P
    metadata::M
end

Metadata.metadata(x::MetaNoop) = getfield(x, :metadata)
Metadata.unsafe_attach_metadata(x::AbstractNoop, m) = MetaNoop(x, m)
Metadata.metadata_type(::Type{MetaNoop{P,M}}) where {P,M} = M

ArrayInterface.parent_type(::Type{MetaNoop{P,M}}) where {P,M} = P
Base.parent(x::MetaNoop) = getfield(x, :parent)
```

It's advised that `Metadata.test_wrapper(MetaNoop, Noop())` is run to ensure it works.
Note that using the dot operator (`.`) that aliases `getproperty` and `setproperty!` is not necessary.

