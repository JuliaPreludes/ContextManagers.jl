module TestCore

using Test
using ContextManagers.++

function test_ignoreerror()
    @with(_ = IgnoreError()) do
        error("error")
    end
    @test true
end

function test_onexit()
    calledwith = []
    @with(
        int = onexit(111) do x
            push!(calledwith, x)
        end,
        io = closing(IOBuffer()),
    ) do
        @test int == 111
        @test io isa IOBuffer
    end
    @test calledwith == [111]
end

function test_non_assignment()
    calledwith = []
    xs = [
        onexit(111) do x
            push!(calledwith, x)
        end,
        onexit(222) do x
            push!(calledwith, x)
        end,
    ]
    @with(xs[2], xs[1]) do
    end
    @test calledwith == [111, 222]
end

function check_onfail(witherror)
    calledwith = []
    thrown = try
        @with(
            int = onfail(111) do x
                push!(calledwith, x)
            end,
            io = closing(IOBuffer()),
        ) do
            @test int == 111
            @test io isa IOBuffer
            witherror && error("error")
        end
        false
    catch
        true
    end
    return calledwith, thrown
end

function test_onfail()
    @test check_onfail(false) == ([], false)
    @test check_onfail(true) == ([111], true)
end

function test_many()
    l1 = ReentrantLock()
    l2 = ReentrantLock()
    @with(l1, l2, ch1 = Channel(1), ch2 = Channel(1)) do
        @test l1 isa ReentrantLock
        @test l2 isa ReentrantLock
        @test ch1 isa Channel
        @test ch2 isa Channel
    end
end

function test_many_function()
    l1 = ReentrantLock()
    l2 = ReentrantLock()
    ContextManagers.with(l1, l2, Channel(1), Channel(1)) do l1, l2, ch1, ch2
        @test l1 isa ReentrantLock
        @test l2 isa ReentrantLock
        @test ch1 isa Channel
        @test ch2 isa Channel
    end
end

function test_error_in_exit()
    calledwith = []
    @with(
        IgnoreError(),
        int = onexit(111) do x
            push!(calledwith, x)
        end,
        onexit(nothing) do _
            error("error")
        end,
    ) do
        @test int == 111
    end
    @test calledwith == [111]
end

end  # module
