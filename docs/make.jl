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

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
