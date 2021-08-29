using Documenter
using ContextManagers

makedocs(
    sitename = "ContextManagers",
    format = Documenter.HTML(),
    modules = [ContextManagers],
    doctest = false,  # tested via test/runtests.jl
    checkdocs = :exports,  # ignore complains about non-exported docstrings
    strict = lowercase(get(ENV, "CI", "false")) == "true",
)

deploydocs(
    repo = "github.com/tkf/ContextManagers.jl",
    push_preview = true,
    # See: https://juliadocs.github.io/Documenter.jl/stable/lib/public/#Documenter.deploydocs
)
