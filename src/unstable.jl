using Core: MethodInstance
using Core.Compiler: CodeInfo, IRCode

include("compilerutils.jl")
using .CompilerUtils: ircode_from_codeinfo, methodinstance_from_expr_new_opaque_closure

struct ChildTaskInfo
    mi::MethodInstance
    inst::Expr
    position::Int
end

"""
    child_task_info(ir::IRCode) -> info::Vector{ChildTaskInfo}

Extract `MethodInstance`s from `:new_opaque_closure` instructions.
"""
function child_task_info(ir::IRCode)
    info = ChildTaskInfo[]
    for i in 1:length(ir.stmts.inst)
        inst = ir.stmts.inst[i]
        Meta.isexpr(inst, :new_opaque_closure) || continue
        mi = methodinstance_from_expr_new_opaque_closure(inst)
        push!(info, ChildTaskInfo(mi, inst, i))
    end
    return info
end

function Core.CodeInfo(info::ChildTaskInfo)
    ci = Base.uncompressed_ir(info.mi.def)::CodeInfo
    ci = Core.Compiler.copy(ci)  # not sure about the ownership
    if ci.parent === nothing
        ci.parent = info.mi
    end
    return ci
end

ci_child_tasks(ir::IRCode) = map(CodeInfo, child_task_info(ir))
ircode_child_tasks(ir::IRCode) = map(ircode_from_codeinfo, ci_child_tasks(ir))

InteractiveUtils.code_typed(info::ChildTaskInfo) = CodeInfo(info) => Any

InteractiveUtils.code_llvm(info::ChildTaskInfo; kwargs...) =
    InteractiveUtils.code_llvm(stdout, info; kwargs...)

function InteractiveUtils.code_llvm(
    io::IO,
    info::ChildTaskInfo;
    world::UInt = typemax(UInt),
    raw::Bool = false,
    dump_module::Bool = false,
    optimize::Bool = true,
    debuginfo::Symbol = :default,
)
    wrapper::Bool = false
    strip_ir_metadata::Bool = !raw
    str = InteractiveUtils._dump_function_linfo_llvm(
        info.mi::MethodInstance,
        world,
        wrapper,
        strip_ir_metadata,
        dump_module,
        optimize,
        debuginfo,
        Base.CodegenParams(),
    )
    if InteractiveUtils.highlighting[:llvm] && get(io, :color, false)
        InteractiveUtils.print_llvm(io, str)
    else
        print(io, str)
    end
end
