module Profiler

const CC = Core.Compiler

# overloads
import Core.Compiler:
    # `AbstractInterpreter` API defined in abstractinterpreterinterface.jl
    InferenceParams, OptimizationParams, get_world_counter, get_inference_cache, code_cache,
    lock_mi_inference, unlock_mi_inference, add_remark!, may_optimize, may_compress,
    may_discard_trees,
    # abstractinterpreter.jl
    abstract_call_gf_by_type, abstract_call_known, abstract_call,
    abstract_eval_special_value, abstract_eval_value_expr, abstract_eval_value,
    abstract_eval_statement

# TODO: use `using` instead
# loaded symbols
import Core:
    MethodInstance, TypeofBottom

import Core.Compiler:
    AbstractInterpreter, NativeInterpreter, InferenceState, InferenceResult,
    Bottom, widenconst, ⊑, isconstType, typeintersect, Builtin, CallMeta, argtypes_to_type,
    MethodMatchInfo, UnionSplitInfo, MethodLookupResult,
    Const, VarTable, AbstractEvalConstant, SSAValue, abstract_eval_ssavalue, Slot, slot_id,
    GlobalRef, GotoIfNot,
    _methods_by_ftype, specialize_method, typeinf, to_tuple_type

import Base.Meta:
    isexpr


include("abstractinterpreterinterface.jl")
include("abstractinterpretation.jl")
include("tfuncs.jl")


function profile!(interp::TPInterpreter, @nospecialize(tt::Type{<:Tuple}))
    ms = _methods_by_ftype(tt, -1, typemax(UInt))
    (ms === false || length(ms) != 1) && error("Unable to find single applicable method for $tt")

    atypes, sparams, m = ms[1]

    # grab the appropriate method instance for these types
    mi = specialize_method(m, atypes, sparams)

    # create an InferenceResult to hold the result
    result = InferenceResult(mi)

    # create an InferenceState to begin inference, give it a world that is always newest
    world = get_world_counter()
    frame = InferenceState(result, #=cached=# true, interp)

    # run type inference on this frame
    typeinf(interp, frame)

    return mi, result # and `interp` now holds traced information
end

function profile_call(f, args...)
    interp = TPInterpreter()
    tt = to_tuple_type(typeof.([f, args...]))
    mi, res = profile!(interp, tt)
    return interp, mi, res
end

macro profile_call(ex, kwargs...)
    @assert isexpr(ex, :call) "function call expression should be given"
    f = ex.args[1]
    args = ex.args[2:end]
    return :(profile_call($(esc(f)), $(map(esc, args)...)))
end

export
    @profile_call, profile_call

end  # module Profiler
