
"""
    MetaIO(io, meta)

Type for storing metadata alongside subtypes of `IO`.
"""
struct MetaIO{M,T<:IO} <: IO
    parent::T
    metadata::M

    global _MetaIO(@nospecialize(p), @nospecialize(m)) = new{typeof(m),typeof(p)}(p, m)
end

for f in [:isreadonly, :isreadable, :iswritable, :stat, :eof, :position, :close,
    :isopen, :ismarked, :mark, :unmark, :reset, :seekend]
    eval(:(Base.$(f)(@nospecialize x::MetaIO) = Base.$(f)(parent(x))))
end

Base.skip(@nospecialize(x::MetaIO), n::Integer) = skip(parent(x), n)
Base.seek(@nospecialize(x::MetaIO), n::Integer) = seek(parent(x), n)
Base.read(@nospecialize(x::MetaIO), n::Integer) = read(parent(x), n)
Base.read!(@nospecialize(x::MetaIO), @nospecialize(r::Ref)) = read!(parent(x), r)
Base.read!(@nospecialize(x::MetaIO), @nospecialize(A::AbstractArray)) = read!(parent(x), A)
Base.read!(@nospecialize(x::MetaIO), r::Array{UInt8}) = read!(parent(x), r)
Base.read!(@nospecialize(x::MetaIO), r::BitArray) = read!(parent(x), r)

Base.write(@nospecialize(x::MetaIO), n::Union{Float16, Float32, Float64, Int128, Int16, Int32, Int64, UInt128, UInt16, UInt32, UInt64}) = write(parent(x), n)
Base.write(@nospecialize(x::MetaIO), n::Base.CodeUnits) = write(parent(x), n)
Base.write(@nospecialize(x::MetaIO), A::Array) = write(parent(x), A)
Base.write(@nospecialize(x::MetaIO), A::BitArray) = write(parent(x), A)
Base.write(@nospecialize(x::MetaIO), @nospecialize(A::AbstractArray)) = write(parent(x), A)

#Base.read(@nospecialize(s::MetaIO), n::Int) = read(parent(s), n)

function Base.write(@nospecialize(s::MetaIO), x::SubArray{T,N,P,I,L} where L where I where P<:Array) where {T, N}
    return write(parent(s), x)
end

