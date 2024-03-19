include("../evaluator/builtins.jl")
#include("../object/object.jl")

abstract type AbstractEnvironment end
struct Environment <: AbstractEnvironment
    store::Dict{String, AbstractObject}
    outer::Union{Environment, Nothing}
end

function get(e::Environment, name::String)
    obj = nothing
    try
        obj = e.store[name]
    catch _
        if e.outer === nothing
            return get(builtinenv, name)
        else
            return get(e.outer, name)
        end
    end
    return obj
end

function set(e::Environment, name::String, val::AbstractObject)
    e.store[name] = val
    val
end

function new_env()
    return Environment(Dict{String, AbstractObject}(), nothing)
end

function new_env(e::Environment)
    return Environment(Dict{String, AbstractObject}(), e)
end

struct Function <: AbstractObject
    args::Vector{Identifier}
    body::BlockStatement
    env::Environment
end
type(::Function) = "FUNCTION_OBJ"
function inspect(f::Function)
    str = "fn "
    str *= string(f.args) 
    str *= " "
    str *= string(f.body)
    str
end

struct BuiltinEnv <: AbstractEnvironment
    store::Dict{String, BuiltIn}
end

builtinenv = BuiltinEnv(builtins)

function get(e::BuiltinEnv, name::String)
    obj = nothing
    try
        obj = e.store[name]
    catch _
        return nothing
    end
    return obj
end
