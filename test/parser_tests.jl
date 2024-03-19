using Test

function int_parsing_test()
    test_input = "5;"
    p = Parser(Lexer(test_input))
    P = parse_program!(p)
    stmts = P.statements
    @test length(stmts) == 1
    @test typeof(P.statements[1]) == ExpressionStatement
    @test typeof(stmts[1].expression) == Integer
    @test stmts[1].expression.value == 5
end


function ident_parsing_test()
    test_input = "foobar;"
    p = Parser(Lexer(test_input))
    P = parse_program!(p)
    stmts = P.statements
    @test length(stmts) == 1
    @test typeof(P.statements[1]) == ExpressionStatement
    @test typeof(stmts[1].expression) == Identifier
    @test stmts[1].expression.value == "foobar"
end

function bool_parsing_test()
    test_input = ["true;", "false;"]
    expected_out = [true, false]
    @testset "Testing booleans: $var" for (i,var) in enumerate(test_input)
        p = Parser(Lexer(var))
        P = parse_program!(p)
        stmts = P.statements
        @test length(stmts) == 1
        @test typeof(P.statements[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) == Boolean
        @test stmts[1].expression.value == expected_out[i]
    end
end

function let_test()
    test_input = "let x = 3;"
    p = Parser(Lexer(test_input))
    P = parse_program!(p)
    stmts = P.statements
    @test length(stmts) == 1
    @test typeof(P.statements[1]) == LetStatement
    @test typeof(stmts[1].name) == Identifier
    @test string(stmts[1]) == "let x = 3"
end

function prefix_parsing_test()
    test_inputs_minus = ["-5", "-foobar"]
    test_inputs_bang = ["!5", "!foobar"]
    @testset "Prefix testing for minus $input" for input in test_inputs_minus
        p = Parser(Lexer(input))
        P = parse_program!(p)
        stmts = P.statements
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: PrefixExpression
        @test stmts[1].expression.operator == MINUS()
    end
    @testset "Prefix testing for bang $input" for input in test_inputs_bang
        p = Parser(Lexer(input))
        P = parse_program!(p)
        stmts = P.statements
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: PrefixExpression
        @test stmts[1].expression.operator == BANG()
    end
end

function binary_op_parsing_test()
    operators = ["+", "-", "*", "/", ">", "<", "==", "!="]
    exps = ["5", "foo", "true"]
    @testset "Binary Operator testing: $op" for op in operators
        @testset "Expression: $expr" for expr in exps
            input = expr * op * expr 
            p = Parser(Lexer(input))
            P = parse_program!(p)
            stmts = P.statements 
            @test length(stmts) == 1
            @test typeof(stmts[1]) == ExpressionStatement
            @test typeof(stmts[1].expression) <: OperatorExpression
        end
    end
end

function infix_op_priority_test()
    input_test = ["3 * 10 + 3;", "1 / 5 - 4;", "3 * 10 > 10;"]
    expected = ["((3 * 10) + 3);", "((1 / 5) - 4);", "((3 * 10) > 10);"]
    @testset "Infix Operator Priority Test: $input" for (i,input) in enumerate(input_test)
        p = Parser(Lexer(input))
        P = parse_program!(p)
        @test string(P.statements[1]) == expected[i]
    end
end

function parent_priority_test()
    input_test = ["(3 + 3) * 4;", "2 / (5 + 5)"]
    expected = ["((3 + 3) * 4);", "(2 / (5 + 5));"]
    @testset "Infix Operator Priority Test: $input" for (i,input) in enumerate(input_test)
        p = Parser(Lexer(input))
        P = parse_program!(p)
        @test string(P.statements[1]) == expected[i]
    end
end

function if_stmt_test()
    condition_inputs = ["true", "false", "foo", "3 < 5", "foo != bar"]
    condition_expected = ["(true)", "(false)", "foo", "(3 < 5)", "(foo != bar)"]
    block_inputs = ["3 + 5;", "3", "false", "foo", "foo + bar;\n 3 + 4"]
    block_expected = ["(3 + 5);", "3;" ,"(false);", "foo;", "(foo + bar);\n(3 + 4);"]
    @testset "if condition testing: $cond" for (i,cond) in enumerate(condition_inputs)
        input = "if " * "( " * cond * " ) " * "{ " * "3" * "}"
        p = Parser(Lexer(input))
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: IfExpression
        @test string(stmts[1]) == "if " * condition_expected[i] * " {\n3;\n};"
    end
    @testset "if block testing: $block" for (i,block) in enumerate(block_inputs)
        input = "if (true) {" * block * "}"
        p = Parser(Lexer(input))
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: IfExpression
        #block_str = block[end] == ";" ? block : block * ";"
        @test string(stmts[1]) == "if (true) {\n" * block_expected[i] * "\n};"
    end
end

function fn_parsing_test()
    parameters_input = ["", "x", "x,y"]
    blocks = ["return 0", "x + y", "x + y;\n 3+ 4"]
    expected_block = ["return 0", "(x + y);", "(x + y);\n(3 + 4);"]
    @testset "Function parameters testing: $params" for params in parameters_input
        input = "fn (" * params *")" * " {3};"
        p = Parser(input)
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: FunctionLiteral
        @test string(stmts[1]) == "fn (" * params * ") {\n3;\n};"
    end
    @testset "Function Block testing: $block" for (i,block) in enumerate(blocks)
        input = "fn () {" * block * "};"
        p = Parser(input)
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: FunctionLiteral
        @test string(stmts[1]) == "fn () {\n" * expected_block[i] * "\n};"
    end
end

function fcall_parsing_test()
    callee_test = ["foobar", "fn(x,y) {x + y}"]
    callee_expected = ["foobar", "fn (x,y) {\n(x + y);\n}"]
    args = ["","a, b", "1+2, 4", "3, add(4,5)"]
    expected_args = ["", "a,b", "(1 + 2),4", "3,add(4,5)"]
    @testset "Function call testing; Callee: $callee" for (i, callee) in enumerate(callee_test)
        input = callee * "(4,5)"
        p = Parser(input)
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: FunctionCall
        @test string(stmts[1]) == callee_expected[i] * "(4,5);"
    end
    @testset "Function call testing; args: $args" for (i, args) in enumerate(args)
        input = "add(" * args * ")"
        p = Parser(input)
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: FunctionCall
        @test string(stmts[1]) == "add(" * expected_args[i] * ");"
    end
end

function string_parsing_test()
    input = [""" "Hello World!" """]
    expected_output = [""""Hello World!";"""]
    @testset "Testing String Parsing: $input" for (i, input) in enumerate(input)
        p = Parser(input)
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: StringLiteral
        @test string(stmts[1]) == expected_output[i]
    end
end

function array_test()
    input = ["[2,3]", "[\"Hello\", \"World\"]"]
    expected_output = ["[2,3];", "[\"Hello\",\"World\"];"]
    @testset "Testing Array Parsing: $input" for (i, input) in enumerate(input)
        p = Parser(input)
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: ArrayLiteral
        @test string(stmts[1]) == expected_output[i]
    end
end

function array_indexing_test()
    input = ["a[3]"]
    expected_output = ["a[3];"]
    @testset "Testing Array Indexing Parsing: $input" for (i, input) in enumerate(input)
        p = Parser(input)
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: ArrayIndex
        @test string(stmts[1]) == expected_output[i]
    end
end

function hash_parsing_test()
    input = ["{\"a\":2}"]
    expected_output = ["{\"a\":2};"]
    @testset "Testing Hash Parsing: $input" for (i, input) in enumerate(input)
        p = Parser(input)
        P = parse_program!(p)
        stmts = P.statements 
        @test length(stmts) == 1
        @test typeof(stmts[1]) == ExpressionStatement
        @test typeof(stmts[1].expression) <: HashLiteral
        @test string(stmts[1]) == expected_output[i]
    end
end
