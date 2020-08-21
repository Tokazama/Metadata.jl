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

### New Metadata Glue Structure

A new structure of type `T` that glues some data `x` to metadata `meta` require the following methods:

* Required methods
  - `Metadata.metadata(x) -> meta`: returns the metadata
  - `Metadata.metadata_type(::Type{T})`: returns the type of the metadata, where `T` is the glue structure
* Optional methods:
  - `Base.parent(x)`: returns the instance attached to the metadata
  - `attach_metadata(x, m) -> T(x, m)`: returns an instance of `T` that has the metadata `m` attached to `x`.

`attach_metadata` is only necessary if there is a specific type that you want to have a fall back for attaching metadata to.
For example, if one wanted to attach metadata to all subtypes of `AbstractGraph` via `MetaGraph` then one could define `Metadata.attach_metadata(g::AbstractGraph, m) = MetaGraph, g, m)`.

### New Types of Metadata

* Required methods:
  - `Metadata.metadata`: should return the same instance because `meta` is it's own metadata
  - `Metadata.metadata_type`
* Optional methods:
  - `Metadata.metadata_keys`: return iterator of metadata's keys
  - `MetadataPropagation(::Type{T})`: should metadata be dropped, shared, or copied.

