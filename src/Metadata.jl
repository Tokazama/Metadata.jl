
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
    metadata_type,
    share_metadata

include("utils.jl")
include("methods.jl")
include("metaarray.jl")
include("ranges.jl")
include("metastruct.jl")
include("elementwise.jl")

"""
    attach_metadata(x, metadata)

Generic method for attaching metadata to `x`.
"""
function attach_metadata(x::AbstractArray, m; elementwise::Bool=false)
    if elementwise
        return ElementwiseMetaArray(x, m)
    else
        return MetaArray(x, m)
    end
end

function attach_metadata(x::AbstractRange, m)
    if known_step(x) === oneunit(eltype(x))
        return MetaUnitRange(x, m)
    else
        return MetaRange(x, m)
    end
end

attach_metadata(m) = Base.Fix2(attach_metadata, m)

@defproperties MetaArray

@defproperties MetaRange

@defproperties MetaUnitRange

@defproperties MetaStruct

@defproperties ElementwiseMetaArray

end # module

