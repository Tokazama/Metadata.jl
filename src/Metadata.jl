
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
    has_metadata,
    metadata,
    metadata!,
    metadata_type,
    share_metadata

const METADATA_TYPES = Union{Module,<:AbstractDict{Symbol,Any},<:NamedTuple}

include("utils.jl")
include("metaid.jl")
include("methods.jl")
include("metaarray.jl")
include("ranges.jl")
include("elementwise.jl")
include("io.jl")

for T in (MetaIO, MetaStruct, MetaArray, MetaRange, MetaUnitRange)
    @eval begin
        @inline function Metadata.metadata(x::$T; dim=nothing)
            if dim === nothing
                return getfield(x, :metadata)
            else
                return metadata(parent(x); dim=dim)
            end
        end


    end
end

@defproperties MetaArray

@defproperties MetaRange

@defproperties MetaUnitRange

@defproperties MetaStruct

@defproperties ElementwiseMetaArray

@defproperties MetaIO

end # module

