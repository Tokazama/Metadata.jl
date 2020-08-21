# Metadata.jl


[![Build Status](https://travis-ci.com/Tokazama/Metadata.jl.svg?branch=master)](https://travis-ci.com/Tokazama/Metadata.jl)
[![stable-docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/Metadata.jl/stable)
[![dev-docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/Metadata.jl/dev)

## Introduction

The `Metadata` package provides a generic interface for interacting with metadata in Julia.
This package typically assumes metadata to be a collection of of values paired to `Symbol` keys (e.g., `Dict{Symbol}`, `NamedTuple`).
However, metadata that doesn't perfectly fit this criteria should still work with most methods if adhering to the basic interface.

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

The optional method is only necessary if there is a specific type that you want there
to be a fall back for attaching metadata to. For example, if one wanted to attach
metadata to all subtypes of `AbstractGraph` via `MetaGraph` then one could define
`Metadata.attach_metadata(g::AbstractGraph, m) = MetaGraph, g, m)`.

### Types of Metadata

* Optional methods:
  - `Metadata.metadata_keys(x)`:
  - `MetadataPropagation`:
