baremodule ContextManagers

export @with

function maybeenter end
function value end
function exit end
function with end
macro with end

function closingwith end
function closing end

struct Handled end

struct NonException
    value::Any
end

struct IgnoreError end

function opentemp end
function opentempdir end

baremodule __ContextManagers_Extras_API
using ..ContextManagers: @with, ContextManagers, IgnoreError, opentemp, opentempdir
export @with, ContextManagers, IgnoreError, opentemp, opentempdir
end  # baremodule __ContextManagers_Extras_API
const (++) = __ContextManagers_Extras_API

module Internal

using ..ContextManagers: ContextManagers, Handled
import ..ContextManagers: @with

include("internal.jl")
include("base.jl")
include("docs.jl")

end  # module Internal

end  # baremodule ContextManagers
