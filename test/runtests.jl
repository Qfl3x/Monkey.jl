#using interpreter
using Test

# include("eval_tests.jl")
# include("parser_tests.jl")
#
# @testset "interpreter.jl" begin
#     @testset "Parsing" begin
#         @testset int_parsing_test()
#         @testset ident_parsing_test()
#         @testset bool_parsing_test()
#         @testset let_test()
#         @testset prefix_parsing_test()
#         @testset binary_op_parsing_test()
#         @testset infix_op_priority_test()
#         @testset parent_priority_test()
#         @testset if_stmt_test()
#         @testset fn_parsing_test()
#         @testset fcall_parsing_test()
#         @testset string_parsing_test()
#         @testset array_test()
#         @testset hash_parsing_test()
#         @testset array_indexing_test()
#         
#     end
#     @testset "Evaluation" begin
#         @testset int_eval_test()
#         @testset bool_eval_test()
#         @testset binary_int_op_eval_test()
#         @testset binary_bool_op_eval_test()
#         @testset bang_eval_test()
#         @testset minus_eval_test()
#         @testset conditional_test()
#         @testset op_error_test()
#         @testset bindings_test()
#         @testset binding_error_test()
#         @testset fn_object_test()
#         @testset fn_call_test()
#         @testset string_eval_test()
#         @testset string_concat_test()
#         @testset builtin_funcs_test()
#         @testset array_eval_test()
#         @testset hash_eval_test()
#         @testset array_index_eval_test()
#     end
# end

include("../src/compiler/compiler.jl")

include("code_tests.jl")
include("./compiler_tests.jl")
@testset "Compiling" begin
    @testset test_make()
    @testset compiler_integer_arithmetic()
end
