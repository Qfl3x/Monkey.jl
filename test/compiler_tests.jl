# include("../src/parser/parser.jl")
# include("../src/compiler/compiler.jl")
struct CompilerTestCase
    input::String
    expected_constants::Vector{Any}
    expected_instructions::Vector{Instructions}
end

function compiler_integer_arithmetic()
    tests = [CompilerTestCase("1+1", [1,1], [Make(OpConstant, 1), Make(OpConstant,2)])]
    run_compiler_tests(tests)
end

function run_compiler_tests(tests::Vector{CompilerTestCase})
    for t in tests
        program = parse_(t.input)
        compiler = Compiler()
        err = compile(compiler, program)
        @test err === nothing
        bytecode = Bytecode(compiler)
        err = test_instructions(t.expected_instructions, bytecode.instructions)
        @test err === nothing
        println(bytecode.constants)
        err = test_constants(t.expected_constants, bytecode.constants)
        @test err === nothing
    end
end

function parse_(s::String)
    p_ = Parser(s)
    return parse_program!(p_)
end

function test_instructions(expected, actual)
    concatted = concat_instructions(expected)
    # concatted_actual = concat_instructions(expected)
    if length(concatted) != length(actual)
        return AssertionError("Not same length, expected $(expected) got $(actual)")
    end
    for (i, ins) in enumerate(concatted)
        if ins != actual[i]
            return AssertionError("Not same instructions, expected $(expected) got $(actual)")
        end
    end
    return nothing
end

function concat_instructions(instructions)
    out = Vector{UInt8}()
    for s in instructions
        push!(out, s.instructions...)
    end
    out
end

function test_constants(expected, actual)
  if length(expected) != length(actual)
        return AssertionError("Not same length of constants, expected $(expected) got $(actual)")
    end
    for (i, c) in enumerate(expected)
        err = test_object(c, actual[i])
        if err !== nothing
            return err
        end
    end
    return nothing
end

function test_object(obj::Int, actual)
    if actual.value != obj
        return AssertionError("Not same value, expected $(obj) got $(actual.value)")
    end
    return nothing
end


