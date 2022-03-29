
"""
    NoMetadata

Internal type for the `Metadata` package that indicates the absence of any metadata.
_DO NOT_ store metadata with the value `NoMetadata()`.
"""
struct NoMetadata end

const no_metadata = NoMetadata()

Base.show(io::IO, ::NoMetadata) = print(io, "no_metadata")

Base.haskey(::NoMetadata, @nospecialize(k)) = false
Base.get(::NoMetadata, @nospecialize(k), default) = default
Base.getindex(::NoMetadata, @nospecialize(k)) = no_metadata
Base.getproperty(::NoMetadata, ::Symbol) = no_metadata

