package program

import "core:fmt"

tokenize :: proc(tokens : ^[dynamic]Token, text : string, file_path : string)
{
	remaining := raw_data(text)
	end := raw_data(text)[len(text):]

	row : int = 1
	row_start : [^]u8 = remaining


	for remaining < end {
		c := remaining[0]

		loc := SourceLocation{file_path, row, ptr_msub(remaining, row_start) + 1}

		switch c {
			case '\t', '\v', '\f', ' ', 0x85, 0xa0, '\r':
				remaining = remaining[1:]
				continue

			case '#', ',', ';', '*', '+', '^', '?', '~', '(', '[', '{', ')', ']', '}':
				append(tokens, Token{cast(TokenKind) c, transmute(string)remaining[:1], loc})
				remaining = remaining[1:]

			case '&': 
				if remaining < end[-1:] && remaining[1] == '&' {
					append(tokens, Token{.DoubleAmpersand, transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Ampersand, transmute(string)remaining[:1], loc});
					remaining = remaining[1:]
				}

			case '|': 
				if remaining < end[-1:] && remaining[1] == '|' {
					append(tokens, Token{.DoublePipe, transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Pipe, transmute(string)remaining[:1], loc});
					remaining = remaining[1:]
				}

			case '<': 
				if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.LessEq, transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.BracketTriangleOpen, transmute(string)remaining[:1], loc});
					remaining = remaining[1:]
				}

			case '>': 
				if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.GreaterEq, transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.BracketTriangleClose, transmute(string)remaining[:1], loc});
					remaining = remaining[1:]
				}

			case '=': 
				if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.Equals, transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Assign, transmute(string)remaining[:1], loc});
					remaining = remaining[1:]
				}

			case '!': 
				if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.NotEquals, transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Exclamationmark, transmute(string)remaining[:1], loc});
					remaining = remaining[1:]
				}

			case '\n': 
				if remaining < end[-1:] && remaining[1] == '\r' {
					append(tokens, Token{.NewLine, transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.NewLine, transmute(string)remaining[:1], loc});
					remaining = remaining[1:]
				}
				row += 1
				row_start = remaining

			case ':':
				if(remaining < end[-1:] && remaining[1] == ':') {
					append(tokens, Token{.StaticScopingOperator, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Colon, transmute(string)remaining[:1], loc})
					remaining = remaining[1:]
				}

			case '-':
				if remaining < end[-1:] && remaining[1] == '>' {
					append(tokens, Token{.DereferenceMember, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Minus, transmute(string)remaining[:1], loc})
					remaining = remaining[1:]
				}

			case '"':
				start := remaining
				for remaining = remaining[1:] ; remaining < end; remaining = remaining[1:] {
					if remaining[0] == '\n' { row += 1; row_start = remaining }
					if remaining[0] == '"' && remaining[-1] != '\\' { remaining = remaining[1:]; break }
				}
				append(tokens, Token{.LiteralString, str_from_se(start, remaining), loc})

			case '\'':
				start := remaining
				for remaining = remaining[1:] ; remaining < end; remaining = remaining[1:] {
					if remaining[0] == '\'' && remaining[-1] != '\\' { remaining = remaining[1:]; break }
				}
				append(tokens, Token{.LiteralCharacter, str_from_se(start, remaining), loc})

			case '/':
				if remaining < end[-1:] && remaining[1] == '/' {
					start := remaining
					for remaining = remaining[1:] ; remaining < end; remaining = remaining[1:] {
						if remaining[0] == '\n' { break }
					}
					append(tokens, Token{.Comment, str_from_se(start, remaining), loc})
				}
				else if remaining < end[-1:] && remaining[1] == '*' {
					start := remaining
					for remaining = remaining[1:] ; remaining < end; remaining = remaining[1:] {
						if remaining[0] == '\n' { row += 1; row_start = remaining }
						if remaining[-1] == '*' && remaining[0] == '/' { remaining = remaining[1:]; break }
					}
					append(tokens, Token{.Comment, str_from_se(start, remaining), loc})
				}
				else {
					append(tokens, Token{.ForwardSlash, transmute(string)remaining[:1], loc})
					remaining = remaining[1:]
				}

			case 'a'..='z', 'A'..='Z', '_':
				start := remaining
				ident_loop: for remaining = remaining[1:]; remaining < end; remaining = remaining[1:] {
					switch remaining[0]  {
						case 'a'..='z', 'A'..='Z', '0'..='9', '_':
							continue

						case:
							break ident_loop
					}
				}
				str := str_from_se(start, remaining)
				switch str {
					case "true", "false":
						append(tokens, Token{.LiteralBool, str, loc})
					case "NULL", "nullptr":
						append(tokens, Token{.LiteralNull, str, loc})
					case:
						append(tokens, Token{.Identifier, str, loc})
				}

			case '.':
				if !(remaining < end[-1:] && '0' <= remaining[1] && remaining[1] <= '9') {
					append(tokens, Token{.Dot, transmute(string)remaining[:1], loc})
					remaining = remaining[1:]
					continue
				}

				fallthrough

			case '0'..='9':
				start := remaining
				is_float := false
				number_loop: for remaining = remaining[1:]; remaining < end; remaining = remaining[1:] {
					switch remaining[0]  {
						case '0'..='9':

						case '.':
							is_float = true

						case 'f':
							is_float = true
							remaining = remaining[1:]
							append(tokens, Token{.LiteralFloat, str_from_se(start, remaining), loc})
							break number_loop

						case:
							append(tokens, Token{is_float ? .LiteralFloat : .LiteralInteger, str_from_se(start, remaining), loc})
							break number_loop
					}
				}

			case:
				assert(false, fmt.tprintf("Unexpected token '%c' (%v) at %v.", c, c, loc))
		}
	}
}

TokenKind :: enum {
	AstNode = 1,

	NewLine              = '\n',
	Exclamationmark      = '!',
	Pound                = '#',
	Comma                = ',',
	Dot                  = '.',
	Colon                = ':',
	Semicolon            = ';',
	Plus                 = '+',
	Minus                = '-',
	Star                 = '*',
	ForwardSlash         = '/',
	Ampersand            = '&',
	Pipe                 = '|',
	Circumflex           = '^',
	Questionmark         = '?',
	BracketRoundOpen     = '(',
	BracketRoundClose    = ')',
	BracketSquareOpen    = '[',
	BracketSquareClose   = ']',
	BracketCurlyOpen     = '{',
	BracketCurlyClose    = '}',
	BracketTriangleOpen  = '<',
	Assign               = '=',
	BracketTriangleClose = '>',
	Tilde                = '~',

	StaticScopingOperator,
	DereferenceMember,
	Identifier,
	LiteralBool,
	LiteralString,
	LiteralInteger,
	LiteralFloat,
	LiteralCharacter,
	LiteralNull,
	Comment,
	
	DoubleAmpersand = 255,
	DoublePipe,
	Equals,
	NotEquals,
	LessEq,
	GreaterEq,
}

Token :: struct {
	kind : TokenKind,
	source : string,
	location : SourceLocation,
}

SourceLocation :: struct {
	file_path : string,
	row, column : int,
}


fmt_token_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	tok := transmute(^Token)arg.data
	if verb == 'v' {
		return fmt_token(fi, tok, 'v')
	}
	else {
		return false
	}
}

fmt_token :: proc(fi: ^fmt.Info, token: ^Token, verb: rune) -> bool
{
	if verb == 'v' {
		fmt.fmt_string(fi, fmt.tprintf("%v:%v @ %v", token.kind, token.source, token.location), 'v')

		return true
	}
	else {
		return false
	}
}

fmt_location_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	loc := transmute(^SourceLocation)arg.data
	if verb == 'v' {
		return fmt_location(fi, loc, 'v')
	}
	else {
		return false
	}
}

fmt_location :: proc(fi: ^fmt.Info, location: ^SourceLocation, verb: rune) -> bool
{
	if verb == 'v' {
		fmt.fmt_string(fi, fmt.tprintf("%v:%v:%v", location.file_path, location.row, location.column), verb)

		return true
	}
	else {
		return false
	}
}
