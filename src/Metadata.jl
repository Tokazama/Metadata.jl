
module Metadata

using ArrayInterface
using ArrayInterface: parent_type, known_first, known_last, known_step

using Base: @propagate_inbounds, OneTo

export
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

attach_metadata(m) = Fix2(attach_metadata, m)

@defsummary MetaStruct

@defsummary MetaArray

@defsummary MetaRange

@defsummary MetaUnitRange

end # module

