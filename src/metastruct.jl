
struct MetaStruct{P,M}
    parent::P
    metadata::M
end

metadata(m::MetaStruct) = getfield(m, :metadata)

Base.parent(m::MetaStruct) = getfield(m, :parent)

ArrayInterface.parent_type(::Type{MetaStruct{P,M}}) where {P,M} = P

metadata_type(::Type{MetaStruct{P,M}}) where {P,M} = M

attach_metadata(x, m) = MetaStruct(x, m)

