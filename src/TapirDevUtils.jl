module TapirDevUtils

export ci_tapir, @ci_tapir, ircode_tapir, @ircode_tapir, newworld_compiler

using InteractiveUtils: code_typed, gen_call_with_extracted_types_and_kwargs

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

end
