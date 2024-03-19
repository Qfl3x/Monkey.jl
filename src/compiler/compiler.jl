import Base.println

include("../code/code.jl")
include("../evaluator/eval.jl")

mutable struct Compiler
    instructions::Vector{UInt8}
    constants::Vector{AbstractObject}
end

function Compiler()
    Compiler([], [])
end

function compile(c::Compiler, node::Program)
    for stmt in node.statements
        compile(c, stmt)
    end
end

function compile(c::Compiler, node::ExpressionStatement)
    compile(c, node.expression)
end

function compile(c::Compiler, node::OperatorExpression)
    compile(c, node.left)
    compile(c, node.right)
    # TODO: Operators support
end

function compile(c::Compiler, node::Integer)
    obj = IntegerObject(node)
    push!(c.constants, obj)
    ins = Make(OpConstant, length(c.constants))
    push!(c.instructions, ins.instructions...)
end

struct Bytecode
    instructions::Vector{UInt8}
    constants::Vector{AbstractObject}
end

function Bytecode(c::Compiler)
    Bytecode(c.instructions, c.constants)
end

function println(bc::Bytecode)
    for ins in bc.instructions
        println(ins)
    end
end

