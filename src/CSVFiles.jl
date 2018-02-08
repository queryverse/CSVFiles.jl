module CSVFiles

using TextParse, IteratorInterfaceExtensions, TableTraits, TableTraitsUtils,
    DataValues
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

IteratorInterfaceExtensions.isiterable(x::CSVStream) = true
TableTraits.isiterabletable(x::CSVStream) = true

function TableTraits.getiterator(file::CSVFile)
    if startswith(file.filename, "https://") || startswith(file.filename, "http://")
        response = HTTP.get(file.filename)
        data = String(response.body)
        res = TextParse._csvread(data, file.delim, file.keywords...)
    else
        res = csvread(file.filename, file.delim; file.keywords...)
    end

    it = TableTraitsUtils.create_tableiterator([i for i in res[1]], [Symbol(i) for i in res[2]])

    return it
end

function TableTraits.getiterator(s::CSVStream)
    res = TextParse.csvread(s.io, s.delim, s.keywords...)

    it = TableTraitsUtils.create_tableiterator([i for i in res[1]], [Symbol(i) for i in res[2]])

    return it
end

function Base.collect(x::CSVFile)
    return collect(getiterator(x))
end

function Base.collect(x::CSVStream)
    return collect(getiterator(x))
end

include("csv_writer.jl")

end # module
