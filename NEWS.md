# CSVFiles.jl v0.16.1
* Fix a bug in the write functionality
* Add proper bounds to all dependencies

# CSVFiles.jl v0.16.0
* Drop julia 0.7 support
* Migrate to Project.toml
* Add streaming support
* Make delim a keyword argument for loading

# CSVFiles.jl v0.15.0
* Add support for writing gz compressed files

# CSVFiles.jl v0.14.0
* Add support for 'application/vnd.dataresource+json' MIME type

# CSVFiles.jl v0.13.0
* Never use StringVector, always use Vector{String} instead

# CSVFiles.jl v0.12.0
* Export FileIO.File and FileIO.@format_str

# CSVFiles.jl v0.11.0
* Change default escapechar for save to "

# CSVFiles.jl v0.10.0
* Add support for the get_columns_copy_using_missing interface

# CSVFiles.jl v0.9.1
* Fix remaining julia 1.0 compat issues

# CSVFiles.jl v0.9.0
* Drop julia 0.6 support, add julia 0.7 support

# CSVFiles.jl v0.8.0
* Add nastring option to save

# CSVFiles.jl v0.7.0
* Add show method

# CSVFiles.jl v0.6.0
* Export load and save from FileIO

# CSVFiles.jl v0.5.1
* Samll bug fixes

# CSVFiles.jl v0.5.0
* Support for FileIO Stream objects

# CSVFiles.jl v0.4.1
* Various small bug fixes

# CSVFiles.jl v0.4.0
* Add support for tsv files

# CSVFiles.jl v0.3.1
* Add dependency on IterableTables.jl back into the package

# CSVFiles.jl v0.3.0
* Move to TableTraits.jl

# CSVFiles.jl v0.2.0
* Add support for http and https downloads via a URL
* Remove DataTables.jl dependency

# CSVFiles.jl v0.1.0
* Add support for omitting the quote_char in csv writing operations
* Rename quote_char to quotechar for CSV write
* Rename escape_char to escapechar for CSV write

# CSVFiles.jl v0.0.1
* Initial release
