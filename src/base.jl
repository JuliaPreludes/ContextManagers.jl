# Closable objects:
ContextManagers.maybeenter(io::IO) = io
ContextManagers.maybeenter(ch::AbstractChannel) = ch

if isdefined(Base, :AbstractLock)
    const AbstractLock = Base.AbstractLock
else
    const AbstractLock = ReentrantLock
end
ContextManagers.maybeenter(l::AbstractLock) = (lock(l); l)
ContextManagers.exit(l::AbstractLock) = unlock(l)

"""
    ContextManagers.opentemp([parent]; kwargs...) -> tf

Create and open a temporary file. The path and the `IO` object can be accessed
through the properties `.path` and `.io` of the returned object `tf`
respectively. The positional and named arguments are passed to `mktemp`.  The
file is automatically removed and the IO object is automatically closed when
used with `@with` or `with`.
"""
ContextManagers.opentemp

struct TemporaryFile
    path::String
    io::IOStream
end

ContextManagers.opentemp(; kwargs...) = TemporaryFile(mktemp(; kwargs...)...)
ContextManagers.opentemp(parent; kwargs...) = TemporaryFile(mktemp(parent; kwargs...)...)

ContextManagers.maybeenter(tf::TemporaryFile) = tf
function ContextManagers.exit(tf::TemporaryFile)
    (path, io) = tf
    rm(path; force = true)
    close(io)
end

Base.IteratorSize(::Type{TemporaryFile}) = Base.HasLength()
Base.length(::TemporaryFile) = 2
Base.iterate(tf::TemporaryFile) = (tf.path, tf.io)
Base.iterate(::TemporaryFile, io::IOStream) = (io, nothing)
Base.iterate(::TemporaryFile, ::Nothing) = nothing

Base.IteratorEltype(::Type{TemporaryFile}) = Base.HasEltype()
Base.eltype(::Type{TemporaryFile}) = Union{String,IOStream}

"""
    ContextManagers.opentempdir(parent=tempdir(); kwargs...) -> td

Create aa temporary directory. The path can be accessed through the property
`.path`  of the returned object `td`. When this is used with `@with` or `with`,
`td` is unwrapped to a `path` automatically. For example, in the do block of
`@with(paath = opentempdir()) do; ...; end`, a string `path` is available.
"""
ContextManagers.opentempdir

struct TemporaryDirectory
    path::String
end

ContextManagers.opentempdir(; kwargs...) = TemporaryDirectory(mktempdir(; kwargs...))
ContextManagers.opentempdir(parent; kwargs...) =
    TemporaryDirectory(mktempdir(parent; kwargs...))

ContextManagers.maybeenter(td::TemporaryDirectory) = td
ContextManagers.value(td::TemporaryDirectory) = td.path
function ContextManagers.exit(td::TemporaryDirectory)
    path = td.path
    rm(path; force = true, recursive = true)
end

ContextManagers.maybeenter(ie::ContextManagers.IgnoreError) = ie
ContextManagers.exit(::ContextManagers.IgnoreError, _) = ContextManagers.Handled()
