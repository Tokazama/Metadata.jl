
struct MetaStruct{P,M}
    parent::P
    metadata::M
end

metadata(m::MetaStruct) = getfield(m, :metadata)

Base.parent(m::MetaStruct) = getfield(m, :parent)

ArrayInterface.parent_type(::Type{MetaStruct{P,M}}) where {P,M} = P

metadata_type(::Type{MetaStruct{P,M}}) where {P,M} = M

attach_metadata(x, m) = MetaStruct(x, m)

function unsafe_attach_eachmeta(x::AbstractVector, m::NamedTuple{L}, i::Int) where {L}
    return MetaStruct(
        x,
        NamedTuple{L}(ntuple(i -> @inbounds(m[L[i]][index]), Val(length(L))))
    )
end

# TODO `eachindex` should change to `ArrayInterface.indices`
function attach_eachmeta(x::AbstractVector, m::NamedTuple)
    return map(i -> unsafe_attach_eachmeta(@inbounds(x[i]), m, i), eachindex(p, m...))
end

#= TODO
function Base.show(io::IO, m::MIME"text/plain", r::$T)
    print(io, "attach_metadata(")
    print(io, parent(r))
    print(io, ", ", Metadata.showarg_metadata(x), ")\n")
    print(io, Metadata.metadata_summary(x))
end
=#
