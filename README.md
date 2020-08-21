# Metadata.jl


## Introduction

## Interface

There are two types of interfaces in `Metadata`.
1. Attaching metadata to other data
2. New types of metadata

### Attaching Metadata

Only two methods are necessary to adopt the `Metadata` interface:
* Required methods
  - `Metadata.metadata(x)`: returns the metadata
  - `Metadata.metadata_type(::Type{T})`: returns the type of the metadata
* Optional methods:
  - `Base.parent(x)`: returns the instance attached to the metadata
  - `attach_metadata(x, m)`: returns a type that has the metadata `m` attached to `x`.
  - `MetadataPropagation`:

The optional method is only necessary if there is a specific type that you want there
to be a fall back for attaching metadata to. For example, if one wanted to attach
metadata to all subtypes of `AbstractGraph` via `MetaGraph` then one could define
`Metadata.attach_metadata(g::AbstractGraph, m) = MetaGraph, g, m)`.

### Types of Metadata

* Optional methods:
  - `Metadata.known_keys(::Type{T})`:
