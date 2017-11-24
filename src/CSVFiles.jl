module CSVFiles

using TextParse, TableTraits, TableTraitsUtils, DataValues, NamedTuples
import FileIO
using HTTP
import IterableTables

struct CSVFile
    filename::String
    delim
    keywords
end

function load(f::FileIO.File{FileIO.format"CSV"}, delim=','; args...)
    return CSVFile(f.filename, delim, args)
end

function load(f::FileIO.File{FileIO.format"TSV"}, delim='\t'; args...)
    return CSVFile(f.filename, delim, args)
end

TableTraits.isiterable(x::CSVFile) = true
TableTraits.isiterabletable(x::CSVFile) = true
TableTraits.supports_get_columns_copy(x::CSVFile) = true

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

include("csv_writer.jl")

end # module
