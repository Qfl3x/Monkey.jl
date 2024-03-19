include("evaluator/eval.jl")

function prompt_line()
    print(">>> ")
    readline()
end

function welcome_message()
    println("Welcome to my REPL")
    println("Type in Code and it will be tokenized")
    println("Press Ctrl-C to stop taking input")
end 

function REPL()
    welcome_message()
    e = new_env()
    while true 
        input = prompt_line()
        p = Parser(input)
        P = parse_program!(p)
        if length(p.errors ) > 0
            for error in p.errors
                println(error)
            end
            continue
        end
        result = eval(P, e)
        print(result)
        if result !== nothing
            println(inspect(result))
        else
            for stmt in P.statements
                println(string(stmt));
            end
        end
    end
end
