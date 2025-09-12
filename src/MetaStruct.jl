
"""
    MetaStruct(p, m)

Binds a parent instance (`p`) to some metadata (`m`). `MetaStruct` is the generic type
constructed when `attach_metadata(p, m)` is called.

See also: [`attach_metadata`](@ref)
"""
struct MetaStruct{M,P}
    parent::P
    metadata::M

    global function _MetaStruct(@nospecialize(p), @nospecialize(m))
        new{typeof(m),typeof(p)}(p, m)
    end
end

Base.eltype(::Type{T}) where {T<:MetaStruct} = eltype(parent_type(T))

Base.copy(x::MetaStruct) = propagate_metadata(x, deepcopy(parent(x)))

Base.:(==)(@nospecialize(x::MetaStruct), @nospecialize(y::MetaStruct)) = ==(parent(x), parent(y))
Base.:(==)(x::Any, @nospecialize(y::MetaStruct)) = ==(x, parent(y))
Base.:(==)(@nospecialize(x::MetaStruct), y::Any) = ==(parent(x), y)
Base.:(==)(@nospecialize(x::MetaStruct), ::Missing) = ==(parent(x), missing)
Base.:(==)(::Missing, @nospecialize(y::MetaStruct)) = ==(missing, parent(y))
Base.:(==)(@nospecialize(x::MetaStruct), y::WeakRef) = ==(parent(x), y)
Base.:(==)(x::WeakRef, @nospecialize(y::MetaStruct)) = ==(x, parent(y))

