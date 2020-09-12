
macro _define_single_function_no_prop(m, f, T)
    esc(:($m.$f(@nospecialize(x::$T)) = $m.$f(parent(x))))
end

macro _define_single_function_prop(m, f, T)
    esc(:($m.$f(@nospecialize(x::$T)) = Metadata.propagate_metadata(x, $m.$f(parent(x)))))
end

macro _define_two_function_no_prop_first(m, f, T1, T2)
    esc(:($m.$f(@nospecialize(x::$T1), y::$T2) = $m.$f(parent(x), y)))
end

macro _define_two_function_prop_first(m, f, T1, T2)
    esc(:($m.$f(@nospecialize(x::$T1), y::$T2) = Metadata.combine_metadata(x, y, $m.$f(parent(x), y))))
end

macro _define_two_function_no_prop_last(m, f, T1, T2)
    esc(:($m.$f(x::$T1, @nospecialize(y::$T2)) = $m.$f(x, parent(y))))
end

macro _define_two_function_prop_last(m, f, T1, T2)
    esc(:($m.$f(x::$T1, @nospecialize(y::$T2)) = Metadata.combine_metadata(x, y, $m.$f(x, parent(y)))))
end

#=
struct OneInt{I<:Integer}
    parent::I

    OneInt() = new{Int}(1)
end

Base.parent(x::OneInt) = getfield(x, :parent)

@_define_single_function_no_prop(Base, +, OneInt)
@_define_single_function_no_prop(Base, -, OneInt)

=#

