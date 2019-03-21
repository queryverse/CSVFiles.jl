# CSVFiles

[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/queryverse/CSVFiles.jl.svg?branch=master)](https://travis-ci.org/queryverse/CSVFiles.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/2b72jbx0lepycifc/branch/master?svg=true)](https://ci.appveyor.com/project/queryverse/csvfiles-jl/branch/master)
[![CSVFiles](http://pkg.julialang.org/badges/CSVFiles_0.6.svg)](http://pkg.julialang.org/?pkg=CSVFiles)
[![codecov.io](http://codecov.io/github/queryverse/CSVFiles.jl/coverage.svg?branch=master)](http://codecov.io/github/queryverse/CSVFiles.jl?branch=master)

## Overview

This package provides load and save support for CSV Files under the
[FileIO.jl](https://github.com/JuliaIO/FileIO.jl) package.

## Installation

Use ``Pkg.add("CSVFiles")`` in Julia to install CSVFiles and its dependencies.

## Usage

### Load a CSV file

To read a CSV file into a ``DataFrame``, use the following julia code:

````julia
using CSVFiles, DataFrames

df = DataFrame(load("data.csv"))
````

To read a gzipped CSV file into a ``DataFrame``:

````julia
using CSVFiles, DataFrames

df = DataFrame(load(File(format"CSV", "data.csv.gz")))
````

The call to ``load`` returns a ``struct`` that is an [IterableTable.jl](https://github.com/queryverse/IterableTables.jl), so it can be passed to any function that can handle iterable tables, i.e. all the sinks in [IterableTable.jl](https://github.com/queryverse/IterableTables.jl). Here are some examples of materializing a CSV file into data structures that are not a ``DataFrame``:

````julia
using CSVFiles, DataTables, IndexedTables, TimeSeries, Temporal, Gadfly

# Load into a DataTable
dt = DataTable(load("data.csv"))

# Load into an IndexedTable
it = IndexedTable(load("data.csv"))

# Load into a TimeArray
ta = TimeArray(load("data.csv"))

# Load into a TS
ts = TS(load("data.csv"))

# Plot directly with Gadfly
plot(load("data.csv"), x=:a, y=:b, Geom.line)
````

One can load both local files and files that can be downloaded via either http or https. To download
from a remote URL, simply pass a URL to the ``load`` function instead of just a filename. In addition
one can also load data from an ``IO`` object, i.e. any stream. The syntax
that scenario is

````julia
df = DataFrame(load(Stream(format"CSV", io)))
````

The ``load`` function also takes a number of parameters:

````julia
load(f::FileIO.File{FileIO.format"CSV"}, delim=','; <arguments>...)
````
#### Arguments:

* ``delim``: the delimiter character
* ``spacedelim``: a ``Bool`` indicating whether columns are space delimited. If ``true``, the value of ``delim`` is ignored
* ``quotechar``: character used to quote strings, defaults to "
* ``escapechar``: character used to escape quotechar in strings. (could be the same as quotechar)
* ``nrows``: number of rows in the file. Defaults to 0 in which case we try to estimate this.
* ``skiplines_begin``: number of rows to skip at the beginning of the file.
* ``header_exists``: boolean specifying whether CSV file contains a header
* ``colnames``: manually specified column names. Could be a vector or a dictionary from Int index (the column) to String column name.
* ``colparsers``: Parsers to use for specified columns. This can be a vector or a dictionary from column name / column index (Int) to a "parser". The simplest parser is a type such as Int, Float64. It can also be a dateformat"...", see CustomParser if you want to plug in custom parsing behavior
* ``type_detect_rows``: number of rows to use to infer the initial colparsers defaults to 20.

These are simply the arguments from [TextParse.jl](https://github.com/JuliaComputing/TextParse.jl), which is used under the hood to read CSV files.

### Save a CSV file

The following code saves any iterable table as a CSV file:
````julia
using CSVFiles

save("output.csv", it)
````
This will work as long as ``it`` is any of the types supported as sources in [IterableTables.jl](https://github.com/queryverse/IterableTables.jl).

Compressed CSV files can be created by specifying the ``.gz`` file extension:

````julia
using CSVFiles

save(File(format"CSV", "output.csv.gz"), df)
````

One can also save into an arbitrary stream:
````julia
using CSVFiles

save(Stream(format"CSV", io), it)
````

The ``save`` function takes a number of arguments:
````julia
save(f::FileIO.File{FileIO.format"CSV"}, data; delim=',', quotechar='"', escapechar='"', nastring="NA", header=true)
````

#### Arguments

* ``delim``: the delimiter character, defaults to ``,``.
* ``quotechar``: character used to quote strings, defaults to ``"``.
* ``escapechar``: character used to escape ``quotechar`` in strings, defaults to ``\``.
* ``nastring``: string to insert in the place of missing values, defaults to ``NA``.
* ``header``: whether a header should be written, defaults to ``true.

### Using the pipe syntax

Both ``load`` and ``save`` also support the pipe syntax. For example, to load a CSV file into a ``DataFrame``, one can use the following code:

````julia
using CSVFiles, DataFrame

df = load("data.csv") |> DataFrame
````

To save an iterable table, one can use the following form:

````julia
using CSVFiles, DataFrame

df = # Aquire a DataFrame somehow

df |> save("output.csv")
````

The pipe syntax is especially useful when combining it with [Query.jl](https://github.com/queryverse/Query.jl) queries, for example one can easily load a CSV file, pipe it into a query, then pipe it to the ``save`` function to store the results in a new file.
