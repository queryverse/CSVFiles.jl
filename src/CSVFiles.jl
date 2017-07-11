module CSVFiles

using TextParse, IterableTables, DataValues, DataTables
import FileIO

struct CSVFile
    filename::String
    delim
    keywords
end

struct CSVStream
    stream
    delim
    keywords
end

function load(f::FileIO.File{FileIO.format"CSV"}, delim=','; args...)
    return CSVFile(f.filename, delim, args)
end

function load(s::FileIO.Stream{FileIO.format"CSV"}, delim=','; args...)
    return CSVStream(s.io, delim, args)
end

IterableTables.isiterable(x::CSVFile) = true
IterableTables.isiterabletable(x::CSVFile) = true

IterableTables.isiterable(x::CSVStream) = true
IterableTables.isiterabletable(x::CSVStream) = true

function IterableTables.getiterator(file::CSVFile)
    res = csvread(file.filename, file.delim; file.keywords...)

    dt = DataTable([i for i in res[1]], [Symbol(i) for i in res[2]])

    it = getiterator(dt)

    return it
end

function IterableTables.getiterator(stream::CSVStream)
    res = csvread(stream.stream, stream.delim; stream.keywords...)

    dt = DataTable([i for i in res[1]], [Symbol(i) for i in res[2]])

    it = getiterator(dt)

    return it
end

include("csv_writer.jl")

end # module
