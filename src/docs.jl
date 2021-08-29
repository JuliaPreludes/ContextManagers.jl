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
    ContextManagers.maybeenter(source) -> context or nothing

Start a `context` managing the resource. Or return `nothing` when `source` does
not implement the context interface.

Default implementation returns `nothing`; i.e.,
"""
ContextManagers.maybeenter

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

is equivalent to

```julia
context = something(ContextManagers.maybeenter(source))
try
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
