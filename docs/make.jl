
using Documenter
using Metadata

makedocs(;
    modules=[Metadata],
    format=Documenter.HTML(),
    pages=[
        "Metadata" => "index.md",
   ],
    repo="https://github.com/Tokazama/Metadata.jl/blob/{commit}{path}#L{line}",
    sitename="Metadata.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/Metadata.jl.git",
)

