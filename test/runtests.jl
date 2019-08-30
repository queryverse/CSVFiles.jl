using CSVFiles
using IteratorInterfaceExtensions
using TableTraits
using FileIO
using DataValues
using Test

@testset "CSVFiles" begin

@testset "basic" begin
    array = collect(load(joinpath(@__DIR__, "data.csv")))
    @test length(array) == 3
    @test array == [(Name="John",Age=34.,Children=2),(Name="Sally",Age=54.,Children=1),(Name="Jim",Age=23.,Children=0)]

    output_filename = tempname() * ".csv"

    try
        array |> save(output_filename)

        array2 = collect(load(output_filename))

        @test array == array2
    finally
        GC.gc()
        rm(output_filename)
    end
end

@testset "traits" begin
    csvf = load(joinpath(@__DIR__, "data.csv"))

    @test IteratorInterfaceExtensions.isiterable(csvf) == true
    @test TableTraits.isiterabletable(csvf) == true
    @test TableTraits.supports_get_columns_copy_using_missing(csvf) == true
end

@testset "missing values" begin
    array3 = [(a=DataValue(3),b="df\"e"),(a=DataValue{Int}(),b="something")]

    @testset "default" begin
        output_filename2 = tempname() * ".csv"

        try
            array3 |> save(output_filename2)
        finally
            rm(output_filename2)
        end
    end

    @testset "alternate" begin
        output_filename2 = tempname() * ".csv"

        try
            array3 |> save(output_filename2, nastring="")
        finally
            rm(output_filename2)
        end
    end
end

@testset "Column interface" begin
    csvf2 = load(joinpath(@__DIR__, "data.csv"))
    @test TableTraits.supports_get_columns_copy_using_missing(csvf2) == true
    data = TableTraits.get_columns_copy_using_missing(csvf2)
    @test data == (Name=["John", "Sally", "Jim"], Age=[34.,54.,23.], Children=[2,1,0])
end

@testset "Less Basic" begin
    array = [(Name="John",Age=34.,Children=2),(Name="Sally",Age=54.,Children=1),(Name="Jim",Age=23.,Children=0)]
    @testset "remote loading" begin
        rem_array = collect(load("https://raw.githubusercontent.com/queryverse/CSVFiles.jl/v0.2.0/test/data.csv"))
        @test length(rem_array) == 3
        @test rem_array == array
    end

    @testset "can round trip TSV" begin
        output_filename3 = tempname() * ".tsv"
        
        try
            array |> save(output_filename3)
            
            array4 = collect(load(output_filename3))
            @test length(array4) == 3
            @test array4 == array
        finally
            GC.gc()
            rm(output_filename3)
        end
    end
    
    @testset "no quote" begin
        output_filename4 = tempname() * ".csv"

        try
            array |> save(output_filename4, quotechar=nothing)

        finally
            GC.gc()
            rm(output_filename4)
        end
    end
end

@testset "Streams" begin
    data = [(Name="John",Age=34.,Children=2),(Name="Sally",Age=54.,Children=1),(Name="Jim",Age=23.,Children=0)]

    @testset "CSV"  begin
        stream = IOBuffer()
        mark(stream)
        fileiostream = FileIO.Stream(FileIO.format"CSV", stream)
        save(fileiostream, data)
        reset(stream)
        mark(stream)
        csvstream = load(fileiostream)
        reloaded_data = collect(csvstream)
        @test IteratorInterfaceExtensions.isiterable(csvstream)        
        @test TableTraits.isiterabletable(csvstream)
        @test TableTraits.supports_get_columns_copy_using_missing(csvstream)
        @test reloaded_data == data

        reset(stream)
        csvstream = load(fileiostream)
        reloaded_data2 = TableTraits.get_columns_copy_using_missing(csvstream)
        @test reloaded_data2 == (Name=["John", "Sally", "Jim"], Age=[34., 54., 23.], Children=[2, 1, 0])
    end

    @testset "TSV" begin
        stream = IOBuffer()
        mark(stream)
        fileiostream = FileIO.Stream(FileIO.format"TSV", stream)
        save(fileiostream, data)
        reset(stream)
        mark(stream)
        csvstream = load(fileiostream)
        reloaded_data = collect(csvstream)
        @test IteratorInterfaceExtensions.isiterable(csvstream)
        @test TableTraits.isiterabletable(csvstream)
        @test TableTraits.supports_get_columns_copy_using_missing(csvstream)
        @test reloaded_data == data

        reset(stream)
        csvstream = load(fileiostream)
        reloaded_data2 = TableTraits.get_columns_copy_using_missing(csvstream)
        @test reloaded_data2 == (Name=["John", "Sally", "Jim"], Age=[34., 54., 23.], Children=[2, 1, 0])
    end
end

@testset "Compression" begin
    data = [(Name="John",Age=34.,Children=2),(Name="Sally",Age=54.,Children=1),(Name="Jim",Age=23.,Children=0)]

    @testset "CSV" begin
        output_filename = "output.csv.gz"
        try
            save(File(format"CSV", output_filename), data)
            reloaded_data = collect(load(File(format"CSV", output_filename)))
            @test reloaded_data == data
        finally
            rm(output_filename)
        end
    end

    @testset "TSV" begin
        output_filename = "output.tsv.gz"
        try
            save(File(format"TSV", output_filename), data)
            reloaded_data = collect(load(File(format"TSV", output_filename)))
            @test reloaded_data == data
        finally
            rm(output_filename)
        end
    end
end

@testset "show" begin
    x = load(joinpath(@__DIR__, "data.csv"))

    @test sprint(show, x) == """
    3x3 CSV file
    Name  │ Age  │ Children
    ──────┼──────┼─────────
    John  │ 34.0 │ 2       
    Sally │ 54.0 │ 1       
    Jim   │ 23.0 │ 0       """

    @test sprint((stream,data)->show(stream, "text/html", data), x) ==
        "<table><thead><tr><th>Name</th><th>Age</th><th>Children</th></tr></thead><tbody><tr><td>&quot;John&quot;</td><td>34.0</td><td>2</td></tr><tr><td>&quot;Sally&quot;</td><td>54.0</td><td>1</td></tr><tr><td>&quot;Jim&quot;</td><td>23.0</td><td>0</td></tr></tbody></table>"

    @test sprint((stream,data)->show(stream, "application/vnd.dataresource+json", data), x) ==
        "{\"schema\":{\"fields\":[{\"name\":\"Name\",\"type\":\"string\"},{\"name\":\"Age\",\"type\":\"number\"},{\"name\":\"Children\",\"type\":\"integer\"}]},\"data\":[{\"Name\":\"John\",\"Age\":34.0,\"Children\":2},{\"Name\":\"Sally\",\"Age\":54.0,\"Children\":1},{\"Name\":\"Jim\",\"Age\":23.0,\"Children\":0}]}"

    @test showable("text/html", x) == true
    @test showable("application/vnd.dataresource+json", x) == true

    open("data.csv", "r") do f
        x2 = load(Stream(format"CSV", f))

        @test sprint(show, x2) == """
    3x3 CSV file
    Name  │ Age  │ Children
    ──────┼──────┼─────────
    John  │ 34.0 │ 2       
    Sally │ 54.0 │ 1       
    Jim   │ 23.0 │ 0       """

        @test sprint((stream,data)->show(stream, "text/html", data), x2) ==
            "<table><thead><tr><th>Name</th><th>Age</th><th>Children</th></tr></thead><tbody><tr><td>&quot;John&quot;</td><td>34.0</td><td>2</td></tr><tr><td>&quot;Sally&quot;</td><td>54.0</td><td>1</td></tr><tr><td>&quot;Jim&quot;</td><td>23.0</td><td>0</td></tr></tbody></table>"
    
        @test sprint((stream,data)->show(stream, "application/vnd.dataresource+json", data), x2) ==
            "{\"schema\":{\"fields\":[{\"name\":\"Name\",\"type\":\"string\"},{\"name\":\"Age\",\"type\":\"number\"},{\"name\":\"Children\",\"type\":\"integer\"}]},\"data\":[{\"Name\":\"John\",\"Age\":34.0,\"Children\":2},{\"Name\":\"Sally\",\"Age\":54.0,\"Children\":1},{\"Name\":\"Jim\",\"Age\":23.0,\"Children\":0}]}"

        @test showable("text/html", x2) == true
        @test showable("application/vnd.dataresource+json", x2) == true        
    end
    
end

@testset "savestreaming" begin
    using DataFrames

    df = DataFrame(A = 1:2:1000, B = repeat(1:10, inner=50), C = 1:500)
    df1 = df[1:5, :]
    df2 = df[6:10, :]

    # Test both csv and tsv formats
    for ext in ("csv", "tsv")
        fname = "output.$ext"
        s = savestreaming(fname, df1)
        write(s, df2)
        write(s, df2)   # add this slice twice
        close(s)
    
        new_df = DataFrame(load(fname))
        @test new_df[1:5,:]   == df1
        @test new_df[6:10,:]  == df2
        @test new_df[11:15,:] == df2

        rm(fname)
    end
end

end # Outer-most testset

