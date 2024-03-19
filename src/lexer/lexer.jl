include("../token/token.jl")

mutable struct Lexer
    input::String
    position::Int
    read_position::Int
    ch::Char
end


function Lexer(input)
    ch = read_char(input, 1)
    Lexer(input, 1, 2, ch)
end

function read_char(input, read_position)
    if read_position > length(input)
        return 0
    else
        return input[read_position]
    end
end

function read_char!(l::Lexer)
    ch = read_char(l.input, l.read_position)
    l.position = l.read_position
    l.read_position += 1
    l.ch = ch
    ch
end

# seperator
function isseperator(ch)
    isspace(ch) 
end

# Eat whitespace
function eat_white_space!(l)
    ch = l.ch
    while isseperator(ch)
        read_char!(l)
        ch = l.ch
    end
end

# Identifier characters
function isvalid_ident_ch(ch)
    isletter(ch) || ch == '_'
end

function read_word!(l)
    ch = l.ch
    ch_curr = ch 
    word = ""
    while typeof(ch_curr) == Char && isvalid_ident_ch(ch_curr)
        word *= ch_curr 
        ch_curr = read_char!(l)
    end
    # Remove the last white space,
    # Side effect: Next character will be after the white space
    if word == "let"
        return Token(LET(), word) 
    elseif word == "fn"
        return Token(FUNCTION(), word) 
    elseif word == "int"
        return Token(INT(), word) 
    elseif word == "true"
        return Token(BOOL(), word) 
    elseif word == "false"
        return Token(BOOL(), word) 
    elseif word == "if"
        return Token(IF(), word) 
    elseif word == "else"
        return Token(ELSE(), word) 
    elseif word == "return"
        return Token(RETURN(), word) 
    else 
        return Token(IDENT(), word) 
    end
end

function read_string(l::Lexer)
    str = "" 
    ch = read_char!(l)
    while ch != '"'
        str *= ch
        ch = read_char!(l)
    end
    read_char!(l)
    return Token(STRING(), str)
end

function next_token!(l::Lexer)
    eat_white_space!(l)
    ch = l.ch
    if ch == '='
        read_char!(l)
        # Book used a "peekAhead" function here
        if l.ch == '='
            read_char!(l)
            return Token(EQ(), "==")
        end
        return Token(ASSIGN(), string(ch))
    elseif ch == '!'
        read_char!(l)
        if l.ch == '='
            read_char!(l)
            return Token(NOT_EQ(), "!=")
        end
        return Token(BANG(), "!")
    elseif ch == ';'
        read_char!(l)
        return Token(SEMICOLON(), string(ch))
    elseif ch == '('
        read_char!(l)
        return Token(LPAREN(), string(ch))
    elseif ch == ')'
        read_char!(l)
        return Token(RPAREN(), string(ch))
    elseif ch == '{'
        read_char!(l)
        return Token(LBRACE(), string(ch))
    elseif ch == '}'
        read_char!(l)
        return Token(RBRACE(), string(ch))
    elseif ch == ','
        read_char!(l)
        return Token(COMMA(), string(ch))
    elseif ch == '+'
        read_char!(l)
        return Token(PLUS(), string(ch))
    elseif ch == '-'
        read_char!(l)
        return Token(MINUS(), string(ch))
    elseif ch == '*'
        read_char!(l)
        return Token(ASTERISK(), string(ch))
    elseif ch == '/'
        read_char!(l)
        return Token(SLASH(), string(ch))
    elseif ch == '>'
        read_char!(l)
        return Token(GT(), string(ch))
    elseif ch == '<'
        read_char!(l)
        return Token(LT(), string(ch))
    elseif ch == '\0'
        read_char!(l)
        return Token(EOF(), string(ch))
    elseif ch == '['
        read_char!(l)
        return Token(LBRACKET(), string(ch))
    elseif ch == ']'
        read_char!(l)
        return Token(RBRACKET(), string(ch))
    elseif ch == ':'
        read_char!(l)
        return Token(COLON(), string(ch))
    elseif ch == '"'
        return read_string(l)
    # Letter
    elseif isvalid_ident_ch(ch)
        return read_word!(l)
    elseif isdigit(ch)
        ch_curr = ch
        word = ""
        while typeof(ch_curr) == Char && isdigit(ch_curr)
            word *= ch_curr 
            ch_curr = read_char!(l)
        end
        return Token(INT(), word)
    else 
        read_char!(l)
        return Token(ILLEGAL(), string(ch))
    end
end
