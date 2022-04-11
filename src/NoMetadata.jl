
"""
    NoMetadata

Internal type for the `Metadata` package that indicates the absence of any metadata.
_DO NOT_ store metadata with the value `NoMetadata()`.
"""
struct NoMetadata end

Base.keys(::NoMetadata) = ()
Base.values(::NoMetadata) = ()
Base.haskey(::NoMetadata, @nospecialize(k)) = false
Base.get(::NoMetadata, @nospecialize(k), d) = d
Base.get(f::Union{Type,Function}, ::NoMetadata, @nospecialize(k)) = f()
Base.iterate(::NoMetadata) = nothing
Base.in(_, ::NoMetadata) = false

const no_metadata = NoMetadata()

Base.show(io::IO, ::NoMetadata) = show(io, MIME"text/plain"(), no_metadata)
Base.show(io::IO, ::MIME"text/plain", ::NoMetadata) = print(io, "no_metadata")

