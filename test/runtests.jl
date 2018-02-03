using FileIO
using CSVFiles
using TableTraits
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

@test isiterable(csvf) == true

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

end
