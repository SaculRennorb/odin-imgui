package program

import "core:fmt"
import "core:slice"
import "core:io"
import str "core:strings"


parse_ast_filescope_sequence :: proc(ast : ^[dynamic]AstNode, tokens : []Token) -> AstNode
{
	root_index := transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .Sequence }) // unfinished node at index 0
	sequence : [dynamic]AstNodeIndex

	remaining_tokens := tokens

	for len(remaining_tokens) > 0 {
		token, tokenss := peek_token(&remaining_tokens, false)
		#partial switch token.kind {
			case .NewLine:
				remaining_tokens = tokenss // eat newline
				append(&sequence, transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .NewLine }))

			case .Identifier:
				switch token.source {
					case "typedef":
						panic(fmt.tprintf("Typedef at %v not implemented.", token))

					case "struct", "class", "union":
						remaining_tokens = tokenss // eat keyword

						if node, node_err := parse_ast_struct_no_keyword(ast, &remaining_tokens); node_err == nil {
							node.kind = token.source == "union" ? .Union : .Struct
							append(&sequence, transmute(AstNodeIndex) append_return_index(ast, node))
							
							t, err := eat_token_expect(&remaining_tokens, .Semicolon)
							if err != nil { panic(fmt.tprintf("Unexpected token after %v def: %v\n", token.source, err)) }
						}
						else {
							panic(fmt.tprintf("Failed to parse %v at %v.", token.source, node_err))
						}

					case:
						if decltype, err := parse_ast_declaration(ast, &remaining_tokens, &sequence); err != nil {
							panic(fmt.tprintf("Failed to parse declaration at %v.", err))
						}
						else if _, err := eat_token_expect(&remaining_tokens, .Semicolon); err != nil {
							if decltype != .FunctionDefinition && decltype != .Namespace {
								panic(fmt.tprintf("Missing semicolon after %v at %v.", decltype, ast[last(sequence[:])^]))
							}
						}
				}

			case:
				was_preproc := #force_inline try_parse_ast_preproc_statement(ast, &remaining_tokens, &sequence, token, tokenss)
				if !was_preproc {
					panic(fmt.tprintf("Unknown token %v for sequence.", token))
				}
		}
	}

	ast[root_index].sequence = sequence
	return ast[root_index]
}

try_parse_ast_preproc_statement :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, token: Token, tokenss: []Token) -> bool
{
	#partial switch token.kind {
		case .PreprocDefine:
			tokens^ = tokenss
			node, err := parse_ast_preproc_define(ast, tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc define at %v.", err))
			}
			append(sequence, transmute(AstNodeIndex) append_return_index(ast, node))

		case .PreprocIf:
			tokens^ = tokenss
			expr, err := parse_ast_preproc_to_line_end(tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc if at %v.", err))
			}
			append(sequence, transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .PreprocIf, token_sequence = expr }))

		case .PreprocElse:
			tokens^ = tokenss
			expr, err := parse_ast_preproc_to_line_end(tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc else at %v.", err))
			}
			append(sequence, transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .PreprocElse, token_sequence = expr }))

		case .PreprocEndif:
			tokens^ = tokenss
			append(sequence, transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .PreprocEndif }))

		case:
			return false
	}

	return true
}

parse_ast_preproc_to_line_end :: proc(tokens : ^[]Token) -> (result : [dynamic]Token, err : AstError)
{
	for len(tokens) > 0 {
		t, ts := peek_token(tokens, false)
		if t.kind == .BackwardSlash {
			tokens^ = ts
			eat_token_expect(tokens, .NewLine, false) or_return
			continue
		}
		if t.kind == .NewLine {
			break;
		}

		append(&result, t)
		tokens^ = ts
	}

	return
}

parse_ast_preproc_define :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	tokens_ := parse_ast_preproc_to_line_end(tokens) or_return
	tokens__ := tokens_[:]
	tokens := &tokens__

	name := eat_token_expect(tokens, .Identifier) or_return
	next, nexts := peek_token(tokens)
	if next.kind == .BracketRoundOpen {
		tokens^ = nexts
		args : [dynamic]Token

		next, nexts = peek_token(tokens)
		for {
			if next.kind == .BracketRoundClose {
				tokens^ = nexts
				break
			}

			arg := eat_token_expect(tokens, .Identifier) or_return
			append(&args, arg)

			next, nexts = peek_token(tokens)
			if next.kind == .Comma {
				tokens^ = nexts
			}
		}

		node = AstNode { kind = .PreprocMacro, preproc_macro = { name = name, args = args[:], expansion_tokens = tokens^ } }
	}
	else {
		node = AstNode { kind = .PreprocDefine, preproc_define = { name, tokens^ } }
	}
	return
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

	if next.kind == .Identifier { // type name is optional
		tokens^ = nexts // eat the name 
		node.struct_or_union.name = next_[:1]

		next, nexts = peek_token(tokens)
		if next.kind == .Colon {
			tokens^ = nexts // eat the : 

			node.struct_or_union.base_type =  parse_ast_type_inner(tokens) or_return

			next, nexts = peek_token(tokens)
		}
	}

	if next.kind == .Semicolon {
		node.struct_or_union.is_forward_declaration = true
		err = nil
		return
	}
	
	if next.kind != .BracketCurlyOpen {
		err = next
		return
	}
	tokens^ = nexts

	parse_ast_scoped_sequence_no_open_brace(ast, tokens, parse_ast_declaration, &members, &node) or_return

	node.struct_or_union.members = members
	err = nil
	return
}

parse_ast_declaration :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, parent_type : ^AstNode = nil) -> (parsed_type : AstNodeKind, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ast)
	sequence_reset := len(sequence)

	defer if err != nil {
		resize(ast, ast_reset)
		resize(sequence, sequence_reset)
		tokens^ = tokens_reset
	}

	
	if parent_type != nil {
		n, ss := peek_token(tokens)

		if n.kind == .Identifier && n.source == last(parent_type.struct_or_union.name).source {
			nn, nns := peek_token(&ss)
			if nn.kind == .BracketRoundOpen {
				tokens^ = ss // eat initializer "name"

				initializer := parse_ast_function_def_no_return_type_and_name(ast, tokens) or_return
				initializer.function_def.function_name = make([dynamic]Token, 1);
				initializer.function_def.function_name[0] = Token {
					kind = .Identifier,
					source = last(parent_type.struct_or_union.name).source,
					location = last(parent_type.struct_or_union.name).location
				}

				parent_type.struct_or_union.initializer = transmute(AstNodeIndex) append_return_index(ast, initializer)
				parsed_type =  .FunctionDefinition
				return
			}
		}
		else if n.kind == .Tilde {
			nn, nns := peek_token(&ss)
			if nn.kind == .Identifier && n.source == last(parent_type.struct_or_union.name).source  {
				nnn, nnns := peek_token(&nns)
				if nnn.kind == .BracketRoundOpen {
					tokens^ = nns // eat deinitializer "~name"

					deinitializer := parse_ast_function_def_no_return_type_and_name(ast, tokens) or_return
					deinitializer.function_def.function_name = make([dynamic]Token, 1);
					deinitializer.function_def.function_name[0] = Token {
						kind = .Identifier,
						source = last(parent_type.struct_or_union.name).source,
						location = last(parent_type.struct_or_union.name).location
					}

					parent_type.struct_or_union.deinitializer = transmute(AstNodeIndex) append_return_index(ast, deinitializer)
					parsed_type =  .FunctionDefinition
					return
				}
			}
		}
	}

	storage := parse_ast_storage_modifier(tokens)

	// var or fn def must have return type
	type_node := parse_ast_type(ast, tokens) or_return

	first_type_segment := type_node.type[0]
	switch first_type_segment.source {
		case "struct", "class", "union":
			node := parse_ast_struct_no_keyword(ast, tokens) or_return
			node.kind = first_type_segment.source == "union" ? .Union : .Struct

			append(sequence, transmute(AstNodeIndex) append_return_index(ast, node))

			parsed_type = node.kind
			err = nil
			return

		case "namespace":
			node := AstNode{ kind = .Namespace }

			name, names := peek_token(tokens) // ffs cpp, namespace name is optional
			if name.kind == .Identifier {
				node.namespace.name = name
				tokens^ = names
			}

			eat_token_expect(tokens, .BracketCurlyOpen) or_return

			defer if err != nil && len(node.namespace.sequence) > 0 { delete(node.namespace.sequence) }
			parse_ast_scoped_sequence_no_open_brace(ast, tokens, parse_ast_declaration, &node.namespace.sequence) or_return

			append(sequence, transmute(AstNodeIndex) append_return_index(ast, node))

			parsed_type = .Namespace
			err = nil
			return
	}

	before_name := tokens^
	name := parse_ast_qualified_name(tokens) or_return 

	next, _ := peek_token(tokens)

	if next.kind == .BracketRoundOpen {
		fndef_node := parse_ast_function_def_no_return_type_and_name(ast, tokens) or_return
		fndef_node.function_def.return_type =  transmute(AstNodeIndex) append_return_index(ast, type_node)
		fndef_node.function_def.function_name = ast_filter_qualified_name(name)
		fndef_node.function_def.flags |= transmute(AstFunctionDefFlags) storage;
		
		append(sequence, transmute(AstNodeIndex) append_return_index(ast, fndef_node))
		parsed_type =  .FunctionDefinition
	}
	else {
		tokens^ = before_name // reset to before name so the statement parses properly

		parse_ast_var_declaration_no_type(ast, tokens, type_node, sequence, transmute(AstVariableDefFlags) storage) or_return
		parsed_type =  ast[sequence[len(sequence) - 1]].kind
	}

	return
}

parse_ast_storage_modifier :: proc(tokens : ^[]Token) -> (storage : AstStorageModifier)
{
	storage_loop: for {
		n, ns := peek_token(tokens)
		if n.kind != .Identifier { break }

		switch n.source {
			case "static": storage |= { .Static }
			case "thread_local": storage |= { .ThreadLocal }
			case "extern": storage |= { .Extern }
			case: break storage_loop
		}

		tokens^ = ns
	}
	return
}

parse_ast_function_def :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	// int main(int a[3]) {}

	storage := parse_ast_storage_modifier(tokens)

	return_type_node := parse_ast_type(ast, tokens) or_return // int
	name := parse_ast_qualified_name(tokens) or_return // main

	node = parse_ast_function_def_no_return_type_and_name(ast, tokens) or_return // (int a[3]) {}

	node.function_def.function_name = ast_filter_qualified_name(name)
	node.function_def.return_type =  transmute(AstNodeIndex) append_return_index(ast, return_type_node)
	node.function_def.flags = transmute(AstFunctionDefFlags) storage

	return
}

parse_ast_function_def_no_return_type_and_name :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	// (int a[3]) {}

	node.kind = .FunctionDefinition

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
		#partial switch next.kind {
			case .BracketRoundClose:
				tokens^ = nexts
				break loop

			case .Comma:
				tokens^ = nexts
				continue

			case:
				type := parse_ast_type(ast, tokens) or_return

				name, names := peek_token(tokens) // name is optionan
				arg_node := AstNode { kind = .VariableDeclaration }
				if name.kind == .Identifier {
					tokens^ = names
					arg_node.var_declaration.var_name = name

					if nn, nns := peek_token(tokens); nn.kind == .Assign {
						tokens^ = nns

						initializer := parse_ast_expression(ast, tokens, { .StopAtComma }) or_return
						arg_node.var_declaration.initializer_expression = transmute(AstNodeIndex) append_return_index(ast, initializer)
					}
				}
				
				
				arg_node.var_declaration.type = transmute(AstNodeIndex) append_return_index(ast, type)
				append(&arguments, transmute(AstNodeIndex) append_return_index(ast, arg_node))
		}
	}

	t, sss := peek_token(tokens)
	if t.kind == .Semicolon {
		node.function_def.flags |= { .ForwardDeclaration }
	}
	else if t.kind == .BracketCurlyOpen {
		tokens^ = sss // eat {

		parse_ast_scoped_sequence_no_open_brace(ast, tokens, parse_ast_statement, &body_sequence) or_return

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

parse_ast_statement :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex) -> (parsed_type : AstNodeKind, err : AstError)
{
	token_reset := tokens^
	ast_reset_size := len(ast)
	sequence_reset := len(sequence)

	defer if err != nil {
		resize(sequence, sequence_reset)
		resize(ast, ast_reset_size)
		tokens^ = token_reset
	}

	storage := parse_ast_storage_modifier(tokens)

	next, nexts := peek_token(tokens)
	#partial switch next.kind {
		case .Return:
			tokens^ = nexts

			node := AstNode{ kind = .Return }
			if return_expr, expr_err := parse_ast_expression(ast, tokens); expr_err == nil {
				node.return_.expression = transmute(AstNodeIndex) append_return_index(ast, return_expr);
			}
			append(sequence, transmute(AstNodeIndex) append_return_index(ast, node))
			parsed_type = .Return
			err = nil
			return

		case .Break:
			tokens^ = nexts
			
			append(sequence, transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .Break }))
			parsed_type = .Break
			err = nil
			return

		case .Continue:
			tokens^ = nexts

			append(sequence, transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .Continue }))
			parsed_type = .Continue
			err = nil
			return

		case .For:
			tokens^ = nexts

			eat_token_expect(tokens, .BracketRoundOpen) or_return
			initializer : [dynamic]AstNodeIndex
			defer delete(initializer)
			parse_ast_statement(ast, tokens, &initializer) or_return
			assert_eq(len(initializer), 1)
			eat_token_expect(tokens, .Semicolon) or_return
			condition := parse_ast_expression(ast, tokens) or_return
			eat_token_expect(tokens, .Semicolon) or_return
			loop_expression := parse_ast_expression(ast, tokens) or_return
			eat_token_expect(tokens, .BracketRoundClose) or_return

			body_sequence : [dynamic]AstNodeIndex
			defer if err != nil { delete(body_sequence) }
			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				parse_ast_scoped_sequence_no_open_brace(ast, tokens, parse_ast_statement, &body_sequence) or_return
			}
			else {
				parse_ast_statement(ast, tokens, &body_sequence) or_return
				eat_token_expect(tokens, .Semicolon) or_return
			}

			node_idx := transmute(AstNodeIndex) append_return_index(ast, AstNode { kind = .For, loop = {
				initializer = initializer[0],
				condition = transmute(AstNodeIndex) append_return_index(ast, condition),
				loop_statement = transmute(AstNodeIndex) append_return_index(ast, loop_expression),
				body_sequence = body_sequence,
			}})
			append(sequence, node_idx)

			parsed_type = .For
			err = nil
			return

		case .While:
			tokens^ = nexts

			eat_token_expect(tokens, .BracketRoundOpen) or_return
			condition := parse_ast_expression(ast, tokens) or_return
			eat_token_expect(tokens, .BracketRoundClose) or_return

			body_sequence : [dynamic]AstNodeIndex
			defer if err != nil { delete(body_sequence) }
			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				parse_ast_scoped_sequence_no_open_brace(ast, tokens, parse_ast_statement, &body_sequence) or_return
			}
			else {
				parse_ast_statement(ast, tokens, &body_sequence) or_return
				eat_token_expect(tokens, .Semicolon) or_return
			}

			node_idx := transmute(AstNodeIndex) append_return_index(ast, AstNode { kind = .While, loop = {
				condition = transmute(AstNodeIndex) append_return_index(ast, condition),
				body_sequence = body_sequence,
			}})
			append(sequence, node_idx)

			parsed_type = .While
			err = nil
			return

		case .Do:
			tokens^ = nexts

			body_sequence : [dynamic]AstNodeIndex
			defer if err != nil { delete(body_sequence) }
			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				parse_ast_scoped_sequence_no_open_brace(ast, tokens, parse_ast_statement, &body_sequence) or_return
			}
			else {
				parse_ast_statement(ast, tokens, &body_sequence) or_return
				eat_token_expect(tokens, .Semicolon) or_return
			}

			eat_token_expect(tokens, .While) or_return
			eat_token_expect(tokens, .BracketRoundOpen) or_return
			condition := parse_ast_expression(ast, tokens) or_return
			eat_token_expect(tokens, .BracketRoundClose) or_return

			node_idx := transmute(AstNodeIndex) append_return_index(ast, AstNode { kind = .Do, loop = {
				condition = transmute(AstNodeIndex) append_return_index(ast, condition),
				body_sequence = body_sequence,
			}})
			append(sequence, node_idx)

			parsed_type = .Do
			err = nil
			return
	}
	err = next

	if type_node, type_err := parse_ast_type(ast, tokens); type_err == nil {
		err = parse_ast_var_declaration_no_type(ast, tokens, type_node, sequence, transmute(AstVariableDefFlags) storage)
		if err == nil {
			parsed_type = .VariableDeclaration
			return
		}
	}

	//reset state after we failed to parse an assignment
	tokens^ = token_reset

	expression := parse_ast_expression(ast, tokens) or_return
	append(sequence, transmute(AstNodeIndex) append_return_index(ast, expression))

	parsed_type = expression.kind
	err = nil
	return
}

parse_ast_scoped_sequence_no_open_brace :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, fn : $F, sequence : ^[dynamic]AstNodeIndex, parent_node : ^AstNode = nil) -> (err : AstError)
{
	for {
		n, ns := peek_token(tokens, false)
		#partial switch n.kind {
			case .BracketCurlyClose:
				tokens^ = ns
				return

			case .NewLine:
				tokens^ = ns
				append(sequence, transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .NewLine }))
				continue
			
			case .Comment:
				tokens^ = ns
				append(sequence, transmute(AstNodeIndex) append_return_index(ast, AstNode{ kind = .Comment, literal = n }))
				continue
		}

		was_preproc := try_parse_ast_preproc_statement(ast, tokens, sequence, n, ns)
		if was_preproc {
			continue
		}

		when F == type_of(parse_ast_statement) {
			member_type := parse_ast_statement(ast, tokens, sequence) or_return
		}
		else when F == type_of(parse_ast_declaration) {
			member_type := parse_ast_declaration(ast, tokens, sequence, parent_node) or_return
		}
		else {
			#panic("wrong fn type")
		}

		#partial switch member_type {
			case .VariableDeclaration, .Sequence, .Struct, .Union, .Do, .ExprBinary, .ExprUnaryLeft, .ExprUnaryRight, .MemberAccess, .FunctionCall, .Return, .Break, .Continue:
				_, sem_err := eat_token_expect(tokens, .Semicolon)
				if sem_err != nil {
					err = sem_err // var declaraions must end in a semicolon
					return
				}
		}
	}

	return
}

parse_ast_var_declaration_no_type :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, base_type : AstNode, sequence : ^[dynamic]AstNodeIndex, storage_flags : AstVariableDefFlags) -> (err : AstError)
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
	last_name : Token

	loop: for {
		next, ns := peek_token(tokens)
		#partial switch next.kind {
			case .Identifier:
				last_name = next
				next_next, nns := peek_token(&ns)
				#partial switch next_next.kind {
					case .Assign: // ... a =  ...
						tokens^ = nns
						value := parse_ast_expression(ast, tokens, { .StopAtComma }) or_return
						decl_node := AstNode{ kind = .VariableDeclaration, var_declaration = {
							type = transmute(AstNodeIndex) append_return_index(ast, base_type),
							var_name = next,
							initializer_expression = transmute(AstNodeIndex) append_return_index(ast, value),
							flags = storage_flags,
						}}
						append(sequence, transmute(AstNodeIndex) append_return_index(ast, decl_node))
						err = nil

					case .BracketSquareOpen: // ... a[ ...
						tokens^ = nns

						length_expression := parse_ast_expression(ast, tokens, { .StopAtComma }) or_return
						eat_token_expect(tokens, .BracketSquareClose) or_return
						
						if current_type.kind == {} { current_type = clone_node(base_type) }
						append(&current_type.type, Token{ kind = .AstNode, location = { column = transmute(int) transmute(AstNodeIndex) append_return_index(ast, length_expression) } })
						err = nil

					case .Comma: // ... a, ...
						tokens^ = nns

						decl_node := AstNode{ kind = .VariableDeclaration, var_declaration = {
							type = transmute(AstNodeIndex) append_return_index(ast, current_type.kind == {} ? base_type : current_type),
							var_name = next,
							flags = storage_flags,
						}}
						append(sequence, transmute(AstNodeIndex) append_return_index(ast, decl_node))
						
						current_type.kind = {} // @leak
						err = tokens[0]

					case .Semicolon: // ... a;
						tokens^ = ns // don't eat the semicolon

						decl_node := AstNode{ kind = .VariableDeclaration, var_declaration = {
							type = transmute(AstNodeIndex) append_return_index(ast, current_type.kind == {} ? base_type : current_type),
							var_name = next,
							flags = storage_flags,
						}}
						append(sequence, transmute(AstNodeIndex) append_return_index(ast, decl_node))
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

				decl_node := AstNode{ kind = .VariableDeclaration, var_declaration = {
					type = transmute(AstNodeIndex) append_return_index(ast, current_type),
					var_name = last_name,
					flags = storage_flags,
				}}
				append(sequence, transmute(AstNodeIndex) append_return_index(ast, decl_node))

				current_type.kind = {} // @leak
				err = tokens[0]


			case .Star:
				//        v
				// int a, *b
				tokens^ = ns

				if current_type.kind == {} { current_type = clone_node(base_type) }
				append(&current_type.type, next)
				err = tokens[0]

			case .Semicolon:
				//         v
				// int b[3];

				// don't eat the semicolon

				if current_type.kind != {} {
					decl_node := AstNode{ kind = .VariableDeclaration, var_declaration = {
						type = transmute(AstNodeIndex) append_return_index(ast, current_type),
						var_name = last_name,
						flags = storage_flags,
					}}
					append(sequence, transmute(AstNodeIndex) append_return_index(ast, decl_node))

					err = nil
				}
				return

			
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


	qualified_name := parse_ast_qualified_name(tokens) or_return
	eat_token_expect(tokens, .BracketRoundOpen) or_return
	for {
		t := eat_token(tokens)

		#partial switch t.kind {
			case .BracketRoundClose:
				err = nil
				node = AstNode{ kind = .FunctionCall, function_call = { 
					qualified_name = ast_filter_qualified_name(qualified_name),
					parameters =  arguments,
				}}
				return
			
			case .Comma:
				continue

			case:
				arg := parse_ast_expression(ast, tokens, { .StopAtComma }) or_return
				
				append(&arguments, transmute(AstNodeIndex) append_return_index(ast, arg))
		}
	}
}

parse_ast_type :: proc(ast :  ^[dynamic]AstNode, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	range := parse_ast_type_inner(tokens) or_return

	node = AstNode { kind = .Type }
	resize(&node.type, len(range))
	copy(node.type[:], range)

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
	has_int_modifier := false

	type_loop: for {
		n, s := peek_token(tokens)
		
		#partial switch n.kind {
			case .Ampersand, .Star:
				tokens^ = s
				continue

			case .Identifier:
				switch n.source {
					case "short", "long":
						tokens^ = s
						has_int_modifier = true
						continue

					case "const", "unsigned", "signed":
						tokens^ = s
						continue

					case "int":
						tokens^ = s
						has_name = true
						continue

					case:
						if has_name || has_int_modifier { break type_loop }

						before := tokens^;

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
		#partial switch t.kind {
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

ast_filter_qualified_name :: proc(tokens : TokenRange) -> (dest : [dynamic]Token)
{
	reserve(&dest, len(tokens))
	for segment in tokens {
		if segment.kind == .StaticScopingOperator { continue }
		append(&dest, segment)
	}
	return
}

ExpressionParserFlags :: bit_set[enum { StopAtComma, StopAtMemberAccess }]
parse_ast_expression :: proc(ast : ^[dynamic]AstNode, tokens : ^[]Token, flags : ExpressionParserFlags = {}) -> (node : AstNode, err : AstError)
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
			append(sequence, transmute(AstNodeIndex) append_return_index(ast, node^)) // append last elm in sequence
			node^ = AstNode{ kind = .Sequence, sequence = sequence^ }
		}
	}
	
	err, _ = peek_token(tokens)
	for {
		before_iteration := tokens^

		next, nexts := peek_token(tokens)

		if err == nil {
			#partial switch next.kind {
				case .Dot, .DereferenceMember:
					if .StopAtMemberAccess in flags {
						if err == nil { fixup_sequence(&node, ast, &sequence) }
						return
					}

					tokens^ = nexts // eat -> 

					right_node := parse_ast_expression(ast, tokens, { .StopAtComma, .StopAtMemberAccess }) or_return

					node = AstNode{ kind = .MemberAccess, member_access = {
						expression = transmute(AstNodeIndex) append_return_index(ast, node),
						member = transmute(AstNodeIndex) append_return_index(ast, right_node),
						through_pointer = next.kind != .Dot,
					}}

					continue

				case .Assign, .Plus, .Minus, .Star, .ForwardSlash, .Ampersand, .Pipe, .Circumflex, .BracketTriangleOpen, .BracketTriangleClose, .DoubleAmpersand, .DoublePipe, .Equals, .NotEquals, .LessEq, .GreaterEq:
					tokens^ = nexts

					right_node := parse_ast_expression(ast, tokens) or_return

					node = AstNode{ kind = .ExprBinary, binary = {
						left = transmute(AstNodeIndex) append_return_index(ast, node),
						operator = transmute(AstBinaryOp) next.kind,
						right = transmute(AstNodeIndex) append_return_index(ast, right_node),
					}}

					continue

				case .BracketSquareOpen:
					tokens^ = nexts

					index_expression := parse_ast_expression(ast, tokens) or_return
					eat_token_expect(tokens, .BracketSquareClose) or_return

					node = AstNode{ kind = .ExprIndex, index = {
						array_expression = transmute(AstNodeIndex) append_return_index(ast, node),
						index_expression = transmute(AstNodeIndex) append_return_index(ast, index_expression),
					}}
					continue

				case .PostfixIncrement, .PostfixDecrement:
					tokens^ = nexts

					node = AstNode{ kind = .ExprUnaryRight, unary_right = {
						operator = next.kind == .PostfixIncrement ? .Increment : .Decrement,
						left = transmute(AstNodeIndex) append_return_index(ast, node),
					}}
					continue
			}
		}

		#partial switch next.kind {
			case .Star, .Minus, .Tilde, .PrefixDecrement, .PrefixIncrement:
				tokens^ = nexts
				right_node := parse_ast_expression(ast, tokens, { .StopAtComma }) or_return
				node = AstNode{ kind = .ExprUnaryLeft, unary_left = {
					operator = transmute(AstUnaryOp)next.kind,
					right = transmute(AstNodeIndex) append_return_index(ast, right_node),
				}}
				err = nil
				continue
			
			case .LiteralFloat:
				node = AstNode{ kind = .LiteralFloat, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .LiteralString:
				node = AstNode{ kind = .LiteralString, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .LiteralInteger:
				node = AstNode{ kind = .LiteralInteger, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .LiteralCharacter:
				node = AstNode{ kind = .LiteralCharacter, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .LiteralNull:
				node = AstNode{ kind = .LiteralNull, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .BracketRoundOpen: // bracketed expression
				tokens^ = nexts
				node = parse_ast_expression(ast, tokens) or_return
				eat_token_expect(tokens, .BracketRoundClose) or_return
				err = nil
				continue

			case .Comma:
				if err == nil && .StopAtComma not_in flags {
					tokens^ = nexts // eat the ,
					append(&sequence, transmute(AstNodeIndex) append_return_index(ast, node))
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
		node = AstNode{ kind = .Identifier, identifier = ast_filter_qualified_name(simple) }
		err = nil

		next, nexts = peek_token(tokens)
		if next.kind == .BracketRoundOpen { // function call
			tokens^ = before_iteration
			node = parse_ast_function_call(ast, tokens) or_return
			continue
		}
	}
}

eat_remaining_line :: proc(tokens : ^[]Token)
{
	for len(tokens) > 0 && eat_token(tokens, false).kind != .NewLine { /**/ }
}

eat_token_expect :: proc(tokens : ^[]Token, expected_type : TokenKind, ignore_newline := true) -> (t : Token, err : AstError)
{
	s : []Token
	t, s = peek_token(tokens, ignore_newline)

	if t.kind == expected_type {
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
		if ignore_newline && t.kind == .NewLine { continue }
		return t
	}
}

peek_token :: proc(tokens : ^[]Token, ignore_newline := true) -> (t : Token, s : []Token) #no_bounds_check
{
	for i := 0; i < len(tokens); i += 1 {
		if !ignore_newline || tokens[i].kind != .NewLine { return tokens[i], tokens[i + 1:] }
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
		if tokens[i].kind != .NewLine { return raw_data(tokens[i:]) }
	}
	return raw_data(tokens^)
}

AstError :: Maybe(Token)


AstUnaryOp :: enum {
	Dereference  = '*',
	Minus        = '-',
	Invert       = '~',
	Increment    = cast(int) TokenKind.PrefixIncrement,
	Decrement    = cast(int) TokenKind.PrefixDecrement,
}

AstBinaryOp :: enum {
	Assign       = '=',
	Plus         = '+',
	Minus        = '-',
	Times        = '*',
	Divide       = '/',
	And          = '&',
	Or           = '|',
	Xor          = '^',
	Less         = '<',
	Greater      = '>',
	
	LogicAnd = cast(int)TokenKind.DoubleAmpersand,
	LogicOr,
	Equals,
	NotEquals,
	LessEq,
	GreaterEq,
}

AstNodeKind :: enum {
	NewLine = 1,
	Comment,
	LiteralString,
	LiteralCharacter,
	LiteralInteger,
	LiteralFloat,
	LiteralBool,
	LiteralNull,
	Identifier,
	Sequence,
	Namespace,
	ExprUnaryLeft,
	ExprUnaryRight,
	ExprBinary,
	ExprIndex,
	MemberAccess,
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
	For,
	Do,
	While,

	PreprocDefine,
	PreprocMacro,
	PreprocIf,
	PreprocElse,
	PreprocEndif,
}

AstNodeIndex :: distinct int

TokenRange :: []Token

AstNode :: struct {
	kind : AstNodeKind,
	using _ : struct #raw_union {
		literal : Token,
		identifier : [dynamic]Token,
		unary_left : struct {
			operator : AstUnaryOp,
			right : AstNodeIndex,
		},
		unary_right : struct {
			operator : AstUnaryOp,
			left : AstNodeIndex,
		},
		binary : struct {
			left, right : AstNodeIndex,
			operator : AstBinaryOp,
		},
		sequence : [dynamic]AstNodeIndex,
		token_sequence : [dynamic]Token,
		namespace : struct {
			name     : Token,
			sequence : [dynamic]AstNodeIndex,
		},
		function_call : struct {
			qualified_name : [dynamic]Token,
			parameters : [dynamic]AstNodeIndex,
		},
		assert : struct {
			condition : AstNodeIndex,
			message : string,
			static : bool,
		},
		type : [dynamic]Token,
		var_declaration : struct {
			type : AstNodeIndex,
			var_name : Token,
			initializer_expression : AstNodeIndex,
			flags : AstVariableDefFlags,
		},
		function_def : struct {
			function_name : [dynamic]Token,
			return_type : AstNodeIndex,
			arguments : [dynamic]AstNodeIndex,
			body_sequence : [dynamic]AstNodeIndex,
			flags : AstFunctionDefFlags,
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
		},
		member_access : struct {
			expression, member : AstNodeIndex,
			through_pointer : bool,
		},
		preproc_define : struct {
			name : Token,
			expansion_tokens : []Token,
		},
		preproc_macro : struct {
			name : Token,
			args : []Token,
			expansion_tokens : []Token,
		},
		loop : struct {
			initializer, condition, loop_statement : AstNodeIndex,
			body_sequence : [dynamic]AstNodeIndex,
		}
	}
}

AstStorageModifier :: bit_set[enum{
	Static      = 0,
	Extern      = 1,
	ThreadLocal = 2,
}]

AstVariableDefFlags :: bit_set[enum{
	Static      = cast(int) AstStorageModifier.Static,
	Extern      = cast(int) AstStorageModifier.Extern,
	ThreadLocal = cast(int) AstStorageModifier.ThreadLocal,
}]

AstFunctionDefFlags :: bit_set[enum{
	Static = cast(int) AstStorageModifier.Static,
	Extern = cast(int) AstStorageModifier.Extern,
	ForwardDeclaration = int(AstStorageModifier.ThreadLocal) + 1,
}]

clone_node :: proc(node : AstNode) -> (clone : AstNode) {
	clone = node
	#partial switch node.kind {
		case .Sequence:
			clone.sequence = slice.clone_to_dynamic(node.sequence[:])
		case .Type:
			clone.type = slice.clone_to_dynamic(node.type[:])
		case .FunctionCall:
			clone.function_call.parameters  = slice.clone_to_dynamic(node.function_call.parameters[:])
	}
	return
}


fmt_astindex_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	idx := transmute(^AstNodeIndex)arg.data
	return fmt_astindex(fi, idx, verb)
}

@(thread_local) current_ast : ^[dynamic]AstNode
fmt_astindex :: proc(fi: ^fmt.Info, idx: ^AstNodeIndex, verb: rune) -> bool
{
	if current_ast == nil { return false }
	if idx == nil {
		io.write_string(fi.writer, "NodeIndex <nil>")
		return true
	}
	if idx^ == 0 {
		io.write_string(fi.writer, "NodeIndex 0")
		return true
	}
	
	io.write_string(fi.writer, fmt.tprintf("NodeIndex %v -> ", transmute(int) idx^))
	fmt.fmt_arg(fi, current_ast[idx^], verb)
	return true
}

fmt_astnode_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	node := transmute(^AstNode)arg.data
	return fmt_astnode(fi, node, verb)
}

fmt_astnode :: proc(fi: ^fmt.Info, node: ^AstNode, verb: rune) -> bool
{
	if current_ast == nil { return false }
	if node == nil {
		io.write_string(fi.writer, "AstNode <nil>")
		return true
	}

	io.write_string(fi.writer, fmt.tprintf("AstNode <%v>", node.kind))

	if fi.record_level > 3 {
		io.write_string(fi.writer, " { ... }")
		return true
	}
	
	switch node.kind {
		case .NewLine            :
		case .Comment            : fmt.fmt_arg(fi, node.literal, 'v')
		case .PreprocIf          : fmt.fmt_arg(fi, node.token_sequence, 'v')
		case .PreprocElse        : fmt.fmt_arg(fi, node.token_sequence, 'v')
		case .PreprocEndif       :
		case .PreprocDefine      : fmt.fmt_arg(fi, node.preproc_define, 'v')
		case .PreprocMacro       : fmt.fmt_arg(fi, node.preproc_macro, 'v')
		case .LiteralString      : fmt.fmt_arg(fi, node.literal, 'v')
		case .LiteralCharacter   : fmt.fmt_arg(fi, node.literal, 'v')
		case .LiteralInteger     : fmt.fmt_arg(fi, node.literal, 'v')
		case .LiteralFloat       : fmt.fmt_arg(fi, node.literal, 'v')
		case .LiteralBool        : fmt.fmt_arg(fi, node.literal, 'v')
		case .LiteralNull        :
		case .For                : fmt.fmt_arg(fi, node.loop, 'v')
		case .Do                 : fmt.fmt_arg(fi, node.loop, 'v')
		case .While              : fmt.fmt_arg(fi, node.loop, 'v')
		case .Identifier         : fmt.fmt_arg(fi, node.identifier, 'v')
		case .Sequence           : fmt.fmt_arg(fi, node.sequence, 'v')
		case .Namespace          : fmt.fmt_arg(fi, node.namespace, 'v')
		case .ExprUnaryLeft      : fmt.fmt_arg(fi, node.unary_left, 'v')
		case .ExprUnaryRight     : fmt.fmt_arg(fi, node.unary_right, 'v')
		case .ExprBinary         : fmt.fmt_arg(fi, node.binary, 'v')
		case .ExprIndex          : fmt.fmt_arg(fi, node.index, 'v')
		case .MemberAccess       : fmt.fmt_arg(fi, node.member_access, 'v')
		case .FunctionCall       : fmt.fmt_arg(fi, node.function_call, 'v')
		case .FunctionDefinition : fmt.fmt_arg(fi, node.function_def, 'v')
		case .Type               : fmt.fmt_arg(fi, node.type, 'v')
		case .VariableDeclaration: fmt.fmt_arg(fi, node.var_declaration, 'v')
		case .Assert             : fmt.fmt_arg(fi, node.assert, 'v')
		case .Return             : fmt.fmt_arg(fi, node.return_, 'v')
		case .Break              : fmt.fmt_arg(fi, node.identifier, 'v')
		case .Continue           : fmt.fmt_arg(fi, node.identifier, 'v')
		case .Struct             : fmt.fmt_arg(fi, node.struct_or_union, 'v')
		case .Union              : fmt.fmt_arg(fi, node.struct_or_union, 'v')
	}
	return true
}
