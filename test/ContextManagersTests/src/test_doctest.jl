module TestDoctest

using Documenter
using Test
using ContextManagers

function test()
    if VERSION < v"1.5"
        @test_broken false
        return
    end
    doctest(ContextManagers; manual = true)
end

end  # module
