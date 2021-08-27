ContextManagers.enter(l::Base.AbstractLock) = (lock(l); l)
ContextManagers.exit(l::Base.AbstractLock) = unlock(l)

function cleanup_mktemp((path, io),)
    rm(path; force = true)
    close(io)
end
ContextManagers.init(::typeof(mktemp), args...; kwargs...) =
    Closing(cleanup_mktemp, mktemp(args...; kwargs...))

cleanup_mktempdir(path) = rm(path; force = true, recursive = true)
ContextManagers.init(::typeof(mktempdir), args...; kwargs...) =
    Closing(cleanup_mktempdir, mktempdir(args...; kwargs...))
