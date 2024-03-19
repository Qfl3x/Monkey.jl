import Base: string
abstract type AbstractToken end

# Elementary stuff
struct ILLEGAL <: AbstractToken end
struct EOF <: AbstractToken end
struct IDENT <: AbstractToken end
struct INT <: AbstractToken end
struct ASSIGN <: AbstractToken end
struct BOOL <: AbstractToken end

# Strings
struct STRING <: AbstractToken end

# Operators
struct PLUS <: AbstractToken end
struct MINUS <: AbstractToken end
struct SLASH <: AbstractToken end
struct ASTERISK <: AbstractToken end 
struct LT <: AbstractToken end 
struct GT <: AbstractToken end 
struct EQ <: AbstractToken end 
struct NOT_EQ <: AbstractToken end 
struct BANG <: AbstractToken end 
string(::PLUS) = "+"
string(::MINUS) = "-"
string(::ASTERISK) = "*"
string(::SLASH) = "/"
string(::LT) = "<"
string(::GT) = ">"
string(::EQ) = "=="
string(::NOT_EQ) = "!="
string(::BANG) = "!"


# Syntax stuff
struct COMMA <: AbstractToken end
struct SEMICOLON <: AbstractToken end
struct LPAREN <: AbstractToken end
struct RPAREN <: AbstractToken end
struct LBRACE <: AbstractToken end
struct RBRACE <: AbstractToken end
struct LBRACKET <: AbstractToken end
struct RBRACKET <: AbstractToken end
struct COLON <: AbstractToken end

# Keywords
struct LET <: AbstractToken end
struct FUNCTION <: AbstractToken end
struct IF <: AbstractToken end
struct ELSE <: AbstractToken end
struct RETURN <: AbstractToken end


struct Token{T}
    type::T
    literal::String 
end

import Base.string 

string(t::Token) = t.literal

function isoptoken(t::Token{T}) where{T}
    if T == PLUS || T == MINUS || T==SLASH || T==ASTERISK 
        return true 
    else
        return false
    end
end

