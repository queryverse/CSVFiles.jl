function _writevalue(io::IO, value::String, delim, quotechar, escapechar, missingstring)
    if isnull(quotechar)
        print(io, value)
    else
        quotechar_unpacked = get(quotechar)
        print(io, quotechar_unpacked)
        for c in value
            if c==quotechar_unpacked || c==escapechar
                print(io, escapechar)
            end
            print(io, c)
        end
        print(io, quotechar_unpacked)
    end
end

function _writevalue(io::IO, value, delim, quotechar, escapechar, missingstring)
    print(io, value)
end

function _writevalue{T}(io::IO, value::DataValue{T}, delim, quotechar, escapechar, missingstring)
    if isnull(value)
        print(io, missingstring)
    else
        _writevalue(io, get(value), delim, quotechar, escapechar, missingstring)
    end
end


@generated function _writecsv{T}(io::IO, it, ::Type{T}, delim, quotechar, escapechar, missingstring)
    col_names = fieldnames(T)
    n = length(col_names)
    push_exprs = Expr(:block)
    for i in 1:n
        push!(push_exprs.args, :( _writevalue(io, i.$(col_names[i]), delim, quotechar, escapechar, missingstring) ))
        if i<n
            push!(push_exprs.args, :( print(io, delim ) ))
        end
    end
    push!(push_exprs.args, :( println(io) ))

    quote
        for i in it
            $push_exprs
        end
    end
end

function _save(io, data; delim=',', quotechar='"', escapechar='\\', missingstring="NA", header=true)
    isiterabletable(data) || error("Can't write this data to a CSV file.")

    it = getiterator(data)
    colnames = TableTraits.column_names(it)

    quotechar_internal = quotechar==nothing ? Nullable{Char}() : Nullable{Char}(quotechar)

    if header
        if isnull(quotechar_internal)
            join(io,[string(colname) for colname in colnames],delim)
        else
            join(io,["$(quotechar)" *replace(string(colname), quotechar, "$(escapechar)$(quotechar)") * "$(quotechar)" for colname in colnames],delim)
        end
        println(io)
    end
    _writecsv(io, it, eltype(it), delim, quotechar_internal, escapechar, missingstring)
end

function _save(filename::AbstractString, data; delim=',', quotechar='"', escapechar='\\', missingstring="NA", header=true)
    isiterabletable(data) || error("Can't write this data to a CSV file.")

    open(filename, "w") do io
        _save(io, data, delim=delim, quotechar=quotechar, escapechar=escapechar, missingstring=missingstring,  header=header)
    end
end

for (FMT, odelim) in ((:CSV, ","), (:TSV, "\t"))
    for (FF, field) in ((:File, :filename), (:Stream, :io))
        @eval function fileio_save(f::FileIO.$FF{FileIO.DataFormat{$(Meta.quot(FMT))}}, data; delim=$odelim, quotechar='"', escapechar='\\', missingstring="NA", header=true)
            return _save(f.$field, data, delim=delim, quotechar=quotechar, escapechar=escapechar, missingstring=missingstring, header=header)
        end
    end
end

