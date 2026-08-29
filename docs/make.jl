using Documenter, CSVFiles

makedocs(
	modules = [CSVFiles],
	sitename = "CSVFiles.jl",
	format = Documenter.HTML(analytics = "UA-132838790-1"),
	warnonly = [:missing_docs],
	pages = [
        "Introduction" => "index.md"
    ]
)

deploydocs(
    repo = "github.com/queryverse/CSVFiles.jl.git"
)
