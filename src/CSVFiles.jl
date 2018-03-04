module CSVFiles

using TextParse, IteratorInterfaceExtensions, TableTraits, TableTraitsUtils,
    DataValues, NamedTuples
import FileIO
using HTTP
import IterableTables

struct CSVFile
    filename::String
    delim
    keywords
end

struct CSVStream
    io
    delim
    keywords
end

function load(f::FileIO.File{FileIO.format"CSV"}, delim=','; args...)
    return CSVFile(f.filename, delim, args)
end

function load(f::FileIO.File{FileIO.format"TSV"}, delim='\t'; args...)
    return CSVFile(f.filename, delim, args)
end

function load(s::FileIO.Stream{FileIO.format"CSV"}, delim=','; args...)
    return CSVStream(s.io, delim, args)
end

function load(s::FileIO.Stream{FileIO.format"TSV"}, delim='\t'; args...)
    return CSVStream(s.io, delim, args)
end

IteratorInterfaceExtensions.isiterable(x::CSVFile) = true
TableTraits.isiterabletable(x::CSVFile) = true
TableTraits.supports_get_columns_copy(x::CSVFile) = true
IteratorInterfaceExtensions.isiterable(x::CSVStream) = true
TableTraits.isiterabletable(x::CSVStream) = true
TableTraits.supports_get_columns_copy(x::CSVStream) = true

function _loaddata(file)
    if startswith(file.filename, "https://") || startswith(file.filename, "http://")
        response = HTTP.get(file.filename)
        data = String(take!(response))
        return TextParse._csvread(data, file.delim, file.keywords...)
    else
        return csvread(file.filename, file.delim; file.keywords...)
    end
end

function TableTraits.getiterator(file::CSVFile)
    res = _loaddata(file)

    it = TableTraitsUtils.create_tableiterator([i for i in res[1]], [Symbol(i) for i in res[2]])

    return it
end

function TableTraits.get_columns_copy(file::CSVFile)
    columns, colnames = _loaddata(file)

    T = eval(:(@NT($(Symbol.(colnames)...)))){typeof.(columns)...}

    return T(columns...)
end

function TableTraits.getiterator(s::CSVStream)
    res = TextParse.csvread(s.io, s.delim, s.keywords...)

    it = TableTraitsUtils.create_tableiterator([i for i in res[1]], [Symbol(i) for i in res[2]])

    return it
end

function TableTraits.get_columns_copy(s::CSVStream)
    columns, colnames = TextParse.csvread(s.io, s.delim, s.keywords...)

    T = eval(:(@NT($(Symbol.(colnames)...)))){typeof.(columns)...}

    return T(columns...)
end

function Base.collect(x::CSVFile)
    return collect(getiterator(x))
end

function Base.collect(x::CSVStream)
    return collect(getiterator(x))
end

include("csv_writer.jl")

end # module
