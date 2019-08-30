function _writevalue(io::IO, value::String, delim, quotechar::Nothing, escapechar, nastring)
    print(io, value)
end

function _writevalue(io::IO, value::String, delim, quotechar, escapechar, nastring)
    print(io, quotechar)
    for c in value
        if c==quotechar || c==escapechar
            print(io, escapechar)
        end
        print(io, c)
    end
    print(io, quotechar)
end

function _writevalue(io::IO, value, delim, quotechar, escapechar, nastring)
    print(io, value)
end

function _writevalue(io::IO, value::DataValue{T}, delim, quotechar, escapechar, nastring) where {T}
    if isna(value)
        print(io, nastring)
    else
        _writevalue(io, get(value), delim, quotechar, escapechar, nastring)
    end
end


@generated function _writecsv(io::IO, it, ::Type{T}, delim, quotechar, escapechar, nastring) where {T}
    col_names = fieldnames(T)
    n = length(col_names)
    push_exprs = Expr(:block)
    for i in 1:n
        push!(push_exprs.args, :( _writevalue(io, i.$(col_names[i]), delim, quotechar, escapechar, nastring) ))
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

function _save(io, data; delim=',', quotechar='"', escapechar='"', nastring="NA", header=true)
    isiterabletable(data) || error("Can't write this data to a CSV file.")

    it = getiterator(data)
    colnames = collect(eltype(it).parameters[1])

    if header
        if quotechar===nothing
            join(io,[string(colname) for colname in colnames],delim)
        else
            join(io,["$(quotechar)" * replace(string(colname), quotechar => "$(escapechar)$(quotechar)") * "$(quotechar)" for colname in colnames],delim)
        end
        println(io)
    end
    _writecsv(io, it, eltype(it), delim, quotechar, escapechar, nastring)
end

function _save(filename::AbstractString, data; delim=',', quotechar='"', escapechar='"', nastring="NA", header=true)
    isiterabletable(data) || error("Can't write this data to a CSV file.")

    ext = last(split(filename, '.'))

    if ext == "gz" # Gzipped
        open(GzipCompressorStream, filename, "w") do io
            _save(io, data, delim=delim, quotechar=quotechar, escapechar=escapechar, nastring=nastring,  header=header)
        end
    else
        open(filename, "w") do io
            _save(io, data, delim=delim, quotechar=quotechar, escapechar=escapechar, nastring=nastring,  header=header)
        end
    end
end



function fileio_save(f::FileIO.File{FileIO.format"CSV"}, data; delim=',', quotechar='"', escapechar='"', nastring="NA", header=true)
    return _save(f.filename, data, delim=delim, quotechar=quotechar, escapechar=escapechar, nastring=nastring, header=header)
end

function fileio_save(f::FileIO.File{FileIO.format"TSV"}, data; delim='\t', quotechar='"', escapechar='"', nastring="NA", header=true)
    return _save(f.filename, data, delim=delim, quotechar=quotechar, escapechar=escapechar, nastring=nastring, header=header)
end

function fileio_save(s::FileIO.Stream{FileIO.format"CSV"}, data; delim=',', quotechar='"', escapechar='"', nastring="NA", header=true)
    return _save(s.io, data, delim=delim, quotechar=quotechar, escapechar=escapechar, nastring=nastring, header=header)
end

function fileio_save(s::FileIO.Stream{FileIO.format"TSV"}, data; delim='\t', quotechar='"', escapechar='"', nastring="NA", header=true)
    return _save(s.io, data, delim=delim, quotechar=quotechar, escapechar=escapechar, nastring=nastring, header=header)
end

#
# Streaming version writes header (if any) on first call, then appends on subsequent calls.
#
const CSV_or_TSV = Union{FileIO.format"CSV", FileIO.format"TSV"}

_delim(T) = T <: FileIO.format"CSV" ? ',' : '\t'

mutable struct CSVFileSaveStream{T}
    io::T
    first_data_written::Bool
    delim::Char
    quotechar::Char
    escapechar::Char
    nastring::AbstractString
    header::Bool
end
                            
function fileio_savestreaming(f::FileIO.File{T}, data=nothing; delim=_delim(T), quotechar='"', escapechar='"', nastring="NA", 
                              header=true) where T <: CSV_or_TSV
    io = open(f.filename, "w")

    if data!==nothing
        _save(io, data; delim=delim, quotechar=quotechar, escapechar=escapechar, nastring=nastring, header=header)
    end

    return CSVFileSaveStream(io, data!==nothing, delim, quotechar, escapechar, nastring, header)
end

function fileio_savestreaming(s::FileIO.Stream{T}, data=nothing; delim=_delim(T), quotechar='"', escapechar='"', nastring="NA", 
                              header=false) where T <: CSV_or_TSV

    if data!==nothing
        _save(s.io, data; delim=delim, quotechar=quotechar, escapechar=escapechar, nastring=nastring, header=header)
    end
                        
    return CSVFileSaveStream(s.io, data!==nothing, delim, quotechar, escapechar, nastring, header)
end

function Base.write(s::CSVFileSaveStream, data)
    _save(s.io, data; delim=s.delim, quotechar=s.quotechar, escapechar=s.escapechar, nastring=s.nastring, header=s.first_data_written ? false : header)
end

function Base.close(s::CSVFileSaveStream)
    close(s.io)
end
