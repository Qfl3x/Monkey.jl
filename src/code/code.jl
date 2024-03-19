using Bits


struct Instructions 
    instructions :: Vector{UInt8}
end

import Base.getindex, Base.length
getindex(ins::Instructions, i::Int64) = ins.instructions[i]
length(ins::Instructions) = length(ins.instructions)

struct Opcode 
    opcode :: UInt8
end

# Define the opcodes
const OpConstant = Opcode(0x00)

struct Definition 
    Name :: String
    OperandWidths :: Vector{Int}
end


const definitions = Dict(
    OpConstant.opcode => Definition("OpConstant", [2])
)

function stringify_opcode(op::UInt8)
    def, err = lookup(op)
    if err !== nothing
        return nothing, ErrorException("opcode $(op) undefined")
    end
    return def.Name
end

function lookup(op::UInt8)
    try
        def = definitions[op]
        return def, nothing
    catch _
        return nothing, AssertionError("opcode $(op) undefined")
    end
end

function to_bigendian(x::T) where(T)
    bitlength = Bits.bitsize(T)
    n_bytes = bitlength ÷ 8
    bytes = Vector{UInt8}(undef, n_bytes)
    running_sum = zero(T)
    for i in 1:n_bytes
        byte = (x - running_sum) >> ((n_bytes -i)*8)
        bytes[i] = byte
        running_sum += byte << ((n_bytes - i) * 8)
    end
    return bytes
end

function stringify_operands(bytes::UInt8...)
    n_bytes = length(bytes)
    if n_bytes % 2 != 0
        throw(ErrorException("Bytes aren't 2-by-2"))
    end
    n_operands = n_bytes ÷ 2
    results = Vector{UInt16}(undef, n_operands)
    i = 1
    for offset in 0:2:(n_bytes - 1)
        byte_1 = bytes[offset + 1]
        byte_2 = bytes[offset + 2]
        result = (UInt16(byte_1) << 8) + UInt16(byte_2)
        results[i] = result
        i += 1
    end
    return results
end

function read_instruction(ins::Instructions)
    if length(ins.instructions) == 0
        return "" 
    end
    op_string = stringify_opcode(ins.instructions[1])
    operands_string = string.(stringify_operands(ins.instructions[2:end]...))
    s = op_string 
    for operand_s in operands_string
        s *= " " * operand_s
    end
    return s
end

import Base.string, Base.print, Base.show
string(ins::Instructions) = read_instruction(ins)
print(ins::Instructions) = print(string(ins))
show(io::IO, ins::Instructions) = show(io, string(ins))

function Make(op::Opcode, operands::Int...)
    def, ok = lookup(op.opcode)
    if ok !== nothing
        return Instructions(Vector{UInt8}())
    end

    instructionlength = 1 + sum(def.OperandWidths)

    instruction = Vector{UInt8}(undef, instructionlength)
    instruction[1] = op.opcode

    offset = 1
    for (i, operand) in enumerate(operands)
        width = def.OperandWidths[i]
        if width == 2
            instruction[offset+1:end] = to_bigendian(UInt16(operand))
        end
    end
    return Instructions(instruction)
end
