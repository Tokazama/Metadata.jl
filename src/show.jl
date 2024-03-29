
"""
    metadata_summary([io], x)

Creates summary readout of metadata for `x`.
"""
metadata_summary(x) = metadata_summary(stdout, x)
metadata_summary(io::IO, x) = print(io, x)
metadata_summary(io::IO, @nospecialize(x::NamedTuple)) = metadata_summary(io, pairs(x))
function metadata_summary(io::IO, @nospecialize(x::AbstractDict))
    print(io, "$(lpad(Char(0x2022), 3)) metadata:")
    suppress = get(x, :suppress, no_data)
    for (k,v) in pairs(x)
        if k !== :suppress
            print(io, "\n     $(k) = ")
            if in(k, suppress)
                print(io, "<suppressed>")
            else
                print(io, v)
            end
        end
    end
end


# this is a currently informal way of changing how showarg displays metadata in
# the argument list. If someone makes a metadata type that's long or complex they
# may want to overload this.
#
# - used within Base.showarg for MetaArray

function Base.show(io::IO, ::MIME"text/plain", @nospecialize(X::MetaArray))
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

Base.summary(io::IO, @nospecialize(x::MetaArray)) = Base.showarg(io, x, true)
function Base.showarg(io::IO, @nospecialize(x::MetaArray), toplevel)
    if toplevel
        print(io, Base.dims2string(length.(axes(x))), " ")
    end
    print(io, "attach_metadata(")
    Base.showarg(io, parent(x), false)
    print(io, ", ", "::$(metadata_type(x))")
    println(io)
    metadata_summary(io, metadata(x))
    print(io, "\n)")
end
function Base.show(io::IO, m::MIME"text/plain", @nospecialize(x::MetaUnitRange))
    if haskey(io, :compact)
        show(io, parent(x))
    else
        print(io, "attach_metadata(")
        print(io, parent(x))
        print(io, ", ", "::$(metadata_type(x))", ")\n")
        Metadata.metadata_summary(io, metadata(x))
    end
end

function Base.show(io::IO, ::MIME"text/plain", @nospecialize(x::MetaStruct))
    print(io, "attach_metadata($(parent(x)), ::$(metadata_type(x)))\n")
    Metadata.metadata_summary(io, metadata(x))
end

