module TestSharedResources

using ContextManagers.++
using Test

function test_channel()
    @sync begin
        ch = Channel{Int}(0)
        @with(handle = SharedResource(ch)) do
            for i in 1:3
                context = open(handle)
                @async try
                    @with(ch = context) do
                        put!(ch, i)
                    end
                catch
                    close(ch)
                    rethrow()
                end
            end
        end
        @test sort!(collect(ch)) == 1:3
    end
end

end  # module
