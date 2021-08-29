module TestCore

using Test
using ContextManagers.++

function test_ignoreerror()
    @with(_ = IgnoreError()) do
        error("error")
    end
    @test true
end

function test_closingwith()
    calledwith = []
    @with(
        int = ContextManagers.closingwith(111) do x
            push!(calledwith, x)
        end,
        io = ContextManagers.closing(IOBuffer()),
    ) do
        @test int == 111
        @test io isa IOBuffer
    end
    @test calledwith == [111]
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
        int = ContextManagers.closingwith(111) do x
            push!(calledwith, x)
        end,
        ContextManagers.closingwith(nothing) do _
            error("error")
        end,
    ) do
        @test int == 111
    end
    @test calledwith == [111]
end

end  # module
