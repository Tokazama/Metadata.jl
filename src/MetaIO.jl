
"""
    MetaIO(io, meta)

Type for storing metadata alongside subtypes of `IO`.
"""
struct MetaIO{T<:IO,M} <: IO
    parent::T
    metadata::M
end

@unwrap Base.isreadonly(x::MetaIO)
@unwrap Base.isreadable(x::MetaIO)
@unwrap Base.iswritable(x::MetaIO)
@unwrap Base.stat(x::MetaIO)
@unwrap Base.eof(x::MetaIO)
@unwrap Base.position(x::MetaIO)
@unwrap Base.close(x::MetaIO)
@unwrap Base.isopen(x::MetaIO)
@unwrap Base.ismarked(x::MetaIO)
@unwrap Base.mark(x::MetaIO)
@unwrap Base.unmark(x::MetaIO)
@unwrap Base.reset(x::MetaIO)
@unwrap Base.seekend(x::MetaIO)

@unwrap Base.skip(x::MetaIO, n::Integer)
@unwrap Base.seek(x::MetaIO, n::Integer)
@unwrap Base.read(x::MetaIO, n::Integer)
@unwrap Base.read!(x::MetaIO, n::Ref)
@unwrap Base.read!(x::MetaIO, n::AbstractArray)
@unwrap Base.read!(x::MetaIO, n::Array{UInt8})
@unwrap Base.read!(x::MetaIO, n::BitArray)

@unwrap Base.write(x::MetaIO, n::Array)
@unwrap Base.write(x::MetaIO, n::AbstractArray)
@unwrap Base.write(x::MetaIO, n::BitArray)
@unwrap Base.write(x::MetaIO, n::Base.CodeUnits)
@unwrap Base.write(x::MetaIO, n::Union{Float16, Float32, Float64, Int128, Int16, Int32, Int64, UInt128, UInt16, UInt32, UInt64})

#Base.read(@nospecialize(s::MetaIO), n::Int) = read(parent(s), n)

function Base.write(@nospecialize(s::MetaIO), x::SubArray{T,N,P,I,L} where L where I where P<:Array) where {T, N}
    return write(parent(s), x)
end

@inline metadata_type(::Type{T}) where {IOT,M,T<:MetaIO{IOT,M}} = M

