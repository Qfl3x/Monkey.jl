# include("../src/code/code.jl")
struct TestMake
    op::Opcode
    operand::Vector{Int}
    expected::Vector{UInt8}
end
function test_make()
    tests = Vector{TestMake}([TestMake(OpConstant, [65534], [OpConstant.opcode, 255, 254])])
    @testset "Testing: $(test.op)" for test in tests
        instruction = Make(test.op, test.operand...)
        @test length(instruction) == length(test.expected)
        for (i, b) in enumerate(test.expected)
            @test instruction[i] == b
        end
    end 
end
