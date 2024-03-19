include("../lexer/lexer.jl")

abstract type AbstractNode end

abstract type AbstractStatement <: AbstractNode end
abstract type AbstractExpression <: AbstractNode end

struct Node <: AbstractNode
    literal::String
end

struct StatementNode <: AbstractStatement
    literal::String
end

struct ExpressionNode <: AbstractExpression
    literal::String
end

struct ExpressionStatement <: AbstractStatement
    expression::AbstractExpression
end

string(e::ExpressionStatement) = string(e.expression) * ";"

mutable struct Program <: AbstractNode
    statements::Vector{AbstractStatement}
end

string(P::Program) = join(string.(P.statements), '\n')
# Program literal equal to statements[1].literal if there are statements

struct Identifier <: AbstractExpression
    token::Token{IDENT}
    value::String
end

string(I::Identifier) = I.token.literal

struct Integer <: AbstractExpression
    token::Token{INT}
    value::Int64
end

string(I::Integer) = I.token.literal

struct Boolean <: AbstractExpression
    token::Token{BOOL}
    value::Bool
end

string(s::Boolean) = "(" * string(s.value) * ")"


struct LetStatement <: AbstractStatement
    token::Token{LET}
    name::Identifier
    value::AbstractExpression
end

string(S::LetStatement) = string(S.token) * " " * string(S.name) * " " * "=" * " " * string(S.value)

struct ReturnStatement <: AbstractStatement
    token::Token{RETURN}
    value::AbstractExpression
end

string(S::ReturnStatement) = S.token.literal * " " * string(S.value)

struct PrefixExpression{T} <: AbstractExpression
    token::Token
    operator::T
    right::AbstractExpression
end

string(S::PrefixExpression) ="(" * string(S.token) * string(S.right) * ")"

struct OperatorExpression{T} <: AbstractExpression
    token::Token{T}
    left::AbstractExpression
    operator::T
    right::AbstractExpression
end

string(S::OperatorExpression) = "(" * string(S.left) * " " * string(S.token) * " " * string(S.right) * ")"

struct BlockStatement <: AbstractStatement
    token::Token{LBRACE}
    statements::Vector{AbstractStatement}
end

function string(bs::BlockStatement)
    str = "{\n"
    for stmt in bs.statements
        str *= string(stmt) * "\n"
    end
    str *= "}"
    str
end

struct IfExpression{T<:Union{Nothing, BlockStatement}} <: AbstractExpression
    token::Token{IF}
    condition::AbstractExpression
    consequence::BlockStatement
    alternative::T
end

string(ifexpr::IfExpression{Nothing}) = "if " * string(ifexpr.condition) * " " * string(ifexpr.consequence)
string(ifexpr::IfExpression{BlockStatement}) = "if " * string(ifexpr.condition) * " " * string(ifexpr.consequence) * "\n" * "else " * string(ifexpr.alternative)

function string(v::Vector{T}) where {T<:AbstractExpression}
    if length(v) == 0
        return "()"
    end
    str = "("
    for ident in v
        str *= string(ident) * ","
    end
    str = str[1:end-1] # Last Comma
    str *= ")"
    return str
end

struct FunctionLiteral <: AbstractExpression
    token::Token{FUNCTION}
    parameters::Vector{Identifier}
    block::BlockStatement
end

string(fn::FunctionLiteral) = "fn" * " " * string( fn.parameters ) * " " * string(fn.block)

struct FunctionCall <: AbstractExpression
    token::Token{LPAREN}
    callee::AbstractExpression
    args::Vector{AbstractExpression}
end

string(fc::FunctionCall) = string(fc.callee) *  string(fc.args) 

struct StringLiteral <: AbstractExpression
    token::Token{STRING}
    value::String
end

string(sl::StringLiteral) = '"' * sl.value * '"'

struct ArrayLiteral <: AbstractExpression
    tok::Token{LBRACKET}
    value::Vector{AbstractExpression}
end

string(a::ArrayLiteral) = '[' * string(a.value)[2:end-1] * ']'

struct ArrayIndex <: AbstractExpression
    tok::Token{LBRACKET}
    array::AbstractExpression
    index::AbstractExpression
end

string(ind::ArrayIndex) = string(ind.array) * '[' * string(ind.index) * ']'

struct HashLiteral <: AbstractExpression
    tok::Token{LBRACE}
    value::Dict
end

function string(hash::HashLiteral)
    str = "{"
    for (k,v) in hash.value
        str *= string(k) * ":" * string(v) * ","
    end
    str = str[1:end-1]
    str *= "}"
    return str
end
