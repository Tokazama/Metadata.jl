
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
function Base.unsafe_read(@nospecialize(x::MetaIO), p::Ptr{UInt8}, n::UInt)
    unsafe_read(parent(x), p, n)
end
function Base.unsafe_write(@nospecialize(x::MetaIO), p::Ptr{UInt8}, n::UInt)
    unsafe_write(parent(x), p, n)
end

