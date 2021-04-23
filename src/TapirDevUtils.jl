module TapirDevUtils

export ci_tapir, @ci_tapir

using InteractiveUtils: code_typed, gen_call_with_extracted_types_and_kwargs

function ci_tapir(f, types)
    @nospecialize
    (ci,), = code_typed(f, types)
    mch = Base._which(Base.tuple_type_cons(typeof(f), types))
    mi = Core.Compiler.specialize_method(mch.method, mch.spec_types, mch.sparams)
    return Core.Compiler.lower_tapir(mi, ci)
end

macro ci_tapir(args...)
    gen_call_with_extracted_types_and_kwargs(__module__, ci_tapir, args)
end

end
