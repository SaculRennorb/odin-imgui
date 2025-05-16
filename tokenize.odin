package program

import "core:fmt"
import "core:io"

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

			case ',', ';', '?', '(', '[', '{', ')', ']', '}', '\\':
				append(tokens, Token{cast(TokenKind) c, transmute(string)remaining[:1], loc})
				remaining = remaining[1:]

			case '*', '~', '%', '^', '=', '!':
				if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{TokenKind(0x100) + TokenKind(c), transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{TokenKind(c), transmute(string)remaining[:1], loc});
					remaining = remaining[1:]
				}

			case '&':
				if remaining < end[-1:] && remaining[1] == '&' {
					append(tokens, Token{.DoubleAmpersand, transmute(string)remaining[:2], loc});
					remaining = remaining[2:]
				}
				else if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.AssignAmpersand, transmute(string)remaining[:2], loc});
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
				else if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.AssignPipe, transmute(string)remaining[:2], loc});
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
				else if remaining < end[-1:] && remaining[1] == '<' {
					if remaining < end[-2:] && remaining[2] == '=' {
						append(tokens, Token{.AssignShiftLeft, transmute(string)remaining[:3], loc});
						remaining = remaining[3:]
					}
					else {
						append(tokens, Token{.ShiftLeft, transmute(string)remaining[:2], loc});
						remaining = remaining[2:]
					}
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
				else if remaining < end[-1:] && remaining[1] == '>' {
					if remaining < end[-2:] && remaining[2] == '=' {
						append(tokens, Token{.AssignShiftRight, transmute(string)remaining[:3], loc});
						remaining = remaining[3:]
					}
					else {
						append(tokens, Token{.ShiftRight, transmute(string)remaining[:2], loc});
						remaining = remaining[2:]
					}
				}
				else {
					append(tokens, Token{.BracketTriangleClose, transmute(string)remaining[:1], loc});
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

			case '#':
				if(remaining < end[-1:] && remaining[1] == '#') {
					append(tokens, Token{.DoublePound, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Pound, transmute(string)remaining[:1], loc})
					remaining = remaining[1:]
				}

			case '-':
				if remaining < end[-1:] && remaining[1] == '-' {
					kind : TokenKind = (remaining < end[-2:] && !is_valid_identifier_start(remaining[2])) ? .PostfixDecrement : .PrefixDecrement
					append(tokens, Token{kind, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
				}
				else if remaining < end[-1:] && remaining[1] == '>' {
					append(tokens, Token{.DereferenceMember, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
				}
				else if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.AssignMinus, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Minus, transmute(string)remaining[:1], loc})
					remaining = remaining[1:]
				}

			case '+':
				if remaining < end[-1:] && remaining[1] == '+' {
					kind : TokenKind = (remaining < end[-2:] && !is_valid_identifier_start(remaining[2])) ? .PostfixIncrement : .PrefixIncrement
					append(tokens, Token{kind, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
				}
				else if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.AssignPlus, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
				}
				else {
					append(tokens, Token{.Plus, transmute(string)remaining[:1], loc})
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
				else if remaining < end[-1:] && remaining[1] == '=' {
					append(tokens, Token{.AssignForwardSlash, transmute(string)remaining[:2], loc})
					remaining = remaining[2:]
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
				kind : TokenKind
				switch str {
					case "true", "false":
						kind = .LiteralBool
					case "NULL", "nullptr":
						kind = .LiteralNull
					case "return":      kind = .Return
					case "switch":      kind = .Switch
					case "case":        kind = .Case
					case "default":     kind = .Default
					case "break":       kind = .Break
					case "continue":    kind = .Continue
					case "for":         kind = .For
					case "do":          kind = .Do
					case "while":       kind = .While
					case "if":          kind = .If
					case "else":        kind = .Else
					case "typedef":     kind = .Typedef
					case "struct":      kind = .Struct
					case "class":       kind = .Class
					case "union":       kind = .Union
					case "enum":        kind = .Enum
					case "template":    kind = .Template
					case "namespace":   kind = .Namespace
					case "operator":    kind = .Operator
					case "static_cast": kind = .StaticCast
					case "const_cast":  kind = .ConstCast
					case "bit_cast":    kind = .BitCast
					case "public":      kind = .Public
					case "protected":   kind = .Protected
					case "private":     kind = .Private
					case "using":       kind = .Using
					case:
						kind = .Identifier
				}
				append(tokens, Token{kind, str, loc})

			case '.':
				if remaining < end[-2:] && remaining[1] == '.' && remaining[2] == '.' {
					append(tokens, Token{.Ellipsis, transmute(string)remaining[:3], loc})
					remaining = remaining[3:]
					continue
				}
				else if !(remaining < end[-1:] && '0' <= remaining[1] && remaining[1] <= '9') {
					append(tokens, Token{.Dot, transmute(string)remaining[:1], loc})
					remaining = remaining[1:]
					continue
				}

				fallthrough

			case '0'..='9':
				start := remaining
				is_hex := false
				is_float := false
				switch remaining[1] {
					case 'x': remaining = remaining[2:]; is_hex = true
					case 'o': remaining = remaining[2:]
					case 'b': remaining = remaining[2:]
				}
				number_loop: for remaining = remaining[1:]; remaining < end; remaining = remaining[1:] {
					switch remaining[0]  {
						case '0'..='9':

						case '\'':

						case '.':
							is_float = true

						case 'a'..='e', 'A'..='E':
						case 'f', 'F':
							if !is_hex {
								append(tokens, Token{.LiteralFloat, str_from_se(start, remaining), loc})
								remaining = remaining[1:]
								break number_loop
							}

						case 'L':
							append(tokens, Token{is_float ? .LiteralFloat : .LiteralInteger, str_from_se(start, remaining), loc})
							remaining = remaining[1:]
							break number_loop

						case 'u':
							append(tokens, Token{.LiteralInteger, str_from_se(start, remaining), loc})
							remaining = remaining[1:]
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

	is_valid_identifier_start :: proc(g : u8) -> bool
	{
		switch g {
			case '_', 'a'..='z', 'A'..='Z': return true;
		}
		return false
	}
}

TokenKind :: enum {
	AstNode = 1,

	NewLine              = '\n', // #x10

	Exclamationmark      = '!',  // #x21
	Pound                = '#',  // #x23

	Percent              = '%',  // #x25
	Ampersand            = '&',  // #x26

	BracketRoundOpen     = '(',  // #x28
	BracketRoundClose    = ')',  // #x29

	Star                 = '*',  // #x2a
	Plus                 = '+',  // #x2b
	Comma                = ',',  // #x2c
	Minus                = '-',  // #x2d
	Dot                  = '.',  // #x2e
	ForwardSlash         = '/',  // #x2f

	Colon                = ':',  // #x3a
	Semicolon            = ';',  // #x3b
	BracketTriangleOpen  = '<',  // #x3c
	Assign               = '=',  // #x3d
	BracketTriangleClose = '>',  // #x3e
	Questionmark         = '?',  // #x3f

	BracketSquareOpen    = '[',  // #x5b
	BackwardSlash        = '\\', // #x5c
	BracketSquareClose   = ']',  // #x5d
	Circumflex           = '^',  // #x5e

	BracketCurlyOpen     = '{',  // #x7b
	Pipe                 = '|',  // #x7c
	BracketCurlyClose    = '}',  // #x7d

	Tilde                = '~',  // #x7f

	_MirroredBinaryOperators = 0x100,
	NotEquals          = _MirroredBinaryOperators + '!',
	LessEq             = _MirroredBinaryOperators + '<',
	Equals             = _MirroredBinaryOperators + '=',
	GreaterEq          = _MirroredBinaryOperators + '>',
	AssignPlus         = _MirroredBinaryOperators + '+',
	AssignMinus        = _MirroredBinaryOperators + '-',
	AssignStar         = _MirroredBinaryOperators + '*',
	AssignAmpersand    = _MirroredBinaryOperators + '&',
	AssignPipe         = _MirroredBinaryOperators + '|',
	AssignCircumflex   = _MirroredBinaryOperators + '^',
	AssignForwardSlash = _MirroredBinaryOperators + '/',
	AssignPercent      = _MirroredBinaryOperators + '%',
	AssignTilde        = _MirroredBinaryOperators + '~',
	AssignShiftLeft,
	AssignShiftRight,
	
	StaticScopingOperator  = 0x200,
	DereferenceMember,
	PrefixIncrement,
	PrefixDecrement,
	PostfixIncrement,
	PostfixDecrement,
	Identifier,
	LiteralBool,
	LiteralString,
	LiteralInteger,
	LiteralFloat,
	LiteralCharacter,
	LiteralNull,
	Comment,
	Ellipsis,

	Public,
	Private,
	Protected,

	Using,
	Typedef,
	Struct,
	Class,
	Union,
	Enum,
	Template,
	Namespace,
	Operator,
	StaticCast,
	ConstCast,
	BitCast,

	Return,
	Break,
	Continue,
	For,
	While,
	Do,
	If,
	Else,
	Switch,
	Case,
	Default,

	PreprocDefine,
	PreprocUndefine,
	PreprocIf,
	PreprocElse,
	PreprocEndif,

	DoublePound,
	DoubleAmpersand,
	DoublePipe,
	ShiftLeft,
	ShiftRight,
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
	return fmt_token(fi, tok, 'v')
}

fmt_token :: proc(fi: ^fmt.Info, token: ^Token, verb: rune) -> bool
{
	fmt.fmt_string(fi, fmt.tprintf("%v:%v @ %v", token.kind, token.source, token.location), 'v')
	return true
}

fmt_location_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	loc := transmute(^SourceLocation)arg.data
	return fmt_location(fi, loc, 'v')
}

fmt_location :: proc(fi: ^fmt.Info, location: ^SourceLocation, verb: rune) -> bool
{
	fmt.fmt_string(fi, fmt.tprintf("%v:%v:%v", location.file_path, location.row, location.column), verb)
	return true
}

fmt_token_range_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	range := transmute(^TokenRange)arg.data
	return fmt_token_range(fi, range, 'v')
}

fmt_token_range :: proc(fi: ^fmt.Info, range: ^TokenRange, verb: rune) -> bool
{
	for segment, i in range {
		if i != 0 { io.write_byte(fi.writer, ' ') }
		io.write_string(fi.writer, segment.source)
	}
	return true
}
