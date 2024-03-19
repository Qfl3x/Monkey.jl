include("../ast/ast.jl")

mutable struct Parser
    l::Lexer
    curr_token::Token
    peek_token::Token
    errors::Vector{String}
end
Parser(s::String) = Parser(Lexer(s))

# Precedence rules
@enum Precedence LOWEST EQUALS LESSGREATER SUM PRODUCT PREFIX CALL 


function Parser(l::Lexer)
    curr_token = next_token!(l)
    peek_token = next_token!(l)

    Parser(l, curr_token, peek_token, Vector{String}([]))
end

function next_token!(p::Parser)
    p.curr_token = p.peek_token
    p.peek_token = next_token!(p.l)
    p.curr_token
end

function next_token!(p::Parser, i::Int)
    for _ in 1:i
        next_token!(p)
    end
end

function expect_peek!(p::Parser, T)
    if typeof(p.peek_token) == Token{T}
        next_token!(p)
        return true
    else
        return false
    end
end

function expect_peek!(p::Parser, ::typeof(isoptoken))
    if isoptoken(p.peek_token)
        next_token!(p)
        return true
    else
        return false
    end
end

# # TODO: Proper expect peek with branches
function expect_peek!(p::Parser, conds...)
    for cond in conds
        if expect_peek!(p, cond) 
            return true
        end
    end
    push!(p.errors, "Expected $conds, got $(p.peek_token) instead")
end


# function parse_operator_exp!(p::Parser, left)
#     op = p.curr_token
#     if expect_peek!(p, IDENT)
#         right = Identifier(p.curr_token)
#         return OperatorStatement(op, right, op, left)
#     elseif expect_peek!(p, INT)
#         right = Integer(p.curr_token)
#         return OperatorStatement(op, right, op, left)
#     end
#     return nothing
# end


function parse_infix_op!(p::Parser, left)
    
end

function parse_prefix_op!(p::Parser)

end

#
# function to_expr(t::Token)
#     if typeof(t) == Token{INT}
#         return ExpressionStatement(Integer(t))
#     elseif typeof(t) == Token{IDENT}
#         return ExpressionStatement(Identifier(t))
#     end
# end

#= Parsing Functions for Prefix ops =#
# Implementation details:
# + All parsing functions (pre and in) don't advance beyond their last processed token
# + 
function parse_prefix!(p::Parser, ::IDENT)
    tok = p.curr_token
    return Identifier(tok, tok.literal)
end

function parse_prefix!(p::Parser, ::INT)
    tok = p.curr_token
    return Integer(tok, parse(Int64, tok.literal))
end

function parse_prefix!(p::Parser, ::STRING)
    tok = p.curr_token
    return StringLiteral(tok, tok.literal)
end

function parse_prefix!(p::Parser, ::MINUS)
    tok = p.curr_token
    next_token!(p)
    right = parse_expression!(p, PREFIX)
    if right !== nothing
        return PrefixExpression(tok, MINUS(), right)
    else
        push!(p.errors, "Syntax Error")
    end
end

function parse_prefix!(p::Parser, ::BANG)
    tok = p.curr_token
    next_token!(p)
    right = parse_expression!(p, PREFIX)
    if right !== nothing
        return PrefixExpression(tok, BANG(), right)
    else
        push!(p.errors, "Syntax Error")
    end
end

function parse_prefix!(p::Parser, ::BOOL)
    tok = p.curr_token
    return Boolean(tok, parse(Bool, tok.literal))
end

function parse_prefix!(p::Parser, ::LPAREN)
    next_token!(p)
    exp = parse_expression!(p, LOWEST)
    if !expect_peek!(p, RPAREN)
        return nothing
    else
        return exp
    end
end

function parse_prefix!(p::Parser, ::IF)
    tok = p.curr_token
    if typeof(p.peek_token) != Token{LPAREN}
        return nothing 
    else
        next_token!(p)
        condition = parse_prefix!(p, p.curr_token.type)
        if typeof(p.peek_token) != Token{LBRACE}
            return nothing
        else
            next_token!(p)
            consequence = parse_block!(p)
            if typeof(p.peek_token) != Token{ELSE}
                ifexpr = IfExpression(tok, condition, consequence, nothing)
                return ifexpr
            else
                next_token!(p, 2)
                alternative = parse_block!(p)
                ifexpr = IfExpression(tok, condition, consequence, alternative)
                return ifexpr
            end
        end
    end
end

function parse_prefix!(p::Parser, ::FUNCTION)
    tok = p.curr_token
    if typeof(p.peek_token) != Token{LPAREN}
        push!(p.errors, "Erroneous Function Literal expression")
        return nothing
    else
        next_token!(p)
        params = parse_fn_params!(p)
        if params === nothing
            return nothing
        end
        if typeof(p.peek_token) != Token{LBRACE}
            push!(p.errors, "Error in Function Literal Block parsing")
        else
            next_token!(p)
            block = parse_block!(p)
            return FunctionLiteral(tok, params, block)
        end
    end
end

function parse_prefix!(p::Parser, ::LBRACKET)
    tok = p.curr_token
    vec = Vector{AbstractExpression}([])
    next_token!(p)
    while typeof(p.curr_token) != Token{RBRACKET}
        elem = parse_expression!(p, LOWEST)
        push!(vec, elem)
        if typeof(p.peek_token) == Token{RBRACKET}
            next_token!(p)
            break
        end
        next_token!(p, 2) # Jump over the comma
    end
    return ArrayLiteral(tok, vec)
end

function parse_prefix!(p::Parser, ::LBRACE)
    tok = p.curr_token
    dict = Dict()
    next_token!(p)
    while typeof(p.curr_token) != Token{EOF}
        key = parse_expression!(p, LOWEST)
        if !(key isa StringLiteral)
            push!(p.errors, "Non-String keys in hashes not supported")
            return nothing
        end
        next_token!(p)
        if !(p.curr_token isa Token{COLON})
            push!(p.errors, "Wrong Hash Syntax")
            return nothing
        end
        next_token!(p, 1)
        value = parse_expression!(p, LOWEST)
        push!(dict, key => value)
        if typeof(p.peek_token) == Token{EOF}
            push!(p.errors, "Parsing Error")
            return nothing
        end
        if typeof(p.peek_token) == Token{RBRACE}
            next_token!(p)
            break
        end
        next_token!(p, 2) # Jump over the comma
    end
    return HashLiteral(tok, dict)
end

#= Precedence lookups =#

function precedence(::Union{PLUS, MINUS})
    SUM
end

function precedence(::Union{ASTERISK, SLASH})
    PRODUCT
end

function precedence(::Union{GT, LT})
    LESSGREATER
end

function precedence(::Union{EQ, NOT_EQ})
    EQUALS
end

function precedence(::LPAREN)
    CALL
end

function precedence(::LBRACKET)
    CALL
end

function precedence(::Any)
    LOWEST
end

function peek_precedence(p::Parser)
    return precedence(p.peek_token.type)
end

function curr_precedence(p::Parser)
    return precedence(p.curr_token.type)
end

#= Parsing Functions for Infix ops =#

function parse_op!(p::Parser, left, ::Union{PLUS, MINUS})
    op_token = p.curr_token
    next_token!(p)
    right = parse_expression!(p, SUM)
    return OperatorExpression(op_token, left, op_token.type, right)
end

function parse_op!(p::Parser, left, ::Union{ASTERISK, SLASH})
    op_token = p.curr_token
    next_token!(p)
    right = parse_expression!(p, PRODUCT)
    return OperatorExpression(op_token, left, op_token.type, right)
end

function parse_op!(p::Parser, left, ::Union{GT, LT})
    op_token = p.curr_token
    next_token!(p)
    right = parse_expression!(p, LESSGREATER)
    return OperatorExpression(op_token, left, op_token.type, right)
end

function parse_op!(p::Parser, left, ::Union{EQ, NOT_EQ})
    op_token = p.curr_token
    next_token!(p)
    right = parse_expression!(p, EQUALS)
    return OperatorExpression(op_token, left, op_token.type, right)
end

function parse_op!(p::Parser, left, ::LPAREN)
    tok = p.curr_token
    next_token!(p)
    args = []
    while typeof(p.curr_token) != Token{RPAREN} 
        arg = parse_expression!(p, LOWEST)
        push!(args, arg)
        if typeof(p.peek_token) == Token{RPAREN}
            next_token!(p)
            break
        end
        next_token!(p, 2) # Jump over the comma
    end
    return FunctionCall(tok, left, args)
end

function parse_op!(p::Parser, left, ::LBRACKET)
    tok = p.curr_token
    next_token!(p)
    index = parse_expression!(p, LOWEST)
    next_token!(p)
    return ArrayIndex(tok, left, index)
end

#= Helper Functions=#

function parse_fn_params!(p::Parser)
    next_token!(p)
    params = Vector{Identifier}([])
    if typeof(p.curr_token) == Token{RPAREN}
        return params
    end
    while typeof(p.curr_token) == Token{IDENT}
        ident = Identifier(p.curr_token, p.curr_token.literal)
        push!(params, ident)
        next_token!(p)
        if typeof(p.curr_token) == Token{COMMA}
            next_token!(p)
            continue
        elseif typeof(p.curr_token) == Token{RPAREN}
            return params
        else
            push!(p.errors, "Function Parameter Error")
            return nothing
        end
    end
end

function parse_block!(p::Parser)
    tok = p.curr_token
    statements = Vector{AbstractStatement}([])
    next_token!(p)
    while typeof(p.curr_token) != Token{RBRACE}
        stmt = parse_statement!(p)
        if stmt !== nothing 
            push!(statements, stmt)
        end
    end
    return BlockStatement(tok, statements)
end

#==#
function parse_expression!(p::Parser, prec)
    curr_token = p.curr_token
    if hasmethod(parse_prefix!, (Parser, typeof(curr_token.type)))
        left = parse_prefix!(p, curr_token.type)
        while p.peek_token.type != SEMICOLON() && prec < peek_precedence(p)
            next_token!(p)
            left = parse_op!(p, left, p.curr_token.type)
        end
        return left 
    end
    return nothing
end

function parse_expressionstatement!(p::Parser, prec)
    expr = parse_expression!(p, prec)
    if expr !== nothing 
        next_token!(p)
        return ExpressionStatement(expr)
    else
        return nothing 
    end
end

function parse_statement!(p::Parser)
    if typeof(p.curr_token) == Token{LET}
        parent_token = p.curr_token
        if expect_peek!(p, IDENT)
            ident = Identifier(p.curr_token, p.curr_token.literal)
            if expect_peek!(p, ASSIGN)
                next_token!(p)
                expr = parse_expression!(p::Parser, LOWEST)
                if expr !== nothing
                    next_token!(p)
                    return LetStatement(parent_token, ident, expr)
                else
                    return nothing
                end
            end
        end
    elseif typeof(p.curr_token) == Token{RETURN}
        parent_token = p.curr_token
        next_token!(p)
        expr = parse_expression!(p, LOWEST)
        if expr !== nothing 
            next_token!(p)
            return ReturnStatement(parent_token, expr)
        else
            push!(p.errors, "Syntax Error")
        end
    elseif typeof(p.curr_token) == Token{EOF} || p.curr_token isa Token{SEMICOLON}
        next_token!(p)
        return nothing
    else # Parsing Expression Statements
        expr_stmt = parse_expressionstatement!(p, LOWEST)
        if expr_stmt !== nothing
            return expr_stmt
        else
            push!(p.errors, "Invalid Expression")
            next_token!(p)
            return nothing
        end
    end
    return "ERROR"
end


function parse_program!(p::Parser)::Program
    statements = Vector{StatementNode}([])
    program = Program(statements)
    while typeof(p.curr_token) != Token{EOF}
        stmt = parse_statement!(p)
        if stmt !== nothing
            push!(program.statements, stmt)
        end
    end
    return program
end

