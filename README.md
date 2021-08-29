# ContextManagers

ContextManagers.jl provides composable resource management interface for Julia.

```julia
using ContextManagers: @with, opentemp, onexit

lck = ReentrantLock()
ch = Channel()

@with(
    lck,
    (path, io) = opentemp(),
    onexit(lock(ch)) do _
        unlock(ch)
        println("Successfully unlocked!")
    end,
) do
    println(io, "Hello World")
end

# output
Successfully unlocked!
```

See also:

* <https://github.com/c42f/ResourceContexts.jl>
