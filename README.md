# Metadata.jl

[![Build Status](https://travis-ci.com/Tokazama/Metadata.jl.svg?branch=master)](https://travis-ci.com/Tokazama/Metadata.jl)
[![stable-docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/Metadata.jl/stable)
[![dev-docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/Metadata.jl/dev)

# Introduction

The term "metadata" is widely used across very different applications.
Therefore, "metadata" may translate to very different structures and implementations in code.
The `Metadata` package attempts to provide a generic interface for interacting with metadata in Julia that is agnostic to the exact type of metadata present.
This package typically assumes metadata to be a collection of values paired to `Symbol` keys (e.g., `AbstractDict{Symbol,Any}`, `NamedTuple`), but metadata that doesn't perfectly fit this criteria should still work with most methods if adhering to the basic interface.

# Attaching Metadata

The most important method to know is `attach_metadata`.
It's intended to give users a generic way of attaching metadata to any given type without worrying about the particulars what type is appropriate for binding metadata to a particular.
For example, attaching metadata to an array should produce something that can act like an array still.
Instead of requiring users to know what type is used internally (`Metadata.MetaArray`), an appropriate type is chosen by default and the method of accessing metadata is the same.
```julia
julia> using Metadata

julia> x = ones(2, 2);

julia> meta = (x = 1, y = 2);

julia> mx = attach_metadata(x, meta)
2×2 attach_metadata(::Array{Float64,2}, ::NamedTuple{(:x, :y),Tuple{Int64,Int64}})
  • metadata:
    - x = 1
    - y = 2
 1.0  1.0
 1.0  1.0

julia> mx.x
1

julia> mx.y
2

```

There are two things you should notice from the previous example:
1. The display is nearly identical to the parent `x`. The only addition is a list of the metadata and the argument used to bind the `x` and `meta`.
2. We can access the metadata as if they were properties.

There are a limited number of interfaces that require special types for binding metadata.
The rest are bound to `Metadata.MetaStruct`.
```julia
julia> mr = attach_metadata(3//5, meta)
attach_metadata(3//5, ::NamedTuple{(:x, :y),Tuple{Int64,Int64}})
  • metadata:
    - x = 1
    - y = 2

julia> propertynames(mr)
(:x, :y)

julia> mr.num
3

julia> mr.den
5
```
Here we attached the same metadata to a rational number.
Again, our metadata is now considered the properties of `mr`, but we can still access the parent's properties.

## Interface For Specific Metadata Glue Types

A new structure of type `T` and instance `g` that glues some data `x` to metadata `m` require the following methods:

| Required Methods                            | Brief Description                                                     |
| ------------------------------------------- | --------------------------------------------------------------------- |
| `Metadata.metadata(g; dim) -> m`            | returns the metadata                                                  |
| `Metadata.metadata_type(::Type{T}; dim)`    | returns the type of the metadata                                      |
| `Base.parent(g) -> x`                       | returns the parent instance attached to the metadata                  |
| `Metadata.attach_metadata(x, m) -> T(x, m)` | returns an instance of `T` that has the metadata `m` attached to `x`. |

| Optional Methods                            | returns an instance of `T` that has the metadata `m` attached to `x`. |
| ------------------------------------------  | --------------------------------------------------------------------- |
| `Base.getproperty(x, k)`                    | get metadata assigned to key `k`                                      |
| `Base.setproperty!(x, k, val)`              | set metadata at key `k` to `val`                                      |
| `Base.propertynames(x)`                     | return the keys/properties of `x`                                     |

## Types of metadata

While the metadata attached could technically be anything, by default it is a dictionary (i.e. `Metadata.MetaID`).
```julia
julia> mx = attach_metadata(ones(2, 2))
2×2 attach_metadata(::Array{Float64,2}, ::Metadata.MetaID)
  • metadata:
 1.0  1.0
 1.0  1.0

julia> mx.x = 1;

julia> mx.y = :foo;

```

Although `MetaID` is technically a subtype of `AbstractDict{Symbol,Any}`, its main function is to redirect everything to a module level dictionary. 
The default module is `Main`, but we could have done `attach_metadata(ones(2, 2), MyOwnModule)`.
In this case the raw dictionary can be accessed  with `metadata(Main, metadata(mx))`.
Most users won't need to (and shouldn't) access these directly.

