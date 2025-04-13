package program

import "core:fmt"
import "core:slice"
import "core:io"
import str "core:strings"

AstContext :: struct {
	ast: ^[dynamic]AstNode,
	ignore_identifiers : []string,
}

ast_parse_filescope_sequence :: proc(ctx : ^AstContext, tokens_ : []Token) -> AstNode
{
	root_index := transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .Sequence }) // unfinished node at index 0
	sequence : [dynamic]AstNodeIndex
	template_spec: [dynamic]AstNodeIndex

	tokens_ := tokens_
	tokens := &tokens_

	for len(tokens) > 0 {
		token, tokenss := peek_token(tokens, false)
		type_switch: #partial switch token.kind {
			case .NewLine:
				tokens^ = tokenss
				append(&sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .NewLine }))

			case .Comment:
				tokens^ = tokenss
				append(&sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .Comment, literal = token }))

			case .Typedef:
				tokens^ = tokenss // eat keyword

				node, err := ast_parse_typedef_no_keyword(ctx, tokens)
				if err != nil {
					panic(fmt.tprintf("Failed to parse typedef at %v.", err))
				}
				append(&sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, node))

				eat_token_expect(tokens, .Semicolon)

			case .Template:
				tokens^ = tokenss // eat keyword

				err : AstError
				template_spec, err = ast_parse_template_spec_no_keyword(ctx, tokens)
				if err != nil {
					panic(fmt.tprintf("Failed to parse template spec at %v.", err))
				}

				eat_token_expect(tokens, .NewLine, false)

			case .Struct, .Class, .Union, .Enum:
				if node, node_err := ast_parse_structure(ctx, tokens); node_err == nil {
					node.structure.template_spec = template_spec
					template_spec = make([dynamic]AstNodeIndex)

					ast_attach_comments(ctx, &sequence, &node)

					append(&sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, node))
					
					if _, err := eat_token_expect(tokens, .Semicolon); err != nil {
						panic(fmt.tprintf("Unexpected token after %v def: %v\n", token.source, err))
					}
				}
				else {
					panic(fmt.tprintf("Failed to parse %v at %v.", token.source, node_err))
				}

			case .Namespace, .Identifier:
				for name in ctx.ignore_identifiers {
					if token.source == name {
						tokens^ = tokenss
						break type_switch
					}
				}

				if node_idx, eat_paragraph, err := ast_parse_declaration(ctx, tokens, &sequence); err != nil {
					panic(fmt.tprintf("Failed to parse declaration at %v.", err))
				}
				else {
					#partial switch ctx.ast[node_idx].kind {
						case .FunctionDefinition:
							ctx.ast[node_idx].function_def.template_spec = template_spec
							template_spec = make([dynamic]AstNodeIndex)

							eat_token_expect(tokens, .Semicolon)

						case .OperatorDefinition:
							eat_token_expect(tokens, .Semicolon)

						case .Namespace:
							/**/

						case:
							if _, err := eat_token_expect(tokens, .Semicolon); err != nil {
									panic(fmt.tprintf("Missing semicolon after %v.", ctx.ast[node_idx]))
							}
					}

					if eat_paragraph {
						eat_token_expect(tokens, .NewLine, false)
						eat_token_expect(tokens, .NewLine, false)
					}
				}

			case:
				was_preproc := #force_inline try_ast_parse_preproc_statement(ctx, tokens, &sequence, token, tokenss)
				if !was_preproc {
					panic(fmt.tprintf("Unknown token %v for sequence.", token))
				}
		}
	}

	ctx.ast[root_index].sequence = sequence
	return ctx.ast[root_index]
}

try_ast_parse_preproc_statement :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, token: Token, tokenss: []Token) -> bool
{
	#partial switch token.kind {
		case .PreprocDefine:
			tokens^ = tokenss
			node, err := ast_parse_preproc_define(ctx, tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc define at %v.", err))
			}
			append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, node))

		case .PreprocIf:
			tokens^ = tokenss
			expr, err := ast_parse_preproc_to_line_end(tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc if at %v.", err))
			}
			append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .PreprocIf, token_sequence = expr }))

		case .PreprocElse:
			tokens^ = tokenss
			expr, err := ast_parse_preproc_to_line_end(tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc else at %v.", err))
			}
			append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .PreprocElse, token_sequence = expr }))

		case .PreprocEndif:
			tokens^ = tokenss
			append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .PreprocEndif }))

		case:
			return false
	}

	return true
}

ast_parse_preproc_to_line_end :: proc(tokens : ^[]Token) -> (result : [dynamic]Token, err : AstError)
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

ast_parse_preproc_define :: proc(ctx: ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	tokens_ := ast_parse_preproc_to_line_end(tokens) or_return
	tokens__ := tokens_[:]
	tokens := &tokens__

	name := eat_token_expect(tokens, .Identifier) or_return
	next, nexts := peek_token(tokens)
	if next.kind == .BracketRoundOpen {
		tokens^ = nexts
		args : [dynamic]Token

		arg_loop: for {
			next, nexts = peek_token(tokens)
			#partial switch next.kind {
				case .BracketRoundClose:
					tokens^ = nexts
					break arg_loop
					
				case .Identifier:
					tokens^ = nexts
					append(&args, next)

					next, nexts = peek_token(tokens)
					if next.kind == .Comma {
						tokens^ = nexts
					}

				case .Ellipsis:
					tokens^ = nexts
					append(&args, next)
			}
		}

		node = AstNode { kind = .PreprocMacro, preproc_macro = { name = name, args = args[:], expansion_tokens = tokens^ } }
	}
	else {
		node = AstNode { kind = .PreprocDefine, preproc_define = { name, tokens^ } }
	}
	return
}

ast_parse_template_spec_no_keyword :: proc(ctx : ^AstContext, tokens : ^[]Token) -> (template_spec : [dynamic]AstNodeIndex, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)

	defer if err != nil {
		delete(template_spec)
		resize(ctx.ast, ast_reset)
		tokens^ = tokens_reset
	}

	eat_token_expect(tokens, .BracketTriangleOpen) or_return
	for {
		if n, ns := peek_token(tokens); n.kind == .BracketTriangleClose {
			tokens^ = ns
			break
		}

		type : AstNode
		if n, ns := peek_token(tokens); n.kind == .Class {
			tokens^ = ns
			
			type = AstNode { kind = .Type }
			append(&type.type, n)
		}
		else {
			type = ast_parse_type(ctx, tokens) or_return
		}
		
		
		name := tokens[0]; tokens^ = tokens[1:]
		
		initializer_expression : AstNodeIndex
		if n, ns := peek_token(tokens); n.kind == .Equals {
			tokens^ = ns // eat = 

			initializer := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return
			initializer_expression = transmute(AstNodeIndex) append_return_index(ctx.ast, initializer)
		}

		node := AstNode { kind = .VariableDeclaration, var_declaration = {
			type = transmute(AstNodeIndex) append_return_index(ctx.ast, type),
			var_name = name,
			initializer_expression = initializer_expression,
		}}
		append(&template_spec, transmute(AstNodeIndex) append_return_index(ctx.ast, node))
	}
	return
}

ast_parse_structure :: proc(ctx: ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	members : [dynamic]AstNodeIndex

	defer if err != nil {
		delete(members)
		resize(ctx.ast, ast_reset)
		tokens^ = tokens_reset
	}

	keyword := eat_token(tokens)
	#partial switch keyword.kind {
		case .Union: node.kind = .Union
		case .Enum : node.kind = .Enum
		case .Struct, .Class : node.kind = .Struct
		case: panic(fmt.tprintf("Invalid keyword to parse structure: %v.", keyword))
	}

	next_, nexts := peek_token_ptr(tokens)
	next := next_[0]

	if next.kind == .Identifier { // type name is optional
		tokens^ = nexts // eat the name 
		node.structure.name = next_[:1]

		next, nexts = peek_token(tokens)
		if next.kind == .Colon {
			tokens^ = nexts // eat the : 

			bt : [dynamic]Token
			ast_parse_type_inner(ctx, tokens, &bt) or_return
			node.structure.base_type = bt[:]

			next, nexts = peek_token(tokens)
		}
	}

	if next.kind == .Semicolon {
		node.structure.is_forward_declaration = true
		err = nil
		return
	}
	
	if next.kind != .BracketCurlyOpen {
		err = next
		return
	}
	tokens^ = nexts

	if keyword.kind == .Enum {
		ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_enum_value_declaration, &members, &node) or_return
	}
	else {
		ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_declaration, &members, &node) or_return
	}

	node.structure.members = members
	err = nil
	return
}

ast_attach_comments :: proc(ctx: ^AstContext, sequence : ^[dynamic]AstNodeIndex, attach_to : ^AstNode)
{
	start_index := 0
	loop: #reverse for sid, sidi in sequence {
		#partial switch ctx.ast[sid].kind {
			case .Comment, .NewLine:
				continue loop
			case:
				start_index = sidi + 1
				break loop
		}
	}

	// skip leading newlines
	for ; start_index < len(sequence); start_index += 1 {
		if ctx.ast[sequence[start_index]].kind != .NewLine {
			break
		}
	}

	attached_comments : ^[dynamic]AstNodeIndex
	#partial switch attach_to.kind {
		case .FunctionDefinition:
			attached_comments = &attach_to.function_def.attached_comments
		case .Struct, .Union, .Enum:
			attached_comments = &attach_to.structure.attached_comments
		case:
			unreachable()
	}

	for sid in sequence[start_index:] {
		ctx.ast[sid].attached = true
		append(attached_comments, sid)
	}
}

ast_parse_declaration :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, parent_type : ^AstNode = nil) -> (parsed_node : AstNodeIndex, eat_paragraph : bool, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	sequence_reset := len(sequence)

	defer if err != nil {
		resize(ctx.ast, ast_reset)
		resize(sequence, sequence_reset)
		tokens^ = tokens_reset
	}

	storage := ast_parse_storage_modifier(tokens)

	if parent_type != nil {
		n, ss := peek_token(tokens)

		if n.kind == .Identifier && n.source == last(parent_type.structure.name).source {
			nn, nns := peek_token(&ss)
			if nn.kind == .BracketRoundOpen {
				tokens^ = ss // eat initializer "name"

				initializer := ast_parse_function_def_no_return_type_and_name(ctx, tokens, true) or_return
				initializer.function_def.function_name = make([dynamic]Token, 1);
				initializer.function_def.flags |= transmute(AstFunctionDefFlags) storage;
				initializer.function_def.function_name[0] = Token {
					kind = .Identifier,
					source = last(parent_type.structure.name).source,
					location = last(parent_type.structure.name).location,
				}

				ast_attach_comments(ctx, sequence, &initializer)

				parent_type.structure.initializer = transmute(AstNodeIndex) append_return_index(ctx.ast, initializer)

				eat_paragraph = true
				parsed_node = parent_type.structure.initializer
				return
			}
		}
		else if n.kind == .Tilde {
			nn, nns := peek_token(&ss)
			if nn.kind == .Identifier && nn.source == last(parent_type.structure.name).source  {
				nnn, nnns := peek_token(&nns)
				if nnn.kind == .BracketRoundOpen {
					tokens^ = nns // eat deinitializer "~name"

					deinitializer := ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return
					deinitializer.function_def.function_name = make([dynamic]Token, 1);
					deinitializer.function_def.flags |= transmute(AstFunctionDefFlags) storage;
					deinitializer.function_def.function_name[0] = Token {
						kind = .Identifier,
						source = last(parent_type.structure.name).source,
						location = last(parent_type.structure.name).location,
					}

					ast_attach_comments(ctx, sequence, &deinitializer)

					parent_type.structure.deinitializer = transmute(AstNodeIndex) append_return_index(ctx.ast, deinitializer)

					eat_paragraph = true
					parsed_node = parent_type.structure.deinitializer
					return
				}
			}
		}
	}

	next, nexts := peek_token(tokens)
	#partial switch next.kind {
		case .Typedef:
			tokens^ = nexts

			node := ast_parse_typedef_no_keyword(ctx, tokens) or_return

			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, node)
			append(sequence, parsed_node)

			err = nil
			return

		case .Struct, .Class, .Union:
			node := ast_parse_structure(ctx, tokens) or_return

			ast_attach_comments(ctx, sequence, &node)

			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, node)
			append(sequence, parsed_node)

			err = nil
			return

		case .Namespace:
			tokens^ = nexts

			node := AstNode{ kind = .Namespace }

			name, names := peek_token(tokens) // ffs cpp, namespace name is optional
			if name.kind == .Identifier {
				node.namespace.name = name
				tokens^ = names
			}

			eat_token_expect(tokens, .BracketCurlyOpen) or_return

			defer if err != nil && len(node.namespace.sequence) > 0 { delete(node.namespace.sequence) }
			ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_declaration, &node.namespace.sequence) or_return

			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, node)
			append(sequence, parsed_node)

			err = nil
			return
	}

	// var or fn def must have return type
	type_node := ast_parse_type(ctx, tokens) or_return

	if next, ns := peek_token(tokens); next.kind == .Operator { // operator [](args) { ... }  might be member or static call
		tokens^ = ns

		node := AstNode{ kind = .OperatorDefinition }

		nn := eat_token(tokens);
		#partial switch nn.kind {
			// asume binary expressions, correct after fn arguments are known
			case .Tilde:              node.operator_def.kind = .Invert
			case .PrefixIncrement:    node.operator_def.kind = .Increment
			case .PostfixDecrement:   node.operator_def.kind = .Decrement
			case .Equals:             node.operator_def.kind = .Equals
			case .NotEquals:          node.operator_def.kind = .NotEquals
			case .Plus:               node.operator_def.kind = .Add
			case .Minus:              node.operator_def.kind = .Subtract
			case .Star:               node.operator_def.kind = .Multiply
			case .ForwardSlash:       node.operator_def.kind = .Divide
			case .Ampersand:          node.operator_def.kind = .BitAnd
			case .Pipe:               node.operator_def.kind = .BitOr
			case .Circumflex:         node.operator_def.kind = .BitXor
			case .Assign:             node.operator_def.kind = .Assign
			case .AssignPlus:         node.operator_def.kind = .AssignAdd
			case .AssignMinus:        node.operator_def.kind = .AssignSubtract
			case .AssignStar:         node.operator_def.kind = .AssignMultiply
			case .AssignForwardSlash: node.operator_def.kind = .AssignDivide
			case .BracketSquareOpen: 
				eat_token_expect(tokens, .BracketSquareClose) or_return
				node.operator_def.kind = .Index

			case .Identifier:
				if nn.source == "new" || nn.source == "delete" {
					break
				}
				fallthrough

			case:
				err = nn
				return
		}
			
		fn_node := ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return
		node.operator_def.underlying_function = transmute(AstNodeIndex) append_return_index(ctx.ast, fn_node)

		arg_count := parent_type != nil ? 1 : 0
		arg_count += len(fn_node.function_def.arguments)
		if arg_count == 1 {
			// fix op type to unary
			#partial switch nn.kind {
				case .Plus:      node.operator_def.kind = .UnaryPlus
				case .Minus:     node.operator_def.kind = .UanryMinus
				case .Star:      node.operator_def.kind = .Dereference
				case .Ampersand: node.operator_def.kind = .AddressOf
				case:
					err = nn
					return
			}
		}

		parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, node)
		append(sequence, parsed_node)

		eat_paragraph = true // @hardcoded
		err = nil
		return
	}

	before_name := tokens^
	if name, name_err := ast_parse_qualified_name(tokens); name_err == nil {
		next, _ = peek_token(tokens)

		if next.kind == .BracketRoundOpen {
			fndef_node := ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return
			fndef_node.function_def.return_type =  transmute(AstNodeIndex) append_return_index(ctx.ast, type_node)
			fndef_node.function_def.function_name = ast_filter_qualified_name(name)
			fndef_node.function_def.flags |= transmute(AstFunctionDefFlags) storage;
	
			ast_attach_comments(ctx, sequence, &fndef_node)
	
			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, fndef_node)
			append(sequence, parsed_node)
			return
		}
	}

	
	tokens^ = before_name // reset to before name so the statement parses properly

	ast_parse_var_declaration_no_type(ctx, tokens, type_node, sequence, transmute(AstVariableDefFlags) storage) or_return
	parsed_node =  sequence[len(sequence) - 1]

	return
}

ast_parse_enum_value_declaration :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex) -> (parsed_node : AstNodeIndex, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	sequence_reset := len(sequence)

	defer if err != nil {
		resize(ctx.ast, ast_reset)
		resize(sequence, sequence_reset)
		tokens^ = tokens_reset
	}

	node := AstNode{ kind = .VariableDeclaration }
	node.var_declaration.var_name = eat_token_expect(tokens, .Identifier) or_return

	if n, ns := peek_token(tokens); n.kind == .Assign {
		tokens^ = ns
		
		value_expr := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return
		node.var_declaration.initializer_expression = transmute(AstNodeIndex) append_return_index(ctx.ast, value_expr)
	}

	parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, node)
	append(sequence, parsed_node)

	return
}

ast_parse_storage_modifier :: proc(tokens : ^[]Token) -> (storage : AstStorageModifier)
{
	storage_loop: for {
		n, ns := peek_token(tokens)
		if n.kind != .Identifier { break }

		switch n.source {
			case "inline": storage |= { .Inline }
			case "static": storage |= { .Static }
			case "thread_local": storage |= { .ThreadLocal }
			case "extern": storage |= { .Extern }
			case "constexpr": storage |= { .Extern }
			case: break storage_loop
		}

		tokens^ = ns
	}
	return
}

ast_parse_function_def :: proc(ctx: ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	// int main(int a[3]) {}
	// int main(int a[3]) const {}

	storage := ast_parse_storage_modifier(tokens)

	return_type_node := ast_parse_type(ctx, tokens) or_return // int
	name := ast_parse_qualified_name(tokens) or_return // main

	node = ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return // (int a[3]) {}

	node.function_def.function_name = ast_filter_qualified_name(name)
	node.function_def.return_type =  transmute(AstNodeIndex) append_return_index(ctx.ast, return_type_node)
	node.function_def.flags = transmute(AstFunctionDefFlags) storage

	return
}

ast_parse_typedef_no_keyword :: proc(ctx : ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	start := raw_data(tokens^)

	for {
		next, ns := peek_token(tokens)
		if next.kind == .Semicolon { break }
		tokens^ = ns
	}

	node = AstNode { kind = .Typedef }
	
	test := raw_data(tokens^)[-1]
	if test.kind == .Identifier {
		type_tokens := slice_from_se(start, raw_data(tokens^)[-1:])
		type := ast_parse_type(ctx, &type_tokens) or_return
		assert_eq(len(type_tokens), 0)
		
		node.typedef.name = test
		node.typedef.type = transmute(AstNodeIndex) append_return_index(ctx.ast, type)
	}
	else { // fnptr
		type_tokens := slice_from_se(start, raw_data(tokens^)[1:])
		type := ast_parse_fnptr_type(ctx, &type_tokens) or_return
		node.typedef.type = transmute(AstNodeIndex) append_return_index(ctx.ast, type)
	}

	return
}

ast_parse_function_args_with_brackets :: proc(ctx: ^AstContext, tokens : ^[]Token, arguments : ^[dynamic]AstNodeIndex) -> (has_vararg : bool, err : AstError)
{
	eat_token_expect(tokens, .BracketRoundOpen) or_return

	args_loop: for {
		next, nexts := peek_token(tokens)
		#partial switch next.kind {
			case .BracketRoundClose:
				tokens^ = nexts
				break args_loop

			case .Comma:
				tokens^ = nexts
				continue

			case .Ellipsis:
				tokens^ = nexts

				append(arguments, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .Varargs }))
				has_vararg = true
				continue

			case:
				type := ast_parse_type(ctx, tokens) or_return

				nn, nns := peek_token(tokens)
				#partial switch nn.kind {
					case .Comma, .BracketRoundClose:
						var_def := AstNode{ kind = .VariableDeclaration, var_declaration = {
							type = transmute(AstNodeIndex) append_return_index(ctx.ast, type),
							// no name
						}}
						append(arguments, transmute(AstNodeIndex) append_return_index(ctx.ast, var_def))

					case: // odent or fnptr brackets
						s : [dynamic]AstNodeIndex
						ast_parse_var_declaration_no_type(ctx, tokens, type, &s, {}, true) or_return

						append(arguments, s[0])
						delete(s)
				}
		}
	}

	return
}

ast_parse_function_def_no_return_type_and_name :: proc(ctx: ^AstContext, tokens : ^[]Token, parse_initializer := false) -> (node : AstNode, err : AstError)
{
	// (int a[3]) {}
	// (int a[3]) const {}

	node.kind = .FunctionDefinition

	token_reset := tokens^
	ast_reset_size := len(ctx.ast)
	arguments : [dynamic]AstNodeIndex
	body_sequence : [dynamic]AstNodeIndex

	defer if err != nil {
		delete(arguments)
		delete(body_sequence)
		resize(ctx.ast, ast_reset_size)
		tokens^ = token_reset
	}

	has_vararg := ast_parse_function_args_with_brackets(ctx, tokens, &arguments) or_return

	t, sss := peek_token(tokens)
	for {
		if t.kind == .Identifier && t.source == "const" { // void xx(...) const {...}
			tokens^ = sss

			node.function_def.flags |= { .Const }

			t, sss = peek_token(tokens)
		}
		else if t.kind == .Identifier && (t.source == "IM_FMTARGS" || t.source == "IM_FMTLIST") { // IM_FMTARGS(1)  @hardcoded
			tokens^ = sss[3:] // skip evetything

			t, sss = peek_token(tokens)
		}
		else {
			break
		}
	}

	if parse_initializer && t.kind == .Colon {
		tokens^ = sss

		initializer_loop: for {
			t, sss = peek_token(tokens)
			#partial switch t.kind {
				case .Identifier:
					tokens^ = sss // eat the member name

					identifier := make([dynamic]Token, 1, 1)
					identifier[0] = t
					left := AstNode{ kind = .Identifier, identifier = identifier }

					eat_token_expect(tokens, .BracketRoundOpen) or_return
					expr := ast_parse_expression(ctx, tokens) or_return
					eat_token_expect(tokens, .BracketRoundClose) or_return
					
					node := AstNode { kind = .ExprBinary, binary = {
						left = transmute(AstNodeIndex) append_return_index(ctx.ast, left),
						operator = .Assign,
						right = transmute(AstNodeIndex) append_return_index(ctx.ast, expr),
					}}

					append(&body_sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .NewLine }))
					append(&body_sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, node))

				case .Comma:
					tokens^ = sss

				case:
					break initializer_loop
			}
		}
	}

	if t.kind == .Semicolon {
		node.function_def.flags |= { .ForwardDeclaration }
	}
	else if t.kind == .BracketCurlyOpen {
		tokens^ = sss // eat {

		ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &body_sequence) or_return

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

ast_parse_statement :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex) -> (parsed_node : AstNodeIndex, err : AstError)
{
	token_reset := tokens^
	ast_reset_size := len(ctx.ast)
	sequence_reset := len(sequence)

	defer if err != nil {
		resize(sequence, sequence_reset)
		resize(ctx.ast, ast_reset_size)
		tokens^ = token_reset
	}

	storage := ast_parse_storage_modifier(tokens)

	next, nexts := peek_token(tokens)
	#partial switch next.kind {
		case .Return:
			tokens^ = nexts

			node := AstNode{ kind = .Return }
			if return_expr, expr_err := ast_parse_expression(ctx, tokens); expr_err == nil {
				node.return_.expression = transmute(AstNodeIndex) append_return_index(ctx.ast, return_expr);
			}
			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, node)
			append(sequence, parsed_node)

			err = nil
			return

		case .Break:
			tokens^ = nexts
			
			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .Break })
			append(sequence, parsed_node)

			err = nil
			return

		case .Continue:
			tokens^ = nexts

			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .Continue })
			append(sequence, parsed_node)

			err = nil
			return

		case .For:
			tokens^ = nexts

			eat_token_expect(tokens, .BracketRoundOpen) or_return
			initializer : [dynamic]AstNodeIndex
			defer delete(initializer)
			ast_parse_statement(ctx, tokens, &initializer) or_return
			assert_eq(len(initializer), 1)
			eat_token_expect(tokens, .Semicolon) or_return
			condition := ast_parse_expression(ctx, tokens) or_return
			eat_token_expect(tokens, .Semicolon) or_return
			loop_expression := ast_parse_expression(ctx, tokens) or_return
			eat_token_expect(tokens, .BracketRoundClose) or_return

			body_sequence : [dynamic]AstNodeIndex
			defer if err != nil { delete(body_sequence) }
			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &body_sequence) or_return
			}
			else {
				ast_parse_statement(ctx, tokens, &body_sequence) or_return
				eat_token_expect(tokens, .Semicolon)
			}

			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode { kind = .For, loop = {
				initializer = initializer[0],
				condition = transmute(AstNodeIndex) append_return_index(ctx.ast, condition),
				loop_statement = transmute(AstNodeIndex) append_return_index(ctx.ast, loop_expression),
				body_sequence = body_sequence,
			}})
			append(sequence, parsed_node)

			err = nil
			return

		case .While:
			tokens^ = nexts

			eat_token_expect(tokens, .BracketRoundOpen) or_return
			condition := ast_parse_expression(ctx, tokens) or_return
			eat_token_expect(tokens, .BracketRoundClose) or_return

			body_sequence : [dynamic]AstNodeIndex
			defer if err != nil { delete(body_sequence) }
			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &body_sequence) or_return
			}
			else {
				ast_parse_statement(ctx, tokens, &body_sequence) or_return
				eat_token_expect(tokens, .Semicolon)
			}

			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode { kind = .While, loop = {
				condition = transmute(AstNodeIndex) append_return_index(ctx.ast, condition),
				body_sequence = body_sequence,
			}})
			append(sequence, parsed_node)

			err = nil
			return

		case .Do:
			tokens^ = nexts

			body_sequence : [dynamic]AstNodeIndex
			defer if err != nil { delete(body_sequence) }
			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &body_sequence) or_return
			}
			else {
				ast_parse_statement(ctx, tokens, &body_sequence) or_return
				eat_token_expect(tokens, .Semicolon) or_return
			}

			eat_token_expect(tokens, .While) or_return
			eat_token_expect(tokens, .BracketRoundOpen) or_return
			condition := ast_parse_expression(ctx, tokens) or_return
			eat_token_expect(tokens, .BracketRoundClose) or_return

			parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode { kind = .Do, loop = {
				condition = transmute(AstNodeIndex) append_return_index(ctx.ast, condition),
				body_sequence = body_sequence,
			}})
			append(sequence, parsed_node)

			err = nil
			return

		case .If:
			tokens^ = nexts

			node := AstNode { kind = .Branch }

			eat_token_expect(tokens, .BracketRoundOpen) or_return
			condition := ast_parse_expression(ctx, tokens) or_return
			eat_token_expect(tokens, .BracketRoundClose) or_return
			
			node.branch.condition = transmute(AstNodeIndex) append_return_index(ctx.ast, condition)

			if n, ns := peek_token(tokens); n.kind == .BracketCurlyOpen {
				tokens^ = ns // {
				ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &node.branch.true_branch_sequence) or_return
			}
			else {
				ast_parse_statement(ctx, tokens, &node.branch.true_branch_sequence) or_return
				eat_token_expect(tokens, .Semicolon)
			}

			if n, ns := peek_token(tokens); n.kind == .Else {
				if nn, nns := peek_token(&ns); nn.kind == .BracketCurlyOpen {
					tokens^ = nns // {
					ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &node.branch.false_branch_sequence) or_return
				}
				else {
					tokens^ = ns // else
					ast_parse_statement(ctx, tokens, &node.branch.false_branch_sequence) or_return
					eat_token_expect(tokens, .Semicolon) // might have a semicolon from single statement or nothing in case of ifelse chain
				}
			}

			parsed_node = transmute(AstNodeIndex) append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, node))

			err = nil
			return
	}
	err = next

	if type_node, type_err := ast_parse_type(ctx, tokens); type_err == nil {
		err = ast_parse_var_declaration_no_type(ctx, tokens, type_node, sequence, transmute(AstVariableDefFlags) storage)
		if err == nil {
			parsed_node = last(sequence[:])^
			return
		}
	}

	//reset state after we failed to parse an assignment
	tokens^ = token_reset

	expression := ast_parse_expression(ctx, tokens) or_return
	parsed_node = transmute(AstNodeIndex) append_return_index(ctx.ast, expression)
	append(sequence, parsed_node)

	err = nil
	return
}

ast_parse_scoped_sequence_no_open_brace :: proc(ctx: ^AstContext, tokens : ^[]Token, $fn : $F, sequence : ^[dynamic]AstNodeIndex, parent_node : ^AstNode = nil) -> (err : AstError)
{
	loop: for {
		n, ns := peek_token(tokens, false)
		#partial switch n.kind {
			case .BracketCurlyClose:
				tokens^ = ns
				return

			case .NewLine:
				tokens^ = ns
				append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .NewLine }))
				continue
			
			case .Comment:
				tokens^ = ns
				append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode{ kind = .Comment, literal = n }))
				continue

			case .Identifier:
				for ignore in ctx.ignore_identifiers {
					if n.source == ignore {
						tokens^ = ns
						continue loop
					}
				}
		}

		was_preproc := try_ast_parse_preproc_statement(ctx, tokens, sequence, n, ns)
		if was_preproc {
			continue
		}

		when F == type_of(ast_parse_statement) { // or ast_parse_enum_value_declaration
			member_node := fn(ctx, tokens, sequence) or_return
			eat_paragraph := false
		}
		else when F == type_of(ast_parse_declaration) {
			member_node, eat_paragraph := ast_parse_declaration(ctx, tokens, sequence, parent_node) or_return
		}
		else {
			#panic("wrong fn type")
		}

		member_kind := ctx.ast[member_node].kind
		#partial switch member_kind {
			case .FunctionDefinition: //TODO(Rennorb) @explain
				if .ForwardDeclaration not_in ctx.ast[member_node].function_def.flags { break }
				fallthrough
				
			case .VariableDeclaration, .Typedef, .Sequence, .Struct, .Union, .Do, .ExprBinary, .ExprUnaryLeft, .ExprUnaryRight, .MemberAccess, .FunctionCall, .OperatorCall, .Return, .Break, .Continue:
				when F == type_of(ast_parse_enum_value_declaration) {
					if fn == ast_parse_enum_value_declaration { // static check only tests for teh shape of the fn
						// enum value declarations (may) end in a comma
						eat_token_expect(tokens, .Comma)
					}
					else {
						// most declarations and statements must end in a semicolon
						eat_token_expect(tokens, .Semicolon) or_return
					}
				}
				else {
					// most declarations and statements must end in a semicolon
					eat_token_expect(tokens, .Semicolon) or_return
				}
		}

		#partial switch member_kind {
			case .FunctionDefinition:
				// attach comments after the declaration in the same line
				if n, ns := peek_token(tokens, false); n.kind == .Comment {
					tokens^ = ns

					append(&ctx.ast[member_node].function_def.attached_comments, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode { kind = .Comment, attached = true, literal = n }))
					append(&ctx.ast[member_node].function_def.attached_comments, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode { kind = .NewLine, attached = true }))
				}

			case .OperatorDefinition:
				// attach comments after the declaration in the same line
				if n, ns := peek_token(tokens, false); n.kind == .Comment {
					tokens^ = ns

					op_def := ctx.ast[member_node]
					fn_def := &ctx.ast[op_def.operator_def.underlying_function]
					append(&fn_def.function_def.attached_comments, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode { kind = .Comment, attached = true, literal = n }))
					append(&fn_def.function_def.attached_comments, transmute(AstNodeIndex) append_return_index(ctx.ast, AstNode { kind = .NewLine, attached = true }))
				}
		}

		if eat_paragraph {
			eat_token_expect(tokens, .NewLine, false)
			eat_token_expect(tokens, .NewLine, false)
		}
	}

	return
}

ast_parse_var_declaration_no_type :: proc(ctx: ^AstContext, tokens : ^[]Token, preparsed_type : AstNode, sequence : ^[dynamic]AstNodeIndex, storage_flags : AstVariableDefFlags, stop_at_comma := false) -> (err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	sequence_reset := len(sequence)

	defer if err != nil {
		resize(sequence, sequence_reset)
		resize(ctx.ast, ast_reset)
		tokens^ = tokens_reset
	}

	// fnptr detection        (*name)(args)
	if n, ns := peek_token(tokens); n.kind == .BracketRoundOpen {
		if nn, nns := peek_token(&ns); nn.kind == .Star {
			tokens^ = nns // skip  (*
			name := eat_token_expect(tokens, .Identifier) or_return
			eat_token_expect(tokens, .BracketRoundClose)
			arguments : [dynamic]AstNodeIndex
			ast_parse_function_args_with_brackets(ctx, tokens, &arguments)

			fn_type := AstNode{ kind = .FunctionDefinition, function_def = {
				return_type = transmute(AstNodeIndex) append_return_index(ctx.ast, preparsed_type),
				arguments = arguments,
			}}
			append(&fn_type.function_def.function_name, name)

			var_def := AstNode { kind = .VariableDeclaration, var_declaration = {
				var_name = name,
				type = transmute(AstNodeIndex) append_return_index(ctx.ast, fn_type),
			}}

			append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, var_def))

			return
		}
	}

	loop: for {
		name : Token
		current_type, width_expression, initializer_expression : AstNode
	
		next : Token; ns : []Token
		type_prefix_loop: for {
			next, ns = peek_token(tokens)
			#partial switch next.kind {
				case .Ampersand, .Star:
					//     v
					// int ***&a
					tokens^ = ns

					if current_type.kind == {} { current_type = clone_node(preparsed_type) }
					append(&current_type.type, next)

				case .Identifier:
					//         v
					// int ***&a
					tokens^ = ns

					name = next

					next, ns = peek_token(tokens)
					break type_prefix_loop

				case:
					err = next
					return
			}
		}

		// found and eaten identifier

		if next.kind == .BracketSquareOpen { // void fn(int a[]);   or  int a[3];
			tokens^ = ns

			type_extension := Token { kind = .AstNode }

			if length_expression, length_err := ast_parse_expression(ctx, tokens); length_err == nil {
				//       v
				// int a[expr];
				type_extension.location.column = append_return_index(ctx.ast, length_expression)
			}
			eat_token_expect(tokens, .BracketSquareClose) or_return

			if current_type.kind == {} { current_type = clone_node(preparsed_type) }
			append(&current_type.type, type_extension)

			next, ns = peek_token(tokens)
		}

		if next.kind == .Colon {
			tokens^ = ns

			width_expression = ast_parse_expression(ctx, tokens, .Comma - ._1) or_return

			next, ns = peek_token(tokens)
		}

		if next.kind == .Assign {
			tokens^ = ns

			initializer_expression = ast_parse_expression(ctx, tokens, .Comma - ._1) or_return

			next, ns = peek_token(tokens)
		}

		node := AstNode { kind = .VariableDeclaration, var_declaration = {
			flags = storage_flags,
			type = transmute(AstNodeIndex) append_return_index(ctx.ast, current_type.kind == {} ? preparsed_type : current_type),
			var_name = name,
			width_expression = width_expression.kind != {} ? transmute(AstNodeIndex) append_return_index(ctx.ast, width_expression) : {},
			initializer_expression = initializer_expression.kind != {} ? transmute(AstNodeIndex) append_return_index(ctx.ast, initializer_expression) : {},
		}}
		append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, node))

		if next.kind != .Comma || stop_at_comma { return }
		
		tokens^ = ns // eat ,
	}
}

ast_parse_function_call :: proc(ctx: ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	arguments : [dynamic]AstNodeIndex

	defer if err != nil {
		delete(arguments)
		resize(ctx.ast, ast_reset)
		tokens^ = tokens_reset
	}


	qualified_name := ast_parse_qualified_name(tokens) or_return
	ast_parse_function_call_arguments(ctx, tokens, &arguments) or_return

	node = AstNode{ kind = .FunctionCall, function_call = {
		qualified_name = ast_filter_qualified_name(qualified_name),
		arguments = arguments,
	}}
	return
}

ast_parse_function_call_arguments :: proc(ctx: ^AstContext, tokens : ^[]Token, arguments : ^[dynamic]AstNodeIndex) -> (err : AstError)
{
	eat_token_expect(tokens, .BracketRoundOpen) or_return
	loop: for {
		n, ns := peek_token(tokens)

		#partial switch n.kind {
			case .BracketRoundClose:
				tokens^ = ns
				break loop
			
			case .Comma:
				tokens^ = ns
				continue

			case:
				arg := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return
				append(arguments, transmute(AstNodeIndex) append_return_index(ctx.ast, arg))
		}
	}

	return
}

ast_parse_fnptr_type :: proc(ctx : ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : AstError) // @cleanup: deduplicate 
{
	return_type := ast_parse_type(ctx, tokens) or_return
	eat_token_expect(tokens, .BracketRoundOpen) or_return
	eat_token_expect(tokens, .Star) or_return
	name, _ := eat_token_expect(tokens, .Identifier)
	eat_token_expect(tokens, .BracketRoundClose) or_return

	node = ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return
	node.function_def.return_type = transmute(AstNodeIndex) append_return_index(ctx.ast, return_type)
	node.function_def.function_name = make([dynamic]Token, 0, 1)
	append(&node.function_def.function_name, name)

	return
}

ast_parse_type :: proc(ctx : ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{
	node = AstNode { kind = .Type }
	ast_parse_type_inner(ctx, tokens, &node.type) or_return

	return
}

ast_parse_type_inner :: proc(ctx : ^AstContext, tokens : ^[]Token, type : ^[dynamic]Token) -> (err : AstError)
{
	// int
	// const int
	// int const
	// const char***
	// const ::char const** const&

	type_reset := len(type)
	defer if err != nil {
		resize(type, type_reset)
	}

	has_name := false
	has_int_modifier := false

	type_loop: for {
		n, ns := peek_token(tokens)
		#partial switch n.kind {
			case .Ampersand, .Star:
				append(type, n); tokens^ = ns
				continue

			case .BracketSquareOpen:
				if nn, nns := peek_token(&ns); nn.kind == .BracketSquareClose {
					tokens^ = nns

					append(type, Token{ kind = .AstNode })

					break type_loop // []can only be the last part
				}
				else {
					tokens^ = ns
					length_expression := ast_parse_expression(ctx, tokens) or_return
					eat_token_expect(tokens, .BracketSquareClose) or_return

					append(type, Token{ kind = .AstNode, location = { column = append_return_index(ctx.ast, length_expression) } })
				}

			case .Identifier:
				switch n.source {
					case "short", "long":
						append(type, n); tokens^ = ns
						has_int_modifier = true
						continue

					case "const", "unsigned", "signed":
						append(type, n); tokens^ = ns
						continue

					case "int":
						append(type, n); tokens^ = ns
						has_name = true
						continue

					case:
						if has_name || has_int_modifier { break type_loop }

						before := tokens^;

						qname := ast_parse_qualified_name(tokens) or_return
						oldl := len(type)
						non_zero_resize(type, oldl + len(qname))
						copy(type[oldl:], qname)

						has_name = true
				}

			case .BracketTriangleOpen:
				append(type, n); tokens^ = ns

				ast_parse_type_inner(ctx, tokens, type)
				append(type, eat_token_expect(tokens, .BracketTriangleClose) or_return) // closing >

			case:
				if !has_name && !has_int_modifier { err = n }
				return
		}
	}

	return
}

ast_parse_qualified_name :: proc(tokens : ^[]Token) -> (r : TokenRange, err : AstError)
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

	end := raw_data(tokens^)
	if start > end { err = start[0]; return }

	range := slice_from_se(start, end)
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

OperatorPresedence :: enum {
	_1               = 1,
	CppCast          = 2,
	PostfixIncrement = 2,
	PostfixDecrement = 2,
	FucntionCall     = 2,
	Index            = 2,
	MemberAccess     = 2,
	PrefixIncrement  = 3,
	PrefixDecrement  = 3,
	UnaryMinus       = 3,
	Not              = 3,
	Invert           = 3,
	CCast            = 3,
	Dereference      = 3,
	AddressOf        = 3,
	Multiply         = 5,
	Divide           = 5,
	Modulo           = 5,
	Add              = 6,
	Subtract         = 6,
	Bitshift         = 7,
	Threeway         = 8,
	Comparison       = 9,
	Equality         = 10,
	BitAnd           = 11,
	BitXor           = 12,
	BitOr            = 13,
	LogicAnd         = 14,
	LogicOr          = 15,
	Tenary           = 16,
	Assign           = 16,
	AssignModify     = 16,
	Comma            = 17,
}
ast_parse_expression :: proc(ctx: ^AstContext, tokens : ^[]Token, max_presedence := max(OperatorPresedence)) -> (node : AstNode, err : AstError)
{
	token_reset := tokens^
	ast_reset_size := len(ctx.ast)
	sequence : [dynamic]AstNodeIndex

	defer if err != nil {
		delete(sequence)
		resize(ctx.ast, ast_reset_size)
		tokens^ = token_reset
	}

	// have to add this before every ok return, defer cannot modify return values
	fixup_sequence :: proc(node : ^AstNode, ctx: ^AstContext, sequence : ^[dynamic]AstNodeIndex)
	{
		if len(sequence) > 0 {
			append(sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, node^)) // append last elm in sequence
			node^ = AstNode{ kind = .Sequence, sequence = sequence^ }
		}
	}
	
	err, _ = peek_token(tokens)
	for {
		before_iteration := tokens^

		next, nexts := peek_token(tokens)

		if err == nil { // we already have a "left" and ar looking for a binary operator
			#partial switch next.kind {
				case .Dot, .DereferenceMember:
					tokens^ = nexts // eat -> or .

					member_name, ns := peek_token(tokens)

					member_node : AstNode
					if n, nns := peek_token(&ns); n.kind == .BracketRoundOpen {
						member_node = ast_parse_function_call(ctx, tokens) or_return
					}
					else {
						tokens^ = ns // eat member name

						identifier := make([dynamic]Token, 0, 1)
						append(&identifier, member_name)
						member_node = AstNode { kind = .Identifier, identifier = identifier }
					}

					node = AstNode{ kind = .MemberAccess, member_access = {
						expression = transmute(AstNodeIndex) append_return_index(ctx.ast, node),
						member = transmute(AstNodeIndex) append_return_index(ctx.ast, member_node),
						through_pointer = next.kind != .Dot,
					}}

					continue

				case .Assign, .Plus, .Minus, .Star, .ForwardSlash, .Ampersand, .Pipe, .Circumflex, .BracketTriangleOpen, .BracketTriangleClose, .DoubleAmpersand, .DoublePipe, .Equals, .NotEquals, .LessEq, .GreaterEq, .ShiftLeft, .ShiftRight, .Percent, .AssignAmpersand, .AssignCircumflex, .AssignForwardSlash, .AssignMinus, .AssignPercent, .AssignPipe, .AssignPlus, .AssignShiftLeft, .AssignShiftRight, .AssignStar:
					presedence : OperatorPresedence
					#partial switch next.kind {
						case .Assign              : presedence = .Assign
						case .Plus                : presedence = .Add
						case .Minus               : presedence = .Subtract
						case .Star                : presedence = .Multiply
						case .ForwardSlash        : presedence = .Divide
						case .Ampersand           : presedence = .BitAnd
						case .Pipe                : presedence = .BitOr
						case .Circumflex          : presedence = .BitXor
						case .BracketTriangleOpen : presedence = .Comparison
						case .BracketTriangleClose: presedence = .Comparison
						case .DoubleAmpersand     : presedence = .LogicAnd
						case .DoublePipe          : presedence = .LogicOr
						case .Equals              : presedence = .Assign
						case .NotEquals           : presedence = .Equality
						case .LessEq              : presedence = .Comparison
						case .GreaterEq           : presedence = .Comparison
						case .ShiftLeft           : presedence = .Bitshift
						case .ShiftRight          : presedence = .Bitshift
						case .Percent             : presedence = .Modulo
						case .AssignPlus, .AssignMinus, .AssignStar, .AssignForwardSlash, .AssignAmpersand, .AssignPipe, .AssignCircumflex, .AssignPercent, .AssignShiftLeft, .AssignShiftRight:
							presedence = .AssignModify
					}

					if max_presedence < presedence { break }

					tokens^ = nexts

					right_node := ast_parse_expression(ctx, tokens, presedence) or_return

					node = AstNode{ kind = .ExprBinary, binary = {
						left = transmute(AstNodeIndex) append_return_index(ctx.ast, node),
						operator = transmute(AstBinaryOp) next.kind,
						right = transmute(AstNodeIndex) append_return_index(ctx.ast, right_node),
					}}

					continue

				case .BracketSquareOpen:
					tokens^ = nexts

					index_expression := ast_parse_expression(ctx, tokens) or_return
					eat_token_expect(tokens, .BracketSquareClose) or_return

					node = AstNode{ kind = .ExprIndex, index = {
						array_expression = transmute(AstNodeIndex) append_return_index(ctx.ast, node),
						index_expression = transmute(AstNodeIndex) append_return_index(ctx.ast, index_expression),
					}}
					continue

				case .PostfixIncrement, .PostfixDecrement:
					tokens^ = nexts

					node = AstNode{ kind = .ExprUnaryRight, unary_right = {
						operator = next.kind == .PostfixIncrement ? .Increment : .Decrement,
						left = transmute(AstNodeIndex) append_return_index(ctx.ast, node),
					}}
					continue

				case .Questionmark:
					tokens^ = nexts

					true_expression := ast_parse_expression(ctx, tokens) or_return
					eat_token_expect(tokens, .Colon) or_return
					false_expression := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return

					node = AstNode{ kind = .ExprTenary, tenary = {
						condition        = transmute(AstNodeIndex) append_return_index(ctx.ast, node),
						true_expression  = transmute(AstNodeIndex) append_return_index(ctx.ast, true_expression),
						false_expression = transmute(AstNodeIndex) append_return_index(ctx.ast, false_expression),
					}}
					continue
			}
		}

		#partial switch next.kind {
			case .Star, .Ampersand, .Plus, .Minus, .Exclamationmark, .Tilde, .PrefixDecrement, .PrefixIncrement:

				presedence : OperatorPresedence
				#partial switch next.kind {
					case .Star           : presedence = .Dereference
					case .Ampersand      : presedence = .AddressOf
					case .Plus           : presedence = .UnaryMinus
					case .Minus          : presedence = .UnaryMinus
					case .Exclamationmark: presedence = .Not
					case .Tilde          : presedence = .Invert
					case .PrefixDecrement: presedence = .PrefixDecrement
					case .PrefixIncrement: presedence = .PrefixIncrement
				}

				if max_presedence < presedence { break }

				tokens^ = nexts

				right_node := ast_parse_expression(ctx, tokens, presedence) or_return
				node = AstNode{ kind = .ExprUnaryLeft, unary_left = {
					operator = transmute(AstUnaryOp)next.kind,
					right = transmute(AstNodeIndex) append_return_index(ctx.ast, right_node),
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

			case .LiteralBool:
				node = AstNode{ kind = .LiteralBool, literal = next }
				tokens^ = nexts; err = nil
				continue

			case .BracketRoundOpen: // bracketed expression or cast
				og_nexts := nexts

				if type, type_err := ast_parse_type(ctx, &nexts); type_err == nil && find_next_actual_token(&nexts)[0].kind == .BracketRoundClose { // cast: (type) expression
					eat_token_expect(&nexts, .BracketRoundClose) or_return
					expression := ast_parse_expression(ctx, &nexts, .CCast) or_return

					tokens^ = nexts

					node = AstNode { kind = .ExprCast, cast_ = {
						type = transmute(AstNodeIndex) append_return_index(ctx.ast, type),
						expression = transmute(AstNodeIndex) append_return_index(ctx.ast, expression),
					}}
				}
				else { // bracketed expression: (expression)
					tokens^ = og_nexts

					inner := ast_parse_expression(ctx, tokens) or_return
					node = AstNode { kind = .ExprBacketed, inner = transmute(AstNodeIndex) append_return_index(ctx.ast, inner)}

					eat_token_expect(tokens, .BracketRoundClose) or_return
				}

				err = nil
				continue

			case .StaticCast: // static_cast<type>(expression)
				tokens^ = nexts

				eat_token_expect(tokens, .BracketTriangleOpen) or_return
				type := ast_parse_type(ctx, tokens) or_return
				eat_token_expect(tokens, .BracketTriangleClose) or_return
				eat_token_expect(tokens, .BracketRoundOpen) or_return
				expression := ast_parse_expression(ctx, tokens) or_return
				eat_token_expect(tokens, .BracketRoundClose) or_return

				node = AstNode { kind = .ExprCast, cast_ = {
					type = transmute(AstNodeIndex) append_return_index(ctx.ast, type),
					expression = transmute(AstNodeIndex) append_return_index(ctx.ast, expression),
				}}

				err = nil
				continue

			case .Operator: // explicit operator call e.g.   operator=(a)
				tokens^ = nexts

				node = AstNode { kind = .OperatorCall }

				n := eat_token(tokens)
				#partial switch n.kind {
					// assume binary for now, adjust after counting arguments
					//case .Plus:      node.operator_call.kind = .UnaryPlus
					//case .Minus:     node.operator_call.kind = .UanryMinus
					case .Tilde             : node.operator_call.kind = .Invert
					case .PrefixIncrement   : node.operator_call.kind = .Increment
					case .PostfixDecrement  : node.operator_call.kind = .Decrement
					case .Equals            : node.operator_call.kind = .Equals
					case .NotEquals         : node.operator_call.kind = .NotEquals
					case .Plus              : node.operator_call.kind = .Add
					case .Minus             : node.operator_call.kind = .Subtract
					case .Star              : node.operator_call.kind = .Multiply
					case .ForwardSlash      : node.operator_call.kind = .Divide
					case .Assign            : node.operator_call.kind = .Assign
					case .AssignPlus        : node.operator_call.kind = .AssignAdd
					case .AssignMinus       : node.operator_call.kind = .AssignSubtract
					case .AssignStar        : node.operator_call.kind = .AssignMultiply
					case .AssignForwardSlash: node.operator_call.kind = .AssignDivide
					case .BracketSquareOpen:
						eat_token_expect(tokens, .BracketSquareClose) or_return
						node.operator_call.kind = .Index
					case:
						err = n
						return
				}

				ast_parse_function_call_arguments(ctx, tokens, &node.operator_call.parameters) or_return

				//NOTE TODO canot do this here, since it might be in a member function and tehrefore missing the first arg

				// if len(node.operator_call.parameters) == 1 {
				// 	#partial switch node.operator_call.kind {
				// 		case .Add: node.operator_call.kind = .UnaryPlus
				// 		case .Subtract: node.operator_call.kind = .UanryMinus
				// 		case .Multiply: node.operator_call.kind = .Dereference
				// 		case .BitAnd: node.operator_call.kind = .AddressOf
				// 		case:
				// 			err = n
				// 			return
				// 	}
				// }

				err = nil
				return

			case .Comma:
				if err == nil && max_presedence >= .Comma {
					tokens^ = nexts // eat the ,
					append(&sequence, transmute(AstNodeIndex) append_return_index(ctx.ast, node))
					err = next
					continue
				}
				else {
					if err == nil { fixup_sequence(&node, ctx, &sequence) }
					return // keep ok state
				}
		}

		simple, simple_err := ast_parse_qualified_name(tokens) 
		if simple_err != nil {
			if err == nil { fixup_sequence(&node, ctx, &sequence) }
			return // keep the ok state
		}
		node = AstNode{ kind = .Identifier, identifier = ast_filter_qualified_name(simple) }
		err = nil

		next, nexts = peek_token(tokens)
		if next.kind == .BracketRoundOpen { // function call
			tokens^ = before_iteration
			node = ast_parse_function_call(ctx, tokens) or_return
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

peek_token_ptr :: proc(tokens : ^[]Token, ignore_newline := true) -> (t : [^]Token, s : []Token) #no_bounds_check
{
	for i := 0; i < len(tokens); i += 1 {
		if !ignore_newline || tokens[i].kind != .NewLine { return raw_data(tokens^)[i:], tokens[i + 1:] }
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

// not castable to AstUnaryOp or AstBinaryOp
AstOverloadedOp :: enum {
	UnaryPlus,
	UanryMinus,
	Invert,
	Increment,
	Decrement,
	Dereference,
	AddressOf,

	Equals,
	NotEquals,
	
	Add,
	Subtract,
	Multiply,
	Divide,
	BitAnd,
	BitOr,
	BitXor,

	Assign,
	AssignAdd,
	AssignSubtract,
	AssignMultiply,
	AssignDivide,
	AssignBitAnd,
	AssignBitOr,
	AssignBitXor,

	Index,
}

// not castable to AstOp
AstUnaryOp :: enum {
	Dereference  = cast(int) TokenKind.Star,
	Plus         = cast(int) TokenKind.Plus,
	Minus        = cast(int) TokenKind.Minus,
	Invert       = cast(int) TokenKind.Tilde,
	Increment    = cast(int) TokenKind.PrefixIncrement, // cleanup explicit pre/post
	Decrement    = cast(int) TokenKind.PrefixDecrement, // cleanup explicit pre/post
}

// not castable to AstOp
AstBinaryOp :: enum {
	Assign           = cast(int) TokenKind.Assign,
	Plus             = cast(int) TokenKind.Plus,
	Minus            = cast(int) TokenKind.Minus,
	Times            = cast(int) TokenKind.Star,
	Divide           = cast(int) TokenKind.ForwardSlash,
	BitAnd           = cast(int) TokenKind.Ampersand,
	BitOr            = cast(int) TokenKind.Pipe,
	BitXor           = cast(int) TokenKind.Circumflex,
	Less             = cast(int) TokenKind.BracketTriangleOpen,
	Greater          = cast(int) TokenKind.BracketTriangleClose,
	Modulo           = cast(int) TokenKind.Percent,	
	LogicAnd         = cast(int) TokenKind.DoubleAmpersand,
	LogicOr          = cast(int) TokenKind.DoublePipe,
	Equals           = cast(int) TokenKind.Equals,
	NotEquals        = cast(int) TokenKind.NotEquals,
	LessEq           = cast(int) TokenKind.LessEq,
	GreaterEq        = cast(int) TokenKind.GreaterEq,
	ShiftLeft        = cast(int) TokenKind.ShiftLeft,
	ShiftRight       = cast(int) TokenKind.ShiftRight,
	AssignAdd        = cast(int) TokenKind.AssignPlus,
	AssignSubtract   = cast(int) TokenKind.AssignMinus,
	AssignMultiply   = cast(int) TokenKind.AssignStar,
	AssignDivide     = cast(int) TokenKind.AssignForwardSlash,
	AssignModulo     = cast(int) TokenKind.AssignPercent,
	AssignShiftLeft  = cast(int) TokenKind.AssignShiftLeft,
	AssignShiftRight = cast(int) TokenKind.AssignShiftRight,
	AssignBitAnd     = cast(int) TokenKind.AssignAmpersand,
	AssignBitOr      = cast(int) TokenKind.AssignPipe,
	AssignBitXor     = cast(int) TokenKind.AssignCircumflex,
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
	ExprCast,
	ExprBacketed,
	ExprTenary,
	MemberAccess,
	FunctionCall,
	OperatorCall,
	FunctionDefinition,
	OperatorDefinition,
	Type,
	VariableDeclaration,
	Assert,
	Return,
	Break,
	Continue,
	Struct,
	Union,
	Enum,
	For,
	Do,
	While,
	Branch,
	Typedef,
	Varargs,

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
	attached : bool,
	using _ : struct #raw_union {
		literal : Token,
		inner : AstNodeIndex,
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
		cast_ : struct {
			type : AstNodeIndex,
			expression : AstNodeIndex,
		},
		sequence : [dynamic]AstNodeIndex,
		token_sequence : [dynamic]Token,
		namespace : struct {
			name     : Token,
			sequence : [dynamic]AstNodeIndex,
		},
		function_call : struct {
			qualified_name : [dynamic]Token,
			arguments : [dynamic]AstNodeIndex,
		},
		operator_call : struct {
			kind : AstOverloadedOp,
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
			width_expression : AstNodeIndex,
			flags : AstVariableDefFlags,
		},
		function_def : struct {
			function_name : [dynamic]Token,
			return_type : AstNodeIndex,
			arguments : [dynamic]AstNodeIndex,
			body_sequence : [dynamic]AstNodeIndex,
			attached_comments : [dynamic]AstNodeIndex,
			template_spec : [dynamic]AstNodeIndex,
			flags : AstFunctionDefFlags,
		},
		operator_def : struct {
			kind : AstOverloadedOp,
			underlying_function : AstNodeIndex,
		},
		index : struct {
			array_expression : AstNodeIndex,
			index_expression : AstNodeIndex,
		},
		return_ : struct {
			expression : AstNodeIndex,
		},
		structure : struct {
			name : TokenRange,
			base_type : TokenRange,
			members : [dynamic]AstNodeIndex,
			initializer : AstNodeIndex,
			deinitializer : AstNodeIndex,
			attached_comments : [dynamic]AstNodeIndex,
			template_spec : [dynamic]AstNodeIndex,
			is_forward_declaration : bool,
		},
		enum_ : struct {
			name : TokenRange,
			base_type : TokenRange,
			members : [dynamic]AstNodeIndex,
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
		},
		branch : struct {
			condition : AstNodeIndex,
			true_branch_sequence, false_branch_sequence : [dynamic]AstNodeIndex,
		},
		tenary : struct {
			condition, true_expression, false_expression : AstNodeIndex,
		},
		typedef : struct {
			name : Token,
			type : AstNodeIndex,
		},
	}
}

AstStorageModifierFlag :: enum{
	Static,
	Extern,
	ThreadLocal,
	Inline,
	Constexpr,
}
AstStorageModifier :: bit_set[AstStorageModifierFlag]

AstVariableDefFlags :: bit_set[enum{
	Static      = cast(int) AstStorageModifier.Static,
	Extern      = cast(int) AstStorageModifier.Extern,
	Inline      = cast(int) AstStorageModifier.Inline,
	ThreadLocal = cast(int) AstStorageModifier.ThreadLocal,
}]

AstFunctionDefFlags :: bit_set[enum{
	Static = cast(int) AstStorageModifier.Static,
	Extern = cast(int) AstStorageModifier.Extern,
	Inline = cast(int) AstStorageModifier.Inline,
	ForwardDeclaration = cast(int) max(AstStorageModifierFlag) + 1,
	Const,
}]

clone_node :: proc(node : AstNode) -> (clone : AstNode) {
	clone = node
	#partial switch node.kind {
		case .Sequence:
			clone.sequence = slice.clone_to_dynamic(node.sequence[:])
		case .Type:
			clone.type = slice.clone_to_dynamic(node.type[:])
		case .FunctionCall:
			clone.function_call.arguments  = slice.clone_to_dynamic(node.function_call.arguments[:])
		// TODO inclomplete
	}
	return
}


fmt_astindex_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	idx := transmute(^AstNodeIndex)arg.data
	return fmt_astindex(fi, idx, verb)
}

@(thread_local) current_ast: ^[dynamic]AstNode
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
		case .Typedef            : fmt.fmt_arg(fi, node.typedef, 'v')
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
		case .Branch             : fmt.fmt_arg(fi, node.branch, 'v')
		case .Identifier         : fmt.fmt_arg(fi, node.identifier, 'v')
		case .Sequence           : fmt.fmt_arg(fi, node.sequence, 'v')
		case .Namespace          : fmt.fmt_arg(fi, node.namespace, 'v')
		case .ExprUnaryLeft      : fmt.fmt_arg(fi, node.unary_left, 'v')
		case .ExprUnaryRight     : fmt.fmt_arg(fi, node.unary_right, 'v')
		case .ExprBinary         : fmt.fmt_arg(fi, node.binary, 'v')
		case .ExprIndex          : fmt.fmt_arg(fi, node.index, 'v')
		case .ExprCast           : fmt.fmt_arg(fi, node.cast_, 'v')
		case .ExprBacketed       : fmt.fmt_arg(fi, node.inner, 'v')
		case .ExprTenary         : fmt.fmt_arg(fi, node.tenary, 'v')
		case .MemberAccess       : fmt.fmt_arg(fi, node.member_access, 'v')
		case .FunctionCall       : fmt.fmt_arg(fi, node.function_call, 'v')
		case .OperatorCall       : fmt.fmt_arg(fi, node.operator_call, 'v')
		case .FunctionDefinition : fmt.fmt_arg(fi, node.function_def, 'v')
		case .OperatorDefinition : fmt.fmt_arg(fi, node.operator_def, 'v')
		case .Type               : fmt.fmt_arg(fi, node.type, 'v')
		case .VariableDeclaration: fmt.fmt_arg(fi, node.var_declaration, 'v')
		case .Assert             : fmt.fmt_arg(fi, node.assert, 'v')
		case .Return             : fmt.fmt_arg(fi, node.return_, 'v')
		case .Break              : fmt.fmt_arg(fi, node.identifier, 'v')
		case .Continue           : fmt.fmt_arg(fi, node.identifier, 'v')
		case .Struct             : fmt.fmt_arg(fi, node.structure, 'v')
		case .Union              : fmt.fmt_arg(fi, node.structure, 'v')
		case .Enum               : fmt.fmt_arg(fi, node.enum_, 'v')
		case .Varargs            :
	}
	return true
}
