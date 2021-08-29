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

struct SharedResource{Source}
    source::Source
end

module Internal

using ..ContextManagers: ContextManagers, Handled, SharedResource
import ..ContextManagers: @with

include("internal.jl")
include("base.jl")
include("sharedresources.jl")
include("docs.jl")

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end ContextManagers

end  # module Internal

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
