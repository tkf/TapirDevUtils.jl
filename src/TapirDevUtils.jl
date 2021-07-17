module TapirDevUtils

export @ci_tapir,
    @ircode_tapir,
    child_task_info,
    ci_child_tasks,
    ci_tapir,
    ircode_child_tasks,
    ircode_tapir,
    newworld_compiler

using InteractiveUtils:
    InteractiveUtils, code_typed, gen_call_with_extracted_types_and_kwargs

try
    include("unstable.jl")
catch err
    @error "Cannot import unstable API" exception = (err, catch_backtrace())
end

function ci_tapir(f, types)
    @nospecialize
    (ci,), = code_typed(f, types)
    mch = Base._which(Base.tuple_type_cons(typeof(f), types))
    mi = Core.Compiler.specialize_method(mch.method, mch.spec_types, mch.sparams)
    return Core.Compiler.lower_tapir(mi, ci)
end

"""
    @ci_tapir f(args...)

Get `CodeInfo` after processed for lowering to Tapir. This is the actual
`CodeInfo` compiled to LLVM (while `@code_typed` still includes Tapir
constructs.)
"""
macro ci_tapir(args...)
    gen_call_with_extracted_types_and_kwargs(__module__, ci_tapir, args)
end

function ircode_tapir(f, types)
    @nospecialize
    (ci,), = code_typed(f, types)
    mch = Base._which(Base.tuple_type_cons(typeof(f), types))
    mi = Core.Compiler.specialize_method(mch.method, mch.spec_types, mch.sparams)
    return Core.Compiler.lower_tapir_to_ircode(mi, ci)
end

"""
    @ircode_tapir f(args...)

Get `IRCode` after processed for lowering to Tapir.
"""
macro ircode_tapir(args...)
    gen_call_with_extracted_types_and_kwargs(__module__, ircode_tapir, args)
end

"""
    newworld_compiler()

Use Revised `Core.Compiler` for real compilation (execution).

It just calls:

    ccall(:jl_set_typeinf_func, Cvoid, (Any,), Core.Compiler.typeinf_ext_toplevel)
"""
newworld_compiler() =
    ccall(:jl_set_typeinf_func, Cvoid, (Any,), Core.Compiler.typeinf_ext_toplevel)

"""
    UnsafeTapir

A namespace that provides Tapir-like API but with simpler but more "unsafe" code
(e.g., no exception handling).  Useful for debugging IR.

Usage:
    using TapirDevUtils: UnsafeTapir as Tapir
"""
module UnsafeTapir
using Base.Experimental: Tapir

const tokenname = gensym(:token)

macro spawn(block)
    var = esc(tokenname)
    block = Expr(:block, __source__, block)
    :(Tapir.@spawnin $var $(esc(block)))
end

macro sync(block)
    var = esc(tokenname)
    block = Expr(:block, __source__, block)
    quote
        let $var = Tapir.@syncregion(), ans = $(esc(block))
            Tapir.@sync_end($var)
            ans
        end
    end
end

end # module UnsafeTapir

const Requires = try
    Base.require(Base.PkgId(Base.UUID(0xae029012a4dd51049daad747884805df), "Requires"))
catch
    nothing
end

@static if Requires isa Module
    using .Requires: @require
end

@static if Requires isa Module
    function __init__()
        @require Cthulhu = "f68482b8-f384-11e8-15f7-abe071a5a75f" include("cthulhu.jl")
    end
end

end
