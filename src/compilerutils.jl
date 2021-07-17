module CompilerUtils

using Core: OpaqueClosure
using Core.Compiler:
    CodeInfo,
    CodeInstance,
    NativeInterpreter,
    OptimizationParams,
    OptimizationState,
    compact!,
    convert_to_ircode,
    copy,
    copy_exprargs,
    slot2reg,
    specialize_method

function methodinstance_from_expr_new_opaque_closure(inst::Expr)
    if !Meta.isexpr(inst, :new_opaque_closure)
        error("not an `Expr(new_opaque_closure, ...)`")
    end

    # Ref: jl_new_opaque_closure
    argt, _isva, _rt_lb, rt_ub, m, = inst.args
    argt::Type{<:Tuple}
    rt_ub::Type
    m::Method
    sig = Tuple{OpaqueClosure{argt,rt_ub},argt.parameters...}
    mi = specialize_method(m, sig, Core.svec())
    if isdefined(mi, :cache)
        return mi
    end
    if !Base.uncompressed_ir(m).inferred
        return mi
    end

    # If the `CodeInfo` is already inferred (likely from Tapir) and not cached,
    # insert a `CodeInstance` to avoid confusing `code_llvm` etc.
    inferred_result = m.source
    codeinst = CodeInstance(
        mi,
        Any,              # rettype
        nothing,          # inferred_const
        inferred_result,
        Int32(0x00),      # const_flags
        m.primary_world,  # min_world
        typemax(UInt),    # max_world
    )
    ccall(:jl_mi_cache_insert, Cvoid, (Any, Any), mi, codeinst)

    return mi
end

function ircode_from_codeinfo(ci::CodeInfo)
    # Making a copy here, as, e.g., `convert_to_ircode` mutates `ci`:
    ci = copy(ci)

    for (i, t) in pairs(ci.ssavaluetypes)
        if is_intermediate_value_type(t)
            ci.ssavaluetypes[i] = Any
        end
    end

    linfo = ci.parent  # MethodInstance
    interp = NativeInterpreter()
    params = OptimizationParams(interp)
    opt = OptimizationState(linfo, ci, params, interp)
    nargs = Int(opt.nargs) - 1
    preserve_coverage = false
    code = copy_exprargs(ci.code)
    ir = convert_to_ircode(ci, code, preserve_coverage, nargs, opt)
    ir = slot2reg(ir, ci, nargs, opt)
    ir = compact!(ir)
    return ir
end

end  # module CompilerUtils
