baremodule ContextManagers

export @with

function maybeenter end
function value end
function exit end
function with end
macro with end

function onexit end
function onfail end
function closing end

struct Handled end

struct NonException
    value::Any
end

struct IgnoreError end

function opentemp end
function opentempdir end

module Internal

using ..ContextManagers: ContextManagers, Handled
import ..ContextManagers: @with

include("internal.jl")
include("base.jl")
include("sharedresources.jl")
include("docs.jl")

end  # module Internal

const SharedResource = Internal.SharedResource

baremodule __ContextManagers_Extras_API
using ..ContextManagers:
    @with,
    ContextManagers,
    IgnoreError,
    SharedResource,
    closing,
    onexit,
    onfail,
    opentemp,
    opentempdir
export @with,
    ContextManagers,
    IgnoreError,
    SharedResource,
    closing,
    onexit,
    onfail,
    opentemp,
    opentempdir
end  # baremodule __ContextManagers_Extras_API
const (++) = __ContextManagers_Extras_API

end  # baremodule ContextManagers
