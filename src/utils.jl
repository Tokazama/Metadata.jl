
# m = module
# f = function
# `no_prop` = do not propagate properties/metadata
# `first` means use parent(x) 
# `last` means parent(y)
macro _define_function_no_prop(m, f, T1)
    esc(:($m.$f(@nospecialize(x::$(T1))) = $m.$f(parent(x))))
end
macro _define_function_no_prop(m, f, T1, T2)
    esc(:($m.$f(x::$(T1), y::$(T2)) = $m.$f(parent(x), parent(y))))
end

macro _define_function_prop(m, f, T1)
    esc(:($m.$f(@nospecialize(x::$(T1))) = Metadata.propagate_metadata(x, $m.$f(parent(x)))))
end
macro _define_function_prop(m, f, T1, T2)
    esc(:($m.$f(x::$(T1), y::$(T2)) = Metadata.combine_metadata(x, y, $m.$f(parent(x), parent(y)))))
end

macro _define_function_no_prop_first(m, f, T1, T2)
    esc(:($m.$f(@nospecialize(x::$T1), y::$T2) = $m.$f(parent(x), y)))
end

macro _define_function_prop_first(m, f, T1, T2)
    esc(:($m.$f(@nospecialize(x::$T1), y::$T2) = Metadata.combine_metadata(x, y, $m.$f(parent(x), y))))
end

macro _define_function_no_prop_last(m, f, T1, T2)
    esc(:($m.$f(x::$T1, @nospecialize(y::$T2)) = $m.$f(x, parent(y))))
end

macro _define_function_prop_last(m, f, T1, T2)
    esc(:($m.$f(x::$T1, @nospecialize(y::$T2)) = Metadata.combine_metadata(x, y, $m.$f(x, parent(y)))))
end
