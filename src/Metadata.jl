
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

include("methods.jl")
include("arrays.jl")
include("metastruct.jl")
include("elementwise.jl")

for T in (:MetaArray,)
    @eval begin
        function Base.similar(A::$T, t::Type, dims)
            return Metadata.share_metadata(A, similar(parent(A), t, dims))
        end

        function Base.similar(A::$T, t::Type, dims::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo}}})
            return Metadata.maybe_propagate_metadata(A, similar(parent(A), t, dims))
        end

        function Base.similar(A::$T, t::Type=eltype(A), dims::Tuple{Vararg{Int64}}=size(A))
            return Metadata.maybe_propagate_metadata(A, similar(parent(A), t, dims))
        end

        function Base.similar(A::$T, t::Type, dims::Union{Integer,AbstractUnitRange}...)
            return Metadata.maybe_propagate_metadata(A, similar(parent(A), t, dims))
        end
    end
end

@defsummary MetaStruct

@defsummary MetaArray

@defsummary MetaRange

@defsummary MetaUnitRange

end # module

