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
        elseif Meta.isexpr(b, :call) || Meta.isexpr(b, :do)
            @gensym value
            resource = b
        else
            error("unexpected syntax: $b")
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

ContextManagers.closing(x) = ContextManagers.closingwith(close, x)

struct Closing{C,T}
    close::C
    value::T
end

ContextManagers.closingwith(close::F, value) where {F} = Closing(close, value)
ContextManagers.maybeenter(c::Closing) = c
ContextManagers.value(c::Closing) = c.value
ContextManagers.exit(c::Closing) = c.close(c.value)
