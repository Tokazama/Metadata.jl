
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

macro _define_function_no_prop_first(m, f, T1, T2)
    esc(:($m.$f(@nospecialize(x::$T1), y::$T2) = $m.$f(parent(x), y)))
end

macro _define_function_no_prop_last(m, f, T1, T2)
    esc(:($m.$f(x::$T1, @nospecialize(y::$T2)) = $m.$f(x, parent(y))))
end

macro defproperties(T)
    esc(quote
        @inline function Base.getproperty(x::$T, k::Symbol)
            if hasproperty(parent(x), k)
                return getproperty(parent(x), k)
            else
                return Metadata.metadata(x, k)
            end
        end

        @inline function Base.setproperty!(x::$T, k::Symbol, val)
            if hasproperty(parent(x), k)
                return setproperty!(parent(x), k, val)
            else
                return Metadata.metadata!(x, k, val)
            end
        end

        @inline Base.propertynames(x::$T) = Metadata.metadata_keys(x)
    end)
end

