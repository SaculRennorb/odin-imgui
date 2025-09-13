package program

import "core:fmt"
import "core:slice"
import "core:io"
import "core:log"
import "base:intrinsics"
import "base:runtime"
import str "core:strings"

AstContext :: struct {
	ast: ^[dynamic]AstNode,
	type_heap : [dynamic]AstType,
	error_stack : [dynamic]AstErrorFrame,
}

@(private)
push_error :: #force_inline proc(ctx : ^AstContext, err : AstErrorFrame, code_location := #caller_location)
{
	err := err
	err.depth = len(ctx.error_stack)
	err.code_location = code_location
	append(&ctx.error_stack, err)
}

@(private)
reset_error :: #force_inline proc(ctx : ^AstContext)
{
	clear(&ctx.error_stack)
}

@(private)
has_error :: #force_inline proc(ctx : ^AstContext) -> bool
{
	return len(ctx.error_stack) != 0
}

@(private)
has_error__reset :: #force_inline proc(ctx : ^AstContext) -> (had_err : bool)
{
	had_err = len(ctx.error_stack) != 0
	reset_error(ctx)
	return
}
@(private)
has_error__clone_reset :: #force_inline proc(ctx : ^AstContext, clone_target : ^[dynamic]AstErrorFrame) -> (had_err : bool)
{
	had_err = len(ctx.error_stack) != 0
	if had_err {
		resize(clone_target, len(ctx.error_stack))
		copy(clone_target[:], ctx.error_stack[:])
	}
	reset_error(ctx)
	return
}

@(private)
format_error :: #force_inline proc(ctx : ^AstContext, message : string) -> string
{
	s := str.builder_make(context.temp_allocator)
	str.write_string(&s, message); str.write_string(&s, ":\n")
	#reverse for err in ctx.error_stack {
		str.write_byte(&s, '\t');
		str.write_string(&s, str.repeat("  ", err.depth, context.temp_allocator));
		fmt.sbprintln(&s, err)
	}
	return str.to_string(s)
}

ast_parse_filescope_sequence :: proc(ctx : ^AstContext, tokens_ : []Token) -> (sequence : [dynamic]AstNodeIndex)
{
	current_ast   = ctx.ast
	current_types = &ctx.type_heap

	if len(ctx.ast) == 0 { append(ctx.ast, AstNode{ kind = .Sequence }) } // dummy ast0 node
	if len(ctx.type_heap) == 0 { append(&ctx.type_heap, AstTypeVoid{ }) } // dummy type0 node
	template_spec: [dynamic]AstNodeIndex

	tokens_ := tokens_
	tokens := &tokens_

	for len(tokens) > 0 {
		token, tokenss := peek_token(tokens, false)
		type_switch: #partial switch token.kind {
			case .NewLine:
				tokens^ = tokenss
				append(&sequence, ast_append_node(ctx, AstNode{ kind = .NewLine }))

			case .Comment:
				tokens^ = tokenss
				append(&sequence, ast_append_node(ctx, AstNode{ kind = .Comment, literal = token }))

			case .Typedef:
				tokens^ = tokenss // eat keyword

				node, _ := ast_parse_typedef_no_keyword(ctx, tokens)
				if has_error(ctx) {
					panic(format_error(ctx, "Failed to parse typedef"))
				}
				append(&sequence, ast_append_node(ctx, node))

				eat_token_expect(tokens, .Semicolon)

			case .Template:
				tokens^ = tokenss // eat keyword

				template_spec, _ = ast_parse_template_spec_no_keyword(ctx, tokens)
				if has_error(ctx) {
					panic(format_error(ctx, "Failed to parse template spec"))
				}

				eat_token_expect_direct(tokens, .NewLine, false)

			case .Struct, .Class, .Union, .Enum:
				if structure, se := ast_parse_structure(ctx, tokens); se == .None {
					node := &ctx.ast[structure]
					node.structure.template_spec = template_spec
					template_spec = make([dynamic]AstNodeIndex)

					ast_attach_comments(ctx, &sequence, node)

					append(&sequence, structure)
					
					if _, err := eat_token_expect(tokens, .Semicolon); err != nil {
						panic(fmt.tprintf("Unexpected token after %v def: %v.", token.source, err))
					}

					if n, ns := peek_token(tokens, false); n.kind == .Comment {
						tokens^ = ns
	
						x := ast_append_node(ctx, AstNode { kind = .Comment, attached = true, literal = n })
						y := ast_append_node(ctx, AstNode { kind = .NewLine, attached = true })
						node := &ctx.ast[structure]
						append(&node.structure.attached_comments, x)
						append(&node.structure.attached_comments, y)
					}
				}
				else {
					panic(format_error(ctx, fmt.tprintf("Failed to parse %v", token.source)))
				}

			case .Namespace, .Identifier:
				decl_error : [dynamic]AstErrorFrame
				if node_idx, eat_paragraph, _ := ast_parse_declaration(ctx, tokens, &sequence); !has_error__clone_reset(ctx, &decl_error) {
					#partial switch ctx.ast[node_idx].kind {
						case .FunctionDefinition:
							ctx.ast[node_idx].function_def.template_spec = template_spec
							template_spec = make([dynamic]AstNodeIndex)
							
							eat_token_expect(tokens, .Semicolon)
							
							if n, ns := peek_token(tokens, false); n.kind == .Comment {
								tokens^ = ns
								
								x := ast_append_node(ctx, AstNode { kind = .Comment, attached = true, literal = n })
								y := ast_append_node(ctx, AstNode { kind = .NewLine, attached = true })
								fndef := &ctx.ast[node_idx].function_def
								append(&fndef.attached_comments, x)
								append(&fndef.attached_comments, y)
							}

						case .OperatorDefinition:
							eat_token_expect(tokens, .Semicolon)

							if n, ns := peek_token(tokens, false); n.kind == .Comment {
								tokens^ = ns

								
								x := ast_append_node(ctx, AstNode { kind = .Comment, attached = true, literal = n })
								y := ast_append_node(ctx, AstNode { kind = .NewLine, attached = true })
								underlying_fn := &ctx.ast[ctx.ast[node_idx].operator_def.underlying_function].function_def
								append(&underlying_fn.attached_comments, x)
								append(&underlying_fn.attached_comments, y)
							}

						case .Namespace:
							/**/

						case:
							if _, err := eat_token_expect(tokens, .Semicolon); err != nil {
								panic(fmt.tprintf("Missing semicolon after %#v.", ctx.ast[node_idx]))
							}
					}

					if eat_paragraph {
						eat_token_expect_direct(tokens, .NewLine, false)
						eat_token_expect_direct(tokens, .NewLine, false)
					}
				}
				else if call, _ := ast_parse_function_call(ctx, tokens); !has_error(ctx) { // top level macro calls
					append(&sequence, ast_append_node(ctx, call))
					eat_token_expect(tokens, .Semicolon) // might might exist
					delete(decl_error)
				}
				else {
					inject_at(&ctx.error_stack, 0, ..decl_error[:])
					panic(format_error(ctx, "Failed to parse declaration or function call"))
				}

			case:
				was_preproc := #force_inline ast_try_parse_preproc_statement(ctx, tokens, &sequence, token, tokenss)
				if !was_preproc {
					panic(fmt.tprintf("Unknown token %v for sequence, last parsed:\n%#v.", token, last(ctx.ast^)))
				}
		}
	}

	ctx.ast[0].sequence.members = sequence

	return
}

ast_try_parse_preproc_statement :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, token: Token, tokenss: []Token) -> bool
{
	#partial switch token.kind {
		case .PreprocDefine:
			tokens^ = tokenss
			node, err := ast_parse_preproc_define(ctx, tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc define: %v.", err))
			}
			append(sequence, ast_append_node(ctx, node))

		case .PreprocUndefine:
			tokens^ = tokenss
			expr, err := ast_parse_preproc_to_line_end(tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc undef: %v.", err))
			}
			append(sequence, ast_append_node(ctx, AstNode{ kind = .Comment, literal = {
				kind = .Comment,
				location = token.location,
				source = fmt.aprintf("//TODO @gen: there was a '#undef %v' here, that cannot be emulated in odin. Make sure everything works as expected."),
			}}))

		case .PreprocIf:
			tokens^ = tokenss
			expr, err := ast_parse_preproc_to_line_end(tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc if: %v.", err))
			}
			append(sequence, ast_append_node(ctx, AstNode{ kind = .PreprocIf, token_sequence = expr }))

		case .PreprocElse:
			tokens^ = tokenss
			expr, err := ast_parse_preproc_to_line_end(tokens)
			if err != nil {
				panic(fmt.tprintf("Failed to parse preproc else: %v.", err))
			}
			append(sequence, ast_append_node(ctx, AstNode{ kind = .PreprocElse, token_sequence = expr }))

		case .PreprocEndif:
			tokens^ = tokenss
			append(sequence, ast_append_node(ctx, AstNode{ kind = .PreprocEndif }))

		case:
			return false
	}

	return true
}

ast_parse_preproc_to_line_end :: proc(tokens : ^[]Token) -> (result : [dynamic]Token, err : Maybe(AstErrorFrame))
{
	for len(tokens) > 0 {
		t, ts := peek_token(tokens, false)
		if t.kind == .BackwardSlash {
			tokens^ = ts
			eat_token_expect_direct(tokens, .NewLine, false) or_return
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

ast_parse_preproc_define :: proc(ctx: ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : Maybe(AstErrorFrame))
{
	tokens_ := ast_parse_preproc_to_line_end(tokens) or_return
	tokens__ := tokens_[:]
	tokens := &tokens__

	name := eat_token_expect(tokens, .Identifier) or_return
	//TODO(Rennorb): Put more of the preproc parsing in the tokenizer
	is_fn_macro :: proc(name : string) -> bool #no_bounds_check { return name[len(name)] == '(' } // @hack
	if is_fn_macro(name.source) {
		eat_token_expect(tokens, .BracketRoundOpen) or_return // (
		args : [dynamic]Token

		arg_loop: for {
			next, nexts := peek_token(tokens)
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

ast_parse_template_spec_no_keyword :: proc(ctx : ^AstContext, tokens : ^[]Token, loc := #caller_location) -> (template_spec : [dynamic]AstNodeIndex, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)

	defer if err != .None {
		push_error(ctx, { message = "Failed to parse template spec" }, loc)
		delete(template_spec)
		resize(ctx.ast, ast_reset)
		tokens^ = tokens_reset
	}

	eat_token_expect_push_err(ctx, tokens, .BracketTriangleOpen) or_return
	loop: for {
		#partial switch n, ns := peek_token(tokens); n.kind {
			case .BracketTriangleClose:
				tokens^ = ns
				break loop

			case .Comma:
				tokens^ = ns
		}

		type : AstTypeIndex
		if n, ns := peek_token(tokens); n.kind == .Class {
			tokens^ = ns

			type = ast_append_type(ctx, AstTypeFragment{ identifier = n })
		}
		else {
			type = ast_parse_type(ctx, tokens) or_return
		}

		name := tokens[0]; tokens^ = tokens[1:]
		
		initializer_expression : AstNodeIndex
		if n, ns := peek_token(tokens); n.kind == .Assign {
			tokens^ = ns // eat = 

			initializer := ast_parse_expression(ctx, tokens, .Comparison - ._1) or_return
			initializer_expression = ast_append_node(ctx, initializer)
		}

		node := AstNode { kind = .TemplateVariableDeclaration, var_declaration = {
			type = type,
			var_name = name,
			initializer_expression = initializer_expression,
		}}
		append(&template_spec, ast_append_node(ctx, node))
	}
	return
}

ast_parse_structure :: proc(ctx: ^AstContext, tokens : ^[]Token, loc := #caller_location) -> (parsed_node : AstNodeIndex, err : AstError)
{
	node : AstNode
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	members : [dynamic]AstNodeIndex

	defer if err != .None {
		push_error(ctx, { message = "Failed to parse structure", actual = first_or_nil(tokens^) }, loc)
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

	next, nexts := peek_token(tokens)
	if next.kind == .Identifier { // type name is optional
		node.structure.name, _ = ast_try_parse_qualified_name(ctx, tokens)

		next, nexts = peek_token(tokens)
		if next.kind == .Colon {
			tokens^ = nexts // eat the : 

			//NOTE(Rennorb): no multiple inheritance for now

			#partial switch n, ns := peek_token(tokens); n.kind {
				case .Public, .Protected, .Private:
					tokens^ = ns
			}

			node.structure.base_type = ast_parse_type(ctx, tokens) or_return

			next, nexts = peek_token(tokens)
		}
	}

	if next.kind == .Semicolon {
		node.structure.flags |= {.IsForwardDeclared}
		parsed_node = ast_append_node(ctx, node)
		return
	}
	
	if next.kind != .BracketCurlyOpen {
		err = .Some
		push_error(ctx, { actual = next, expected = { kind = .BracketCurlyOpen }})
		return
	}
	tokens^ = nexts

	if keyword.kind == .Enum {
		ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_enum_value_declaration, &members, &node) or_return
	}
	else {
		ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_declaration, &members, &node, true) or_return
	}

	node.structure.members = members

	parsed_node = ast_append_node(ctx, node)

	synthetic_structure_type : AstTypeIndex
	for name_frag := node.structure.name; name_frag != {}; {
		name_frag_node := ctx.ast[name_frag]
		synthetic_structure_type = ast_append_type(ctx, AstTypeFragment{
			identifier = name_frag_node.identifier.token,
			parent_fragment = synthetic_structure_type,
		})
		name_frag = name_frag_node.identifier.parent
	}

	var := ast_append_node(ctx, AstNode{ kind = .VariableDeclaration, var_declaration = {
		type     = synthetic_structure_type,
		var_name = Token{ kind = .Identifier, source = "this" },
	}})
	ctx.ast[parsed_node].structure.synthetic_this_var = var

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
				if len(sequence) > sidi + 1 && ctx.ast[sequence[sidi + 1]].kind != .NewLine {
					// check for the case of 
					//  int i; // some comment for i
					//  // some attached comment
					//  function()
					// and don't attach  "some comment for i"
					start_index = sidi + 2
				}
				else {
					start_index = sidi + 1
				}
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
		case .OperatorDefinition:
			attached_comments = &ctx.ast[attach_to.operator_def.underlying_function].function_def.attached_comments
		case:
			unreachable()
	}

	for sid in sequence[start_index:] {
		ctx.ast[sid].attached = true
		append(attached_comments, sid)
	}
}

ast_parse_declaration :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, parent_type : ^AstNode = nil, parse_width_expression := false, loc := #caller_location) -> (parsed_node : AstNodeIndex, eat_paragraph : bool, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	sequence_reset := len(sequence)

	defer if err != .None {
		push_error(ctx, { message = "Failed to parse declaration", actual = first_or_nil(tokens^) }, loc)
		resize(ctx.ast, ast_reset)
		resize(sequence, sequence_reset)
		tokens^ = tokens_reset
	}

	template_spec : [dynamic]AstNodeIndex
	if n, ns := peek_token(tokens); n.kind == .Template {
		tokens^ = ns
		template_spec = ast_parse_template_spec_no_keyword(ctx, tokens) or_return
	}

	storage := ast_parse_storage_modifier(tokens)

	if parent_type != nil && parent_type.structure.name != 0 /* anonymous types don't have a name */ {
		n, ss := peek_token(tokens)

		if n.kind == .Identifier && n.source == ctx.ast[parent_type.structure.name].identifier.token.source {
			nn, nns := peek_token(&ss)
			if nn.kind == .BracketRoundOpen {
				tokens^ = ss // eat initializer "name"

				initializer := ast_parse_function_def_no_return_type_and_name(ctx, tokens, true) or_return
				initializer.function_def.flags |= transmute(AstFunctionDefFlags) storage  | {.IsCtor}
				initializer.function_def.function_name = append_simple_identifier(ctx, n)

				ast_attach_comments(ctx, sequence, &initializer)

				parsed_node = ast_append_node(ctx, initializer)
				return
			}
		}
		else if n.kind == .Tilde {
			nn, nns := peek_token(&ss)
			if nn.kind == .Identifier && nn.source == ctx.ast[parent_type.structure.name].identifier.token.source  {
				nnn, nnns := peek_token(&nns)
				if nnn.kind == .BracketRoundOpen {
					tokens^ = nns // eat deinitializer "~name"

					deinitializer := ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return
					deinitializer.function_def.flags |= transmute(AstFunctionDefFlags) storage | {.IsDtor}
					deinitializer.function_def.function_name = append_simple_identifier(ctx, nn)

					ast_attach_comments(ctx, sequence, &deinitializer)

					parsed_node = ast_append_node(ctx, deinitializer)
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

			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return

		case .Struct, .Class, .Union:
			parsed_node = ast_parse_structure(ctx, tokens) or_return

			ast_attach_comments(ctx, sequence, &ctx.ast[parsed_node])

			
			if n, _ := peek_token(tokens); n.kind == .Semicolon { // simple declaration
				append(sequence, parsed_node)
				return	
			}

			inline_struct_type := ast_append_type(ctx, AstTypeInlineStructure(parsed_node))
			ast_parse_var_declaration_no_type(ctx, tokens, inline_struct_type, sequence, {}) or_return
			parsed_node = last(sequence^)^ // @hack
			return

		case .Enum:
			tokens^ = nexts

			node := AstNode { kind = .Enum }

			if n, ns := peek_token(tokens); n.kind == .Identifier {
				tokens^ = ns

				node.structure.name = ast_append_node(ctx, { kind = .Identifier, identifier = { token = n } })
			}

			eat_token_expect_push_err(ctx, tokens, .BracketCurlyOpen) or_return

			ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_enum_value_declaration, &node.structure.members, &node) or_return

			ast_attach_comments(ctx, sequence, &node)

			
			if n, _ := peek_token(tokens); n.kind == .Semicolon { // simple declaration
				parsed_node = ast_append_node(ctx, node)
				append(sequence, parsed_node)
				return	
			}

			inline_struct_type := ast_append_type(ctx, AstTypeInlineStructure(parsed_node))
			ast_parse_var_declaration_no_type(ctx, tokens, inline_struct_type, sequence, {}) or_return
			parsed_node = last(sequence^)^ // @hack
			return

		case .Namespace:
			tokens^ = nexts

			node := AstNode{ kind = .Namespace }

			name, names := peek_token(tokens) // ffs cpp, namespace name is optional
			if name.kind == .Identifier {
				node.namespace.name = name
				tokens^ = names
			}

			eat_token_expect_push_err(ctx, tokens, .BracketCurlyOpen) or_return

			defer if err != .None && len(node.namespace.member_sequence) > 0 { delete(node.namespace.member_sequence) }
			ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_declaration, &node.namespace.member_sequence) or_return

			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return

		case .Operator: // operator bool() { }    custom call operator comes without return type...
			tokens^ = nexts

			implicit_cast_type := ast_parse_type(ctx, tokens) or_return
			fn_node := ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return
			fn_node.function_def.return_type = implicit_cast_type
			
			node := AstNode{ kind = .OperatorDefinition, operator_def = { kind = .ImplicitCast } }
			node.operator_def.underlying_function = ast_append_node(ctx, fn_node)
			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)

			eat_paragraph = true // @hardcoded
			return
	}

	before_type := tokens^
	// var or fn def must have return type, exceptions are out of like ctors / dtors...
	type, _ := ast_parse_type(ctx, tokens)
	if has_error(ctx) { // specifically out of band for dtor parsing
		type = 0
		tokens^ = before_type
	}

	storage |= ast_parse_storage_modifier(tokens) // mods after return type   static void inline fn()

	if next, ns := peek_token(tokens); next.kind == .Operator { // operator [](args) { ... }  might be member or static call
		tokens^ = ns

		node := AstNode{ kind = .OperatorDefinition }

		nn, nns := peek_token(tokens);
		#partial switch nn.kind {
			// asume binary expressions, correct after fn arguments are known
			case .Tilde:              tokens^ = nns; node.operator_def.kind = .Invert
			case .PrefixIncrement:    tokens^ = nns; node.operator_def.kind = .Increment
			case .PostfixDecrement:   tokens^ = nns; node.operator_def.kind = .Decrement
			case .Equals:             tokens^ = nns; node.operator_def.kind = .Equals
			case .NotEquals:          tokens^ = nns; node.operator_def.kind = .NotEquals
			case .Plus:               tokens^ = nns; node.operator_def.kind = .Add
			case .Minus:              tokens^ = nns; node.operator_def.kind = .Subtract
			case .Star:               tokens^ = nns; node.operator_def.kind = .Multiply
			case .ForwardSlash:       tokens^ = nns; node.operator_def.kind = .Divide
			case .Ampersand:          tokens^ = nns; node.operator_def.kind = .BitAnd
			case .Pipe:               tokens^ = nns; node.operator_def.kind = .BitOr
			case .Circumflex:         tokens^ = nns; node.operator_def.kind = .BitXor
			case .Assign:             tokens^ = nns; node.operator_def.kind = .Assign
			case .AssignPlus:         tokens^ = nns; node.operator_def.kind = .AssignAdd
			case .AssignMinus:        tokens^ = nns; node.operator_def.kind = .AssignSubtract
			case .AssignStar:         tokens^ = nns; node.operator_def.kind = .AssignMultiply
			case .AssignForwardSlash: tokens^ = nns; node.operator_def.kind = .AssignDivide
			case .BracketSquareOpen: 
				eat_token_expect_push_err(ctx, &nns, .BracketSquareClose) or_return
				tokens^ = nns
				node.operator_def.kind = .Index

			case .Identifier:
				if nn.source == "new" {
					tokens^ = nns
					break
				}
				else if nn.source == "delete" {
					tokens^ = nns
					break
				}
				fallthrough

			case:
				err = .Some
				push_error(ctx, { actual = nn, message = "Expected valid operator (one of ~, ++, --, ==, !=, +, -, *, /, &, |, ^, =, +=, -=, *=, /=, [], new, delete)" })
				return
		}

		fn_node := ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return
		fn_node.function_def.return_type = type
		node.operator_def.underlying_function = ast_append_node(ctx, fn_node)

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
					err = .Some
					push_error(ctx, { actual = nn, message = "Expected valid unary operator (one of +, -, *, &)" })
					return
			}
		}

		parsed_node = ast_append_node(ctx, node)
		append(sequence, parsed_node)

		eat_paragraph = true // @hardcoded
		return
	}

	detected_ctor := false
	if tokens[0].kind == .BracketRoundOpen {
		// detect out of band constructor without a type   e.g.     A::A()
		if f, e := ctx.type_heap[type].(AstTypeFragment); e && f.parent_fragment != 0 {
			if p, e := ctx.type_heap[f.parent_fragment].(AstTypeFragment); e && p.identifier.source == f.identifier.source {
				tokens^ = before_type
				type = 0
				detected_ctor = true
			}
		}
	}

	before_name := tokens^
	name, detected_dtor := ast_try_parse_qualified_name(ctx, tokens, true)

	if name != 0 {
		reset_error(ctx) // reset potential error from type parsing

		next, _ = peek_token(tokens)

		if next.kind == .BracketRoundOpen {
			fndef_node := ast_parse_function_def_no_return_type_and_name(ctx, tokens, detected_ctor) or_return
			fndef_node.function_def.template_spec = template_spec
			fndef_node.function_def.return_type =  type
			fndef_node.function_def.function_name = name
			fndef_node.function_def.flags |= transmute(AstFunctionDefFlags) storage;
			if detected_ctor { fndef_node.function_def.flags |= { .IsCtor } }
			if detected_dtor { fndef_node.function_def.flags |= { .IsDtor } }
	
			ast_attach_comments(ctx, sequence, &fndef_node)
	
			parsed_node = ast_append_node(ctx, fndef_node)
			append(sequence, parsed_node)
			return
		}
	}
	else if has_error(ctx) {
		// no type and no name -> error
		err = .Some
		return
	}

	
	tokens^ = before_name // reset to before name so the statement parses properly

	ast_parse_var_declaration_no_type(ctx, tokens, type, sequence, transmute(AstVariableDefFlags) storage, parse_width_expression = parse_width_expression) or_return
	parsed_node =  sequence[len(sequence) - 1]

	return
}

ast_parse_enum_value_declaration :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, loc := #caller_location) -> (parsed_node : AstNodeIndex, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	sequence_reset := len(sequence)

	defer if err != .None {
		push_error(ctx, { message = "Failed to parse enum value declaration" }, loc)
		resize(ctx.ast, ast_reset)
		resize(sequence, sequence_reset)
		tokens^ = tokens_reset
	}

	node := AstNode{ kind = .VariableDeclaration }
	node.var_declaration.var_name = eat_token_expect_push_err(ctx, tokens, .Identifier) or_return

	if n, ns := peek_token(tokens); n.kind == .Assign {
		tokens^ = ns
		
		value_expr := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return
		node.var_declaration.initializer_expression = ast_append_node(ctx, value_expr)
	}

	parsed_node = ast_append_node(ctx, node)
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
			case "constexpr": storage |= { .Constexpr }
			case "mutable": storage |= { .Mutable }
			case "explicit": storage |= { .Explicit }
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

	return_type := ast_parse_type(ctx, tokens) or_return // int
	name, was_dtor := ast_parse_qualified_name(ctx, tokens, true) or_return // main

	node = ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return // (int a[3]) {}

	node.function_def.function_name = name
	node.function_def.return_type =  return_type
	node.function_def.flags = transmute(AstFunctionDefFlags) storage
	if was_dtor { node.function_def.flags |= { .IsDtor } }

	return
}

ast_parse_typedef_no_keyword :: proc(ctx : ^AstContext, tokens : ^[]Token) -> (node : AstNode, err : AstError)
{

	node.kind = .Typedef

	#partial switch t, _ := peek_token(tokens); t.kind {
		case .Class, .Struct, .Union, .Enum:
			node.typedef.type = ast_parse_structure(ctx, tokens) or_return
			node.typedef.name = eat_token_expect_push_err(ctx, tokens, .Identifier) or_return
			return
	}

	start := raw_data(tokens^)

	for {
		next, ns := peek_token(tokens)
		if next.kind == .Semicolon { break }
		tokens^ = ns
	}


	if test := raw_data(tokens^)[-1]; test.kind == .Identifier {
		type_tokens := slice_from_se(start, raw_data(tokens^)[-1:])
		type := ast_parse_type(ctx, &type_tokens) or_return
		assert_eq(len(type_tokens), 0)
		
		node.typedef.name = test
		node.typedef.type = ast_append_node(ctx, { kind = .Type, type = type })
	}
	else { // fnptr
		typedef_tokens := slice_from_se(start, raw_data(tokens^)[1:])
		type := ast_parse_fnptr_type(ctx, &typedef_tokens) or_return
		node.typedef.type = ast_append_node(ctx, { kind = .Type, type = type })
		node.typedef.name = ctx.type_heap[ctx.type_heap[type].(AstTypePointer).destination_type].(AstTypeFunction).name
	}

	return
}

ast_parse_function_args_def_with_brackets :: proc(ctx: ^AstContext, tokens : ^[]Token, arguments : ^[dynamic]AstNodeIndex) -> (has_vararg : bool, err : AstError)
{
	eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return

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

				append(arguments, ast_append_node(ctx, AstNode{ kind = .Varargs }))
				has_vararg = true
				continue

			case:
				type := ast_parse_type(ctx, tokens) or_return

				current_arg: for {
					nn, nns := peek_token(tokens)
					#partial switch nn.kind {
						case .Comma, .BracketRoundClose:
							var_def := AstNode{ kind = .VariableDeclaration, var_declaration = {
								type = type,
								// no name
							}}
							append(arguments, ast_append_node(ctx, var_def))
							break current_arg

						case .Comment:  // fn(int /*length*/)
							tokens^ = nns // just skip this for now

						case: // ident or fnptr brackets
							s : [1]AstNodeIndex
							d := slice.into_dynamic(s[:])
							ast_parse_var_declaration_no_type(ctx, tokens, type, &d, {}, stop_at_comma = true) or_return

							append(arguments, s[0])
							break current_arg
					}
				}
		}
	}

	return
}

ast_parse_function_def_no_return_type_and_name :: proc(ctx: ^AstContext, tokens : ^[]Token, parse_initializer := false, loc := #caller_location) -> (node : AstNode, err : AstError)
{
	// (int a[3]) {}
	// (int a[3]) const {}

	node.kind = .FunctionDefinition

	token_reset := tokens^
	ast_reset_size := len(ctx.ast)
	arguments : [dynamic]AstNodeIndex
	body_sequence : [dynamic]AstNodeIndex

	defer if err != .None {
		push_error(ctx, { message = "Failed to parse function def", actual = first_or_nil(tokens^) }, loc)
		delete(arguments)
		delete(body_sequence)
		resize(ctx.ast, ast_reset_size)
		tokens^ = token_reset
	}

	has_vararg := ast_parse_function_args_def_with_brackets(ctx, tokens, &arguments) or_return

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
		else if t.kind == .Comment {
			tokens^ = sss

			append(&node.function_def.attached_comments, ast_append_node(ctx, AstNode{ kind = .Comment, literal = t }))

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
					node := ast_parse_function_call(ctx, tokens) or_return
					
					initialized_member := node.function_call.expression

					node.function_call.expression = append_simple_identifier(ctx, Token{ kind = .Identifier, source = "init" })

					call := AstNode{ kind = .MemberAccess, member_access = {
						expression = initialized_member,
						member = ast_append_node(ctx, node)
					}}

					append(&body_sequence, ast_append_node(ctx, AstNode{ kind = .NewLine }))
					append(&body_sequence, ast_append_node(ctx, call))

				case .Comma:
					tokens^ = sss

				case:
					break initializer_loop
			}
		}
	}

	if t.kind == .Semicolon {
		node.function_def.flags |= { .IsForwardDeclared }
	}
	else if t.kind == .BracketCurlyOpen {
		tokens^ = sss // eat {

		ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &body_sequence) or_return

		node.function_def.body_sequence = body_sequence
	}
	else {
		err = .Some
		push_error(ctx, { actual = t, message = "Expected either ';' as forward declaration or '{' folowed by funcion body" })
		return
	}

	node.function_def.arguments = arguments
	return
}

ast_parse_statement :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, parse_width_expression := false, loc := #caller_location) -> (parsed_node : AstNodeIndex, err : AstError)
{
	token_reset := tokens^
	ast_reset_size := len(ctx.ast)
	sequence_reset := len(sequence)

	__d :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : ^[dynamic]AstNodeIndex, ast_reset_size, sequence_reset : int, token_reset : []Token, loc : runtime.Source_Code_Location) {
		push_error(ctx, { message = "Failed to parse statement", actual = first_or_nil(tokens^) }, loc)
		resize(sequence, sequence_reset)
		resize(ctx.ast, ast_reset_size)
		tokens^ = token_reset
	}

	defer if err != .None {
		__d(ctx, tokens, sequence, ast_reset_size, sequence_reset, token_reset, loc)
	}

	storage := ast_parse_storage_modifier(tokens)

	next, nexts := peek_token(tokens)
	#partial switch next.kind {
		case .Return:
			tokens^ = nexts

			node := AstNode{ kind = .Return }
			if return_expr, _ := ast_parse_expression(ctx, tokens); !has_error__reset(ctx) {
				node.return_.expression = ast_append_node(ctx, return_expr);
			}
			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return

		case .Break:
			tokens^ = nexts
			
			parsed_node = ast_append_node(ctx, AstNode{ kind = .Break, literal = next })
			append(sequence, parsed_node)
			return

		case .Continue:
			tokens^ = nexts

			parsed_node = ast_append_node(ctx, AstNode{ kind = .Continue, literal = next })
			append(sequence, parsed_node)
			return

		case .Goto:
			tokens^ = nexts

			node := AstNode{
				kind = .Goto,
				label = eat_token_expect_push_err(ctx, tokens, .Identifier) or_return,
			}
			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return

		case .For:
			tokens^ = nexts

			eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return

			node := AstNode { kind = .For }

			ast_parse_statement(ctx, tokens, &node.loop.initializer)
			reset_error(ctx)

			#partial switch n, ns := peek_token(tokens); n.kind {
				case .Semicolon: // normal for loop    for(int i = 0; i < 3; i++)
					tokens^ = ns // eat ;

					if condition, _ := ast_parse_expression(ctx, tokens); !has_error__reset(ctx) {
						node.loop.condition = make_one(ast_append_node(ctx, condition))
					}

					eat_token_expect_push_err(ctx, tokens, .Semicolon) or_return

					if loop_expression, _ := ast_parse_expression(ctx, tokens); !has_error__reset(ctx) {
						if loop_expression.kind == .Sequence {
							node.loop.loop_statement = loop_expression.sequence.members
						}
						else {
							node.loop.loop_statement = make_one(ast_append_node(ctx, loop_expression))
						}
					}

				case .Colon: // foreach loop   for(auto& a : b)
					tokens^ = ns // eat :

					node.loop.is_foreach = true

					iterator := ast_parse_expression(ctx, tokens) or_return
					node.loop.loop_statement = make_one(ast_append_node(ctx, iterator))

				case:
					err = .Some
					push_error(ctx, { actual = n, message = "Expected colon or semicolon" })
					return
			}
			

			eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

			defer if err != .None { delete(node.loop.body_sequence) }
			// @brittle
			if c, _ := eat_token_expect(tokens, .Comment); has_error__reset(ctx) {
				append(&node.loop.body_sequence, ast_append_node(ctx, AstNode{ kind = .NewLine }))
				append(&node.loop.body_sequence, ast_append_node(ctx, AstNode{ kind = .Comment, literal = c }))
			}

			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &node.loop.body_sequence) or_return
			}
			else {
				ast_parse_statement(ctx, tokens, &node.loop.body_sequence) or_return
				eat_token_expect(tokens, .Semicolon)
			}

			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return

		case .While:
			tokens^ = nexts

			eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
			condition : [dynamic]AstNodeIndex
			ast_parse_statement(ctx, tokens, &condition) or_return
			assert_eq(len(condition), 1)
			eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

			body_sequence : [dynamic]AstNodeIndex
			defer if err != .None { delete(body_sequence) }
			// @brittle
			if c, _ := eat_token_expect(tokens, .Comment); has_error__reset(ctx) {
				append(&body_sequence, ast_append_node(ctx, AstNode{ kind = .NewLine }))
				append(&body_sequence, ast_append_node(ctx, AstNode{ kind = .Comment, literal = c }))
			}

			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &body_sequence) or_return
			}
			else {
				ast_parse_statement(ctx, tokens, &body_sequence) or_return
				eat_token_expect(tokens, .Semicolon)
			}

			parsed_node = ast_append_node(ctx, AstNode { kind = .While, loop = {
				condition = condition,
				body_sequence = body_sequence,
			}})
			append(sequence, parsed_node)
			return

		case .Do:
			tokens^ = nexts

			body_sequence : [dynamic]AstNodeIndex
			defer if err != .None { delete(body_sequence) }

			// @brittle
			if c, _ := eat_token_expect(tokens, .Comment); has_error__reset(ctx) {
				append(&body_sequence, ast_append_node(ctx, AstNode{ kind = .NewLine }))
				append(&body_sequence, ast_append_node(ctx, AstNode{ kind = .Comment, literal = c }))
			}

			n, ns := peek_token(tokens)
			if n.kind == .BracketCurlyOpen {
				tokens^ = ns

				ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &body_sequence) or_return
			}
			else {
				ast_parse_statement(ctx, tokens, &body_sequence) or_return
				eat_token_expect_push_err(ctx, tokens, .Semicolon) or_return
			}

			eat_token_expect_push_err(ctx, tokens, .While) or_return
			eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
			condition := ast_parse_expression(ctx, tokens) or_return
			eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

			parsed_node = ast_append_node(ctx, AstNode { kind = .Do, loop = {
				condition = make_one(ast_append_node(ctx, condition)),
				body_sequence = body_sequence,
			}})
			append(sequence, parsed_node)
			return

		case .If:
			tokens^ = nexts

			node := AstNode { kind = .Branch }

			eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return // opening (

			//NOTE(Rennorb): We need to try and parse a statement (vardef) first, even if we have to correct it afterwards,
			// otherwise  'if(int* a = b)'  will get parsed as 'int times (assign b to a)', as there is no type analysis here.

			before_statement := tokens^
			ast_reset := len(ctx.ast)
			type_reset := len(ctx.type_heap)

			ast_parse_statement(ctx, tokens, &node.branch.condition) or_return
			if n, ns := peek_token(tokens); n.kind == .Semicolon { // if (int a = 0; a == 0) { .. }
				tokens^ = ns // eat the ; 
				condition := ast_parse_expression(ctx, tokens) or_return
				append(&node.branch.condition, ast_append_node(ctx, condition))
			}
			else {
				cond := ctx.ast[node.branch.condition[0]]
				// check for and correct  binary and being parsed as vardef of a reference type; 'a & b'  looks like  'int& a', same with 'a * b'
				if len(node.branch.condition) == 1 && cond.kind == .VariableDeclaration && cond.var_declaration.initializer_expression == {} {
					resize(&node.branch.condition, 1)
					tokens^ = before_statement
					resize(ctx.ast, ast_reset)
					resize(&ctx.type_heap, type_reset)

					expr := ast_parse_expression(ctx, tokens) or_return
					#no_bounds_check node.branch.condition[0] = ast_append_node(ctx, expr)
				}
			}

			eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return // closing )

			true_branch_sequence : [dynamic]AstNodeIndex
			scoped_true_branch := false

			// @brittle
			eol_comment, eol_comment_err := eat_token_expect_direct(tokens, .Comment)
			if eol_comment_err == nil  {
				append(&true_branch_sequence, ast_append_node(ctx, AstNode{ kind = .NewLine }))
				append(&true_branch_sequence, ast_append_node(ctx, AstNode{ kind = .Comment, literal = eol_comment }))
			}

			eol_coment_insertion_point := len(true_branch_sequence)

			if n, ns := peek_token(tokens); n.kind == .BracketCurlyOpen {
				scoped_true_branch = true
				tokens^ = ns // {
				ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &true_branch_sequence) or_return
			}
			else {
				n, ns := peek_token(tokens)
				ast_try_parse_preproc_statement(ctx, tokens, &true_branch_sequence, n, ns) // can also exist between branches if its not wrapped in curly braces

				ast_parse_statement(ctx, tokens, &true_branch_sequence) or_return
				eat_token_expect(tokens, .Semicolon)
			}

			// @brittle
			eol_comment, eol_comment_err = eat_token_expect_direct(tokens, .Comment, false)
			if eol_comment_err == nil {
				inject_at(&true_branch_sequence, eol_coment_insertion_point + 0, ast_append_node(ctx, AstNode{ kind = .NewLine }))
				inject_at(&true_branch_sequence, eol_coment_insertion_point + 1, ast_append_node(ctx, AstNode{ kind = .Comment, literal = eol_comment }))
				inject_at(&true_branch_sequence, eol_coment_insertion_point + 2, ast_append_node(ctx, AstNode{ kind = .NewLine }))
			}
			if len(true_branch_sequence) > 1 && ctx.ast[last(true_branch_sequence)^].kind != .NewLine {
				append(&true_branch_sequence, ast_append_node(ctx, AstNode{ kind = .NewLine })) //TODO(Rennorb) @cleanup
			}

			false_branch_sequence : [dynamic]AstNodeIndex
			scoped_false_branch := false

			// @brittle
			before_comment := tokens^
			comment_above_else, else_comment_err := eat_token_expect_direct(tokens, .Comment)

			if n, ns := peek_token(tokens); n.kind == .Else {
				chained_branch : AstNodeIndex = 0

				if nn, nns := peek_token(&ns); nn.kind == .BracketCurlyOpen {
					scoped_false_branch = true

					tokens^ = nns // {

					eol_coment_insertion_point = len(false_branch_sequence)

					ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &false_branch_sequence) or_return
				}
				else {
					tokens^ = ns // else

					n, ns := peek_token(tokens)
					ast_try_parse_preproc_statement(ctx, tokens, &false_branch_sequence, n, ns) // can also exist between branches if its not wrapped in curly braces

					ast_parse_statement(ctx, tokens, &false_branch_sequence) or_return
					eat_token_expect(tokens, .Semicolon) // might have a semicolon from single statement or nothing in case of ifelse chain

					eol_coment_insertion_point = 0
					skip_preproc_loop: for fi in false_branch_sequence {
						#partial switch ctx.ast[fi].kind {
							case .PreprocDefine, .PreprocElse, .PreprocEndif, .PreprocIf, .PreprocMacro:
								/**/
							case .Branch:
								//NOTE(Rennorb): If a ifelse is chained to the first branch, comments that should be placed in the else branch sequence
								// instead should be palced inside the true branch of the chaned if.
								chained_branch = fi
								break skip_preproc_loop
							case:
								break skip_preproc_loop
						}
					}
				}

				false_branch_sequence_ : [dynamic]AstNodeIndex
				if chained_branch == 0 {
					false_branch_sequence_ = false_branch_sequence
				}
				else {
					chained := ctx.ast[chained_branch].branch
					if true_branch := ctx.ast[chained.true_branch]; true_branch.kind == .Sequence {
						false_branch_sequence_ = true_branch.sequence.members
					}
					else {
						append(&false_branch_sequence_, chained.true_branch)
					}
				}

				if else_comment_err == nil {
					inject_at(&false_branch_sequence_, eol_coment_insertion_point + 0, ast_append_node(ctx, AstNode{ kind = .NewLine }))
					inject_at(&false_branch_sequence_, eol_coment_insertion_point + 1, ast_append_node(ctx, AstNode{ kind = .Comment, literal = comment_above_else }))
					eol_coment_insertion_point += 2
				}

				// @brittle
				eol_comment, eol_comment_err = eat_token_expect_direct(tokens, .Comment, false)
				if eol_comment_err == nil {
					inject_at(&false_branch_sequence_, eol_coment_insertion_point + 0, ast_append_node(ctx, AstNode{ kind = .NewLine }))
					inject_at(&false_branch_sequence_, eol_coment_insertion_point + 1, ast_append_node(ctx, AstNode{ kind = .Comment, literal = eol_comment }))
					inject_at(&false_branch_sequence_, eol_coment_insertion_point + 2, ast_append_node(ctx, AstNode{ kind = .NewLine }))
				}
				if len(false_branch_sequence_) > 1 && ctx.ast[last(false_branch_sequence_)^].kind != .NewLine {
					append(&false_branch_sequence_, ast_append_node(ctx, AstNode{ kind = .NewLine }))
				}


				if chained_branch == 0 {
					false_branch_sequence = false_branch_sequence_
				}
				else {
					if len(false_branch_sequence_) > 1 {
						chained := ctx.ast[chained_branch].branch
						if true_branch := &ctx.ast[chained.true_branch]; true_branch.kind == .Sequence {
							true_branch.sequence.members = false_branch_sequence_
						}
						else {
							sequence := ast_append_node(ctx, { kind = .Sequence, sequence = { braced = true, members = false_branch_sequence_ }})
							ctx.ast[chained_branch].branch.true_branch = sequence
						}
					}
				}
			}
			else {
				// reset before eaten comment
				tokens^ = before_comment
			}

			if scoped_true_branch {
				node.branch.true_branch = ast_append_node(ctx, AstNode{ kind = .Sequence, sequence = { braced = true, members = true_branch_sequence } })
			}
			else {
				switch len(true_branch_sequence) {
					case 1:
						node.branch.true_branch = true_branch_sequence[0]
						delete(true_branch_sequence)

					case:
						node.branch.true_branch = ast_append_node(ctx, AstNode{ kind = .Sequence, sequence = { braced = true, members = true_branch_sequence } })
				}
			}

			if scoped_false_branch {
				node.branch.false_branch = ast_append_node(ctx, AstNode{ kind = .Sequence, sequence = { braced = true, members = false_branch_sequence } })
			}
			else {
				switch len(false_branch_sequence) {
					case 0:
						/**/

					case 1:
						node.branch.false_branch = false_branch_sequence[0]
						delete(false_branch_sequence)

					case:
						node.branch.false_branch = ast_append_node(ctx, AstNode{ kind = .Sequence, sequence = { braced = true, members = false_branch_sequence } })
				}
			}

			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return

		case .Switch:
			tokens^ = nexts

			node := AstNode{ kind = .Switch }

			eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
			expression_node := ast_parse_expression(ctx, tokens) or_return
			node.switch_.expression = ast_append_node(ctx, expression_node)
			eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return
			eat_token_expect_push_err(ctx, tokens, .BracketCurlyOpen) or_return

			cases_loop: for {
				n, ns := peek_token(tokens)
				#partial switch n.kind {
					case .BracketCurlyClose:
						tokens^ = ns
						break cases_loop

					case .Case:
						tokens^ = ns
						match_expression_node := ast_parse_expression(ctx, tokens) or_return
						match_expression := ast_append_node(ctx, match_expression_node)
						eat_token_expect_push_err(ctx, tokens, .Colon) or_return

						case_body_sequence : [dynamic]AstNodeIndex
						eate_curly_brace := ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &case_body_sequence) or_return

						append_nothing(&node.switch_.cases)
						last(node.switch_.cases[:])^ = { match_expression = match_expression, body_sequence = case_body_sequence }

						if eate_curly_brace { break cases_loop }

					case .Default:
						tokens^ = ns
						eat_token_expect_push_err(ctx, tokens, .Colon) or_return

						case_body_sequence : [dynamic]AstNodeIndex
						eate_curly_brace := ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &case_body_sequence) or_return

						append_nothing(&node.switch_.cases)
						last(node.switch_.cases[:])^ = { body_sequence = case_body_sequence }

						if eate_curly_brace { break cases_loop }
				}
			}

			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return

		case .BracketCurlyOpen:
			tokens^ = nexts

			node := AstNode { kind = .Sequence, sequence = { braced = true } }
			ast_parse_scoped_sequence_no_open_brace(ctx, tokens, ast_parse_statement, &node.sequence.members) or_return

			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return

		case .Struct, .Class, .Union, .Enum:
			parsed_node = ast_parse_structure(ctx, tokens) or_return

			ast_attach_comments(ctx, sequence, &ctx.ast[parsed_node])

			if n, _ := peek_token(tokens); n.kind == .Semicolon { // normal declaration

				if n, ns := peek_token(tokens, false); n.kind == .Comment {
					tokens^ = ns

					x := ast_append_node(ctx, AstNode { kind = .Comment, attached = true, literal = n })
					y := ast_append_node(ctx, AstNode { kind = .NewLine, attached = true })
					structure := &ctx.ast[parsed_node].structure
					append(&structure.attached_comments, x)
					append(&structure.attached_comments, y)
				}

				append(sequence, parsed_node)
				return
			}

			inline_struct_type := ast_append_type(ctx, AstTypeInlineStructure(parsed_node))
			ast_parse_var_declaration_no_type(ctx, tokens, inline_struct_type, sequence, {}) or_return
			parsed_node = last(sequence^)^ // @hack
			return

		case .Using:
			tokens^ = nexts

			eat_token_expect_push_err(ctx, tokens, .Namespace) or_return

			parsed_node, _ = ast_parse_qualified_name(ctx, tokens) or_return
			ctx.ast[parsed_node].kind = .UsingNamespace

			append(sequence, parsed_node)
			return

		case .Identifier:
			if nn, nns := peek_token(&nexts); nn.kind == .Colon {
				tokens^ = nns

				parsed_node = ast_append_node(ctx, AstNode{ kind = .Label, label = next })
				append(sequence, parsed_node)
				return
			}

		case .Typedef:
			tokens^ = nexts

			node := ast_parse_typedef_no_keyword(ctx, tokens) or_return

			parsed_node = ast_append_node(ctx, node)
			append(sequence, parsed_node)
			return
	}


	if type_node, te := ast_parse_type(ctx, tokens); te == .None {
		err = ast_parse_var_declaration_no_type(ctx, tokens, type_node, sequence, transmute(AstVariableDefFlags) storage, parse_width_expression = parse_width_expression)
		if err == .None {
			parsed_node = last(sequence[:])^
			return
		}
	}
	reset_error(ctx)

	//reset state after we failed to parse an assignment
	tokens^ = token_reset

	expression := ast_parse_expression(ctx, tokens) or_return
	parsed_node = ast_append_node(ctx, expression)
	append(sequence, parsed_node)

	err = .None
	return
}

ast_parse_scoped_sequence_no_open_brace :: proc(ctx: ^AstContext, tokens : ^[]Token, $fn : $F, sequence : ^[dynamic]AstNodeIndex, parent_node : ^AstNode = nil, parse_width_expression := false) -> (did_exit_on_curly_brace : bool, err : AstError)
{
	loop: for {
		n, ns := peek_token(tokens, false)
		#partial switch n.kind {
			case .BracketCurlyClose:
				tokens^ = ns
				did_exit_on_curly_brace = true
				return

			case .Case, .Default: // for case branches
				return

			case .NewLine:
				tokens^ = ns
				append(sequence, ast_append_node(ctx, AstNode{ kind = .NewLine }))
				continue
			
			case .Comment:
				tokens^ = ns
				append(sequence, ast_append_node(ctx, AstNode{ kind = .Comment, literal = n }))
				continue

			case .Public, .Protected, .Private:
				// ignore for now 
				tokens^ = ns
				eat_token_expect_push_err(ctx, tokens, .Colon) or_return
				continue
		}

		was_preproc := ast_try_parse_preproc_statement(ctx, tokens, sequence, n, ns)
		if was_preproc {
			continue
		}

		when F == type_of(ast_parse_statement) {
			member_index := ast_parse_statement(ctx, tokens, sequence, parse_width_expression) or_return
			eat_paragraph := false
		}
		else when F == type_of(ast_parse_enum_value_declaration) {
			member_index := ast_parse_enum_value_declaration(ctx, tokens, sequence) or_return
			eat_paragraph := false
		}
		else when F == type_of(ast_parse_declaration) {
			member_index, eat_paragraph := ast_parse_declaration(ctx, tokens, sequence, parent_node, parse_width_expression) or_return
		}
		else {
			#panic("wrong fn type")
		}

		member := ctx.ast[member_index]
		#partial switch member.kind {
			case .FunctionDefinition:
				if parent_node != nil {
					if .IsCtor in member.function_def.flags {
						append(sequence, member_index)
					}
					else if .IsDtor in member.function_def.flags {
						parent_node.structure.deinitializer = member_index
					}
				}

				if .IsForwardDeclared in member.function_def.flags{
					eat_token_expect_push_err(ctx, tokens, .Semicolon) or_return
				}

			case .VariableDeclaration:
				if parent_node != nil && member.var_declaration.initializer_expression != {} {
					parent_node.structure.flags |= { .HasImplicitCtor }
				}

				when F == type_of(ast_parse_enum_value_declaration) {
					ctx.ast[member_index].var_declaration.type = parent_node.structure.base_type
				}

				fallthrough
				
			case .Typedef, .Struct, .Union, .Enum, .Do, .ExprBinary, .ExprUnaryLeft, .ExprUnaryRight, .ExprCast, .MemberAccess, .FunctionCall, .OperatorCall, .Return, .Break, .Continue, .Goto, .UsingNamespace:
				when F == type_of(ast_parse_enum_value_declaration) {
					// enum value declarations (may) end in a comma
					eat_token_expect(tokens, .Comma)
				}
				else {
					// most declarations and statements must end in a semicolon
					eat_token_expect_push_err(ctx, tokens, .Semicolon) or_return
				}

			case .Sequence:
				//if ctx.ast[member.sequence.members[0]].kind == .VariableDeclaration {
					eat_token_expect(tokens, .Semicolon) //or_return
				//}
		}

		#partial switch member.kind {
			case .FunctionDefinition:
				// attach comments after the declaration in the same line
				if n, ns := peek_token(tokens, false); n.kind == .Comment {
					tokens^ = ns

					x := ast_append_node(ctx, AstNode { kind = .Comment, attached = true, literal = n })
					append(&ctx.ast[member_index].function_def.attached_comments, x)
					y := ast_append_node(ctx, AstNode { kind = .NewLine, attached = true })
					append(&ctx.ast[member_index].function_def.attached_comments, y)
				}

			case .OperatorDefinition:
				// attach comments after the declaration in the same line
				if n, ns := peek_token(tokens, false); n.kind == .Comment {
					tokens^ = ns

					idx := member.operator_def.underlying_function
					x := ast_append_node(ctx, AstNode { kind = .Comment, attached = true, literal = n })
					append(&ctx.ast[idx].function_def.attached_comments, x)
					y := ast_append_node(ctx, AstNode { kind = .NewLine, attached = true })
					append(&ctx.ast[idx].function_def.attached_comments, y)
				}
		}

		if eat_paragraph {
			eat_token_expect_direct(tokens, .NewLine, false)
			eat_token_expect_direct(tokens, .NewLine, false)
		}
	}

	return
}

ast_parse_var_declaration_no_type :: proc(ctx: ^AstContext, tokens : ^[]Token, preparsed_type : AstTypeIndex, sequence : ^[dynamic]AstNodeIndex, storage_flags : AstVariableDefFlags, stop_at_comma := false, parse_width_expression := false, loc := #caller_location) -> (err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	sequence_reset := len(sequence)

	defer if err != .None {
		push_error(ctx, { message = "Failed to parse variable declaration" }, loc)
		resize(sequence, sequence_reset)
		resize(ctx.ast, ast_reset)
		tokens^ = tokens_reset
	}

	// fnptr detection  v
	//             int  (*name)(args)
	if n, ns := peek_token(tokens); n.kind == .BracketRoundOpen {
		if nn, nns := peek_token(&ns); nn.kind == .Star {
			tokens^ = nns // skip  (*

			fnptr := ast_parse_fnptr_type_starting_at_name(ctx, tokens, preparsed_type) or_return

			var_def := AstNode { kind = .VariableDeclaration, var_declaration = {
				var_name = ctx.type_heap[ctx.type_heap[fnptr].(AstTypePointer).destination_type].(AstTypeFunction).name,
				type = fnptr,
			}}

			append(sequence, ast_append_node(ctx, var_def))

			return
		}
	}

	loop: for {
		name : Token
		width_expression, initializer_expression : AstNode
		type := preparsed_type
	
		next : Token; ns : []Token
		type_prefix_loop: for {
			next, ns = peek_token(tokens)
			#partial switch next.kind {
				case .Ampersand, .Star:
					//     v
					// int ***&a
					tokens^ = ns

					type = ast_append_type(ctx, AstTypePointer{
						destination_type = type,
						flags = next.kind == .Ampersand ? { .Reference } : { },
					})

				case .Identifier:
					//         v
					// int ***&a
					tokens^ = ns

					name = next

					next, ns = peek_token(tokens)
					break type_prefix_loop

				case:
					err = .Some
					push_error(ctx, { actual = next, message = "Expected type extension" })
					return
			}
		}

		// found and eaten identifier

		for next.kind == .BracketSquareOpen { // void fn(int a[]);   or  int a[3];   or   int a[3][4];
			tokens^ = ns

			length_expr : AstNodeIndex

			if nn, nns := peek_token(tokens); nn.kind != .BracketSquareClose {
				//       v
				// int a[expr];
				l := ast_parse_expression(ctx, tokens) or_return
				length_expr = ast_append_node(ctx, l)
			}

			eat_token_expect_push_err(ctx, tokens, .BracketSquareClose) or_return

			type = ast_append_type(ctx, AstTypeArray{ element_type = type, length_expression = length_expr })

			next, ns = peek_token(tokens)
		}

		if parse_width_expression && next.kind == .Colon {
			tokens^ = ns

			width_expression = ast_parse_expression(ctx, tokens, .Comma - ._1) or_return

			next, ns = peek_token(tokens)
		}

		if next.kind == .Assign {
			tokens^ = ns

			initializer_expression = ast_parse_expression(ctx, tokens, .Comma - ._1) or_return

			next, ns = peek_token(tokens)
		}
		else if next.kind == .BracketCurlyOpen { //  int a[3] { 1, 2, 3};
			tokens^ = ns

			initializer_expression = ast_parse_compound_initializer_no_start_curly_brace(ctx, tokens) or_return

			next, ns = peek_token(tokens)
		}

		node := AstNode { kind = .VariableDeclaration, var_declaration = {
			flags = storage_flags,
			type = type,
			var_name = name,
			width_expression = width_expression.kind != {} ? ast_append_node(ctx, width_expression) : {},
			initializer_expression = initializer_expression.kind != {} ? ast_append_node(ctx, initializer_expression) : {},
		}}
		append(sequence, ast_append_node(ctx, node))

		if next.kind == .BracketRoundOpen { //  S123  a(1, 2, 3) type of initializer
			// dont eat opeing (, it will get eaten by ast_aprse_function_call_arguments

			call := AstNode{ kind = .FunctionCall, function_call = {
				expression = append_simple_identifier(ctx, { kind = .Identifier, source = "init", location = next.location }),
			}}
			ast_parse_function_call_arguments(ctx, tokens, &call.function_call.arguments) or_return

			synthesized_initializer := AstNode{ kind = .MemberAccess, member_access = {
				expression = append_simple_identifier(ctx, name),
				member = ast_append_node(ctx, call),
			}}

			append(sequence, ast_append_node(ctx, synthesized_initializer))

			next, ns = peek_token(tokens)
		}

		#partial switch next.kind {
			case .Comma:
				if stop_at_comma { return }
				tokens^ = ns // eat ,

			case .Semicolon, // int a;
					.BracketRoundClose, // fn(int a)
					.Colon: // for(int a : b)
				return
			
			case:
				push_error(ctx, { message = "Expected valid variable declaration temination token", actual = next })
				err = .Some
				return
		}
	}
}

ast_parse_function_call :: proc(ctx: ^AstContext, tokens : ^[]Token, loc := #caller_location) -> (node : AstNode, err : AstError)
{
	tokens_reset := tokens^
	ast_reset := len(ctx.ast)
	arguments : [dynamic]AstNodeIndex

	defer if err != .None {
		push_error(ctx, { message = "Failed to parse function call" })
		delete(arguments)
		resize(ctx.ast, ast_reset)
		tokens^ = tokens_reset
	}


	qualified_name, _ := ast_parse_qualified_name(ctx, tokens) or_return

	template_arguments : [dynamic]AstNodeIndex
	if n, ns := peek_token(tokens); n.kind == .BracketTriangleOpen {
		tokens^ = ns
		ast_parse_generic_arguments_no_opening_bracket(ctx, tokens, &template_arguments) or_return
	}

	// Some special parsing for specific functions...
	// Ually this would have to be way more complicated to handle macros, but ill jsut hardcode this.
	switch ctx.ast[qualified_name].identifier.token.source {
		case "va_arg":
			eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
			resize(&arguments, 2)
			arguments[0] = ast_append_node(ctx, ast_parse_expression(ctx, tokens, .Comma - ._1) or_return)
			eat_token_expect_push_err(ctx, tokens, .Comma) or_return
			type := ast_parse_type(ctx, tokens) or_return
			arguments[1] = ast_append_node(ctx, AstNode{ kind = .Type, type = type })
			eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

		case "sizeof":
			eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
			tr := tokens^
			resize(&arguments, 1)
			type, terr := ast_parse_type(ctx, tokens); reset_error(ctx)
			nn, nns := peek_token(tokens)
			if terr == .None && nn.kind == .BracketRoundClose {
				arguments[0] = ast_append_node(ctx, AstNode{ kind = .Type, type = type })
			}
			else {
				tokens^ = tr
				expr := ast_parse_expression(ctx, tokens) or_return
				arguments[0] = ast_append_node(ctx, expr)
			}
			eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

		case "offsetof":
			eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
			resize(&arguments, 2)
			expr := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return
			arguments[0] = ast_append_node(ctx, expr)
			eat_token_expect_push_err(ctx, tokens, .Comma) or_return
			field := eat_token_expect_push_err(ctx, tokens, .Identifier) or_return
			arguments[1] = append_simple_identifier(ctx, field)
			eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

		case:
			ast_parse_function_call_arguments(ctx, tokens, &arguments) or_return
	}
	node = AstNode{ kind = .FunctionCall, function_call = {
		expression = qualified_name,
		template_arguments = template_arguments,
		arguments = arguments,
	}}
	return
}

ast_parse_function_call_arguments :: proc(ctx: ^AstContext, tokens : ^[]Token, arguments : ^[dynamic]AstNodeIndex, loc := #caller_location) -> (err : AstError)
{
	defer if err != .None {
		push_error(ctx, { message = "Failed to parse function call arguemnts" })
	}

	eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
	loop: for {
		n, ns := peek_token(tokens)

		#partial switch n.kind {
			case .BracketRoundClose:
				tokens^ = ns
				break loop
			
			case .Comma:
				tokens^ = ns
				continue

			case .Comment:
				tokens^ = ns
				//TODO

			case:
				arg := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return
				append(arguments, ast_append_node(ctx, arg))
		}
	}

	return
}

ast_parse_fnptr_type :: proc(ctx : ^AstContext, tokens : ^[]Token) -> (type : AstTypeIndex, err : AstError)
{
	return_type := ast_parse_type(ctx, tokens) or_return
	eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
	eat_token_expect_push_err(ctx, tokens, .Star) or_return

	type = ast_parse_fnptr_type_starting_at_name(ctx, tokens, return_type) or_return

	return
}

ast_parse_fnptr_type_starting_at_name :: proc(ctx : ^AstContext, tokens : ^[]Token, preparsed_return_type : AstTypeIndex) -> (type : AstTypeIndex, err : AstError)
{
	name, _ := eat_token_expect_push_err(ctx, tokens, .Identifier) // name is optional
	eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

	arguments : [dynamic]AstNodeIndex
	ast_parse_function_args_def_with_brackets(ctx, tokens, &arguments) or_return

	fn := ast_append_type(ctx, AstTypeFunction{
		name = name,
		arguments = arguments[:],
		return_type = preparsed_return_type,
	})

	type = ast_append_type(ctx, AstTypePointer{ destination_type = fn })

	return
}

ast_parse_type :: proc(ctx : ^AstContext, tokens : ^[]Token, parent_type : AstTypeIndex = {}, loc := #caller_location) -> (type : AstTypeIndex, err : AstError)
{
	// int
	// const int
	// int const
	// const char***
	// const ::char const** const&
	// A<int, int*>

	type_reset := len(ctx.type_heap)
	tokens_reset := tokens^
	defer if err != .None {
		push_error(ctx, { message = "Failed to parse type", actual = first_or_nil(tokens^) })
		tokens^ = tokens_reset
		resize(&ctx.type_heap, type_reset)
	}

	has_name := false
	has_int_modifier := false

	type = parent_type
	primitive_fragments : [dynamic]Token

	next_is_const := false
	if parent_type == {} {
		// const usually referes to the left side, except it can be on the verry left and referrs to the right element in that case... 
		if n, ns := peek_token(tokens); n.kind == .Identifier && n.source == "const" {
			tokens^ = ns
			next_is_const = true
		}
	}

	type_loop: for {
		n, ns := peek_token(tokens)

		if n.kind == .Identifier {
			switch n.source {
				case "const":
					tokens^ = ns
					#partial switch &frag in ctx.type_heap[type] {
						case AstTypePointer  : frag.flags |= { .Const }
						case AstTypeFragment : frag.flags |= { .Const }
						case AstTypePrimitive: frag.flags |= { .Const }
						case AstTypeVoid     : frag.flags |= { .Const }

						case:
							err = .Some
							push_error(ctx, {
								message = fmt.aprintf("const modifier can only be applied to pointers, fragments, primitives or void, but the previous fragment was %v.", frag),
								actual = n,
							})
							return
					}
					continue
					
				case "auto":
					tokens^ = ns
					type = ast_append_type(ctx, AstTypeAuto{ token = n });
					has_name = true
					continue

				case "void":
					tokens^ = ns
					type = ast_append_type(ctx, AstTypeVoid{ token = n });
					has_name = true
					continue

				case "short", "long":
					tokens^ = ns
					append(&primitive_fragments, n)
					has_int_modifier = true
					continue

				case "unsigned", "signed":
					tokens^ = ns
					append(&primitive_fragments, n)
					has_int_modifier = true
					continue

				case "int", "char", "float", "double", "bool":
					tokens^ = ns

					append(&primitive_fragments, n)
					type = ast_append_type(ctx, AstTypePrimitive{ fragments = primitive_fragments[:], flags = next_is_const ? { .Const } : {} });
					primitive_fragments = {} // reset
					next_is_const = false

					has_name = true
					continue

				case:
					if has_int_modifier || has_name {
						if len(primitive_fragments) > 0 {
							type = ast_append_type(ctx, AstTypePrimitive{ fragments = primitive_fragments[:] });
						}
						break type_loop
					}

					tokens^ = ns

					type = ast_append_type(ctx, AstTypeFragment{ parent_fragment = type, identifier = n, flags = next_is_const ? { .Const } : {} })
					next_is_const = false

					has_name = true
					continue
			}
		}
		else if len(primitive_fragments) > 0 {
			type = ast_append_type(ctx, AstTypePrimitive{ fragments = primitive_fragments[:] });
			primitive_fragments = {} // reset
			has_name = true
			continue
		}

		#partial switch n.kind {
			case .Ampersand, .Star:
				if type == {} {
					push_error(ctx, { message = "Expected type before pointer designation", actual = n })
					err = .Some
					return
				}

				tokens^ = ns
				type = ast_append_type(ctx, AstTypePointer{
					destination_type = type,
					flags = n.kind == .Ampersand ? { .Reference } : { },
				});

			case .BracketSquareOpen:
				if type == {} {
					push_error(ctx, { message = "Expected type before array designation", actual = n })
					err = .Some
					return
				}

				if nn, nns := peek_token(&ns); nn.kind == .BracketSquareClose { // ...[]
					tokens^ = nns
					type = ast_append_type(ctx, AstTypeArray{ element_type = type });
					break type_loop // []can only be the last part
				}
				else { // ...[3]
					tokens^ = ns
					length_expression := ast_parse_expression(ctx, tokens) or_return
					eat_token_expect_push_err(ctx, tokens, .BracketSquareClose) or_return

					type = ast_append_type(ctx, AstTypeArray{
						element_type = type,
						length_expression = ast_append_node(ctx, length_expression),
					});
				}

			case .Identifier:
				/**/

			case .StaticScopingOperator:
				tokens^ = ns // eat the ::

				// reset the name parser and wait for a nother identifier segment 
				has_name = false 


			case .BracketTriangleOpen:
				if type == {} {
					push_error(ctx, { message = "Expected type before generic parameters", actual = n })
					err = .Some
					return
				}

				tokens^ = ns

				params : [dynamic]AstNodeIndex

				if e := ast_parse_generic_arguments_no_opening_bracket(ctx, tokens, &params); e != .None {
					delete(params)
					err = .Some
					return
				}

				(&ctx.type_heap[type].(AstTypeFragment)).generic_parameters = params[:]

			case:
				if !has_name && !has_int_modifier {
					err = .Some
					push_error(ctx, { actual = n, message = "Expected type" })
				}
				return
		}
	}

	return
}

ast_parse_generic_arguments_no_opening_bracket :: proc(ctx : ^AstContext, tokens : ^[]Token, argument_storage : ^[dynamic]AstNodeIndex, loc := #caller_location) -> (err : AstError)
{
	for {
		#partial switch nn, nns := peek_token(tokens); nn.kind {
			case .BracketTriangleClose:
				tokens^ = nns // closing >
				return

			case .Comma:
				tokens^ = nns

			case:
				if param, type_err := ast_parse_type(ctx, tokens); type_err == .None {
					append(argument_storage, ast_append_node(ctx, AstNode{ kind = .Type, type = param}))
					continue
				}
				reset_error(ctx)

				if expr, expr_err := ast_parse_expression(ctx, tokens, .Comparison - ._1); expr_err == .None {
					append(argument_storage, ast_append_node(ctx, expr))
					continue
				}
				else {
					err = .Some
					push_error(ctx, { message = "Failed to parse template arguemnts, expected inner type or expression", actual = nn })
					return
				}
		}
	}
}

ast_parse_qualified_name :: proc(ctx : ^AstContext, tokens : ^[]Token, accept_dtor := false, loc := #caller_location) -> (name_head : AstNodeIndex, was_dtor : bool, err : AstError)
{
	name_head, was_dtor = ast_try_parse_qualified_name(ctx, tokens, accept_dtor)
	if name_head != 0 { return }

	push_error(ctx, { expected = { kind = .Identifier }, actual = tokens[0], code_location = loc })
	err = .Some
	return
}

ast_try_parse_qualified_name :: proc(ctx : ^AstContext, tokens : ^[]Token, accept_dtor := false) -> (name_head : AstNodeIndex, was_dtor : bool)
{
	node : AstNode
	node, was_dtor = #force_inline ast_try_parse_qualified_name_incomplete(ctx, tokens, accept_dtor)
	if node.kind != {} {
		name_head = ast_append_node(ctx, node)
	}
	return
}

ast_try_parse_qualified_name_incomplete :: proc(ctx : ^AstContext, tokens : ^[]Token, accept_dtor := false) -> (node : AstNode, was_dtor : bool)
{
	next_can_be_tilde := true
	for {
		n, ns := peek_token(tokens)
		#partial switch n.kind {
			case .StaticScopingOperator:
				tokens^ = ns
				next_can_be_tilde = true
			
			case .Identifier:
				tokens^ = ns

				parent : AstNodeIndex
				if node.kind != {} { parent = ast_append_node(ctx, node) }

				node = { kind = .Identifier, identifier = { parent = parent, token = n } }

				next_can_be_tilde = false

			case .Tilde:
				if !accept_dtor || !next_can_be_tilde { return }

				tokens^ = ns

				was_dtor = true

			case:
				return
		}
	}
}

ast_try_parse_out_of_band_dtor_name :: proc(ctx : ^AstContext, tokens : ^[]Token) -> (name : AstNodeIndex)
{
	for {
		n, ns := peek_token(tokens)
		#partial switch n.kind {
			case .StaticScopingOperator:
				tokens^ = ns
			
			case .Identifier:
				tokens^ = ns

				name = ast_append_node(ctx, { kind = .Identifier, identifier = { parent = name, token = n } })

			case .Tilde:
				/**/

			case:
				return
		}
	}
}


OperatorPresedence :: enum {
	_1               = 1,
	CppCast          = 2,
	PostfixIncrement = 2,
	PostfixDecrement = 2,
	FunctionCall     = 2,
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

ast_parse_expression :: proc(ctx: ^AstContext, tokens : ^[]Token, max_presedence := max(OperatorPresedence), comment_storage : ^[dynamic]Token = nil, loc := #caller_location) -> (node : AstNode, err : AstError)
{
	token_reset := tokens^
	ast_reset_size := len(ctx.ast)
	sequence : [dynamic]AstNodeIndex

	__d :: proc(ctx: ^AstContext, tokens : ^[]Token, sequence : [dynamic]AstNodeIndex, ast_reset_size : int, token_reset : []Token, loc : runtime.Source_Code_Location) {
		push_error(ctx, { message = "Failed to parse expression", actual = first_or_nil(tokens^) }, loc)
		delete(sequence)
		resize(ctx.ast, ast_reset_size)
		tokens^ = token_reset
	}
	defer if err != .None {
		__d(ctx, tokens, sequence, ast_reset_size, token_reset, loc)
	}

	// have to add this before every ok return, defer cannot modify return values
	fixup_sequence :: proc(node : ^AstNode, ctx: ^AstContext, sequence : ^[dynamic]AstNodeIndex)
	{
		reset_error(ctx)
		if len(sequence) > 0 {
			append(sequence, ast_append_node(ctx, node^)) // append last elm in sequence
			node^ = AstNode{ kind = .Sequence, sequence = { members = sequence^} }
		}
	}


	err_, _ := peek_token(tokens)
	err = .Some
	defer if err == .Some {
		push_error(ctx, { actual = err_, message = "Expected valid expression" })
	}

	for {
		before_iteration := tokens^

		next, nexts := peek_token(tokens)

		if err == .None { // we already have a "left" and are looking for a binary operator
			#partial switch next.kind {
				case .Dot, .DereferenceMember:
					tokens^ = nexts // eat -> or .

					member_name, ns := peek_token(tokens)

					member_node : AstNode
					if member_name.kind == .Tilde { // explicit dtor call
						tokens^ = ns // skip ~
						member_node = ast_parse_function_call(ctx, tokens) or_return
						member_node.function_call.is_destructor = true
					}
					else if n, _ := peek_token(&ns); n.kind == .BracketRoundOpen {
						member_node = ast_parse_function_call(ctx, tokens) or_return
					}
					else {
						tokens^ = ns // eat member name

						member_node = AstNode { kind = .Identifier, identifier = { token = member_name }}
					}

					node = AstNode{ kind = .MemberAccess, member_access = {
						expression = ast_append_node(ctx, node),
						member = ast_append_node(ctx, member_node),
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
						case .Equals              : presedence = .Equality
						case .NotEquals           : presedence = .Equality
						case .LessEq              : presedence = .Comparison
						case .GreaterEq           : presedence = .Comparison
						case .ShiftLeft           : presedence = .Bitshift
						case .ShiftRight          : presedence = .Bitshift
						case .Percent             : presedence = .Modulo
						case .AssignPlus, .AssignMinus, .AssignStar, .AssignForwardSlash, .AssignAmpersand, .AssignPipe, .AssignCircumflex, .AssignPercent, .AssignShiftLeft, .AssignShiftRight:
							presedence = .AssignModify
					}

					if max_presedence < presedence {
						fixup_sequence(&node, ctx, &sequence)
						return
					}

					tokens^ = nexts

					right_node := ast_parse_expression(ctx, tokens, presedence) or_return

					node = AstNode{ kind = .ExprBinary, binary = {
						left = ast_append_node(ctx, node),
						operator = transmute(AstBinaryOp) next.kind,
						right = ast_append_node(ctx, right_node),
					}}

					continue

				case .BracketSquareOpen:
					tokens^ = nexts

					index_expression := ast_parse_expression(ctx, tokens) or_return
					eat_token_expect_push_err(ctx, tokens, .BracketSquareClose) or_return

					node = AstNode{ kind = .ExprIndex, index = {
						array_expression = ast_append_node(ctx, node),
						index_expression = ast_append_node(ctx, index_expression),
					}}
					continue

				case .PostfixIncrement, .PostfixDecrement:
					tokens^ = nexts

					node = AstNode{ kind = .ExprUnaryRight, unary_right = {
						operator = next.kind == .PostfixIncrement ? .Increment : .Decrement,
						left = ast_append_node(ctx, node),
					}}
					continue

				case .Questionmark:
					if max_presedence < .Tenary {
						fixup_sequence(&node, ctx, &sequence)
						return
					}

					tokens^ = nexts

					true_expression := ast_parse_expression(ctx, tokens) or_return
					eat_token_expect_push_err(ctx, tokens, .Colon) or_return
					false_expression := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return

					node = AstNode{ kind = .ExprTenary, tenary = {
						condition        = ast_append_node(ctx, node),
						true_expression  = ast_append_node(ctx, true_expression),
						false_expression = ast_append_node(ctx, false_expression),
					}}
					continue

				case .BracketRoundOpen: // function call of some sort
					args : [dynamic]AstNodeIndex
					ast_parse_function_call_arguments(ctx, tokens, &args) or_return

					node = AstNode{ kind = .FunctionCall, function_call = {
						expression = ast_append_node(ctx, node),
						arguments  = args,
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

				if max_presedence < presedence {
					if err != .None == false { fixup_sequence(&node, ctx, &sequence) }
					return
				}

				tokens^ = nexts

				right_node := ast_parse_expression(ctx, tokens, presedence) or_return
				node = AstNode{ kind = .ExprUnaryLeft, unary_left = {
					operator = transmute(AstUnaryOp)next.kind,
					right = ast_append_node(ctx, right_node),
				}}
				err = .None
				continue
			
			case .LiteralFloat:
				node = AstNode{ kind = .LiteralFloat, literal = next }
				tokens^ = nexts; err = .None
				continue

			case .LiteralString:
				node = AstNode{ kind = .LiteralString, literal = next }
				tokens^ = nexts; err = .None
				continue

			case .LiteralInteger:
				node = AstNode{ kind = .LiteralInteger, literal = next }
				tokens^ = nexts; err = .None
				continue

			case .LiteralCharacter:
				node = AstNode{ kind = .LiteralCharacter, literal = next }
				tokens^ = nexts; err = .None
				continue

			case .LiteralNull:
				node = AstNode{ kind = .LiteralNull, literal = next }
				tokens^ = nexts; err = .None
				continue

			case .LiteralBool:
				node = AstNode{ kind = .LiteralBool, literal = next }
				tokens^ = nexts; err = .None
				continue

			case .BracketRoundOpen: // bracketed expression or cast
				og_nexts := nexts

				err_reset := len(ctx.error_stack)
				if type, te := ast_parse_type(ctx, &nexts); te == .None && find_next_actual_token(&nexts)[0].kind == .BracketRoundClose { // cast: (type) expression
					eat_token_expect_push_err(ctx, &nexts, .BracketRoundClose) or_return

					if expression, ee := ast_parse_expression(ctx, &nexts, .CCast); ee == .None {
						// next expression parsed properly, this was in fact a cast
						tokens^ = nexts

						node = AstNode { kind = .ExprCast, cast_ = {
							type = type,
							expression = ast_append_node(ctx, expression),
						}}

						err = .None
						continue
					}
					// next expression failed to parse, this was actualyl a bracketed expression that looked like a type
					//TODO(Rennorb) @perf: Duplicate some work by reparsing, probably doenst matter.
				}
				resize(&ctx.error_stack, err_reset)

				// bracketed expression: (expression)

				if tokens[1].kind == .Star && tokens[2].kind == .Identifier && tokens[3].kind == .BracketRoundClose && tokens[4].kind == .BracketRoundOpen { // fnptr call: (*fnptr)(a, b, c)

					ident := append_simple_identifier(ctx, tokens[2])

					tokens^ = tokens[4:] // eat everythign upt ot the '(a, b, ...'  args

					args : [dynamic]AstNodeIndex
					ast_parse_function_call_arguments(ctx, tokens, &args) or_return

					node = AstNode { kind = .FunctionCall, function_call = {
						expression = ident,
						arguments = args,
					}}

					err = .None
					continue
				}

				tokens^ = og_nexts // eat (

				inner := ast_parse_expression(ctx, tokens) or_return
				node = AstNode { kind = .ExprBacketed, inner = ast_append_node(ctx, inner)}

				eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

				err = .None
				continue

			case .StaticCast, .ConstCast, .BitCast: // static_cast<type>(expression)
				tokens^ = nexts

				eat_token_expect_push_err(ctx, tokens, .BracketTriangleOpen) or_return
				type := ast_parse_type(ctx, tokens) or_return
				eat_token_expect_push_err(ctx, tokens, .BracketTriangleClose) or_return
				eat_token_expect_push_err(ctx, tokens, .BracketRoundOpen) or_return
				expression := ast_parse_expression(ctx, tokens) or_return
				eat_token_expect_push_err(ctx, tokens, .BracketRoundClose) or_return

				node = AstNode { kind = .ExprCast, cast_ = {
					type = type,
					expression = ast_append_node(ctx, expression),
					kind = next.kind == .ConstCast ? .Const : next.kind == .BitCast ? .Bit : .Static,
				}}

				err = .None
				continue

			case .Operator: // explicit operator call e.g.   operator=(a)
				tokens^ = nexts

				node = AstNode { kind = .OperatorCall }

				n, ns := peek_token(tokens)
				#partial switch n.kind {
					// assume binary for now, adjust after counting arguments
					//case .Plus:      node.operator_call.kind = .UnaryPlus
					//case .Minus:     node.operator_call.kind = .UanryMinus
					case .Tilde             : tokens^ = ns; node.operator_call.kind = .Invert
					case .PrefixIncrement   : tokens^ = ns; node.operator_call.kind = .Increment
					case .PostfixDecrement  : tokens^ = ns; node.operator_call.kind = .Decrement
					case .Equals            : tokens^ = ns; node.operator_call.kind = .Equals
					case .NotEquals         : tokens^ = ns; node.operator_call.kind = .NotEquals
					case .Plus              : tokens^ = ns; node.operator_call.kind = .Add
					case .Minus             : tokens^ = ns; node.operator_call.kind = .Subtract
					case .Star              : tokens^ = ns; node.operator_call.kind = .Multiply
					case .ForwardSlash      : tokens^ = ns; node.operator_call.kind = .Divide
					case .Assign            : tokens^ = ns; node.operator_call.kind = .Assign
					case .AssignPlus        : tokens^ = ns; node.operator_call.kind = .AssignAdd
					case .AssignMinus       : tokens^ = ns; node.operator_call.kind = .AssignSubtract
					case .AssignStar        : tokens^ = ns; node.operator_call.kind = .AssignMultiply
					case .AssignForwardSlash: tokens^ = ns; node.operator_call.kind = .AssignDivide
					case .BracketSquareOpen:
						eat_token_expect_push_err(ctx, &ns, .BracketSquareClose) or_return
						tokens^ = ns
						node.operator_call.kind = .Index
					case: // TODO explicit custom cast call doesnt make much sense
						err = .Some
						push_error(ctx, { actual = n, message = "Expected valid operator (one of ~, ++, --, ==, !=, +, -, *, /, &, |, ^, =, +=, -=, *=, /=, [])" })
						return
				}

				ast_parse_function_call_arguments(ctx, tokens, &node.operator_call.parameters) or_return

				err = .None
				continue

			case .BracketCurlyOpen: // compound initializer
				tokens^ = nexts // eat the {
				node = ast_parse_compound_initializer_no_start_curly_brace(ctx, tokens) or_return

				err = .None
				continue

			case .BracketSquareOpen:
				node = ast_parse_lambda_declaration(ctx, tokens) or_return
				err = .None
				continue

			case .Comma:
				if err == .None && max_presedence >= .Comma {
					tokens^ = nexts // eat the ,
					append(&sequence, ast_append_node(ctx, node))
					err = .Some
					push_error(ctx, { actual = next, message = "Expected preceeding comma to not be freestanding" })
					continue
				}
				else {
					if err == .None { fixup_sequence(&node, ctx, &sequence) }
					return // keep ok state
				}

			case .Comment:
				if comment_storage != nil { append(comment_storage, next) }
				tokens^ = nexts
				continue
		}

		tok_reset := tokens^
		ast_reset := len(ctx.ast)
		simple, _ := ast_try_parse_qualified_name_incomplete(ctx, tokens)
		if simple.kind == {} {
			resize(ctx.ast, ast_reset)
			tokens^ = tok_reset

			if err == .None { fixup_sequence(&node, ctx, &sequence) }
			return // keep the ok state
		}

		// dont parse 'int a' (two idents) as expression
		if node.kind == .Identifier {
			push_error(ctx, { actual = next, message = "Did not expect two identifiers after each other" }, loc)
			err = .Some
			return
		}

		node = simple
		err = .None

		next, nexts = peek_token(tokens)
		if next.kind == .BracketRoundOpen { // function call
			tokens^ = before_iteration
			node = ast_parse_function_call(ctx, tokens) or_return
			continue
		}

		if next.kind == .BracketTriangleOpen { // maybe generic function call ? 
			ast_reset := len(ctx.ast)
			type_reset := len(ctx.type_heap)
			if fn_call_node, _ := ast_parse_function_call(ctx, &before_iteration); !has_error__reset(ctx) {
				node = fn_call_node
				tokens^ = before_iteration
			}
			else { // probably a comparison then   a < b
				resize(ctx.ast, ast_reset)
				resize(&ctx.type_heap, type_reset)
			}
		}
	}
}

ast_parse_compound_initializer_no_start_curly_brace :: proc(ctx : ^AstContext, tokens: ^[]Token) -> (node : AstNode, err : AstError)
{
	node = AstNode{ kind = .CompoundInitializer }

	member_loop: for {
		n, ns := peek_token(tokens, false)
		#partial switch n.kind {
			case .BracketCurlyClose:
				tokens^ = ns // eat the }
				break member_loop

			case .Comma:
				tokens^ = ns // eat the ,

			case .Comment:
				tokens^ = ns
				append(&node.compound_initializer.values, ast_append_node(ctx, AstNode{ kind = .Comment, literal = n }))

			case .NewLine:
				tokens^ = ns
				append(&node.compound_initializer.values, ast_append_node(ctx, AstNode{ kind = .NewLine }))

			case:
				was_preproc := ast_try_parse_preproc_statement(ctx, tokens, &node.compound_initializer.values, n, ns)
				if was_preproc { break }

				comments := make([dynamic]Token, context.temp_allocator)
				expression := ast_parse_expression(ctx, tokens, .Comma - ._1, &comments) or_return
				append(&node.compound_initializer.values, ast_append_node(ctx, expression))

				for c in comments {
					append(&node.compound_initializer.values, ast_append_node(ctx, AstNode{ kind = .Comment, literal = c }))
				}
		}
	}
	return
}

//TODO(Rennorb): Regression test
ast_parse_lambda_declaration :: proc(ctx : ^AstContext, tokens : ^[]Token, loc := #caller_location) -> (node : AstNode, err : AstError)
{
	node.kind = .LambdaDefinition

	defer if err == .Some {
		push_error(ctx, { message = "Failed to parse lambda deffinition" }, loc)
	}

	eat_token_expect_push_err(ctx, tokens, .BracketSquareOpen) or_return
	capture_loop: for {
		n, ns := peek_token(tokens)
		#partial switch n.kind {
			case .BracketSquareClose:
				tokens^ = ns
				break capture_loop

			case .Comma:
				tokens^ = ns

			case .Ampersand, .Identifier:
				expression := ast_parse_expression(ctx, tokens, .Comma - ._1) or_return
				append(&node.lambda_def.captures, ast_append_node(ctx, expression))

			case:
				push_error(ctx, { actual = n, message = "Expected valid lambda capture set" }, loc)
				err = .Some
				return
		}
	}

	fn_def := ast_parse_function_def_no_return_type_and_name(ctx, tokens) or_return
	node.lambda_def.underlying_function = ast_append_node(ctx, fn_def)

	return
}

eat_remaining_line :: proc(tokens : ^[]Token)
{
	for len(tokens) > 0 && eat_token(tokens, false).kind != .NewLine { /**/ }
}

eat_token_expect :: proc { eat_token_expect_direct, eat_token_expect_push_err }

eat_token_expect_push_err :: proc(ctx : ^AstContext, tokens : ^[]Token, expected_type : TokenKind, ignore_newline := true, loc := #caller_location) -> (t : Token, err : AstError)
{
	err_ : Maybe(AstErrorFrame)
	t, err_ = eat_token_expect_direct(tokens, expected_type, ignore_newline, loc)
	if e, er := err_.?; er {
		push_error(ctx, e, loc)
		err = .Some
	}
	return
}

eat_token_expect_direct :: proc(tokens : ^[]Token, expected_type : TokenKind, ignore_newline := true, loc := #caller_location) -> (t : Token, err : Maybe(AstErrorFrame))
{
	s : []Token
	t, s = peek_token(tokens, ignore_newline)

	if t.kind == expected_type {
		tokens^ = s
	}
	else {
		err = AstErrorFrame{ actual = t, expected = { kind = expected_type }, code_location = loc }
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

AstError :: enum { None, Some }

AstErrorFrame :: struct {
	actual, expected : Token,
	message : string,
	code_location : runtime.Source_Code_Location,
	depth : int,
}

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

	New,
	Delete,
	Index,
	ImplicitCast,
}

// not castable to AstOp
AstUnaryOp :: enum {
	Dereference  = cast(int) TokenKind.Star,
	AddressOf    = cast(int) TokenKind.Ampersand,
	Plus         = cast(int) TokenKind.Plus,
	Minus        = cast(int) TokenKind.Minus,
	Invert       = cast(int) TokenKind.Tilde,
	Not          = cast(int) TokenKind.Exclamationmark,
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
	//ScopeAccess,
	Identifier,
	Sequence,
	Namespace,
	UsingNamespace,
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
	CompoundInitializer,
	FunctionDefinition,
	OperatorDefinition,
	LambdaDefinition,
	Type,
	VariableDeclaration,
	TemplateVariableDeclaration,
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
	Goto,
	Label,
	Branch,
	Switch,
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
		identifier : struct {
			token : Token,
			parent : AstNodeIndex,
		},
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
			type : AstTypeIndex,
			expression : AstNodeIndex,
			kind : enum{ Static, Const, Bit }
		},
		sequence : struct {
			members : [dynamic]AstNodeIndex,
			declared_names : map[string]AstNodeIndex,
			parent_scope : AstNodeIndex,
			braced : bool,
		},
		token_sequence : [dynamic]Token,
		namespace : struct {
			name     : Token,
			member_sequence : [dynamic]AstNodeIndex,
			declared_names : map[string]AstNodeIndex,
			parent_scope : AstNodeIndex,
			merged_member_sequence : [dynamic]AstNodeIndex, // @hack used for overload detection
		},
		function_call : struct {
			expression : AstNodeIndex,
			template_arguments : [dynamic]AstNodeIndex,
			arguments  : [dynamic]AstNodeIndex,
			is_destructor : bool,
		},
		operator_call : struct {
			kind : AstOverloadedOp,
			parameters : [dynamic]AstNodeIndex,
		},
		compound_initializer : struct {
			values : [dynamic]AstNodeIndex,
		},
		assert : struct {
			condition : AstNodeIndex,
			message : string,
			static : bool,
		},
		type : AstTypeIndex,
		var_declaration : struct {
			type : AstTypeIndex,
			var_name : Token,
			initializer_expression : AstNodeIndex,
			width_expression : AstNodeIndex,
			parent_structure : AstNodeIndex,
			flags : AstVariableDefFlags,
		},
		function_def : struct {
			function_name : AstNodeIndex,
			return_type : AstTypeIndex,
			arguments : [dynamic]AstNodeIndex,
			body_sequence : [dynamic]AstNodeIndex,
			attached_comments : [dynamic]AstNodeIndex,
			template_spec : [dynamic]AstNodeIndex,
			flags : AstFunctionDefFlags,
			declared_names : map[string]AstNodeIndex,
			parent_scope : AstNodeIndex,
			parent_structure : AstNodeIndex,
		},
		operator_def : struct {
			kind : AstOverloadedOp,
			underlying_function : AstNodeIndex,
			is_explicit : bool,
		},
		lambda_def : struct {
			captures : [dynamic]AstNodeIndex,
			underlying_function : AstNodeIndex,
		},
		index : struct {
			array_expression : AstNodeIndex,
			index_expression : AstNodeIndex,
		},
		return_ : struct {
			expression : AstNodeIndex,
		},
		label : Token,
		structure : struct {
			name : AstNodeIndex,
			base_type : AstTypeIndex,
			members : [dynamic]AstNodeIndex,
			deinitializer : AstNodeIndex,
			attached_comments : [dynamic]AstNodeIndex,
			template_spec : [dynamic]AstNodeIndex,
			generic_instantiations : map[string]AstNodeIndex,
			flags : AstStructureFlags,
			synthetic_this_var : AstNodeIndex,
			declared_names : map[string]AstNodeIndex,
			parent_scope : AstNodeIndex,
			parent_structure : AstNodeIndex,
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
			initializer, condition, loop_statement : [dynamic]AstNodeIndex,
			body_sequence : [dynamic]AstNodeIndex,
			is_foreach : bool,
			declared_names : map[string]AstNodeIndex,
			parent_scope : AstNodeIndex,
		},
		branch : struct {
			condition : [dynamic]AstNodeIndex,
			true_branch, false_branch : AstNodeIndex,
			declared_names : map[string]AstNodeIndex, // used for the scope of teh condition itself
			parent_scope : AstNodeIndex,
		},
		switch_ : struct {
			expression : AstNodeIndex,
			// default case will have an empty expression
			cases : [dynamic]struct {
				match_expression : AstNodeIndex,
				body_sequence : [dynamic]AstNodeIndex,
			},
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
	Mutable,
	Explicit,
	_1 = 10,
}
AstStorageModifier :: bit_set[AstStorageModifierFlag]

AstVariableDefFlags :: bit_set[enum{
	Static      = cast(int) AstStorageModifier.Static,
	Extern      = cast(int) AstStorageModifier.Extern,
	Inline      = cast(int) AstStorageModifier.Inline,
	ThreadLocal = cast(int) AstStorageModifier.ThreadLocal,
	Mutable     = cast(int) AstStorageModifier.Mutable,
	_1 = 10,
}]

AstFunctionDefFlags :: bit_set[enum{
	Static = cast(int) AstStorageModifier.Static,
	Extern = cast(int) AstStorageModifier.Extern,
	Inline = cast(int) AstStorageModifier.Inline,
	IsForwardDeclared = cast(int) max(AstStorageModifierFlag) + 1,
	Const,
	IsCtor,
	IsDtor,
}]

AstStructureFlags :: bit_set[enum {
	IsForwardDeclared,
	HasImplicitCtor,
}]


fmt_astindex_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	idx := transmute(^AstNodeIndex)arg.data
	return fmt_astindex(fi, idx, verb)
}

@(thread_local) current_ast: ^[dynamic]AstNode
@(thread_local) displayed_nodes : map[AstNodeIndex]struct{}
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

	if _, _, not_yet_shown, _ := map_entry(&displayed_nodes, idx^); not_yet_shown {
		fmt.fmt_arg(fi, current_ast[idx^], verb)
	}
	else {
		fmt.wprintf(fi.writer, "AstNode <%v> <repeat>", current_ast[idx^].kind)
	}

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

	if node.attached {
		io.write_string(fi.writer, " [attached] ")
	}

	if fi.record_level > 10 {
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
		case .Goto               : fmt.fmt_arg(fi, node.label, 'v')
		case .Label              : fmt.fmt_arg(fi, node.label, 'v')
		case .Branch             : fmt.fmt_arg(fi, node.branch, 'v')
		case .Switch             : fmt.fmt_arg(fi, node.switch_, 'v')
		case .Identifier         : fmt.fmt_arg(fi, node.identifier, 'v')
		case .Sequence           : fmt.fmt_arg(fi, node.sequence, 'v')
		case .Namespace          : fmt.fmt_arg(fi, node.namespace, 'v')
		case .UsingNamespace     : fmt.fmt_arg(fi, node.identifier, 'v')
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
		case .CompoundInitializer: fmt.fmt_arg(fi, node.compound_initializer, 'v')
		case .FunctionDefinition : fmt.fmt_arg(fi, node.function_def, 'v')
		case .OperatorDefinition : fmt.fmt_arg(fi, node.operator_def, 'v')
		case .LambdaDefinition   : fmt.fmt_arg(fi, node.lambda_def, 'v')
		case .Type               : fmt.fmt_arg(fi, node.type, 'v')
		case .VariableDeclaration: fmt.fmt_arg(fi, node.var_declaration, 'v')
		case .TemplateVariableDeclaration: fmt.fmt_arg(fi, node.var_declaration, 'v')
		case .Assert             : fmt.fmt_arg(fi, node.assert, 'v')
		case .Return             : fmt.fmt_arg(fi, node.return_, 'v')
		case .Break              : fmt.fmt_arg(fi, node.literal, 'v')
		case .Continue           : fmt.fmt_arg(fi, node.literal, 'v')
		case .Struct             : fmt.fmt_arg(fi, node.structure, 'v')
		case .Union              : fmt.fmt_arg(fi, node.structure, 'v')
		case .Enum               : fmt.fmt_arg(fi, node.structure, 'v')
		case .Varargs            :
	}
	return true
}

fmt_ast_err_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	err := transmute(^Maybe(AstErrorFrame))arg.data
	return fmt_ast_err(fi, &err.?, 'v')
}
fmt_ast_erri_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	err := transmute(^AstErrorFrame)arg.data
	return fmt_ast_err(fi, err, 'v')
}

fmt_ast_err :: proc(fi: ^fmt.Info, err: ^AstErrorFrame, verb: rune) -> bool
{
	if err.code_location != {} {
		fmt.fmt_arg(fi, err.code_location, 'v')
		fmt.fmt_string(fi, ": ", 'v')
	}
	if err.message != "" {
		fmt.fmt_string(fi, err.message, 'v')
	}
	else {
		fmt.fmt_string(fi, fmt.tprintf("Expected %v", err.expected.kind), 'v')
	}
	if err.actual != {} {
		fmt.fmt_string(fi, fmt.tprintf(" at %v", err.actual), 'v')
	}
	return true
}

@(thread_local) current_types: ^[dynamic]AstType
fmt_asttypeidx :: proc(fi: ^fmt.Info, idx: ^AstTypeIndex, verb: rune) -> bool
{
	if len(current_types) == 0 { return false }
	if idx == nil {
		io.write_string(fi.writer, "TypeIndex <nil>")
		return true
	}
	switch idx^ {
		case  0: io.write_string(fi.writer, "TypeIndex 0");      return true
		// :ExplicitBuiltinTypes
		case -1: io.write_string(fi.writer, "TYPE_LIT_NULL");    return true
		case -2: io.write_string(fi.writer, "TYPE_LIT_BOOL");    return true
		case -3: io.write_string(fi.writer, "TYPE_LIT_INT32");   return true
		case -4: io.write_string(fi.writer, "TYPE_LIT_INT64");   return true
		case -5: io.write_string(fi.writer, "TYPE_LIT_FLOAT32"); return true
		case -6: io.write_string(fi.writer, "TYPE_LIT_FLOAT64"); return true
		case -7: io.write_string(fi.writer, "TYPE_LIT_STRING");  return true
		case -8: io.write_string(fi.writer, "TYPE_LIT_CHAR");    return true
	}
	
	io.write_string(fi.writer, fmt.tprintf("TypeIndex %v -> ", transmute(int) idx^))
	fmt.fmt_arg(fi, current_types[idx^], verb)
	return true
}

fmt_asttypeidx_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	idx := transmute(^AstTypeIndex)arg.data
	return fmt_asttypeidx(fi, idx, verb)
}


AstTypeInlineStructure :: distinct AstNodeIndex
AstTypeFunction :: struct {
	name        : Token,
	arguments   : []AstNodeIndex,
	return_type : AstTypeIndex,
}
AstTypePointer :: struct {
	flags            : bit_set[enum{ Const, Reference }],
	destination_type : AstTypeIndex,
}
AstTypeArray :: struct {
	element_type      : AstTypeIndex,
	length_expression : AstNodeIndex, // can be empty
}
AstTypeFragment :: struct {
	identifier         : Token,
	generic_parameters : []AstNodeIndex, // can by type or expression
	flags              : bit_set[enum{ Const }],
	parent_fragment    : AstTypeIndex,
}
AstTypePrimitive :: struct {
	fragments : []Token,
	flags     : bit_set[enum{ Const }],
}
AstTypeAuto :: struct {
	token : Token,
}
AstTypeVoid :: struct {
	token : Token,
	flags : bit_set[enum{ Const }],
}

AstType :: union { AstTypeInlineStructure, AstTypeFunction, AstTypePointer, AstTypeArray, AstTypeFragment, AstTypePrimitive, AstTypeAuto, AstTypeVoid }


AstTypeIndex :: distinct int 

// :ExplicitBuiltinTypes
TYPE_LIT_NULL    : AstTypeIndex : -1
TYPE_LIT_BOOL    : AstTypeIndex : -2
TYPE_LIT_INT32   : AstTypeIndex : -3
TYPE_LIT_INT64   : AstTypeIndex : -4
TYPE_LIT_FLOAT32 : AstTypeIndex : -5
TYPE_LIT_FLOAT64 : AstTypeIndex : -6
TYPE_LIT_STRING  : AstTypeIndex : -7
TYPE_LIT_CHAR    : AstTypeIndex : -8

ast_append_type :: #force_inline proc(ctx : ^AstContext, frag : AstType) -> AstTypeIndex
{
	return transmute(AstTypeIndex) append_return_index(&ctx.type_heap, frag)
}

ast_append_node :: #force_inline proc(ctx : ^AstContext, node : AstNode) -> AstNodeIndex
{
	return transmute(AstNodeIndex) append_return_index(ctx.ast, node)
}

append_simple_identifier :: #force_inline proc(ctx : ^$Ctx, identifier : Token) -> AstNodeIndex
{
	when Ctx == AstContext {
		return ast_append_node(ctx, { kind = .Identifier, identifier = { token = identifier } })
	}
	else {
		return cvt_append_node(ctx, { kind = .Identifier, identifier = { token = identifier } })
	}
}
