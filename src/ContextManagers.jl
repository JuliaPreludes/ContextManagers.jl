baremodule ContextManagers

export @with

function init end
function enter end
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

module Internal

using ..ContextManagers: ContextManagers, Handled
import ..ContextManagers: @with

include("internal.jl")
include("base.jl")
include("docs.jl")

end  # module Internal

end  # baremodule ContextManagers
