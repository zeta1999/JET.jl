"""
    SomeType

Wrapper type for "type-profiled" variables -- the actual type is kept in
  `type` field.
"""
struct SomeType
  type::Type
end

"""
    IntrinsicFunctionType

Wrapper type for `Core.IntrinsicFunction`s. This type serves as a workaround so that
  we can identify `Core.IntrinsicFunction`s from their type (which is supposed to be
  obtained from [`typeof′`](@ref) function).
"""
struct IntrinsicFunctionType
  f::Core.IntrinsicFunction
end

"""
    struct Undefined end

A Singleton type that represents when the type profiler failed to track a type.
It should be reported when and where this is introduced, and then any further
  profiling for things including this type won't be executed.
"""
struct Undefined end
