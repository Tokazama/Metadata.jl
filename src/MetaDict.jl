
struct MetaDict{K, V, P <: AbstractDict{K, V},M} <: AbstractDict{K, V}
    parent::P
    metadata::M

    global _MetaDict
    function _MetaDict(@nospecialize(p::AbstractDict), @nospecialize(m))
        new{typeof(m),typeof(p),keytype(p),valtype(p)}(p, m)
    end
    _MetaDict(@nospecialize(p::NamedTuple), @nospecialize(m)) = _MetaDict(pairs(p), m)
end

function Base.sizehint!(@nospecialize(d::MetaDict), n::Integer)
    sizehint!(parent(d), n)
    return d
end

Base.push!(@nospecialize(d::MetaDict), p::Pair) = push!(parent(d), p)
Base.pop!(@nospecialize(d::MetaDict), args...) = pop!(parent(d), args...)
function Base.empty!(@nospecialize(d::MetaDict))
    empty!(parent(d))
    return d
end
function Base.delete!(@nospecialize(d::MetaDict), key)
    delete!(parent(d), key)
    return d
end

function ArrayInterface.can_setindex(@nospecialize T::Type{<:MetaDict})
    ArrayInterface.can_setindex(parent_type(T))
end

Base.get(@nospecialize(d::MetaDict), k, default) = get(parent(d), k, default)
Base.get(f::Union{Type,Function}, @nospecialize(d::MetaDict), k) = get(f, parent(d), k)
Base.get!(@nospecialize(d::MetaDict), k, default) = get!(parent(d), k, default)
Base.get!(f::Union{Type,Function}, @nospecialize(d::MetaDict), k) = get!(f, parent(d), k)

@propagate_inbounds Base.getindex(@nospecialize(d::MetaDict), k) = parent(d)[k]
@propagate_inbounds Base.setindex!(@nospecialize(d::MetaDict), v, k) = setindex!(parent(d), v, k)

Base.haskey(@nospecialize(d::MetaDict), k) = haskey(parent(d), k)

Base.iterate(@nospecialize(d::MetaDict), args...) = iterate(parent(d), args...)

for f in [:length, :first,:last, :isempty, :keys, :values]
    eval(:(Base.$(f)(@nospecialize d::MetaDict) = Base.$(f)(parent(d))))
end

