function _writevalue(io::IO, value::String, delim, quote_char, escape_char)
    if isnull(quote_char)
        print(io, value)
    else
        quote_char_unpacked = get(quote_char)
        print(io, quote_char_unpacked)
        for c in value
            if c==quote_char_unpacked
                print(io, escape_char)
            end
            print(io, c)
        end
        print(io, quote_char_unpacked)
    end
end

function _writevalue(io::IO, value, delim, quote_char, escape_char)
    print(io, value)
end

function _writevalue{T}(io::IO, value::DataValue{T}, delim, quote_char, escape_char)
    if isnull(value)
        print(io, "NA")
    else
        _writevalue(io, get(value), delim, quote_char, escape_char)
    end
end


@generated function _writecsv{T}(io::IO, it, ::Type{T}, delim, quote_char, escape_char)
    col_names = fieldnames(T)
    n = length(col_names)
    push_exprs = Expr(:block)
    for i in 1:n
        push!(push_exprs.args, :( _writevalue(io, i.$(col_names[i]), delim, quote_char, escape_char) ))
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

function save(f::FileIO.File{FileIO.format"CSV"}, data; delim=',', quote_char='"', escape_char='\\', header=true)
    isiterabletable(data) || error("Can't write this data to a CSV file.")

    it = getiterator(data)
    colnames = IterableTables.column_names(it)

    quote_char_internal = quote_char==nothing ? Nullable{Char}() : Nullable{Char}(quote_char)

    open(f.filename, "w") do io
        if header
            if isnull(quote_char_internal)
                join(io,[string(colname) for colname in colnames],delim)
            else
                join(io,["$(quote_char)" *replace(string(colname), quote_char, "$(escape_char)$(quote_char)") * "$(quote_char)" for colname in colnames],delim)
            end
            println(io)
        end
        _writecsv(io, it, eltype(it), delim, quote_char_internal, escape_char)
    end    
end
