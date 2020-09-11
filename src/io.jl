
struct MetaIO{T<:IO,M} <: IO
    parent::T
    metadata::M
end

Base.parent(x::MetaIO) = getfield(x, :parent)
metadata(x::MetaIO) = getfield(x, :metadata)

#=
for f in (isreadonly,)
    @eval begin
        Base.$f(@nosepcialize(x::MetaIO)) = Base.$f(parent(x))
    end
end
=#

Base.isreadonly(@nospecialize(s::MetaIO)) = isreadonly(parent(s))
Base.isreadable(@nospecialize(s::MetaIO)) = isreadable(parent(s))
Base.iswritable(@nospecialize(s::MetaIO)) = iswritable(parent(s))

Base.seek(@nospecialize(s::MetaIO), n::Integer) = seek(parent(s), n)
Base.position(@nospecialize(s::MetaIO))  = position(parent(s))
Base.skip(@nospecialize(s::MetaIO), n::Integer) = skip(parent(s), n)
Base.eof(@nospecialize(s::MetaIO)) = eof(parent(s))
Base.stat(@nospecialize(s::MetaIO)) = stat(parent(s))
Base.close(@nospecialize(s::MetaIO)) = close(parent(s))
Base.isopen(@nospecialize(s::MetaIO)) = isopen(parent(s))
Base.ismarked(@nospecialize(s::MetaIO)) = ismarked(parent(s))
Base.mark(@nospecialize(s::MetaIO)) = mark(parent(s))
Base.unmark(@nospecialize(s::MetaIO)) = unmark(parent(s))
Base.reset(@nospecialize(s::MetaIO)) = reset(parent(s))
Base.seekend(@nospecialize(s::MetaIO)) = seekend(parent(s))

Base.read(@nospecialize(s::MetaIO), n::Int) = read(parent(s), n)
Base.read!(@nospecialize(s::MetaIO), x) = read!(parent(s), x)
Base.read!(@nospecialize(s::MetaIO), x::Ref{T}) where {T} = read!(parent(s), x)

Base.write(@nospecialize(s::MetaIO), x) = write(parent(s), x)
function Base.write(s::MetaIO, val::Union{Float16, Float32, Float64, Int128, Int16, Int32, Int64, UInt128, UInt16, UInt32, UInt64})
    return write(parent(s), val)
end

