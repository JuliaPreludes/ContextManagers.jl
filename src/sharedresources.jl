"""
    ContextManagers.SharedResource(source)

Create a sharable resource that is closed once the "last" context using the
shared resource is closed.

!!! warning
    The `source` itself should produce "thread-safe" API if this is shared
    between `@spawn`ed task.

`SharedResource` supports the following pattern

```julia
@sync begin
    @with(handle = SharedResource(source)) do  # (1)
        for x in xs
            context = open(handle)  # (2)
            @spawn begin
                @with(value = context) do  # (3)
                    use(value, x)
                end  # (4a)
            end
        end
    end  # (4b)
    ...
end
```

(1) The underling `source` is entered when `SharedResource` is entered.  A
`handle` to this shared resource can be obtained by entering the context of the
`SharedResource`.

(2) A `context` for obtaining the value of the context of the original `source`
can be obtained by `open` the `handle`. When sharing the resource across tasks,
it typically has to be done *before* spawning the task.

(3) The `value` from the original `source` can be obtained by entering the
`context`.

(4) The last shared context exitting the `@with` block ends the original
context.  In the above pattern, the context of the `source` may exit at the
`end` (4b) of the outer `@with` if `xs` is empty or all the child tasks exit
first.

# Extended help
## Notes

This is inspired by Nathaniel J. Smith's comment:
<https://github.com/python-trio/trio/issues/719#issuecomment-462119589>
"""
struct SharedResource{Source}
    source::Source
end

struct SharedHandle{Context}
    context::Context
    nopens::Threads.Atomic{Int}
end

struct RootSharedContext{Handle<:SharedHandle}
    handle::Handle
end

struct SharedContext{Handle<:SharedHandle}
    handle::Handle
end

ContextManagers.maybeenter(shared::SharedResource) =
    RootSharedContext(SharedHandle(_enter(shared.source), Threads.Atomic{Int}(1)))

ContextManagers.value(context::RootSharedContext) = context.handle

Base.open(handle::SharedHandle) = ContextManagers.maybeenter(handle)
function ContextManagers.maybeenter(handle::SharedHandle)
    # TODO: maybe store `current_task` in `handle` to makesure that it is opened
    # in the same task?
    n = handle.nopens[]
    while n > 0
        old = Threads.atomic_cas!(handle.nopens, n, n + 1)
        old == n && break
        n = old
    end
    if n == 0
        error("already closed")
    end
    return SharedContext(handle)
end

ContextManagers.maybeenter(context::SharedContext) = context

ContextManagers.value(context::SharedContext) =
    ContextManagers.value(context.handle.context)

# TODO: What to do when there is an error? Immediately close? But what when
# there are multiple errors? See also:
# https://github.com/python-trio/trio/issues/719#issuecomment-427317591
function ContextManagers.exit(context::Union{SharedContext,RootSharedContext})
    nopens = context.handle.nopens
    context = context.handle.context
    if Threads.atomic_sub!(nopens, 1) == 1
        ContextManagers.exit(context)
    end
    return
end

# TODO: close should be idempotent
# Base.close(context::SharedContext) = ContextManagers.exit(context)
