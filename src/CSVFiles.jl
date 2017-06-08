module CSVFiles

using TextParse, IterableTables, DataValues, DataTables
import FileIO

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
    res = csvread(file.filename, file.delim; file.keywords...)

    dt = DataTable([i for i in res[1]], [Symbol(i) for i in res[2]])

    it = getiterator(dt)

    return it
end

include("csv_writer.jl")

end # module
