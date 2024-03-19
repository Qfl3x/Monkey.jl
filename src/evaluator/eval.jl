include("../parser/parser.jl")
include("../object/environment.jl")

IntegerObject(i::Integer) = IntegerObject(i.value)
BooleanObject(b::Boolean) = b.value ? TRUE : FALSE

function eval(node::T, e) where {T<:AbstractNode}
    if node isa Integer
        return IntegerObject(node)
    elseif node isa Boolean
        return BooleanObject(node)
    elseif node isa OperatorExpression
        left = eval(node.left, e)
        right = eval(node.right, e)
        if node.operator == PLUS()
            return left + right
        elseif node.operator == MINUS()
            return left - right
        end
    end
end

function eval(node::Integer, e)
    return IntegerObject(node)
end

function eval(node::Boolean, e)
    return BooleanObject(node)
end

# Other Data Types go here:
function eval(node::StringLiteral, e)
    return StringObject(node.value)
end
function eval(node::OperatorExpression, e)
    left = eval(node.left, e)
    right = eval(node.right, e)
    if left isa Error
        return left
    elseif right isa Error
        return right
    end
    if node.operator isa PLUS && right isa StringObject && left isa StringObject
        return evalStringConcat(left, right)
    elseif node.operator isa PLUS || node.operator isa MINUS ||node.operator isa SLASH ||node.operator isa ASTERISK 
        if right isa IntegerObject && left isa IntegerObject
            return evalIntOp(left, right, node.operator)
        else
            return Error("Type Error: $(type(left)) $(string(node.operator)) $(type(right))")
        end
    elseif node.operator isa GT || node.operator isa LT
        if right isa IntegerObject && left isa IntegerObject
            return  evalBoolOp_Int(left, right, node.operator)
        else
            return Error("Type Error: $(type(left)) $(string(node.operator)) $(type(right))")
        end
    elseif node.operator isa EQ ||node.operator isa NOT_EQ
        if right isa IntegerObject && left isa IntegerObject
            return evalBoolOp_Int(left, right, node.operator)
        elseif right isa BooleanObject && left isa BooleanObject
            return evalBoolOp_Bool(left, right, node.operator)
        else
            return Error("Type Error: $(type(left)) $(string(node.operator)) $(type(right))")
        end
    end
end

function evalIntOp(left, right, op)
    if op == PLUS()
        return IntegerObject(left.value + right.value)
    elseif op == MINUS()
        return IntegerObject(left.value - right.value)
    elseif op == SLASH()
        return IntegerObject(left.value ÷ right.value)
    elseif op == ASTERISK()
        return IntegerObject(left.value * right.value)
    end
    
end

function evalBoolOp_Int(left, right, op)
    if op isa GT
        return BooleanObject(left.value > right.value)
    elseif op isa LT
        return BooleanObject(left.value < right.value)
    elseif op isa EQ
        return BooleanObject(left.value == right.value)
    elseif op isa NOT_EQ
        return BooleanObject(left.value != right.value)
    end
end

function evalBoolOp_Bool(left,right, op)
    if op isa EQ
        return BooleanObject(left == right)
    elseif op isa NOT_EQ
        return BooleanObject(left != right)
    end
end

function evalStringConcat(left, right)
    return StringObject(left.value * right.value)
end

function eval(node::PrefixExpression, e)
    right = eval(node.right, e)
    if right isa Error
        return right
    end
    if node.operator == BANG()
        if right isa BooleanObject
            return BooleanObject(!(right.value))
        elseif right isa IntegerObject
            return BooleanObject(false) #!5 == true
        elseif right isa NullObject
            return BooleanObject(true)
        else
            return Error("Type Error: $(string(node.operator)) $(type(right))")
        end
    elseif node.operator == MINUS()
        if right isa IntegerObject
            return IntegerObject(- right.value)
        else
            return Error("Type Error: $(string(node.operator)) $(type(right))")
        end
    end
end

function eval(node::IfExpression, e)
    cond = eval(node.condition, e)
    if cond.value !== nothing && cond.value != false
        return  eval(node.consequence, e)
    elseif node.alternative isa Nothing
        return NullObject()
    else
        return eval(node.alternative, e)
    end
end

function eval(node::ReturnStatement, e)
    expr = node.value
    return Result(eval(expr, e))
end

function eval(node::LetStatement, e::Environment)
    val = eval(node.value, e)
    if val isa Error
        return val
    end
    ident = node.name.value
    e.store[ident] = val
    val
end

function eval(node::Identifier, e::Environment)
    val = get(e, node.value)
    if val !== nothing
        return val
    end
    return Error("Identifier not found: $(node.value)")
end

function eval(node::FunctionLiteral, e::Environment)
    return Function(node.parameters, node.block, e)
end

function eval(node::FunctionCall, e::Environment)
    fn = eval(node.callee, e)
    if fn isa Error
        return fn
    end
    args_eval = [eval(arg, e) for arg in node.args]
    if any(x -> x isa Error, args_eval)
        return args_eval[findfirst(x-> x isa Error, args_eval)]
    end
    if fn isa Function && length(args_eval) != length(fn.args)
        return Error("Function takes $(length(fn.args)) arguments, only $(length(args_eval)) arguments passed")
    end
    if fn isa BuiltIn
        return fn(args_eval...)
    end
    env = new_env(fn.env)
    for (i, arg) in enumerate(fn.args)
        set(env, arg.value, args_eval[i])
    end
    result = eval(fn.body, env)
    if result isa Result
        return result.value
    else
        return result
    end
end

function eval(node::ArrayLiteral, e::Environment)
    ArrayObject(Vector{AbstractObject}([eval(elem, e) for elem in node.value]))
end

function eval(node::ArrayIndex, e::Environment)
    index_obj = eval(node.index, e)
    if node.array isa ArrayLiteral
        if index_obj.value >= length(node.array.value)
            return Error("Index $(index_obj) is out of bounds for array $(node.array)")
        else
            return eval(node.array.value[node.index.value + 1], e::Environment)
        end
    end
    arr = eval(node.array, e::Environment)
    if arr isa ArrayObject
        return arr.value[index_obj.value + 1]
    else
        return arr.value[index_obj]
    end
end

function eval(node::HashLiteral, e::Environment)
    keys = node.value.keys
    values = node.value.vals
    function make_pair(k, v)
        return eval(k, e) => eval(v, e)
    end
    HashObject(Dict([make_pair(k,v) for (k,v) in node.value]))
end

function eval(node::BlockStatement, e)
    result = nothing
    for stmt in node.statements
        result = eval(stmt, e)
        if result isa Result 
            return result
        elseif result isa Error
            return result
        end
    end
    return result
end

function eval(node::Any, e)
    return Error("Evaluation Error: $(string(node))")
end

function eval(node::ExpressionStatement, e)
    return eval(node.expression, e)
end

function eval(node::Program)
    result = nothing 
    e = new_env()
    for stmt in node.statements
        result = eval(stmt, e)
        if result isa Result 
            return result.value
        elseif result isa Error
            return result
        end
    end
    return result
end

function eval(node::Program, e::Environment)
    result = nothing 
    for stmt in node.statements
        result = eval(stmt, e)
        if result isa Result 
            return result.value
        elseif result isa Error
            return result
        end
    end
    return result
end
