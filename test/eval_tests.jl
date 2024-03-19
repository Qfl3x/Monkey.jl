include("../src/evaluator/eval.jl")

function testeval(input)
    p = Parser(input)
    P = parse_program!(p)
    return eval(P)
end

function int_eval_test()
    input = "3;"
    result = testeval(input)
    @test result isa IntegerObject
    @test result.value == 3
end

function bool_eval_test()
    input = "true;"
    result = testeval(input)
    @test result isa BooleanObject
    @test result.value == true
end

function binary_int_op_eval_test()
    inputs = ["3 + 3;", "3 - 3;", "1 + 1 * 2"]
    expected = [6, 0, 3]
    @testset "Binary Int Op: $input" for (i,input) in enumerate(inputs)
        result = testeval(input)
        @test result isa IntegerObject
        @test result.value == expected[i]
    end
end

function binary_bool_op_eval_test()
    inputs = ["3 > 3", "1 < 2", "1 == 2", "1 == 1", "6 == (3 * 2)", "true == false", "3 != 5", "1 != 1", "true != true", "true != false"]
    expected = [false, true, false, true, true, false, true, false, false, true]
    @testset "Binary Boolean Op: $input" for (i,input) in enumerate(inputs)
        result = testeval(input)
        @test result isa BooleanObject
        @test result.value == expected[i]
    end
end

function bang_eval_test()
    inputs = ["!false", "!true", "!5", "!!false", "!!5"]
    expected_type = [BooleanObject, BooleanObject, BooleanObject, BooleanObject, BooleanObject]
    expected_val = [true, false, false, false, true]
    @testset "Testing Bang Operator: $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa expected_type[i]
        @test result.value == expected_val[i]
    end
end

function minus_eval_test()
    inputs = ["-5", "-(-1)"]
    expected_type = [IntegerObject, IntegerObject]
    expected_val = [-5, 1]
    @testset "Testing minus Operator: $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa expected_type[i]
        @test result.value == expected_val[i]
    end
end

function conditional_test()
    inputs = ["if (true) {10}",
              "if (false) {10}",
              "if (1 > 0) {10}",
              "if (1 > 2) {10}",
              "if (1 > 1) {10} else {20}",
        "if (1 > 0) {10} else {20}",]
    expected_val = [10, nothing, 10, nothing, 20, 10]
    expected_type = [IntegerObject, NullObject, IntegerObject, NullObject, IntegerObject, IntegerObject]
    @testset "Testing conditionals : $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa expected_type[i]
        @test result.value == expected_val[i]
    end
end

function return_test()
    inputs = ["return 10", "3; return 10;", "return 10; 9;", "3; return 10; 9", "if (true) {return 10; 3;}",
    "if (true) { if (true) { return 10 }; return 1;}"]
    expected_val = [10, 10, 10, 10, 10, 10]
    @testset "Testing return statements : $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa IntegerObject
        @test result.value == expected_val[i]
    end
end

function op_error_test()
    inputs = ["true + false;", "5 * true;", "-true", "if (5 > 2) { true + false; }", "true + false; 5"]
    expected_val = ["Type Error: BOOLEAN + BOOLEAN", "Type Error: INTEGER_OBJ * BOOLEAN", "Type Error: - BOOLEAN", "Type Error: BOOLEAN + BOOLEAN", "Type Error: BOOLEAN + BOOLEAN"]
    @testset "Testing Operation Errors: $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa Error
        @test result == Error(expected_val[i])
    end
end

function bindings_test()
    inputs = ["let x = 3; x",
"let x = 3 + 3;x",
"let a = 4; let b = a; b",
        "let a = 1; let b = 2; let c = a + b; c"]
    expected_val = [3, 6, 4, 3]
    expected_type = [IntegerObject, IntegerObject, IntegerObject, IntegerObject]
    @testset "Testing Bindings statements : $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa IntegerObject
        @test result.value == expected_val[i]
    end
end

function binding_error_test()
    inputs = ["foobar", "foobar + 4"]
    expected_val = ["Identifier not found: foobar", "Identifier not found: foobar"]
    @testset "Testing binding errors: $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa Error
        @test result == Error(expected_val[i])
    end
end

function fn_object_test()
    inputs = ["fn(x) { x + 2;}"]
    expected_val = ["fn (x) {\n(x + 2);\n}"]
    @testset "Testing Function Object Definitions: $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa Function
        @test inspect(result) == expected_val[i]
    end
end

function fn_call_test()
    inputs = ["let identity = fn(x) { return x; }; identity(3)", "let identity = fn(x) { x; }; identity(3)",
        "let identity = fn(x) { return x; };identity(true)", "let add = fn(x,y) { x + y }; add(3,4)", "fn(x){x + 5}(5)"]
    expected_val = [3, 3, true, 7, 10]
    expected_type = [IntegerObject, IntegerObject, BooleanObject, IntegerObject, IntegerObject]
    @testset "Testing Function Calls: $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa expected_type[i]
        @test result.value == expected_val[i]
    end
end

function string_eval_test()
    input = """ "Hello World!" """
    result = testeval(input)
    @test result isa StringObject
    @test result.value == "Hello World!"
end

function string_concat_test()
    input = [""" "Hello" + " " + "World!" """]
    expected_output = ["Hello World!"]
    @testset "Testing String Concatenation: $input" for (i, input) in enumerate(input)
        result = testeval(input)
        @test result isa StringObject
        @test result.value == expected_output[i]
    end
end

function builtin_funcs_test()
    inputs = ["len(\"Hello\")", "first([2,3])", "last([4,5])", "rest([1,2,3])", "push([1,2], 3)"]
    expected_val = [5, 2, 5, [IntegerObject(2), IntegerObject(3)], [IntegerObject(1), IntegerObject(2), IntegerObject(3)]]
    expected_type = [IntegerObject, IntegerObject, IntegerObject, ArrayObject, ArrayObject]
    @testset "Testing Builtin Function Calls: $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa expected_type[i]
        @test result.value == expected_val[i]
    end
end

function array_eval_test()
    inputs = ["[2,3]"]
    expected_val = [[IntegerObject(2), IntegerObject(3)]]
    @testset "Testing Array Definitions : $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa ArrayObject
        @test result.value == expected_val[i]
    end
end

function hash_eval_test()
    inputs = ["{\"gf\":5, \"bf\":2}"]
    expected_val = [Dict(StringObject("gf") => IntegerObject(5), StringObject("bf") => IntegerObject(2))]
    @testset "Testing Hash Definitions : $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa HashObject
        @test result.value == expected_val[i]
    end
end
function array_index_eval_test()
    inputs = ["[2,3][1]", "fn () {return [1,2,3]}()[0]", "{\"gf\":5, \"bf\":2}[\"gf\"]"]
    expected_val = [3, 1, 5]
    expected_type = [IntegerObject, IntegerObject, IntegerObject]
    @testset "Testing Array Indexing: $input" for (i, input) in enumerate(inputs)
        result = testeval(input)
        @test result isa expected_type[i]
        @test result.value == expected_val[i]
    end
end
