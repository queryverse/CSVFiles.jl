using Documenter, CSVFiles

makedocs(
	modules = [CSVFiles],
	sitename = "CSVFiles.jl",
	analytics="UA-132838790-1",
	pages = [
        "Introduction" => "index.md"
    ]
)

deploydocs(
    repo = "github.com/queryverse/CSVFiles.jl.git"
)
