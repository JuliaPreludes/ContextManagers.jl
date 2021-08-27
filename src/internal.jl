ContextManagers.init(f, args...; kwargs...) = f(args...; kwargs...)
ContextManagers.enter(x) = x

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
        elseif Meta.isexpr(b, :call) || Meta.isexpr(b, :do)
            @gensym value
            resource = b
        else
            error("unexpected syntax: $b")
        end
        if Meta.isexpr(resource, :call)
            # Transform `f(...)` to `create(f, ...)`
            if Meta.isexpr(get(resource.args, 1, nothing), :parameters)
                resource = Expr(
                    :call,
                    reosurce.args[1],
                    ContextManagers.init,
                    resource.args[2:end]...,
                )
            else
                resource = Expr(:call, ContextManagers.init, resource.args...)
            end
        end
        quote
            # Using `let` so that it works with `value === resource`
            let $context = $ContextManagers.enter($resource),
                $value = $ContextManagers.value($context),
                $ans = nothing,
                $handled = false

                try
                    $ans = $ex
                catch $err
                    $handled = $_exit($context, $err)
                    $handled || rethrow()
                end
                $handled || $_exit($context, nothing)
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
    context = ContextManagers.enter(resource1)
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

ContextManagers.closing(x) = ContextManagers.closingwith(close, x)

struct Closing{C,T}
    close::C
    value::T
end

ContextManagers.closingwith(close::F, value) where {F} = Closing(close, value)
ContextManagers.enter(c::Closing) = c
ContextManagers.value(c::Closing) = c.value
ContextManagers.exit(c::Closing) = c.close(c.value)
