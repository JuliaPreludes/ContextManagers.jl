module TestDoctest

using Documenter
using Test
using ContextManagers

function test()
    doctest(ContextManagers; manual = true)
end

end  # module
