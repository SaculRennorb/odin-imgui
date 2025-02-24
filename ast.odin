package program

import "core:fmt"
import "core:slice"
import str "core:strings"


parse_ast_filescope_sequence :: proc(ast : ^[dynamic]AstNode, tokens : []Token) -> AstNode
{
	root_index := append_return_index(ast, AstNode{ type = .Sequence }) // unfinished node at index 0
	sequence : [dynamic]AstNodeIndex

	remaining_tokens := tokens

	for len(remaining_tokens) > 0 {
		token, tokenss := peek_token(&remaining_tokens)
		#partial switch token.type {
			case .Identifier:
				switch token.source {
					case "typedef":
						panic(fmt.tprintf("Typedef at %v not implemented.", token))

					case "struct", "class", "union":
						remaining_tokens = tokenss // eat keyword

						if node, node_err := parse_ast_struct_no_keyword(ast, &remaining_tokens); node_err == nil {
							node.type = token.source == "union" ? .Union : .Struct
							append(&sequence, append_return_index(ast, node))
							
							t, err := eat_token_expect(&remaining_tokens, .Semicolon)
							if err != nil { panic(fmt.tprintf("Unexpected token after %v def: %v\n", token.source, err)) }

							continue
						}
						else {
							panic(fmt.tprintf("Failed to parse %v at %v.", token.source, node_err))
						}

					case:
						token_reset_point := remaining_tokens
						ast_reset_point := len(ast)
	
						if node, node_err := parse_ast_function_def(ast, &remaining_tokens); node_err == nil {
							n, err := append(&sequence, append_return_index(ast, node))
							continue
						}
						else {
							resize(ast, ast_reset_point); remaining_tokens = token_reset_point
							
							panic(fmt.tprintf("Failed to parse function def at %v.", node_err)) // TODO(Rennorb) @completeness
						}
	
				}

			case:
				panic(fmt.tprintf("Unknown token %v for sequence.", token))
		}
	}

	ast[root_index].sequence = sequence
	return ast[root_index]
}

parse_ast_struct_no_keyword :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ast)
	members : [dynamic]AstNodeIndex

	defer if err != nil {
		delete(members)
		resize(ast, ast_reset)
		tokens^ = tokens_reset
	}

	node = {}

	next_ := find_next_actual_token(tokens)
	next, nexts := next_[0], next_[1:len(tokens) - ptr_msub(next_, raw_data(tokens^))]

	if next.type == .Identifier { // type name is optional
		tokens^ = nexts // eat the name 
		node.struct_or_union.name = next_[:1]

		next, nexts = peek_token(tokens)
		if next.type == .Colon {
			tokens^ = nexts // eat the : 

			node.struct_or_union.base_type = parse_ast_type_inner(tokens) or_return

			next, nexts = peek_token(tokens)
		}
	}

	if next.type == .Semicolon {
		node.struct_or_union.is_forward_declaration = true
		err = nil
		return
	}
	
	if next.type != .BracketCurlyOpen {
		err = next
		return
	}
	tokens^ = nexts

	for {
		n, ss := peek_token(tokens)
		if n.type == .BracketCurlyClose {
			tokens^ = ss // eat closing }
			break
		}

		member_type := parse_ast_declaration(ast, tokens, &members, &node) or_return

		_, sem_err := eat_token_expect(tokens, .Semicolon)
		if (member_type == .VariableDeclaration || member_type == .Sequence) && sem_err != nil {
			err = sem_err // var declaraions must end in a semicolon
			return
		}
	}

	node.struct_or_union.members = members
	err = nil
	return
}

parse_ast_declaration :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, parent_type : ^AstNode = nil) -> (parsed_type : AstNodeType, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ast)

	defer if err != nil {
		resize(ast, ast_reset)
		tokens^ = tokens_reset
	}

	
	if parent_type != nil {
		n, ss := peek_token(tokens)

		if n.type == .Identifier && n.source == last(parent_type.struct_or_union.name).source {
			nn, nns := peek_token(&ss)
			if nn.type == .BracketRoundOpen {
				tokens^ = ss // eat initializer "name"

				initializer := parse_ast_function_def_no_return_type_and_name(ast, tokens) or_return
				initializer.function_def.function_name = make([]Token, 1);
				initializer.function_def.function_name[0] = Token {
					type = .Identifier,
					source = last(parent_type.struct_or_union.name).source,
					location = last(parent_type.struct_or_union.name).location
				}

				parent_type.struct_or_union.initializer = append_return_index(ast, initializer)
				parsed_type = .FunctionDefinition
				return
			}
		}
		else if n.type == .Tilde {
			nn, nns := peek_token(&ss)
			if nn.type == .Identifier && n.source == last(parent_type.struct_or_union.name).source  {
				nnn, nnns := peek_token(&nns)
				if nnn.type == .BracketRoundOpen {
					tokens^ = nns // eat deinitializer "~name"

					deinitializer := parse_ast_function_def_no_return_type_and_name(ast, tokens) or_return
					deinitializer.function_def.function_name = make([]Token, 1);
					deinitializer.function_def.function_name[0] = Token {
						type = .Identifier,
						source = last(parent_type.struct_or_union.name).source,
						location = last(parent_type.struct_or_union.name).location
					}

					parent_type.struct_or_union.deinitializer = append_return_index(ast, deinitializer)
					parsed_type = .FunctionDefinition
					return
				}
			}
		}
	}

	// var or fn def must have return type
	type_node := parse_ast_type(ast, tokens) or_return

	first_type_segment := type_node.type_declaration.segments[0]
	switch first_type_segment.source {
		case "struct", "class", "union":
			node := parse_ast_struct_no_keyword(ast, tokens) or_return
			node.type = first_type_segment.source == "union" ? .Union : .Struct
			eat_token_expect(tokens, .Semicolon) or_return

			append(sequence, append_return_index(ast, node))

			err = nil
			return
	}

	before_name := tokens^
	name := parse_ast_qualified_name(tokens) or_return 

	next, _ := peek_token(tokens)

	if next.type == .BracketRoundOpen {
		fndef_node := parse_ast_function_def_no_return_type_and_name(ast, tokens) or_return
		fndef_node.function_def.return_type = append_return_index(ast, type_node)
		fndef_node.function_def.function_name = name
		
		append(sequence, append_return_index(ast, fndef_node))
		parsed_type = .FunctionDefinition
	}
	else {
		tokens^ = before_name // reset to before name so the statement parses properly

		parse_ast_var_declaration_no_type(ast, tokens, type_node, sequence) or_return
		parsed_type = ast[sequence[len(sequence) - 1]].type
	}

	return
}

parse_ast_function_def :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	// int main(int a[3]) {}

	return_type_node := parse_ast_type(ast, tokens) or_return // int
	name := parse_ast_qualified_name(tokens) or_return // main

	node = parse_ast_function_def_no_return_type_and_name(ast, tokens) or_return // (int a[3]) {}

	node.function_def.function_name = name
	node.function_def.return_type = append_return_index(ast, return_type_node)

	return
}

parse_ast_function_def_no_return_type_and_name :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	// (int a[3]) {}

	node.type = .FunctionDefinition

	eat_token_expect(tokens, .BracketRoundOpen) or_return // (

	token_reset := tokens^
	ast_reset_size := len(ast)
	arguments : [dynamic]AstNodeIndex
	body_sequence : [dynamic]AstNodeIndex

	defer if err != nil {
		delete(arguments)
		delete(body_sequence)
		resize(ast, ast_reset_size)
		tokens^ = token_reset
	}


	loop: for {
		next, nexts := peek_token(tokens)
		#partial switch next.type {
			case .BracketRoundClose:
				tokens^ = nexts
				break loop

			case .Comma:
				tokens^ = nexts
				continue

			case:
				type := parse_ast_type(ast, tokens) or_return

				name, names := peek_token(tokens) // name is optionan
				arg_node := AstNode { type = .VariableDeclaration }
				if name.type == .Identifier {
					tokens^ = names
					arg_node.var_declaration.var_name = name

					if nn, nns := peek_token(tokens); nn.type == .Assign {
						tokens^ = nns

						initializer := parse_ast_expression(ast, tokens, false) or_return
						arg_node.var_declaration.initializer_expression = append_return_index(ast, initializer)
					}
				}
				
				
				arg_node.var_declaration.type = append_return_index(ast, type)
				append(&arguments, append_return_index(ast, arg_node))
		}
	}

	t, sss := peek_token(tokens)
	if t.type == .Semicolon {
		node.function_def.is_forward_declaration = true;
	}
	else if t.type == .BracketCurlyOpen {
		tokens^ = sss // eat {

		for {
			n, ss := peek_token(tokens)
			if n.type == .BracketCurlyClose {
				tokens^ = ss // eat closing }
				break
			}

			parse_ast_statement(ast, tokens, &body_sequence) or_return
			eat_token_expect(tokens, .Semicolon) or_return
		}

		node.function_def.body_sequence = body_sequence
	}
	else {
		err = t
		return
	}

	node.function_def.arguments = arguments
	err = nil
	return
}

parse_ast_statement :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex) -> (err : AstError)
{
	token_reset := tokens^
	ast_reset_size := len(ast)
	sequence_reset := len(sequence)

	defer if err != nil {
		resize(sequence, sequence_reset)
		resize(ast, ast_reset_size)
		tokens^ = token_reset
	}

	err, _ = peek_token(tokens)
	if type_node, type_err := parse_ast_type(ast, tokens); type_err == nil {
		if len(type_node.type_declaration.segments) == 1 {
			switch type_node.type_declaration.segments[0].source {
				case "return":
					node := AstNode{ type = .Return }
					if return_expr, expr_err := parse_ast_expression(ast, tokens); expr_err == nil {
						node.return_.expression = append_return_index(ast, return_expr);
					}
					append(sequence, append_return_index(ast, node))
					err = nil
					return

				case "break":
					append(sequence, append_return_index(ast, AstNode{ type = .Break }))
					err = nil
					return

				case "continue":
					append(sequence, append_return_index(ast, AstNode{ type = .Continue }))
					err = nil
					return
			}
		}

		err = parse_ast_var_declaration_no_type(ast, tokens, type_node, sequence)
		if err == nil {
			return
		}
	}

	//reset state after we failed to parse an assignment
	tokens^ = token_reset

	expression := parse_ast_expression(ast, tokens) or_return
	append(sequence, append_return_index(ast, expression))

	err = nil
	return
}

parse_ast_var_declaration_no_type :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, base_type : AstNode, sequence : ^[dynamic]AstNodeIndex) -> (err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ast)
	sequence_reset := len(sequence)

	defer if err != nil {
		resize(sequence, sequence_reset)
		resize(ast, ast_reset)
		tokens^ = tokens_reset
	}

	current_type : AstNode
	err, _ = peek_token(tokens)

	loop: for {
		next, ns := peek_token(tokens)
		#partial switch next.type {
			case .Identifier:
				next_next, nns := peek_token(&ns)
				#partial switch next_next.type {
					case .Assign:
						tokens^ = nns
						value := parse_ast_expression(ast, tokens, false) or_return
						decl_node := AstNode{ type = .VariableDeclaration, var_declaration = {
							type = append_return_index(ast, base_type),
							var_name = next,
							initializer_expression = append_return_index(ast, value),
						}}
						append(sequence, append_return_index(ast, decl_node))
						err = nil

					case .BracketSquareOpen:
						tokens^ = nns

						length_expression := parse_ast_expression(ast, tokens, false) or_return
						eat_token_expect(tokens, .BracketSquareClose) or_return
						
						if current_type.type == ._Unknown { current_type = clone_node(base_type) }
						current_type.type_declaration.array_length_expression = append_return_index(ast, current_type)
						err = nil

					case .Comma:
						tokens^ = nns

						decl_node := AstNode{ type = .VariableDeclaration, var_declaration = {
							type = append_return_index(ast, current_type.type == ._Unknown ? base_type : current_type),
							var_name = next,
						}}
						append(sequence, append_return_index(ast, decl_node))
						
						current_type.type = ._Unknown // @leak
						err = tokens[0]

					case .Semicolon:
						tokens^ = ns // don't eat the semicolon

						decl_node := AstNode{ type = .VariableDeclaration, var_declaration = {
							type = append_return_index(ast, current_type.type == ._Unknown ? base_type : current_type),
							var_name = next,
						}}
						append(sequence, append_return_index(ast, decl_node))
						err = nil
						return

					case:
						err = tokens[0]
						return
				}
			
			case .Comma:
				//         v
				// int a[1], b
				tokens^ = ns

				current_type.type = ._Unknown // @leak
				err = tokens[0]


			case .Star:
				//        v
				// int a, *b
				tokens^ = ns

				if current_type.type == ._Unknown { current_type = clone_node(base_type) }
				append(&current_type.type_declaration.segments, next)
				err = tokens[0]
			
			case:
				break loop
		}
	}

	return
}

parse_ast_function_call :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ast)
	arguments : [dynamic]AstNodeIndex

	defer if err != nil {
		delete(arguments)
		resize(ast, ast_reset)
		tokens^ = tokens_reset
	}


	qualified_name : TokenRange
	qualified_name = parse_ast_qualified_name(tokens) or_return
	eat_token_expect(tokens, .BracketRoundOpen) or_return
	for {
		t := eat_token(tokens)

		#partial switch t.type {
			case .BracketRoundClose:
				err = nil
				node = AstNode{ type = .FunctionCall, function_call = { 
					qualified_name = qualified_name,
					parameters =  arguments,
				}}
				return
			
			case .Comma:
				continue

			case:
				arg := parse_ast_expression(ast, tokens, false) or_return
				
				append(&arguments, append_return_index(ast, arg))
		}
	}
}

parse_ast_type :: proc(ast :  ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	range := parse_ast_type_inner(tokens) or_return

	node = AstNode { type = .Type }
	resize(&node.type_declaration.segments, len(range))
	copy(node.type_declaration.segments[:], range)
	return
}
parse_ast_type_inner :: proc(tokens : ^[]Token) -> (type : TokenRange, err : AstError)
{
	// int
	// const int
	// int const
	// const char***
	// const ::char const** const&

	start := find_next_actual_token(tokens)

	has_name := false

	type_loop: for {
		n, s := peek_token(tokens)
		
		#partial switch n.type {
			case .Ampersand, .Star:
				tokens^ = s
				continue

			case .Identifier:
				switch n.source {
					case "const", "short", "long", "unsigned", "signed":
						tokens^ = s
						continue

					case:
						if has_name { break type_loop }

						parse_ast_qualified_name(tokens)
						has_name = true
						
				}

			case .BracketTriangleOpen:
				tokens^ = s
				parse_ast_type_inner(tokens)
				eat_token_expect(tokens, .BracketTriangleClose) // closing >

			case:
				break type_loop
		}
	}

	range := slice_from_se(start, raw_data(tokens^))
	return range, len(range) > 0 ? nil : start[0]
}

parse_ast_qualified_name :: proc(tokens : ^[]Token) -> (r : TokenRange, err : AstError)
{
	start := find_next_actual_token(tokens)

	last_comp_was_ident := false
	loop: for {
		t, s := peek_token(tokens)
		#partial switch t.type {
			case .StaticScopingOperator:
				tokens^ = s
				last_comp_was_ident = false

			case .Identifier:
				if last_comp_was_ident { break loop }
				tokens^ = s
				last_comp_was_ident = true

			case:
				break loop
		}
	}

	range := slice_from_se(start, raw_data(tokens^))
	return range, len(range) > 0 ? nil : start[0]
}

parse_ast_expression :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, parse_comma_as_chain := true) -> (node : AstNode, err : AstError)
{
	token_reset := tokens^
	ast_reset_size := len(ast)
	sequence : [dynamic]AstNodeIndex

	defer if err != nil {
		delete(sequence)
		resize(ast, ast_reset_size)
		tokens^ = token_reset
	}

	// have to add this before every ok return, defer cannot modify return values
	fixup_sequence :: proc(node : ^AstNode, ast : ^[dynamic]AstNode, sequence : ^[dynamic]AstNodeIndex)
	{
		if len(sequence) > 0 {
			append(sequence, append_return_index(ast, node^)) // append last elm in sequence
			node^ = AstNode{ type = .Sequence, sequence = sequence^ }
		}
	}
	
	err, _ = peek_token(tokens)
	for {
		before_iteration := tokens^

		next, nexts := peek_token(tokens)

		if err == nil {
			#partial switch next.type {
				case .Assign, .Dot, .Plus, .Minus, .Star, .ForwardSlash, .Ampersand, .Pipe, .Circumflex, .BracketTriangleOpen, .BracketTriangleClose, .DoubleAmpersand, .DoublePipe, .Equals, .NotEquals, .LessEq, .GreaterEq:

					tokens^ = nexts

					right_node := parse_ast_expression(ast, tokens) or_return

					node = AstNode{ type = .ExprBinary, binary = {
						left = append_return_index(ast, node),
						operator = transmute(AstBinaryOp) next.type,
						right = append_return_index(ast, right_node),
					}}
					continue

				case .BracketSquareOpen:
					tokens^ = nexts
					index_expression := parse_ast_expression(ast, tokens) or_return
					eat_token_expect(tokens, .BracketSquareClose) or_return

					node = AstNode{ type = .ExprIndex, index = {
						array_expression = append_return_index(ast, node),
						index_expression = append_return_index(ast, index_expression),
					}}
					continue
			}
		}

		#partial switch next.type {
			case .Star, .Minus, .Tilde: 
				tokens^ = nexts
				right_node := parse_ast_expression(ast, tokens, false) or_return
				node = AstNode{ type = .ExprUnary, unary = {
					operator = transmute(AstUnaryOp)next.type,
					right = append_return_index(ast, right_node),
				}}
				err = nil
				continue
			
			case .LiteralFloat:
				node = AstNode{ type = .LiteralFloat, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .LiteralString:
				node = AstNode{ type = .LiteralString, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .LiteralInteger:
				node = AstNode{ type = .LiteralInteger, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .LiteralCharacter:
				node = AstNode{ type = .LiteralCharacter, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .BracketRoundOpen: // bracketed expression
				tokens^ = nexts
				node = parse_ast_expression(ast, tokens) or_return
				eat_token_expect(tokens, .BracketRoundClose) or_return
				err = nil
				continue

			case .Comma:
				if err == nil && parse_comma_as_chain {
					tokens^ = nexts // eat the ,
					append(&sequence, append_return_index(ast, node))
					err = next
					continue
				}
				else {
					if err == nil { fixup_sequence(&node, ast, &sequence) }
					return // keep ok state
				}
		}

		simple, simple_err := parse_ast_qualified_name(tokens) 
		if simple_err != nil {
			if err == nil { fixup_sequence(&node, ast, &sequence) }
			return // keep the ok state
		}
		node = AstNode{ type = .Identifier, identifier = simple }
		err = nil

		next, nexts = peek_token(tokens)
		if next.type == .BracketRoundOpen { // function call
			tokens^ = before_iteration
			node = parse_ast_function_call(ast, tokens) or_return
			continue
		}
	}
}

eat_remaining_line :: proc(tokens : ^[]Token)
{
	for len(tokens) > 0 && eat_token(tokens, false).type != .NewLine { /**/ }
}

eat_token_expect :: proc(tokens : ^[]Token, expected_type : TokenType, ignore_newline := true) -> (t : Token, err : AstError)
{
	s : []Token
	t, s = peek_token(tokens, ignore_newline)

	if t.type == expected_type {
		tokens^ = s
	}
	else {
		err = t
	}

	return
}

eat_token :: proc(tokens : ^[]Token, ignore_newline := true) -> Token
{
	for {
		t := tokens[0]
		tokens^ = tokens[1:]
		if ignore_newline && t.type == .NewLine { continue }
		return t
	}
}

peek_token :: proc(tokens : ^[]Token, ignore_newline := true) -> (t : Token, s : []Token) #no_bounds_check
{
	for i := 0; i < len(tokens); i += 1 {
		if !ignore_newline || tokens[i].type != .NewLine { return tokens[i], tokens[i + 1:] }
	}
	return {}, tokens^
}

rewind :: proc(tokens : ^[]Token, rewind_count : int) #no_bounds_check
{
	tokens^ = tokens[-rewind_count:]
}

find_next_actual_token :: proc(tokens : ^[]Token) -> [^]Token #no_bounds_check
{
	for i := 0; i < len(tokens); i += 1 {
		if tokens[i].type != .NewLine { return raw_data(tokens[i:]) }
	}
	return raw_data(tokens^)
}

AstError :: Maybe(Token)

KNOWN_TYPES :: [?]string {
	"int",
	"uint",
	"short",
	"long",
	"char",
	"byte",
	"float",
	"double",
}


AstUnaryOp :: enum {
	Dereference  = '*',
	Minus        = '-',
	Invert       = '~',
}

AstBinaryOp :: enum {
	Assign       = '=',
	Dot          = '.',
	Plus         = '+',
	Minus        = '-',
	Times        = '*',
	Divide       = '/',
	And          = '&',
	Or           = '|',
	Xor          = '^',
	Less         = '<',
	Greater      = '>',
	
	LogicAnd = cast(int)TokenType.DoubleAmpersand,
	LogicOr,
	Equals,
	NotEquals,
	LessEq,
	GreaterEq,
}

AstNodeType :: enum {
	_Unknown = 0,
	LiteralString,
	LiteralCharacter,
	LiteralInteger,
	LiteralFloat,
	LiteralBool,
	Identifier,
	Sequence,
	ExprUnary,
	ExprBinary,
	ExprIndex,
	FunctionCall,
	FunctionDefinition,
	Type,
	VariableDeclaration,
	Assert,
	Return,
	Break,
	Continue,
	Struct,
	Union,
}

AstNodeIndex :: distinct int

TokenRange :: []Token

AstNode :: struct {
	type : AstNodeType,
	using _ : struct #raw_union {
		literal : Token,
		identifier : TokenRange,
		unary : struct {
			operator : AstUnaryOp,
			right : AstNodeIndex,
		},
		binary : struct {
			left : AstNodeIndex,
			operator : AstBinaryOp,
			right : AstNodeIndex,
		},
		sequence : [dynamic]AstNodeIndex,
		function_call : struct {
			qualified_name : TokenRange,
			parameters : [dynamic]AstNodeIndex,
		},
		assert : struct {
			condition : AstNodeIndex,
			message : string,
			static : bool,
		},
		preproc_if : struct {
			condition : AstNodeIndex,
			true_branch : AstNodeIndex,
			false_branch : AstNodeIndex,
		},
		type_declaration : struct {
			segments : [dynamic]Token,
			array_length_expression : AstNodeIndex,
		},
		var_declaration : struct {
			type : AstNodeIndex,
			var_name : Token,
			initializer_expression : AstNodeIndex,
		},
		function_def : struct {
			function_name : TokenRange,
			return_type : AstNodeIndex,
			arguments : [dynamic]AstNodeIndex,
			body_sequence : [dynamic]AstNodeIndex,
			is_forward_declaration : bool,
		},
		index : struct {
			array_expression : AstNodeIndex,
			index_expression : AstNodeIndex,
		},
		return_ : struct {
			expression : AstNodeIndex,
		},
		struct_or_union : struct {
			name : TokenRange,
			base_type : TokenRange,
			members : [dynamic]AstNodeIndex,
			is_forward_declaration : bool,
			initializer : AstNodeIndex,
			deinitializer : AstNodeIndex,
		}
	}
}

clone_node :: proc(node : AstNode) -> (clone : AstNode) {
	clone = node
	#partial switch node.type {
		case .Sequence:
			clone.sequence = slice.clone_to_dynamic(node.sequence[:])
		case .Type:
			clone.type_declaration.segments = slice.clone_to_dynamic(node.type_declaration.segments[:])
		case .FunctionCall:
			clone.function_call.parameters  = slice.clone_to_dynamic(node.function_call.parameters[:])
	}
	return
}
