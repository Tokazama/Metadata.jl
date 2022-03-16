
"""
    MetaIO(io, meta)

Type for storing metadata alongside subtypes of `IO`.
"""
struct MetaIO{T<:IO,M} <: IO
    parent::T
    metadata::M
end

metadata_type(::Type{<:MetaIO{<:Any,M}}) where {M} = M

ArrayInterface.parent_type(::Type{T}) where {IOType,T<:MetaIO{IOType}} = IOType

for s in [:isreadonly, :isreadable, :iswritable, :stat, :eof, :position, :close, :isopen, :ismarked, :mark, :unmark, :reset, :seekend]
    eval(:(Base.$(s)(x::MetaIO) = Base.$(s)(parent(x))))
end

Base.skip(s::MetaIO, n::Integer) = skip(parent(s), n)
Base.seek(s::MetaIO, n::Integer) = seek(parent(s), n)
Base.read(s::MetaIO, n::Integer) = seek(parent(s), n)

Base.read!(s::MetaIO, r::Ref) = read!(parent(s), r)
Base.read!(s::MetaIO, x::AbstractArray) = read!(parent(s), x)
Base.read!(s::MetaIO, x::Array{UInt8}) = read!(parent(s), x)
Base.read!(s::MetaIO, x::BitArray) = read!(parent(s), x)

Base.write(s::MetaIO, x::Array) = write(parent(s), x)
Base.write(s::MetaIO, x::AbstractArray) = write(parent(s), x)
Base.write(s::MetaIO, x::BitArray) = write(parent(s), x)
Base.write(s::MetaIO, x::Base.CodeUnits) = write(parent(s), x)
Base.write(s::MetaIO, x::Union{Float16, Float32, Float64, Int128, Int16, Int32, Int64, UInt128, UInt16, UInt32, UInt64}) = write(parent(s), x)
Base.write(@nospecialize(s::MetaIO), x::SubArray{T,N,P,I,L} where L where I where P<:Array) where {T, N} = write(parent(s), x)

