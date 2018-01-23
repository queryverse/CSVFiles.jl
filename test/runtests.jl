using FileIO
using TableTraits
using IterableTables
using NamedTuples
using DataFrames
using Base.Test

@testset "CSVFiles" begin

df = load(joinpath(@__DIR__, "data.csv")) |> DataFrame
@test size(df) == (3,3)
@test df[:Name] == ["John", "Sally", "Jim"]
@test df[:Age] == [34.,54.,23]
@test df[:Children] == [2,1,0]

output_filename = tempname() * ".csv"

try
    df |> save(output_filename)

    df2 = load(output_filename) |> DataFrame

    @test df == df2
finally
    gc()
    rm(output_filename)
end

output_filename = tempname() * ".tsv"

try
    df |> save(output_filename)

    df2 = load(output_filename) |> DataFrame

    @test df == df2
finally
    gc()
    rm(output_filename)
end

csvf = load(joinpath(@__DIR__, "data.csv"))

@test isiterable(csvf) == true

df3 = DataFrame(a=@data([3, NA]), b=["df\"e", "something"])

output_filename2 = tempname() * ".csv"

try
    df3 |> save(output_filename2)
finally
    rm(output_filename2)
end

df = load("https://raw.githubusercontent.com/davidanthoff/CSVFiles.jl/v0.2.0/test/data.csv") |> DataFrame
@test size(df) == (3,3)
@test df[:Name] == ["John", "Sally", "Jim"]
@test df[:Age] == [34.,54.,23]
@test df[:Children] == [2,1,0]

f = load(joinpath(@__DIR__, "data.csv"))
@test TableTraits.supports_get_columns_copy(f) == true
data = TableTraits.get_columns_copy(f)
@test data == @NT(Name=["John", "Sally", "Jim"], Age=[34.,54.,23.], Children=[2,1,0])

end
