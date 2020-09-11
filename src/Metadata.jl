
module Metadata
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end Metadata

using ArrayInterface
using ArrayInterface: parent_type, known_first, known_last, known_step

using Base: @propagate_inbounds, OneTo

export
    attach_eachmeta,
    attach_metadata,
    copy_metadata,
    elementwise,
    has_metadata,
    metadata,
    metadata!,
    metadata_type,
    share_metadata

const METADATA_TYPES = Union{Module,<:AbstractDict{Symbol,Any},<:NamedTuple}

include("metaid.jl")
include("methods.jl")
include("metaarray.jl")
include("ranges.jl")
include("elementwise.jl")
include("io.jl")


attach_metadata(x::AbstractArray, m::METADATA_TYPES=Main) = MetaArray(x, _maybe_metaid(m))

function attach_metadata(x::AbstractRange, m::METADATA_TYPES=Main)
    if known_step(x) === oneunit(eltype(x))
        return MetaUnitRange(x, _maybe_metaid(m))
    else
        return MetaRange(x, _maybe_metaid(m))
    end
end
attach_metadata(x::IO, m::METADATA_TYPES=Main) = MetaIO(x, _maybe_metaid(m))

attach_metadata(m::METADATA_TYPES) = Base.Fix2(attach_metadata, _maybe_metaid(m))

@defproperties MetaArray

@defproperties MetaRange

@defproperties MetaUnitRange

@defproperties MetaStruct

@defproperties ElementwiseMetaArray

@defproperties MetaIO

end # module

