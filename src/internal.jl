ContextManagers.maybeenter(::Any) = nothing

function _enter(source)
    context = ContextManagers.maybeenter(source)
    context === nothing && notasource(source)
    return something(context)
end

function notasource(@nospecialize(source))::Union{}
    error("Not a context source: ", source)
end

function ContextManagers.exit(x, @nospecialize(err))
    ContextManagers.exit(x)
    return nothing
end

ContextManagers.exit(ctx) = close(ctx)

Base.getindex(err::ContextManagers.NonException) = err.value

function _exit(context, @nospecialize(err))::Bool
    if !(err isa Exception)
        err = ContextManagers.NonException(err)
    end
    y = ContextManagers.exit(context, err)::Union{Handled,Nothing}
    # TODO: better error message
    return y isa Handled
end

macro with(doblock::Expr, bindings...)
    unsupported() = error("unsupported syntax")
    Meta.isexpr(doblock, :(->), 2) && doblock.args[1] == Expr(:tuple) || unsupported()
    body = doblock.args[2]
    ex = foldr(bindings; init = body) do b, ex
        @gensym err ans handled context
        if b isa Symbol
            value = resource = b
        elseif Meta.isexpr(b, :kw, 2)
            value, resource = b.args
            if value === :_
                @gensym value
            end
        else
            @gensym value
            resource = b
        end
        quote
            # Using `let` so that it works with `value === resource`
            let $context = $_enter($resource),
                $value = $ContextManagers.value($context),
                $ans = nothing,
                $handled = false

                try
                    $ans = $ex
                catch $err
                    $handled = $_exit($context, $err)
                    $handled || rethrow()
                end
                $handled || $ContextManagers.exit($context, nothing)
                $ans
            end
        end
    end
    return esc(ex)
end

ContextManagers.with(f::F, resource1, resources...) where {F} =
    _with(f, resource1, resources...)

_with(f) = f()
function _with(f::F, resource1, resources...) where {F}
    ans = nothing
    handled = false
    context = _enter(resource1)
    try
        x = ContextManagers.value(context)
        ans = _with(resources...) do args...
            f(x, args...)
        end
    catch err
        handled = _exit(context, err)
        handled || rethrow()
    end
    handled || _exit(context, nothing)
    return ans
end

ContextManagers.value(x) = x

ContextManagers.closing(x) = ContextManagers.onexit(close, x)

"""
    ContextManagers.onexit(cleanup, x)
    ContextManagers.onexit(cleanup)

Create a context manager that runs `cleanup(x)` upon exit.

# Example

```jldoctest
julia> using ContextManagers: @with, onexit

julia> @with(
           onexit(111) do x
               @show x
           end,
       ) do
       end;
x = 111
```
"""
ContextManagers.onexit

struct OnExit{C,T}
    close::C
    value::T
end

ContextManagers.onexit(close::F, value) where {F} = OnExit(close, value)
ContextManagers.maybeenter(c::OnExit) = c
ContextManagers.value(c::OnExit) = c.value
ContextManagers.exit(c::OnExit) = c.close(c.value)

ContextManagers.onexit(close::F) where {F} = OnExit(_ -> close(), nothing)

"""
    ContextManagers.onfail(cleanup, x)
    ContextManagers.onfail(cleanup)

Create a context manager that runs `cleanup(x)` upon unsuccessful exit.

# Example

```jldoctest
julia> using ContextManagers: @with, IgnoreError, onfail

julia> @with(
           onfail(111) do x
               @show x
           end,
       ) do
       end;  # prints nothing

julia> @with(
           IgnoreError(),
           onfail(111) do x
               @show x
           end,
       ) do
           error("error")
       end;
x = 111
```
"""
ContextManagers.onfail

struct OnFail{C,T}
    close::C
    value::T
end

ContextManagers.onfail(close::F, value) where {F} = OnFail(close, value)
ContextManagers.maybeenter(c::OnFail) = c
ContextManagers.value(c::OnFail) = c.value
function ContextManagers.exit(c::OnFail, err)
    if err !== nothing
        c.close(c.value)
    end
    return nothing
end

ContextManagers.onfail(close::F) where {F} = OnFail(_ -> close(), nothing)
