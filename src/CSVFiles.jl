module CSVFiles

using TextParse, IteratorInterfaceExtensions, TableTraits, TableTraitsUtils,
    DataValues, FileIO, HTTP, TableShowUtils, CodecZlib
import IterableTables

export load, save, File, @format_str

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

function Base.show(io::IO, source::CSVFile)
    TableShowUtils.printtable(io, getiterator(source), "CSV file")
end

function Base.show(io::IO, ::MIME"text/html", source::CSVFile)
    TableShowUtils.printHTMLtable(io, getiterator(source))
end

Base.showable(::MIME"text/html", source::CSVFile) = true

function Base.show(io::IO, ::MIME"application/vnd.dataresource+json", source::CSVFile)
    TableShowUtils.printdataresource(io, getiterator(source))
end

Base.showable(::MIME"application/vnd.dataresource+json", source::CSVFile) = true

function Base.show(io::IO, source::CSVStream)
    TableShowUtils.printtable(io, getiterator(source), "CSV file")
end

function Base.show(io::IO, ::MIME"text/html", source::CSVStream)
    TableShowUtils.printHTMLtable(io, getiterator(source))
end

Base.showable(::MIME"text/html", source::CSVStream) = true

function Base.show(io::IO, ::MIME"application/vnd.dataresource+json", source::CSVStream)
    TableShowUtils.printdataresource(io, getiterator(source))
end

Base.showable(::MIME"application/vnd.dataresource+json", source::CSVStream) = true

function fileio_load(f::FileIO.File{FileIO.format"CSV"}, deprecated_delim=nothing; delim=deprecated_delim===nothing ? ',' : deprecated_delim, args...)   
    if deprecated_delim!==nothing
        deprecated_delim!=delim && error("deprecated_delim and delim can not both be used at the same time.")
        Base.depwarn("The positional `delim` keyword in the `load` function is deprecated. Instead use the keyword argument `delim`.", :CSVFiles)
    end

    return CSVFile(f.filename, delim, args)
end

function fileio_load(f::FileIO.File{FileIO.format"TSV"}, deprecated_delim=nothing; delim=deprecated_delim===nothing ? '\t' : deprecated_delim, args...)
    if deprecated_delim!==nothing
        deprecated_delim!=delim && error("deprecated_delim and delim can not both be used at the same time.")
        Base.depwarn("The positional `delim` keyword in the `load` function is deprecated. Instead use the keyword argument `delim`.", :CSVFiles)
    end

    return CSVFile(f.filename, delim, args)
end

function fileio_load(s::FileIO.Stream{FileIO.format"CSV"}, deprecated_delim=nothing; delim=deprecated_delim===nothing ? ',' : deprecated_delim, args...)
    if deprecated_delim!==nothing
        deprecated_delim!=delim && error("deprecated_delim and delim can not both be used at the same time.")
        Base.depwarn("The positional `delim` keyword in the `load` function is deprecated. Instead use the keyword argument `delim`.", :CSVFiles)
    end

    return CSVStream(s.io, delim, args)
end

function fileio_load(s::FileIO.Stream{FileIO.format"TSV"}, deprecated_delim=nothing; delim=deprecated_delim===nothing ? '\t' : deprecated_delim, args...)
    if deprecated_delim!==nothing
        deprecated_delim!=delim && error("deprecated_delim and delim can not both be used at the same time.")
        Base.depwarn("The positional `delim` keyword in the `load` function is deprecated. Instead use the keyword argument `delim`.", :CSVFiles)
    end

    return CSVStream(s.io, delim, args)
end

IteratorInterfaceExtensions.isiterable(x::CSVFile) = true
TableTraits.isiterabletable(x::CSVFile) = true
TableTraits.supports_get_columns_copy(x::CSVFile) = true
TableTraits.supports_get_columns_copy_using_missing(x::CSVFile) = true

IteratorInterfaceExtensions.isiterable(x::CSVStream) = true
TableTraits.isiterabletable(x::CSVStream) = true
TableTraits.supports_get_columns_copy(x::CSVStream) = true
TableTraits.supports_get_columns_copy_using_missing(x::CSVStream) = true

function _loaddata(file; kwargs...)
    if startswith(file.filename, "https://") || startswith(file.filename, "http://")
        response = HTTP.get(file.filename)
        data = String(response.body)
        return TextParse._csvread(data, file.delim; stringarraytype=Array, file.keywords..., kwargs...)
    else
        return csvread(file.filename, file.delim; stringarraytype=Array, file.keywords..., kwargs...)
    end
end

# ---------------------------------------------------------------------------
# TextParse missing-value sink for DataValueArray: the parser writes
# DataValue-based columns directly, so no Union{Missing,T} array is ever
# allocated on this path (see TextParse's `missingarraytype`).
# ---------------------------------------------------------------------------

TextParse.allocmissing(::Type{DataValueArray}, ::Type{T}, N) where {T} =
    DataValueArray{T,1}(Vector{T}(undef, N), fill(true, N))

TextParse.setmissing!(col::DataValueArray, i) = (col.isna[i] = true; nothing)

TextParse.ismissingcolumn(::DataValueArray) = true

TextParse.colmatchestype(col::DataValueArray{T,1}, ::Type{S}) where {T,S} =
    S == Union{Missing,T}

function TextParse.promotemissing(::Type{DataValueArray}, col::Array{Missing}, rowno, ::Type{T}) where {T}
    S = Base.nonmissingtype(T)
    S === Any && (S = Missing)
    return DataValueArray{S,1}(Vector{S}(undef, length(col)), fill(true, length(col)))
end

function TextParse.promotemissing(::Type{DataValueArray}, col::Vector{S}, rowno, ::Type{T}) where {S,T}
    VT = Base.nonmissingtype(T)
    values = Vector{VT}(undef, length(col))
    isna = fill(true, length(col))
    for i = 1:rowno
        values[i] = col[i]
        isna[i] = false
    end
    return DataValueArray{VT,1}(values, isna)
end

function TextParse.promotemissing(::Type{DataValueArray}, col::DataValueArray{S,1}, rowno, ::Type{T}) where {S,T}
    VT = Base.nonmissingtype(T)
    VT === S && return col
    values = Vector{VT}(undef, length(col.values))
    for i = 1:rowno
        col.isna[i] || (values[i] = col.values[i])
    end
    return DataValueArray{VT,1}(values, copy(col.isna))
end

function IteratorInterfaceExtensions.getiterator(file::CSVFile)
    res = _loaddata(file)

    it = TableTraitsUtils.create_tableiterator([i for i in res[1]], [Symbol(i) for i in res[2]])

    return it
end

function TableTraits.get_columns_copy(file::CSVFile)
    columns, colnames = _loaddata(file; missingarraytype=DataValueArray)
    return NamedTuple{(Symbol.(colnames)...,), Tuple{typeof.(columns)...}}((columns...,))
end

function TableTraits.get_columns_copy_using_missing(file::CSVFile)
    columns, colnames = _loaddata(file)
     return NamedTuple{(Symbol.(colnames)...,), Tuple{typeof.(columns)...}}((columns...,))
end

function IteratorInterfaceExtensions.getiterator(s::CSVStream)
    res = TextParse.csvread(s.io, s.delim; stringarraytype=Array, s.keywords...)

    it = TableTraitsUtils.create_tableiterator([i for i in res[1]], [Symbol(i) for i in res[2]])

    return it
end

function TableTraits.get_columns_copy(s::CSVStream)
    columns, colnames = TextParse.csvread(s.io, s.delim; stringarraytype=Array, s.keywords..., missingarraytype=DataValueArray)
    return NamedTuple{(Symbol.(colnames)...,), Tuple{typeof.(columns)...}}((columns...,))
end

function TableTraits.get_columns_copy_using_missing(s::CSVStream)
    columns, colnames = TextParse.csvread(s.io, s.delim; stringarraytype=Array, s.keywords...)
    return NamedTuple{(Symbol.(colnames)...,), Tuple{typeof.(columns)...}}((columns...,))
end

function Base.collect(x::CSVFile)
    return collect(getiterator(x))
end

function Base.collect(x::CSVStream)
    return collect(getiterator(x))
end

include("csv_writer.jl")

end # module
