using CSVFiles
using NamedTuples
using DataValues
using Base.Test

@testset "CSVFiles" begin

array = collect(load(joinpath(@__DIR__, "data.csv")))
@test length(array) == 3
@test array == [@NT(Name="John",Age=34.,Children=2),@NT(Name="Sally",Age=54.,Children=1),@NT(Name="Jim",Age=23.,Children=0)]

output_filename = tempname() * ".csv"

try
    array |> save(output_filename)

    array2 = collect(load(output_filename))

    @test array == array2
finally
    gc()
    rm(output_filename)
end

csvf = load(joinpath(@__DIR__, "data.csv"))

@test IteratorInterfaceExtensions.isiterable(csvf) == true
@test TableTraits.isiterabletable(csvf) == true

array3 = [@NT(a=DataValue(3),b="df\"e"),@NT(a=DataValue{Int}(),b="something")]

output_filename2 = tempname() * ".csv"

try
    array3 |> save(output_filename2)
finally
    rm(output_filename2)
end

array = collect(load("https://raw.githubusercontent.com/davidanthoff/CSVFiles.jl/v0.2.0/test/data.csv"))
@test length(array) == 3
@test array == [@NT(Name="John",Age=34.,Children=2),@NT(Name="Sally",Age=54.,Children=1),@NT(Name="Jim",Age=23.,Children=0)]

output_filename3 = tempname() * ".tsv"

try
    array |> save(output_filename3)

    array4 = collect(load(output_filename3))
    @test length(array4) == 3
    @test array4 == array
finally
    gc()
    rm(output_filename3)
end

output_filename4 = tempname() * ".csv"

try
    array |> save(output_filename4, quotechar=nothing)

finally
    gc()
    rm(output_filename4)
end

data = [@NT(Name="John",Age=34.,Children=2),@NT(Name="Sally",Age=54.,Children=1),@NT(Name="Jim",Age=23.,Children=0)]

stream = IOBuffer()
mark(stream)
fileiostream = FileIO.Stream(FileIO.format"CSV", stream)
save(fileiostream, data)
reset(stream)
csvstream = load(fileiostream)
reloaded_data = collect(csvstream)
@test IteratorInterfaceExtensions.isiterable(csvstream)
@test TableTraits.isiterabletable(csvstream)
@test reloaded_data == data

stream = IOBuffer()
mark(stream)
fileiostream = FileIO.Stream(FileIO.format"TSV", stream)
save(fileiostream, data)
reset(stream)
csvstream = load(fileiostream)
reloaded_data = collect(csvstream)
@test IteratorInterfaceExtensions.isiterable(csvstream)
@test TableTraits.isiterabletable(csvstream)
@test reloaded_data == data

end

