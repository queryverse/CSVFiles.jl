module CSVFiles

using TextParse, IterableTables, DataValues
import FileIO
using HTTP

struct CSVFile
    filename::String
    delim
    keywords
end

function load(f::FileIO.File{FileIO.format"CSV"}, delim=','; args...)
    return CSVFile(f.filename, delim, args)
end

IterableTables.isiterable(x::CSVFile) = true
IterableTables.isiterabletable(x::CSVFile) = true

function IterableTables.getiterator(file::CSVFile)
    if startswith(file.filename, "https://") || startswith(file.filename, "http://")
        response = HTTP.get(file.filename)
        data = String(take!(response))
        res = TextParse._csvread(data, file.delim, file.keywords...)
    else
        res = csvread(file.filename, file.delim; file.keywords...)
    end

    it = IterableTables.create_tableiterator([i for i in res[1]], [Symbol(i) for i in res[2]])

    return it
end

include("csv_writer.jl")

end # module
