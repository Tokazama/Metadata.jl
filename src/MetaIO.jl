
"""
    MetaIO(io, meta)

Type for storing metadata alongside subtypes of `IO`.
"""
struct MetaIO{T<:IO,M} <: IO
    parent::T
    metadata::M
end

ArrayInterface.parent_type(::Type{T}) where {IOType,T<:MetaIO{IOType}} = IOType

@_define_function_no_prop(Base, isreadonly, MetaIO)
@_define_function_no_prop(Base, isreadable, MetaIO)
@_define_function_no_prop(Base, iswritable, MetaIO)
@_define_function_no_prop(Base, stat, MetaIO)
@_define_function_no_prop(Base, eof, MetaIO)
@_define_function_no_prop(Base, position, MetaIO)
@_define_function_no_prop(Base, close, MetaIO)
@_define_function_no_prop(Base, isopen, MetaIO)
@_define_function_no_prop(Base, ismarked, MetaIO)
@_define_function_no_prop(Base, mark, MetaIO)
@_define_function_no_prop(Base, unmark, MetaIO)
@_define_function_no_prop(Base, reset, MetaIO)
@_define_function_no_prop(Base, seekend, MetaIO)

@_define_function_no_prop_first(Base, skip, MetaIO, Integer)
@_define_function_no_prop_first(Base, seek, MetaIO, Integer)
@_define_function_no_prop_first(Base, read, MetaIO, Integer)
@_define_function_no_prop_first(Base, read!, MetaIO, Ref)
@_define_function_no_prop_first(Base, read!, MetaIO, AbstractArray)
@_define_function_no_prop_first(Base, read!,  MetaIO, Array{UInt8})
@_define_function_no_prop_first(Base, read!,  MetaIO, BitArray)

@_define_function_no_prop_first(Base, write, MetaIO, Array)
@_define_function_no_prop_first(Base, write, MetaIO, AbstractArray)
@_define_function_no_prop_first(Base, write, MetaIO, BitArray)
@_define_function_no_prop_first(Base, write, MetaIO, Base.CodeUnits)
@_define_function_no_prop_first(Base, write, MetaIO, Union{Float16, Float32, Float64, Int128, Int16, Int32, Int64, UInt128, UInt16, UInt32, UInt64})


#Base.read(@nospecialize(s::MetaIO), n::Int) = read(parent(s), n)

function Base.write(@nospecialize(s::MetaIO), x::SubArray{T,N,P,I,L} where L where I where P<:Array) where {T, N}
    return write(parent(s), x)
end

@inline metadata_type(::Type{T}) where {IOT,M,T<:MetaIO{IOT,M}} = M

