module TestBase

using Test
using ContextManagers.++

function test_iobuffer()
    @with(io = IOBuffer()) do
        @test io isa IOBuffer
    end
    @test true
end

function test_lock()
    l = ReentrantLock()
    @with(l) do
        @test l isa ReentrantLock
    end
    @sync begin
        @async lock(l) do
        end
    end
    @test true
end

function test_channel()
    ch = Channel(1)
    @with(ch) do
        put!(ch, 1)
    end
    @test !isopen(ch)
end

function test_opentemp_success()
    tmppath = nothing
    @with((path, io) = opentemp()) do
        tmppath = path
        @test io isa IO
        @test isfile(tmppath)
    end
    @test !isfile(tmppath)
end

function test_opentemp_error()
    tmppath = Ref{Any}(nothing)
    @with(IgnoreError(), (path, io) = opentemp()) do
        tmppath[] = path
        @test io isa IO
        @test isfile(tmppath[])
        error("error")
    end
    @test !isfile(tmppath[])
end

function test_opentempdir_success()
    tmppath = nothing
    @with(path = opentempdir()) do
        tmppath = path
        @test isdir(tmppath)
    end
    @test !isdir(tmppath)
end

function test_opentempdir_error()
    tmppath = Ref{Any}(nothing)
    @with(IgnoreError(), path = opentempdir()) do
        tmppath[] = path
        @test isdir(tmppath[])
        error("error")
    end
    @test !isdir(tmppath[])
end

end  # module
