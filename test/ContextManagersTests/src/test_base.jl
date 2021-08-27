module TestBase

using Test
using ContextManagers
using ..TestCore: Suppress

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

function test_mktemp_success()
    tmppath = nothing
    @with((path, io) = mktemp()) do
        tmppath = path
        @test io isa IO
        @test isfile(tmppath)
    end
    @test !isfile(tmppath)
end

function test_mktemp_error()
    tmppath = Ref{Any}(nothing)
    @with(Suppress(), (path, io) = mktemp()) do
        tmppath[] = path
        @test io isa IO
        @test isfile(tmppath[])
        error("error")
    end
    @test !isfile(tmppath[])
end

function test_mktempdir_success()
    tmppath = nothing
    @with(path = mktempdir()) do
        tmppath = path
        @test isdir(tmppath)
    end
    @test !isdir(tmppath)
end

function test_mktempdir_error()
    tmppath = Ref{Any}(nothing)
    @with(Suppress(), path = mktempdir()) do
        tmppath[] = path
        @test isdir(tmppath[])
        error("error")
    end
    @test !isdir(tmppath[])
end

end  # module
