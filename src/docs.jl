"""
    @with(
        resource1 = init1,
        resource2 = init2,
        ...
        resourcen = initn,
    ) do
        use(resource1, resource2, ..., resourcen)
    end
"""
:(ContextManagers.@with)

"""
    ContextManagers.with(init...) do resources...
        use(resources...)
    end
"""
ContextManagers.with

"""
    ContextManagers.init(f, args...; kwargs...) -> source

Create a `source` of context.

Default implementation is `f(args...; kwargs...)`.
"""
ContextManagers.init(f, args...; kwargs...) = f(args...; kwargs...)

"""
    ContextManagers.enter(source) -> context

Start a `context` managing the resource.

Default implementation is a pass-through (identity) function.
"""
ContextManagers.enter

"""
    ContextManagers.value(context) -> resource

Default implementation is a pass-through (identity) function.
"""
ContextManagers.value

"""
    ContextManagers.exit(context)
    ContextManagers.exit(context, err) -> nothing or ContextManagers.Handled()

Cleanup the `context`.  Default implementation is `close`.

Roughly speaking,

```julia
@with(resource = f(args...)) do
    use(resource)
end
```

is lowered to

```julia
source = ContextManagers.init(f, args...)
try
    context = ContextManagers.enter(source)
    resource = ContextManagers.value(context)

    use(resource)

finally
    ContextManagers.exit(context)
end
````

In the two-argument version `ContextManagers.exit(context, err)` (where `err` is
`nothing` or an `Exception`), the error can be suppressed by returning
`ContextManagers.Handled()`.
"""
ContextManagers.exit
