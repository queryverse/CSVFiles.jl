module CSVFiles

using TextParse, TableTraits, TableTraitsImplementationHelpers, DataValues
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

TableTraits.isiterable(x::CSVFile) = true
TableTraits.isiterabletable(x::CSVFile) = true

function TableTraits.getiterator(file::CSVFile)
    if startswith(file.filename, "https://") || startswith(file.filename, "http://")
        response = HTTP.get(file.filename)
        data = String(take!(response))
        res = TextParse._csvread(data, file.delim, file.keywords...)
    else
        res = csvread(file.filename, file.delim; file.keywords...)
    end

    it = TableTraitsImplementationHelpers.create_tableiterator([i for i in res[1]], [Symbol(i) for i in res[2]])

    return it
end

include("csv_writer.jl")

end # module
