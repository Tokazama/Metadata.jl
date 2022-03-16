
Base.summary(io::IO, x::MetaArray) = Base.showarg(io, x, true)
function Base.showarg(io::IO, x::MetaArray, toplevel)
    if toplevel
        print(io, Base.dims2string(length.(axes(x))), " ")
    end
    print(io, "attach_metadata(")
    Base.showarg(io, parent(x), false)
    print(io, ", ", showarg_metadata(x))
    println(io)
    metadata_summary(io, x)
    print(io, "\n)")
end


function Base.show(io::IO, ::MIME"text/plain", X::MetaArray)
    summary(io, X)
    isempty(X) && return
    Base.show_circular(io, X) && return

    if !haskey(io, :compact) && length(axes(X, 2)) > 1
        io = IOContext(io, :compact => true)
    end
    if get(io, :limit, false) && eltype(X) === Method
        io = IOContext(io, :limit => false)
    end

    if get(io, :limit, false) && Base.displaysize(io)[1] - 4 <= 0
        return print(io, " …")
    else
        println(io)
    end

    io = IOContext(io, :typeinfo => eltype(X))

    recur_io = IOContext(io, :SHOWN_SET => X)
    Base.print_array(recur_io, parent(X))
end

# this is a currently informal way of changing how showarg displays metadata in
# the argument list. If someone makes a metadata type that's long or complex they
# may want to overload this.
#
# - used within Base.showarg for MetaArray
showarg_metadata(x) = "::$(metadata_type(x))"

"""
    metadata_summary([io], x)

Creates summary readout of metadata for `x`.
"""
metadata_summary(x) = showmeta(stdout, x)
metadata_summary(io::IO, x) = print(io, "$(lpad(Char(0x2022), 3)) metadata:\n    $(x)")
function metadata_summary(io::IO, @nospecialize(x::NamedTuple))
    metadata_summary(io, pairs(x))
end
function metadata_summary(io::IO, x::AbstractDict)
    print(io, "$(lpad(Char(0x2022), 3)) metadata:")
    suppress = getmeta(x, :suppress, ())
    for (k,v) in x
        if k !== :suppress
            println(io)
            print(io, "     ")
            print(io, "$k")
            print(io, " = ")
            if in(k, suppress)
                print(io, "<suppressed>")
            else
                print(io, v)
            end
        end
    end
end

