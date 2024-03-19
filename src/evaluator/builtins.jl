include("../object/object.jl")

len() = IntegerObject(0)
len(s::StringObject) = IntegerObject(length(s.value))
len(a::ArrayObject) = IntegerObject(length(a.value))

first(a::ArrayObject) = a.value[1]
last(a::ArrayObject) = a.value[end]
push(a::ArrayObject, obj::AbstractObject) = ArrayObject(push!(copy(a.value), obj))
puts(a::AbstractObject) = inspect(a)

function rest(a::ArrayObject)
    if len(a).value >= 2
        return ArrayObject(copy(a.value[2:end]))
    elseif len(a).value == 1
        return ArrayObject(Vector{AbstractObject}([]))
    else
        return NullObject()
    end

end

builtins = Dict{String, BuiltIn}(
    "len" => BuiltIn(len),
    "first" => BuiltIn(first),
    "last" => BuiltIn(last), 
    "rest" => BuiltIn(rest),
    "push" => BuiltIn(push),
    "puts" => BuiltIn(puts))





