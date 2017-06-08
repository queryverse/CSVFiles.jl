using FileIO
using IterableTables
using DataFrames
using Base.Test

@testset "CSVFiles" begin

df = load(joinpath(@__DIR__, "data.csv")) |> DataFrame
@test size(df) == (3,3)
@test df[:Name] == ["John", "Sally", "Jim"]
@test df[:Age] == [34.,54.,23]
@test df[:Children] == [2,1,0]

output_filename = tempname()

df |> save(output_filename)

df2 = load(output_filename) |> DataFrame

@test df == df2

end
