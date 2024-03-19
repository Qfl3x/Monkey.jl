import Base: getproperty
abstract type AbstractObject end

# All Objects should have a Type and an "Inspect"

struct IntegerObject <: AbstractObject
    value::Int64
end
type(::IntegerObject) = "INTEGER_OBJ"
inspect(o::IntegerObject) = string(o.value)

struct BooleanObject <: AbstractObject
    value::Bool
end
type(::BooleanObject) = "BOOLEAN"
inspect(o::BooleanObject) = string(o.value)

const TRUE = BooleanObject(true)
const FALSE = BooleanObject(false)

struct Result
    value::AbstractObject
end


struct NullObject <: AbstractObject end
type(::NullObject) = "NULL"
inspect(::NullObject) = nothing
getproperty(::NullObject, v::Symbol) = v == :value ? nothing : error("Null Object has no field $v")

struct Error  <: AbstractObject
    message::String
end
type(::Error) = "ERROR"
inspect(e::Error) = e.message

# DataTypes Below:

struct StringObject <: AbstractObject
    value::String
end
type(::StringObject) = "STRING"
inspect(s::StringObject) = s.value

struct ArrayObject <: AbstractObject
    value::Vector{AbstractObject}
end
inspect(a::ArrayObject) = a.value

struct HashObject <: AbstractObject
    value::Dict
end
type(::HashObject) = "HASH"
function inspect(hash::HashObject)
    str = "{"
    for (k,v) in hash.value
        str *= inspect(k) * ":" * inspect(v) * ","
    end
    str = str[1:end-1]
    str *= "}"
    return str
end

# REPL Inspect
function inspect(s::String)
    display(s)
    return NullObject()
end
# Builtin functions

struct BuiltIn <: AbstractObject
    fn::Any
end

function (b::BuiltIn)(obj::AbstractObject...)
    b.fn(obj...)
end


