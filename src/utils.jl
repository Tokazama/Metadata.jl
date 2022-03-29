
argexpr(e::Symbol) = e
function argexpr(e::Expr)
    if e.head === :(::)
        return argexpr(e.args[1])
    elseif e.head === :macrocall
        return argexpr(e.args[3])
    else
        return e
    end
end

macro unwrap(e::Expr)
    _unwrap(2, e)
end
macro unwrap(pos::Int, e::Expr)
    _unwrap(pos + 1, e)
end

function _unwrap(pos::Int, e::Expr)
    if e.head === :macrocall
        call_expr = e.args[3]
        mcall = e.args[1]
        mline = e.args[2]
    else  # e.head === :call
        call_expr = e.args
        mcall = nothing
        mline = nothing
    end

    body = Expr(:block, Expr(:call, call_expr[1]))
    body_call = body.args[1]
    thunk = Expr(:call, call_expr[1])
    for i in 2:length(call_expr)
        if i === pos
            p = gensym(:parent)
            push!(thunk.args, :(@nospecialize($(call_expr[i]))))
            pushfirst!(body.args, Expr(:(=), p, :(parent($(argexpr(call_expr[i]))))))
            push!(body_call.args, p)
        else
            push!(thunk.args, call_expr[i])
            push!(body_call.args, argexpr(call_expr[i]))
        end
    end
    body = Expr(:block, body)
    if mcall !== nothing
        return esc(Expr(:macrocall, mcall, mline, Expr(:(=), thunk, body)))
    else
        return esc(Expr(:(=), thunk, body))
    end
end

macro defproperties(T)
    esc(quote
        Base.parent(x::$T) = getfield(x, :parent)

        @inline function Metadata.metadata(x::$T; dim=nothing, kwargs...)
            if dim === nothing
                return getfield(x, :metadata)
            else
                return metadata(parent(x); dim=dim)
            end
        end

        Base.getproperty(x::$T, k::String) = Metadata.metadata(x, k)
        @inline function Base.getproperty(x::$T, k::Symbol)
            if hasproperty(parent(x), k)
                return getproperty(parent(x), k)
            else
                return Metadata.metadata(x, k)
            end
        end

        Base.setproperty!(x::$T, k::String, v) = Metadata.metadata!(x, k, v)
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

