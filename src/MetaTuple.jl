
struct MetaTuple{N,P,M}
    parent::P
    metadata::M

    global _MetaTuple(p::P, m::M) where {P,M} = new{length(p),P,M}(p, m)
end

StaticArrayInterface.known_length(::Type{<:MetaTuple{N}}) where {N} = N

Base.eltype(T::Type{<:MetaTuple}) = eltype(parent_type(T))

for f in [:length, :firstindex, :lastindex, :first,:last, :all, :any, :isempty, :prod, :sum]
    eval(:(Base.$(f)(@nospecialize t::MetaTuple) = Base.$(f)(parent(t))))
end

Base.tail(t::MetaTuple) = _MetaTuple(Base.tail(parent(t)), metadata(t))

Base.front(t::MetaTuple) = _MetaTuple(Base.front(parent(t)), metadata(t))

Base.eachindex(@nospecialize t::MetaTuple) = static(1):static(known_length(t))
Base.axes(@nospecialize t::MetaTuple) = (eachindex(T),)

Base.getindex(@nospecialize(t::MetaTuple), ::Colon) = t
@propagate_inbounds Base.getindex(@nospecialize(t::MetaTuple), i::Int) = parent(t)[i]
@propagate_inbounds Base.getindex(@nospecialize(t::MetaTuple), i::Integer) = t[Int(i)]

@inline function Base.iterate(@nospecialize(t::MetaTuple), i::Int=1)
    if 1 <= i <= length(t)
        return (@inbounds t[i], i + 1)
    else
        return nothing
    end
end

# FIXME
Base.empty(@nospecialize x::MetaTuple) = _MetaTuple((), no_data)

function Base.setindex(x::MetaTuple, v, i::Int)
    _MetaTuple(Base.setindex(parent(x), v, i), metadata(x))
end

Base.map(f, t::MetaTuple) = _MetaTuple(map(f, paren(t)), metadata(t))

Base.in(item, t::MetaTuple) = in(item, parent(t))

Base.reverse(t::MetaTuple) = _MetaTuple(reverse(parent(t)), metadata(t))

#getindex(t::Tuple, b::AbstractArray{Bool,1}) = length(b) == length(t) ? getindex(t, findall(b)) : throw(BoundsError(t, b))

function Base.get(@nospecialize(t::MetaTuple), i::Integer, default)
    if i in 1:length(t)
        return @inbounds(parent(t)[i])
    else
        return default
    end
end
function Base.get(f::Union{Type,Function}, @nospecialize(t::MetaTuple), i::Integer)
    out = get(t, i, no_data)
    if out === no_data
        return f()
    else
        return out
    end
end

Base.findfirst(f::Function, @nospecialize(t::MetaTuple)) = findfirst(f, parent(t))

Base.findlast(f::Function, @nospecialize(t::MetaTuple)) = findlast(f, parent(t))

#Base.filter(f, t::MetaTuple) = length(t) < 32 ? filter_rec(f, t) : Tuple(filter(f, collect(t)))

for f in [:(==), :isequal, :(<),:isless]
    eval(:(Base.$(f)(x::MetaTuple, y::Tuple) = Base.$(f)(parent(x), y)))
    eval(:(Base.$(f)(x::MetaTuple, y::MetaTuple) = Base.$(f)(parent(x), parent(y))))
    eval(:(Base.$(f)(x::Tuple, y::MetaTuple) = Base.$(f)(x, parent(y))))
end

Base.hash(t::MetaTuple, h::UInt) = hash(parent(t), h)

# a version of `in` esp. for NamedTuple, to make it pure, and not compiled for each tuple length
#foreach(f, itr::Tuple) = foldl((_, x) -> (f(x); nothing), itr, init=nothing)
#foreach(f, itrs::Tuple...) = foldl((_, xs) -> (f(xs...); nothing), zip(itrs...), init=nothing)

