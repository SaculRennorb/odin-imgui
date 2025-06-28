package program

import      "core:os"
import      "core:fmt"
import      "core:mem"
import str  "core:strings"
import      "core:strconv"
import path "core:path/filepath"
import      "base:runtime"
import      "base:builtin"
import      "core:math"
import      "core:slice"
import      "core:log"
import      "core:io"
import sa   "core:container/small_array"

ConverterContext :: struct {
	result : str.Builder,
	ast : [dynamic]AstNode,
	type_heap : [dynamic]AstType,
	root_sequence : []AstNodeIndex,
	context_heap : [dynamic]Scope,
	temp_context_heap : [dynamic]Scope,
	overload_resolver : map[string][dynamic]string,
	next_anonymous_struct_index : i32,
}

convert_and_format :: proc(ctx : ^ConverterContext, implicit_names : [][2]string)
{
	ONE_INDENT :: "\t"

	if len(ctx.root_sequence) != 0 {
		current_scope_heap = &ctx.context_heap
		current_temp_scope_heap = &ctx.temp_context_heap
		append(&ctx.context_heap, Scope{ parent = { index = 0, persistence = .Persistent } })
		append(&ctx.temp_context_heap, Scope{ parent = { index = 0, persistence = .Temporary } })

		for pair in implicit_names {
			insert_new_definition(ctx, .Persistent, { index = 0, persistence = .Persistent }, pair[0], 0, pair[1])
		}

		str.write_string(&ctx.result, "package test\n\n")
		write_node_sequence(ctx, ctx.root_sequence, { index = 0, persistence = .Persistent }, .Persistent, "")
	}

	write_node :: proc(ctx : ^ConverterContext, current_node_index : AstNodeIndex, scope_persistence : PersistenceKind, scope : ScopeIndex, indent_str := "", definition_prefix := "") -> (requires_termination, requires_new_paragraph, swallow_paragraph : bool)
	{
		current_node := &ctx.ast[current_node_index]
		node_kind_switch: #partial switch current_node.kind {
			case .NewLine:
				str.write_byte(&ctx.result, '\n')

			case .Comment:
				str.write_string(&ctx.result, current_node.literal.source)

			case .Sequence:
				if current_node.sequence.braced { str.write_byte(&ctx.result, '{') }
				write_node_sequence(ctx, current_node.sequence.members[:], scope, scope_persistence, indent_str)
				if current_node.sequence.braced {
					if len(current_node.sequence.members) > 0 && ctx.ast[last(current_node.sequence.members[:])^].kind == .NewLine {
						str.write_string(&ctx.result, indent_str)
					}
					str.write_byte(&ctx.result, '}')
				}

			case .PreprocDefine:
				define := current_node.preproc_define

				str.write_string(&ctx.result, define.name.source)
				str.write_string(&ctx.result, " :: ")

				contentTokensCount := 0
				lastContentTokenKind : TokenKind
				for t in define.expansion_tokens {
					#partial switch t.kind {
						case .Comment, .NewLine:
							/**/
						case:
							contentTokensCount += 1
							lastContentTokenKind = t.kind
					}
				}
				
				switch contentTokensCount {
					case 0:
						str.write_string(&ctx.result, "true")
						write_token_range(&ctx.result, define.expansion_tokens, "") // still print in case there are comments

					case 1:
						write_token_range(&ctx.result, define.expansion_tokens, "")
						#partial switch lastContentTokenKind {
							case .LiteralBool, .LiteralCharacter, .LiteralFloat, .LiteralInteger, .LiteralNull, .LiteralString:
								insert_new_definition(ctx, .Persistent, scope, define.name.source, current_node_index, define.name.source)
						}

					case:
						write_token_range(&ctx.result, define.expansion_tokens, "")
				}

				insert_new_definition(ctx, .Persistent, { index = 0, persistence = .Persistent }, define.name.source, current_node_index, define.name.source)

			case .Typedef:
				define := current_node.typedef
				
				str.write_string(&ctx.result, define.name.source)
				type_node := ctx.ast[define.type]
				#partial switch type_node.kind {
					case .Type:
						str.write_string(&ctx.result, " :: ")
						write_type(ctx, scope, scope_persistence, type_node.type, indent_str, indent_str)

					case: // structure
						write_node(ctx, define.type, scope_persistence, scope, indent_str, indent_str)
				}

				insert_new_definition(ctx, scope_persistence, scope, define.name.source, current_node_index, define.name.source)

			case .Type:
				write_type(ctx, scope, scope_persistence, current_node.type, indent_str, indent_str)

			case .PreprocMacro:
				macro := current_node.preproc_macro

				arg_count := 0

				str.write_string(&ctx.result, macro.name.source)
				str.write_string(&ctx.result, " :: #force_inline proc \"contextless\" (")
				for arg in macro.args {
					if arg.kind != .Ellipsis {
						if arg_count > 0 { str.write_string(&ctx.result, ", ") }
						str.write_string(&ctx.result, arg.source)
						str.write_string(&ctx.result, " : ")
						fmt.sbprintf(&ctx.result, "$T%v", arg_count)

						arg_count += 1
					}
				}

				// scan the expansion and find stringify operations to turn into #caller_expression's
				idents_to_stringify : map[string]struct{}
				defer delete(idents_to_stringify)
				for i := 0; i < len(macro.expansion_tokens); i += 1 {
					if macro.expansion_tokens[i].kind == .Pound && i + 1 < len(macro.expansion_tokens) && macro.expansion_tokens[i + 1].kind == .Identifier {
						idents_to_stringify[macro.expansion_tokens[i + 1].source] = {}
					}
				}

				for i in idents_to_stringify {
					if arg_count > 0 { str.write_string(&ctx.result, ", ") }
					str.write_string(&ctx.result, "__")
					str.write_string(&ctx.result, i)
					str.write_string(&ctx.result, "_str := #caller_expression(")
					str.write_string(&ctx.result, i)
					str.write_byte(&ctx.result, ')')
				}

				// varargs after synthesized args
				for arg in macro.args {
					if arg.kind == .Ellipsis {
						if arg_count > 0 { str.write_string(&ctx.result, ", ") }
						str.write_string(&ctx.result, "args : ..[]any")
					}

					arg_count += 1
				}

				str.write_string(&ctx.result, ") //TODO @gen: Validate the parameters were not passed by reference.\n")
				str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{\n")
				current_member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)

				for i in idents_to_stringify {
					str.write_string(&ctx.result, current_member_indent_str)
					str.write_string(&ctx.result, "_ = ")
					str.write_string(&ctx.result, i)
					str.write_string(&ctx.result, " // Silence warnings in case the param is no longer used because of stringification changes. @gen\n")
				}

				last_broke_line := true
				for i := 0; i < len(macro.expansion_tokens); i += 1 {
					tok := macro.expansion_tokens[i]
					if last_broke_line { str.write_string(&ctx.result, current_member_indent_str) }
					#partial switch tok.kind {
						case .Semicolon:
							str.write_string(&ctx.result, ";\n")
							last_broke_line = true

						case .Pound:
							if i + 1 < len(macro.expansion_tokens) && macro.expansion_tokens[i + 1].kind == .Identifier {
								i += 1 // skip pound, ident will be skipped by loop

								str.write_string(&ctx.result, "__")
								str.write_string(&ctx.result, macro.expansion_tokens[i].source)
								str.write_string(&ctx.result, "_str")

								last_broke_line = false
								break
							}

							fallthrough

						case:
							str.write_string(&ctx.result, tok.source)
							last_broke_line = false
					}
				}
				if !last_broke_line { str.write_byte(&ctx.result, '\n') }
				str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "}\n")

				insert_new_definition(ctx, .Persistent, { index = 0, persistence = .Persistent }, macro.name.source, current_node_index, macro.name.source)

			case .FunctionDefinition:
				write_function(ctx, scope, scope_persistence, current_node_index, definition_prefix, nil, indent_str)

				swallow_paragraph = .IsForwardDeclared in current_node.function_def.flags 

			case .Struct, .Union:
				member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				swallow, new_para := write_struct_union(ctx, current_node, current_node_index, scope, scope_persistence, indent_str, member_indent_str, definition_prefix)
				swallow_paragraph |= swallow
				requires_new_paragraph |= new_para

			case .Enum:
				structure := &current_node.structure

				if len(structure.name) == 0 {
					structure.name = make_one(Token{ kind = .Identifier, source = fmt.aprintf("E%v", ctx.next_anonymous_struct_index) })[:]
					ctx.next_anonymous_struct_index += 1
				}
				complete_structure_name := fold_token_range(definition_prefix, structure.name)

				og_scope := scope
				scope := scope

				_, _, forward_declared_context := try_find_definition_for_name(ctx, scope, structure.name, {.Type})
				if forward_declared_context != nil {
					forward_declaration := ctx.ast[forward_declared_context.node]
					assert_node_kind(forward_declaration, .Enum)
	
					forward_comments := forward_declaration.structure.attached_comments
					inject_at(&structure.attached_comments, 0, ..forward_comments[:])
				}

				// enums spill out members into parent context, don't replace the scope for members
				scope = {
					index = transmute(uint) append_return_index(select_scope_heap(ctx, scope_persistence), Scope{ node = current_node_index, parent = scope, complete_name = complete_structure_name }),
					persistence = scope_persistence,
				}
				get_scope(ctx, og_scope).definitions[last(structure.name).source] = scope

				if .IsForwardDeclared in structure.flags {
					swallow_paragraph = true
					return
				}

				// write directly, they are marked for skipping in write_sequence
				for aid in structure.attached_comments {
					write_node(ctx, aid, scope_persistence, og_scope)
				}

				str.write_string(&ctx.result, complete_structure_name);
				str.write_string(&ctx.result, " :: enum ")

				if structure.base_type != {} {
					write_type(ctx, og_scope, scope_persistence, structure.base_type, indent_str, indent_str)
				}
				else {
					str.write_string(&ctx.result, "i32")
				}

				str.write_string(&ctx.result, " {")

				member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				last_was_newline := false
				for cii := 0; cii < len(structure.members); cii += 1 {
					ci := structure.members[cii]
					#partial switch ctx.ast[ci].kind {
						case .VariableDeclaration:
							member := ctx.ast[ci].var_declaration

							emember_context := insert_new_definition(ctx, .Persistent, scope, member.var_name.source, ci, fmt.aprint(complete_structure_name, member.var_name.source, sep = "."))
							get_scope(ctx, og_scope).definitions[member.var_name.source] = emember_context

							if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
							else { str.write_byte(&ctx.result, ' ') }
							str.write_string(&ctx.result, member.var_name.source)

							if member.initializer_expression != {} {
								str.write_string(&ctx.result, " = ")
								write_node(ctx, member.initializer_expression, scope_persistence, scope)
							}

							str.write_byte(&ctx.result, ',')

							last_was_newline = false

						case .NewLine:
							str.write_byte(&ctx.result, '\n')
							last_was_newline = true

						case .Comment:
							if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
							else { str.write_byte(&ctx.result, ' ') }
							str.write_string(&ctx.result, ctx.ast[ci].literal.source)

							last_was_newline = false

						case:
							write_preproc_node(&ctx.result, ctx.ast[ci])
					}
				}

				if len(structure.members) > 0 && ctx.ast[last(structure.members)^].kind == .NewLine { str.write_string(&ctx.result, indent_str) }
				else { str.write_byte(&ctx.result, ' ') }
				str.write_byte(&ctx.result, '}')

			case .VariableDeclaration, .TemplateVariableDeclaration:
				vardef := current_node.var_declaration

				complete_name := fold_token_range(definition_prefix, { vardef.var_name })
				insert_new_definition(ctx, scope_persistence, scope, vardef.var_name.source, current_node_index, complete_name)

				str.write_string(&ctx.result, complete_name);

				type := ctx.type_heap[vardef.type]
				if is_variant(type, AstTypeAuto) {
					assert(vardef.initializer_expression != {})
					
					str.write_string(&ctx.result, " := ")
					write_node(ctx, vardef.initializer_expression, scope_persistence, scope, indent_str)
				}
				else {
					str.write_string(&ctx.result, " : ")

					#partial switch t in type {
						case AstTypeInlineStructure:
							// Anonymous structure context. It's added after the var name which is wired, but that doesn't matter as its stored in a map.
							synthetic_name := fmt.tprintf(ANONYMOUS_STRUCT_NAME_FORMAT, ctx.next_anonymous_struct_index)
							insert_new_definition(ctx, scope_persistence, scope, synthetic_name, AstNodeIndex(t), synthetic_name)
							ctx.next_anonymous_struct_index += 1
					}

					write_type(ctx, scope, scope_persistence, vardef.type, indent_str, indent_str)

					if vardef.width_expression != {} {
						str.write_string(&ctx.result, " | ")
						write_node(ctx, vardef.width_expression, scope_persistence, scope)
					}

					if vardef.initializer_expression != {} {
						str.write_string(&ctx.result, " = ")

						expression_morph: {
							initializer := ctx.ast[vardef.initializer_expression]
							// short circuit pointer to ref assignments and vice versa
							if initializer.kind == .ExprUnaryLeft {
								if initializer.unary_left.operator == .Dereference {
									right_type_idx, _ := resolve_type(ctx, initializer.unary_left.right, scope)
									right_type := ctx.type_heap[right_type_idx]

									if rptr, is_ptr := right_type.(AstTypePointer); is_ptr && .Reference not_in rptr.flags { // ? = *p
										left_type := ctx.type_heap[vardef.type]

										if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference in lptr.flags { // r = *pq
											write_node(ctx, initializer.unary_left.right, scope_persistence, scope)
											break expression_morph
										}
									}
								}
								else if initializer.unary_left.operator == .AddressOf && ctx.ast[initializer.unary_left.right].kind != .ExprIndex { // exclude = &a[b]
									right_type_idx, _ := resolve_type(ctx, initializer.unary_left.right, scope)
									right_type := ctx.type_heap[right_type_idx]

									if rptr, is_ptr := right_type.(AstTypePointer); is_ptr && .Reference in rptr.flags { // ? = &r
										left_type := ctx.type_heap[vardef.type]

										if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference not_in lptr.flags { // p = &r
											write_node(ctx, initializer.unary_left.right, scope_persistence, scope)
											break expression_morph
										}
									}
								}
							}

							write_node(ctx, vardef.initializer_expression, scope_persistence, scope, indent_str)
						}
					}
				}

				requires_termination = true

			case .LambdaDefinition:
				lambda := current_node.lambda_def
				function_ := &ctx.ast[lambda.underlying_function]
				function := &function_.function_def

				if len(lambda.captures) == 0 {
					name_reset := len(ctx.context_heap)
					scope := insert_new_definition(ctx, scope_persistence, scope, "__", current_node_index, "__")
					defer resize(&ctx.context_heap, name_reset)

					write_function_type(ctx, scope, scope_persistence, function_^, "", nil)

					switch len(function.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { }");

						case 1:
							str.write_string(&ctx.result, " { ");
							write_node(ctx, function.body_sequence[0], scope_persistence, scope)
							str.write_string(&ctx.result, " }");

						case:
							str.write_byte(&ctx.result, '\n')

							str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{")
							body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
							write_node_sequence(ctx, function.body_sequence[:], scope, scope_persistence, body_indent_str)
							str.write_string(&ctx.result, indent_str); str.write_byte(&ctx.result, '}')
					}
				}
				else {
					member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)

					captures_struct_name := "__l_0_captures" // TODO
					function_name := "__l_0_function" // TODO

					// initialize
					str.write_string(&ctx.result, captures_struct_name)
					str.write_string(&ctx.result, " {\n")

					str.write_string(&ctx.result, member_indent_str)
					str.write_string(&ctx.result, function_name)
					str.write_string(&ctx.result, ",\n")

					str.write_string(&ctx.result, member_indent_str)
					for ci in lambda.captures {
						c := ctx.ast[ci]
						#partial switch c.kind {
							case .ExprUnaryLeft:
								assert_eq(c.unary_left.operator, AstUnaryOp.AddressOf)
								str.write_byte(&ctx.result, '&')
								fallthrough
							case .Identifier:
								str.write_string(&ctx.result, last(c.identifier).source)
								str.write_string(&ctx.result, ", ")
						}
						str.write_string(&ctx.result, ", ")
					}
					str.write_byte(&ctx.result, '\n')

					str.write_string(&ctx.result, indent_str)
					str.write_string(&ctx.result, "}\n")


					// captures struct
					str.write_string(&ctx.result, indent_str)
					str.write_string(&ctx.result, captures_struct_name)
					str.write_string(&ctx.result, " :: struct {\n")

					str.write_string(&ctx.result, member_indent_str)
					str.write_string(&ctx.result, "__invoke : typeof(")
					str.write_string(&ctx.result, function_name)
					str.write_string(&ctx.result, "),\n")

					str.write_string(&ctx.result, member_indent_str)
					for ci in lambda.captures {
						c := ctx.ast[ci]
						#partial switch c.kind {
							case .Identifier:
								str.write_string(&ctx.result, last(c.identifier).source)
								str.write_string(&ctx.result, " : ")

								capture_type, _ := resolve_type(ctx, ci, scope)
								write_type(ctx, scope, scope_persistence, capture_type, "", "")

								str.write_string(&ctx.result, ", ")

							case .ExprUnaryLeft:
								assert_eq(c.unary_left.operator, AstUnaryOp.AddressOf)
								
								c := ctx.ast[c.unary_left.right]
								str.write_string(&ctx.result, last(c.identifier).source)
								str.write_string(&ctx.result, " : ")
								
								capture_type, _ := resolve_type(ctx, c.unary_left.right, scope)
								str.write_byte(&ctx.result, '^')
								write_type(ctx, scope, scope_persistence, capture_type, "", "")

								str.write_string(&ctx.result, ", ")
						}
					}

					str.write_string(&ctx.result, indent_str)
					str.write_string(&ctx.result, "}\n")


					// function def
					name_reset := len(ctx.context_heap)
					scope := insert_new_definition(ctx, .Persistent, scope, function_name, current_node_index, function_name)
					defer resize(&ctx.context_heap, name_reset)

					str.write_string(&ctx.result, indent_str)
					str.write_string(&ctx.result, function_name)
					str.write_string(&ctx.result, " :: proc(")
					str.write_string(&ctx.result, "__l : ^")
					str.write_string(&ctx.result, captures_struct_name)
					for ai in function.arguments {
						str.write_string(&ctx.result, ", ")
						write_node(ctx, ai, scope_persistence, scope)
					}
					str.write_byte(&ctx.result, ')')

					switch len(function.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { }")

						case 1:
							str.write_string(&ctx.result, " { using __l; ")
							write_node(ctx, function.body_sequence[0], scope_persistence, scope)
							str.write_string(&ctx.result, " }\n")

						case:
							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "{\n")
							str.write_string(&ctx.result, member_indent_str)
							str.write_string(&ctx.result, "using __l")
							write_node_sequence(ctx, function.body_sequence[:], scope, scope_persistence, member_indent_str)

							if ctx.ast[last(function.body_sequence)^].kind == .NewLine { str.write_string(&ctx.result, indent_str) }
							str.write_string(&ctx.result, "}\n")
					}

				}
				requires_termination = true

			case .Return:
				str.write_string(&ctx.result, "return")

				if current_node.return_.expression != {} {
					str.write_byte(&ctx.result, ' ')
					write_node(ctx, current_node.return_.expression, scope_persistence, scope)
				}

			case .Goto: // LabelConversion
				str.write_string(&ctx.result, "continue ")
				str.write_string(&ctx.result, current_node.label.source)
				str.write_string(&ctx.result, " /* @gen goto: validate direction */")

				requires_termination = true

			case .LiteralBool, .LiteralFloat, .LiteralInteger, .LiteralString, .LiteralCharacter, .Continue, .Break:
				str.write_string(&ctx.result, current_node.literal.source)

				requires_termination = true

			case .LiteralNull:
				str.write_string(&ctx.result, "nil")

				requires_termination = true

			case .ExprUnaryLeft:
				switch current_node.unary_left.operator {
					case .AddressOf, .Plus, .Minus, .Invert:
						str.write_byte(&ctx.result, byte(current_node.unary_left.operator))
						write_node(ctx, current_node.unary_left.right, scope_persistence, scope)

					case .Not:
						str.write_byte(&ctx.result, '!')
						write_node(ctx, current_node.unary_left.right, scope_persistence, scope)

					case .Dereference:
						write_node(ctx, current_node.unary_left.right, scope_persistence, scope)
						str.write_byte(&ctx.result, '^')

					case .Increment:
						str.write_string(&ctx.result, "pre_incr(&")
						write_node(ctx, current_node.unary_left.right, scope_persistence, scope)
						str.write_byte(&ctx.result, ')')

					case .Decrement:
						str.write_string(&ctx.result, "pre_decr(&")
						write_node(ctx, current_node.unary_left.right, scope_persistence, scope)
						str.write_byte(&ctx.result, ')')
				}

				requires_termination = true

			case .ExprUnaryRight:
				#partial switch current_node.unary_right.operator {
					case .Increment:
						str.write_string(&ctx.result, "post_incr(&")
						write_node(ctx, current_node.unary_right.left, scope_persistence, scope)
						str.write_byte(&ctx.result, ')')

					case .Decrement:
						str.write_string(&ctx.result, "post_decr(&")
						write_node(ctx, current_node.unary_right.left, scope_persistence, scope)
						str.write_byte(&ctx.result, ')')
				}

				requires_termination = true

			case .ExprBinary:
				binary := current_node.binary

				write_op :: proc(ctx : ^ConverterContext, operator : AstBinaryOp)
				{
					#partial switch operator {
						case .LogicAnd:   str.write_string(&ctx.result, "&&")
						case .LogicOr:    str.write_string(&ctx.result, "||")
						case .Equals:     str.write_string(&ctx.result, "==")
						case .NotEquals:  str.write_string(&ctx.result, "!=")
						case .LessEq:     str.write_string(&ctx.result, "<=")
						case .GreaterEq:  str.write_string(&ctx.result, ">=")
						case .ShiftLeft:  str.write_string(&ctx.result, "<<")
						case .ShiftRight: str.write_string(&ctx.result, ">>")
						case .AssignAdd:  str.write_string(&ctx.result, "+=")
						case .AssignSubtract: str.write_string(&ctx.result, "-=")
						case .AssignMultiply:   str.write_string(&ctx.result, "*=")
						case .AssignDivide:     str.write_string(&ctx.result, "/=")
						case .AssignModulo:     str.write_string(&ctx.result, "%=")
						case .AssignShiftLeft:  str.write_string(&ctx.result, "<<=")
						case .AssignShiftRight: str.write_string(&ctx.result, ">>=")
						case .AssignBitAnd:     str.write_string(&ctx.result, "&=")
						case .AssignBitOr:      str.write_string(&ctx.result, "|=")
						case .AssignBitXor:     str.write_string(&ctx.result, "~=")
						case .BitXor: str.write_byte(&ctx.result, '~')
						case:
							str.write_byte(&ctx.result, u8(operator))
					}
				}

				right := ctx.ast[binary.right]
				right_switch: #partial switch right.kind {
					case .ExprBinary:
						#partial switch right.binary.operator {
							case .Assign, .AssignAdd, .AssignBitAnd, .AssignBitOr, .AssignBitXor, .AssignDivide, .AssignModulo, .AssignMultiply, .AssignShiftLeft, .AssignShiftRight, .AssignSubtract:
								write_node(ctx, binary.right, scope_persistence, scope)
								str.write_string(&ctx.result, "; ")

								write_node(ctx, binary.left, scope_persistence, scope)
								str.write_byte(&ctx.result, ' ')
								write_op(ctx, binary.operator)
								str.write_byte(&ctx.result, ' ')
								write_node(ctx, right.binary.left, scope_persistence, scope)

								break right_switch
							}

						fallthrough

					case:
						#partial switch binary.operator {
							case .Assign:
								left_type_idx, left_type_ctx := resolve_type(ctx, binary.left, scope)
								left_type := ctx.type_heap[left_type_idx]
								// short circuit pointer to ref assignments and vice versa
								if right.kind == .ExprUnaryLeft {
									if right.unary_left.operator == .Dereference {
										right_type_idx, _ := resolve_type(ctx, right.unary_left.right, scope)
										right_type := ctx.type_heap[right_type_idx]

										if rptr, is_ptr := right_type.(AstTypePointer); is_ptr && .Reference not_in rptr.flags { // ? = *p
											if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference in lptr.flags { // r = *p
												write_node(ctx, binary.left, scope_persistence, scope)
												str.write_string(&ctx.result, " = ")
												write_node(ctx, right.unary_left.right, scope_persistence, scope)
												break
											}
										}
									}
									else if right.unary_left.operator == .AddressOf && ctx.ast[right.unary_left.right].kind != .ExprIndex {
										right_type_idx, _ := resolve_type(ctx, right.unary_left.right, scope)
										right_type := ctx.type_heap[right_type_idx]

										if rptr, is_ptr := right_type.(AstTypePointer); is_ptr && .Reference in rptr.flags { // ? = &r
											if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference not_in lptr.flags { // p = &r
												write_node(ctx, binary.left, scope_persistence, scope)
												str.write_string(&ctx.result, " = ")
												write_node(ctx, right.unary_left.right, scope_persistence, scope)
												break
											}
										}
									}
								}

								// deref assign to references   r = v  -> p^ = v, except when its a[i] = v
								if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference in lptr.flags && ctx.ast[binary.left].kind != .ExprIndex {
									write_node(ctx, binary.left, scope_persistence, scope)
									str.write_string(&ctx.result, "^ = ")
									write_node(ctx, binary.right, scope_persistence, scope)
									break
								}

								fallthrough


							case:
								write_node(ctx, binary.left, scope_persistence, scope)
								str.write_byte(&ctx.result, ' ')
								write_op(ctx, binary.operator)
								str.write_byte(&ctx.result, ' ')
								write_node(ctx, binary.right, scope_persistence, scope)
						}
				}

				requires_termination = true

			case .ExprBacketed:
				str.write_byte(&ctx.result, '(')
				write_node(ctx, current_node.inner, scope_persistence, scope)
				str.write_byte(&ctx.result, ')')

				requires_termination = true

			case .ExprCast:
				if is_variant(ctx.type_heap[current_node.cast_.type], AstTypeVoid) {
					// special discard case
					str.write_string(&ctx.result, "_ = ")
				}
				else {
					if current_node.cast_.kind == .Static {
						str.write_string(&ctx.result, "cast(")
					}
					else {
						str.write_string(&ctx.result, "transmute(")
					}
					write_type(ctx, scope, scope_persistence, current_node.cast_.type, indent_str, indent_str)
					str.write_string(&ctx.result, ") ")
				}

				write_node(ctx, current_node.cast_.expression, scope_persistence, scope)

				requires_termination = true

			case .MemberAccess:
				member := ctx.ast[current_node.member_access.member]

				expression_type, expression_type_context_idx := resolve_type(ctx, current_node.member_access.expression, scope)
				expression_type_context := get_scope(ctx, expression_type_context_idx)

				if member.kind == .FunctionCall {
					fncall := member.function_call

					expression_type_node := ctx.ast[expression_type_context.node]
					structure_name : []Token
					#partial switch expression_type_node.kind { // TODO(Rennorb) @cleanup
						case .Struct, .Union:
							structure_name = expression_type_node.structure.name
						case .TemplateVariableDeclaration:
							structure_name = {expression_type_node.var_declaration.var_name}
					}

					fn_name_expr := ctx.ast[member.function_call.expression]
					assert_eq(fn_name_expr.kind, AstNodeKind.Identifier)
					fn_name := last(fn_name_expr.identifier[:]).source

					if len(structure_name) > 0 && last(structure_name).source == fn_name {
						str.write_string(&ctx.result, member.function_call.is_destructor ? "deinit" : "init")
					}
					else {
						if fn_name == "init" && is_variant(ctx.type_heap[expression_type], AstTypePrimitive) {
							write_node(ctx, current_node.member_access.expression, scope_persistence, scope)
							str.write_string(&ctx.result, " = ")
							write_node(ctx, fncall.arguments[0], scope_persistence, scope)

							requires_termination = true
							break
						}
						else if expression_type_context.parent.index != 0 {
							containing_scope := ctx.ast[get_scope(ctx, expression_type_context.parent).node]
							if containing_scope.kind == .Namespace {
								str.write_string(&ctx.result, containing_scope.namespace.name.source)
								str.write_byte(&ctx.result, '_')
							}

							write_token_range(&ctx.result, fn_name_expr.identifier[:])
						}
						else{
							write_token_range(&ctx.result, fn_name_expr.identifier[:])
						}
					}

					str.write_byte(&ctx.result, '(')
					for aidx in fncall.template_arguments {
						write_node(ctx, aidx, scope_persistence, scope)
						str.write_string(&ctx.result, ", ")
					}
					if !current_node.member_access.through_pointer { str.write_byte(&ctx.result, '&') }
					write_node(ctx, current_node.member_access.expression, scope_persistence, scope)
					for aidx in fncall.arguments {
						str.write_string(&ctx.result, ", ")
						write_node(ctx, aidx, scope_persistence, scope)
					}
					str.write_byte(&ctx.result, ')')
				}
				else {
					write_node(ctx, current_node.member_access.expression, scope_persistence, scope)
					str.write_byte(&ctx.result, '.')

					_, _, actual_member_context := try_find_definition_for_name(ctx, expression_type_context_idx, member.identifier[:])

					this_type := ctx.ast[expression_type_context.node]
					if this_type.kind != .Struct && this_type.kind != .Union && this_type.kind != .Enum \
						&& this_type.kind != .TemplateVariableDeclaration {
						panic(fmt.tprintf("Unexpected member access expression type %#v with member %v", this_type, member.identifier))
					}


					if actual_member_context != nil {
						str.write_string(&ctx.result, actual_member_context.complete_name)
					}
					else {
						log.warn("failed to resolve type for", member.identifier) // fix for incomplete generic resolver
						write_token_range(&ctx.result, member.identifier[:])
					}
				}

				requires_termination = true

			case .ExprIndex:
				write_node(ctx, current_node.index.array_expression, scope_persistence, scope)
				str.write_byte(&ctx.result, '[')
				write_node(ctx, current_node.index.index_expression, scope_persistence, scope)
				str.write_byte(&ctx.result, ']')

				requires_termination = true

			case .ExprTenary:
				write_node(ctx, current_node.tenary.condition, scope_persistence, scope)
				str.write_string(&ctx.result, " ? ")
				write_node(ctx, current_node.tenary.true_expression, scope_persistence, scope)
				str.write_string(&ctx.result, " : ")
				write_node(ctx, current_node.tenary.false_expression, scope_persistence, scope)

				requires_termination = true

			case .Identifier:
				_, _, def := find_definition_for_name(ctx, scope, current_node.identifier[:])
				parent := ctx.ast[get_scope(ctx, def.parent).node]

				if (ctx.ast[def.node].kind != .TemplateVariableDeclaration && (parent.kind == .Struct || parent.kind == .Union) && .Static not_in ctx.ast[def.node].var_declaration.flags) {
					str.write_string(&ctx.result, "this.")
				}
				else if parent.kind == .Enum && ctx.ast[get_scope(ctx, scope).node].kind != .Enum {
					write_token_range(&ctx.result, parent.structure.name)
					str.write_byte(&ctx.result, '.')
					str.write_string(&ctx.result, last(current_node.identifier).source)

					requires_termination = true
					break	
				}

				write_token_range(&ctx.result, current_node.identifier[:])

				requires_termination = true

			case .FunctionCall:
				fncall := current_node.function_call

				if expr := ctx.ast[fncall.expression]; expr.kind == .Identifier {
					// @hardcoded: Print indents directly so we don't have to add all std functions to the name resolver.
					fn_name := last(expr.identifier[:]).source
					// convert some top level function names
					switch fn_name {
						case "sizeof":
							str.write_string(&ctx.result, "size_of")

						case "offsetof":
							assert_eq(len(fncall.arguments), 2)

							str.write_string(&ctx.result, "offset_of")
							str.write_byte(&ctx.result, '(')
							
							write_node(ctx, fncall.arguments[0], scope_persistence, scope)
							
							str.write_string(&ctx.result, ", ")

							ident := ctx.ast[fncall.arguments[1]].identifier
							assert_eq(len(ident), 1)
							str.write_string(&ctx.result, ident[0].source)
							
							str.write_byte(&ctx.result, ')')

							requires_termination = true	
							break node_kind_switch

						case:
							str.write_string(&ctx.result, fn_name)
					}
				}
				else {
					write_node(ctx, fncall.expression, scope_persistence, scope)
				}
				str.write_byte(&ctx.result, '(')
				arg_index := 0
				for aidx in fncall.template_arguments {
					if arg_index != 0 { str.write_string(&ctx.result, ", ") }
					write_node(ctx, aidx, scope_persistence, scope)
					arg_index += 1
				}
				for aidx in fncall.arguments {
					if arg_index != 0 { str.write_string(&ctx.result, ", ") }
					write_node(ctx, aidx, scope_persistence, scope)
					arg_index += 1
				}
				str.write_byte(&ctx.result, ')')

				requires_termination = true

			case .CompoundInitializer:
				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)

				body := current_node.compound_initializer.values[:]
				str.write_byte(&ctx.result, '{')
				write_node_sequence(ctx, body, scope, .Temporary, body_indent_str, termination = ",", always_terminate = true)
				if len(body) > 0 && ctx.ast[last(body)^].kind == .NewLine { str.write_string(&ctx.result, indent_str) }
				str.write_byte(&ctx.result, '}')

				requires_termination = true

			case .Namespace:
				ns := current_node.namespace

				complete_name := fold_token_range(definition_prefix, { ns.name })

				// try merging the namespace with an existing one
				_, existing_context_idx, _ := try_find_definition_for_name(ctx, scope, { ns.name }, { .Namespace })
				scope := existing_context_idx.index != 0 ? existing_context_idx : insert_new_definition(ctx, .Persistent, scope, ns.name.source, current_node_index, complete_name)

				write_node_sequence(ctx, trim_newlines_start(ctx, ns.sequence[:]), scope, scope_persistence, indent_str, complete_name)

				swallow_paragraph = true


			case .For, .While, .Do:
				loop := current_node.loop

				context_reset := len(ctx.temp_context_heap)
				scope := insert_new_definition(ctx, .Temporary, scope, "__", current_node_index, "__")
				defer resize(&ctx.temp_context_heap, context_reset)

				condition_node : AstNode

				str.write_string(&ctx.result, "for")
				if !loop.is_foreach {
					if len(loop.initializer) != 0 || len(loop.loop_statement) != 0 {
						str.write_byte(&ctx.result, ' ')
						if len(loop.initializer) != 0 { write_node_sequence_merged(ctx, loop.initializer[:], scope, .Temporary) }
						str.write_string(&ctx.result, "; ")
						if len(loop.condition) != 0 {
							assert_eq(len(loop.condition), 1)
							write_node(ctx, loop.condition[0], .Temporary, scope)
						}
						str.write_string(&ctx.result, "; ")
						if len(loop.loop_statement) != 0 { write_node_sequence_merged(ctx, loop.loop_statement[:], scope, .Temporary) }
					}
					else if len(loop.condition) != 0 && current_node.kind != .Do {
						assert_eq(len(loop.condition), 1)
						condition_node = ctx.ast[loop.condition[0]]
						if condition_node.kind != .VariableDeclaration {
							str.write_byte(&ctx.result, ' ')
							write_node(ctx, loop.condition[0], .Temporary, scope)
						}
					}
				}
				else { // foreach
					str.write_byte(&ctx.result, ' ')
					
					assert_eq(len(loop.initializer), 1)
					initializer := ctx.ast[loop.initializer[0]]
					assert_eq(initializer.kind, AstNodeKind.VariableDeclaration)
					str.write_string(&ctx.result, initializer.var_declaration.var_name.source)

					insert_new_definition(ctx, .Persistent, scope, initializer.var_declaration.var_name.source, loop.initializer[0], initializer.var_declaration.var_name.source)
					
					str.write_string(&ctx.result, " in ")
					
					assert_eq(len(loop.loop_statement), 1)
					write_node(ctx, loop.loop_statement[0], .Temporary, scope)
				}

				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				if len(loop.condition) != 0 && current_node.kind == .Do {
					assert_eq(len(loop.condition), 1)
					switch len(loop.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { if !(")
							write_node(ctx, loop.condition[0], .Temporary, scope)
							str.write_string(&ctx.result, ") { break } }")
	
						case 1:
							str.write_string(&ctx.result, " {\n")

							str.write_string(&ctx.result, body_indent_str)
							write_node(ctx, loop.body_sequence[0], .Temporary, scope)

							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, body_indent_str)
							str.write_string(&ctx.result, "if !(")
							write_node(ctx, loop.condition[0], .Temporary, scope)
							str.write_string(&ctx.result, ") { break }\n")

							str.write_string(&ctx.result, indent_str)
							str.write_byte(&ctx.result, '}')
	
						case:
							str.write_string(&ctx.result, " {")

							write_node_sequence(ctx, loop.body_sequence[:], scope, .Temporary, body_indent_str)

							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, body_indent_str)
							str.write_string(&ctx.result, "if !(")
							write_node(ctx, loop.condition[0], .Temporary, scope)
							str.write_string(&ctx.result, ") { break }\n")

							str.write_string(&ctx.result, indent_str)
							str.write_byte(&ctx.result, '}')
					}
				}
				else if condition_node.kind == .VariableDeclaration {
					str.write_string(&ctx.result, " {\n")

					str.write_string(&ctx.result, body_indent_str)
					write_node(ctx, loop.condition[0], .Temporary, scope)
					str.write_byte(&ctx.result, '\n')

					str.write_string(&ctx.result, body_indent_str)
					str.write_string(&ctx.result, "if !(")
					str.write_string(&ctx.result, condition_node.var_declaration.var_name.source)
					str.write_string(&ctx.result, ") { break }\n")

					switch len(loop.body_sequence) {
						case 0:
							str.write_string(&ctx.result, indent_str)
							str.write_byte(&ctx.result, '}')

						case:
							if ctx.ast[loop.body_sequence[0]].kind != .NewLine {
								str.write_byte(&ctx.result, '\n')
							}

							write_node_sequence(ctx, loop.body_sequence[:], scope, .Temporary, body_indent_str)

							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "}")
					}
				}
				else {
					switch len(loop.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { }")

						case 1:
							str.write_string(&ctx.result, " { ")
							write_node(ctx, loop.body_sequence[0], .Temporary, scope)
							str.write_string(&ctx.result, " }")

						case:
							str.write_string(&ctx.result, " {")

							write_node_sequence(ctx, loop.body_sequence[:], scope, .Temporary, body_indent_str)

							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "}")
					}
				}

				requires_termination = true
				requires_new_paragraph = true

			case .Branch:
				branch := current_node.branch

				context_heap_reset := len(&ctx.temp_context_heap)
				// scope including the condition since that can declare its own variables
				scope := insert_new_definition(ctx, .Temporary, scope, "__", current_node_index, "__")

				str.write_string(&ctx.result, "if ")
				switch len(branch.condition) {
					case 1:
						if ctx.ast[branch.condition[0]].kind == .VariableDeclaration {
							write_node(ctx, branch.condition[0], .Temporary, scope)
							str.write_string(&ctx.result, "; ")
							str.write_string(&ctx.result, ctx.ast[branch.condition[0]].var_declaration.var_name.source)
						}
						else {
							write_node(ctx, branch.condition[0], .Temporary, scope)
						}

					case 2:
						if ctx.ast[branch.condition[0]].kind == .VariableDeclaration && ctx.ast[branch.condition[1]].kind != .VariableDeclaration {
							write_node(ctx, branch.condition[0], .Temporary, scope)
							str.write_string(&ctx.result, "; ")
							write_node(ctx, branch.condition[1], .Temporary, scope)
							break
						}

					fallthrough

					case:
						panic(fmt.tprintf("Cant convert branch condition %#v", branch.condition))
				}

				body_indent_str : string

				switch len(branch.true_branch_sequence) {
					case 0:
						str.write_string(&ctx.result, " { }")

					case 1:
						context_heap_reset := len(&ctx.temp_context_heap)
						scope := insert_new_definition(ctx, .Persistent, scope, "__", current_node_index, "__")

						str.write_string(&ctx.result, " { ")
						write_node(ctx, branch.true_branch_sequence[0], .Temporary, scope)
						str.write_string(&ctx.result, " }")

						resize(&ctx.temp_context_heap, context_heap_reset)

					case:
						context_heap_reset := len(&ctx.temp_context_heap)
						scope := insert_new_definition(ctx, .Persistent, scope, "__", current_node_index, "__")
						
						str.write_string(&ctx.result, " {")
						body_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
						write_node_sequence(ctx, branch.true_branch_sequence[:], scope, .Temporary, body_indent_str)
						if ctx.ast[last(branch.true_branch_sequence[:])^].kind == .NewLine {
							str.write_string(&ctx.result, indent_str);
						}
						str.write_byte(&ctx.result, '}')

						resize(&ctx.temp_context_heap, context_heap_reset)
				}

				switch len(branch.false_branch_sequence) {
					case 0:
						 /**/

					case 1:
						scope := insert_new_definition(ctx, .Persistent, scope, "__", current_node_index, "__")

						if ctx.ast[branch.false_branch_sequence[0]].kind == .Branch { // else if chaining
							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "else ")
							write_node(ctx, branch.false_branch_sequence[0], .Temporary, scope, indent_str)
						}
						else {
							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "else { ")
							write_node(ctx, branch.false_branch_sequence[0], .Temporary, scope)
							if ctx.ast[last(branch.false_branch_sequence[:])^].kind == .NewLine {
								str.write_string(&ctx.result, indent_str);
							}
							str.write_string(&ctx.result, " }")
						}

					case:
						scope := insert_new_definition(ctx, .Persistent, scope, "", current_node_index, "")

						str.write_byte(&ctx.result, '\n')
						str.write_string(&ctx.result, indent_str)
						str.write_string(&ctx.result, "else {")
						if body_indent_str == "" { body_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator) }
						write_node_sequence(ctx, branch.false_branch_sequence[:], scope, .Temporary, body_indent_str)
						str.write_string(&ctx.result, indent_str)
						str.write_byte(&ctx.result, '}')
				}

				resize(&ctx.temp_context_heap, context_heap_reset)

				requires_termination = true

			case .Switch:
				switch_ := current_node.switch_

				str.write_string(&ctx.result, "switch ")
				write_node(ctx, switch_.expression, .Temporary, scope)

				str.write_string(&ctx.result, " {\n")
				
				case_body_indent_str := str.concatenate({ indent_str, ONE_INDENT, ONE_INDENT }, context.temp_allocator)
				case_indent_str := case_body_indent_str[:len(case_body_indent_str) - len(ONE_INDENT)]

				for case_, case_i in switch_.cases {
					str.write_string(&ctx.result, case_indent_str)
					str.write_string(&ctx.result, "case")
					if case_.match_expression != {} {
						str.write_byte(&ctx.result, ' ')
						write_node(ctx, case_.match_expression, .Temporary, scope)
					}
					str.write_byte(&ctx.result, ':')

					write_node_sequence(ctx, case_.body_sequence[:], scope, .Temporary, case_body_indent_str)

					// Cpp defaults to fallthrough, so try to detect if we should break (or not).
					// This won't catch cases where the case looks like 
					// case x: { ..; break; }   case y: ...
					// but even in that case inserting a fallthrough after the brace does not change the behavior of the resulting code.
					has_newline_after := false
					should_break := false
					#reverse for ix in case_.body_sequence {
						#partial switch ctx.ast[ix].kind {
							case .NewLine:
								has_newline_after = true
							case .Break:
								should_break = true
								fallthrough
							case:
								break
						}
					}

					if case_i < len(switch_.cases) - 1 {
						if !should_break {
							if has_newline_after {
								str.write_string(&ctx.result, case_body_indent_str)
							}
							else {
								str.write_string(&ctx.result, "; ")
							}
							str.write_string(&ctx.result, "fallthrough")
						}
						str.write_byte(&ctx.result, '\n')
					}
				}

				str.write_string(&ctx.result, indent_str)
				str.write_byte(&ctx.result, '}')

			case .OperatorDefinition:
				/* just ignore for now */

			case .OperatorCall:
				call := current_node.operator_call

				str.write_string(&ctx.result, "operator_")
				fmt.sbprint(&ctx.result, call.kind)
				str.write_byte(&ctx.result, '(')
				for aidx, i in call.parameters {
					if i != 0 { str.write_string(&ctx.result, ", ") }
					write_node(ctx, aidx, .Temporary, scope)
				}
				str.write_byte(&ctx.result, ')')

				requires_termination = true

			case .UsingNamespace:
				// assume we are already in a scope, its time to pull in namespace members

				_, _, namespace_context := find_definition_for_name(ctx, scope, current_node.using_namespace.namespace, { .Namespace })

				for def_name, def in namespace_context.definitions {
					get_scope(ctx, scope).definitions[def_name] = def
				}

				swallow_paragraph = true

			case:
				was_preproc := #force_inline write_preproc_node(&ctx.result, current_node^)
				if was_preproc {
					break
				}

				log.error("Unknown ast node:", current_node)
				runtime.trap();
		}
		return
	}

	write_node_sequence_merged :: proc(ctx : ^ConverterContext, sequence : []AstNodeIndex, scope : ScopeIndex, scope_persistence : PersistenceKind)
	{
		if len(sequence) < 2 {
			write_node(ctx, sequence[0], .Temporary, scope)
			return
		}

		kind : AstNodeKind
		for si in sequence {
			nk := ctx.ast[si].kind
			if kind == {} { kind = nk }
			else {
				#partial switch kind {
					case .VariableDeclaration:
						assert_eq(nk, AstNodeKind.VariableDeclaration)
					case .ExprBinary, .ExprUnaryLeft, .ExprUnaryRight:
						#partial switch nk {
							case .ExprBinary, .ExprUnaryLeft, .ExprUnaryRight:
								/* ok */
							case:
								panic(fmt.tprintf("Invalid node kind to merge into sequence (last: %v, next: %v)", kind, nk))
						}
					case:
						panic(fmt.tprintf("Invalid node for sequence merge (last: %v, next: %v)", kind, nk))
				}
			}
		}

		#partial switch kind {
			case .VariableDeclaration:
				type : AstTypeIndex
				for si, i in sequence {
					decl := &ctx.ast[si].var_declaration
					if type == {} { type = decl.type }
					else {
						assert_eq(type, decl.type)
					}

					if i > 0 { str.write_string(&ctx.result, ", ") }
					str.write_string(&ctx.result, decl.var_name.source)
					insert_new_definition(ctx, .Temporary, scope, decl.var_name.source, si, decl.var_name.source)
				}

				str.write_string(&ctx.result, " : ")

				write_type(ctx, scope, scope_persistence, type, "", "")

				str.write_string(&ctx.result, " = ")

				for si, i in sequence {
					decl := &ctx.ast[si].var_declaration
					if i > 0 { str.write_string(&ctx.result, ", ") }
					if decl.initializer_expression != {} {
						write_node(ctx, decl.initializer_expression, .Temporary, scope)
					}
					else {
						str.write_string(&ctx.result, "{}")
					}
				}

			case .ExprUnaryLeft, .ExprUnaryRight, .ExprBinary:
				for si, i in sequence {
					if i > 0 { str.write_string(&ctx.result, ", ") }
					#partial switch ctx.ast[si].kind {
						case .ExprBinary:
							binary := &ctx.ast[si].binary
							#partial switch binary.operator {
								case .Assign:
									fallthrough
								case .AssignAdd, .AssignSubtract, .AssignDivide, .AssignModulo, .AssignBitAnd, .AssignBitOr, .AssignBitXor, .AssignMultiply:
									fallthrough
								case .AssignShiftLeft, .AssignShiftRight:
									write_node(ctx, binary.left, .Temporary, scope)

								case:
									panic(fmt.tprintf("Invalid binary operator for sequence merge: ", binary.operator))
							}

						case .ExprUnaryLeft:
							unary := &ctx.ast[si].unary_left
							#partial switch unary.operator {
								case .Decrement:
									fallthrough
								case .Increment:
									write_node(ctx, unary.right, .Temporary, scope)
								case:
									panic(fmt.tprintf("Invalid unary left operator for sequence merge: ", unary.operator))
							}

						case .ExprUnaryRight:
							unary := &ctx.ast[si].unary_right
							#partial switch unary.operator {
								case .Decrement:
									fallthrough
								case .Increment:
									write_node(ctx, unary.left, .Temporary, scope)
								case:
									panic(fmt.tprintf("Invalid unary left operator for sequence merge: ", unary.operator))
							}
					}
				}

				str.write_string(&ctx.result, " = ")

				for si, i in sequence {
					if i > 0 { str.write_string(&ctx.result, ", ") }
					#partial switch ctx.ast[si].kind {
						case .ExprBinary:
							binary := &ctx.ast[si].binary
							#partial switch binary.operator {
								case .Assign:
									write_node(ctx, binary.right, .Temporary, scope)

								case .AssignAdd, .AssignSubtract, .AssignDivide, .AssignModulo, .AssignBitAnd, .AssignBitOr, .AssignBitXor, .AssignMultiply:
									write_node(ctx, binary.left, .Temporary, scope)
									str.write_byte(&ctx.result, ' ');
									str.write_byte(&ctx.result, cast(byte) (binary.operator - cast(AstBinaryOp) TokenKind._MirroredBinaryOperators));
									str.write_byte(&ctx.result, ' ')
									write_node(ctx, binary.right, .Temporary, scope)

								case .AssignShiftLeft, .AssignShiftRight:
									write_node(ctx, binary.left, .Temporary, scope)
									str.write_string(&ctx.result, binary.operator == .AssignShiftLeft ? " << " : " >> ")
									write_node(ctx, binary.right, .Temporary, scope)

								case:
									panic(fmt.tprintf("Invalid binary operator for sequence merge: ", binary.operator))
							}

						case .ExprUnaryLeft:
							unary := &ctx.ast[si].unary_left
							#partial switch unary.operator {
								case .Decrement:
									write_node(ctx, unary.right, .Temporary, scope)
									str.write_string(&ctx.result, " - 1")

								case .Increment:
									write_node(ctx, unary.right, .Temporary, scope)
									str.write_string(&ctx.result, " + 1")

								case:
									panic(fmt.tprintf("Invalid unary left operator for sequence merge: ", unary.operator))
							}

						case .ExprUnaryRight:
							unary := &ctx.ast[si].unary_right
							#partial switch unary.operator {
								case .Decrement:
									write_node(ctx, unary.left, .Temporary, scope)
									str.write_string(&ctx.result, " - 1")

								case .Increment:
									write_node(ctx, unary.left, .Temporary, scope)
									str.write_string(&ctx.result, " + 1")

								case:
									panic(fmt.tprintf("Invalid unary left operator for sequence merge: ", unary.operator))
							}
					}
				}

			case:
				panic(fmt.tprintf("Invalid node kind for sequence merge: ", kind))
		}
	}

	write_node_sequence :: proc(ctx : ^ConverterContext, sequence : []AstNodeIndex, scope : ScopeIndex, scope_persistence : PersistenceKind, indent_str : string, definition_prefix := "", termination := ";", always_terminate := false)
	{
		previous_requires_termination := false
		previous_requires_new_paragraph := false
		should_swallow_paragraph := false
		previous_node_kind : AstNodeKind
		
		for cii := 0; cii < len(sequence); cii += 1 {
			ci := sequence[cii]
			if ctx.ast[ci].attached { continue }

			node_kind := ctx.ast[ci].kind
			if previous_requires_termination && (always_terminate ||  (node_kind != .NewLine)) {
				str.write_string(&ctx.result, termination)
				if node_kind != .NewLine { str.write_byte(&ctx.result, ' ') }
			}
			if previous_requires_new_paragraph && len(sequence) > cii + 1 {
				if node_kind != .NewLine { str.write_string(&ctx.result, "\n\n") }
				else if ctx.ast[sequence[cii + 1]].kind != .NewLine { str.write_byte(&ctx.result, '\n') }
			}
			if node_kind != .NewLine && previous_node_kind == .NewLine {
				str.write_string(&ctx.result, indent_str)
			}
			if should_swallow_paragraph {
				should_swallow_paragraph = false
				if ctx.ast[ci].kind == .NewLine {
					cii += 1
					if cii < len(sequence) {
						ci = sequence[cii]
					}
				}
				if ctx.ast[ci].kind == .NewLine { continue }
			}

			if node_kind == .Label { // :LabelConversion
				member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				
				str.write_string(&ctx.result, ctx.ast[ci].label.source)
				str.write_string(&ctx.result, ": for {\n")

				write_node_sequence(ctx, sequence[cii + 1:], scope, scope_persistence, member_indent_str, definition_prefix, termination, always_terminate)

				str.write_byte(&ctx.result, '\n')
				str.write_string(&ctx.result, member_indent_str)
				str.write_string(&ctx.result, "break\n")
				str.write_string(&ctx.result, indent_str)
				str.write_string(&ctx.result, "}\n")

				return
			}

			previous_requires_termination, previous_requires_new_paragraph, should_swallow_paragraph = write_node(ctx, ci, scope_persistence, scope, indent_str, definition_prefix)
			previous_node_kind = node_kind
		}
	}

	write_struct_union :: proc(ctx : ^ConverterContext, structure_node : ^AstNode, structure_node_index : AstNodeIndex, scope : ScopeIndex, scope_persistence : PersistenceKind, indent_str, member_indent_str : string, definition_prefix := "") -> (swallow_paragraph, requires_new_paragraph : bool)
	{
		structure := &structure_node.structure

		complete_structure_name := fold_token_range(definition_prefix, structure.name)

		og_scope := scope
		scope := scope

		_, _, forward_declared_context := try_find_definition_for_name(ctx, scope, structure.name)
		if forward_declared_context != nil {
			forward_declaration := ctx.ast[forward_declared_context.node]
			assert(forward_declaration.kind == .Struct || forward_declaration.kind == .Union)

			forward_comments := forward_declaration.structure.attached_comments
			inject_at(&structure.attached_comments, 0, ..forward_comments[:])
		}

		if .IsForwardDeclared in structure.flags {
			scope = {
				index = transmute(uint) append_return_index(select_scope_heap(ctx, scope_persistence), Scope{ node = structure_node_index, parent = scope, complete_name = complete_structure_name }),
				persistence = scope_persistence,
			}
			get_scope(ctx, og_scope).definitions[last(structure.name).source] = scope

			swallow_paragraph = true
			return
		}

		// write directly, they are marked for skipping in write_sequence
		for aid in structure.attached_comments {
			write_node(ctx, aid, scope_persistence, scope)
		}

		str.write_string(&ctx.result, complete_structure_name);
		str.write_string(&ctx.result, " :: ")

		has_static_var_members, nc := write_struct_union_type(ctx, structure_node, structure_node_index, scope, scope_persistence, og_scope, indent_str, member_indent_str, complete_structure_name)
		scope = nc

		if has_static_var_members {
			str.write_byte(&ctx.result, '\n')
			for midx in structure.members {
				if ctx.ast[midx].kind != .VariableDeclaration || .Static not_in ctx.ast[midx].var_declaration.flags { continue }
				member := ctx.ast[midx].var_declaration

				complete_member_name := fold_token_range(complete_structure_name, { member.var_name })
				insert_new_definition(ctx, .Persistent, scope, member.var_name.source, midx, complete_member_name)

				str.write_byte(&ctx.result, '\n')
				str.write_string(&ctx.result, indent_str);
				str.write_string(&ctx.result, complete_member_name);
				str.write_string(&ctx.result, " : ")
				write_type(ctx, scope, scope_persistence, member.type, indent_str, indent_str)

				if member.initializer_expression != {} {
					str.write_string(&ctx.result, " = ");
					write_node(ctx, member.initializer_expression, scope_persistence, scope)
				}
			}
		}

		if (structure.deinitializer != {} && .IsForwardDeclared not_in ctx.ast[structure.deinitializer].function_def.flags) {
			deinitializer := ctx.ast[structure.deinitializer]

			complete_deinitializer_name := str.concatenate({ complete_structure_name, "_deinit" })
			scope := insert_new_definition(ctx, .Persistent, scope, last(deinitializer.function_def.function_name[:]).source, structure.deinitializer, complete_deinitializer_name)
			insert_new_overload(ctx, "deinit", complete_deinitializer_name)

			context_heap_reset := len(&ctx.temp_context_heap) // keep fn as leaf node
			defer {
				clear(&get_scope(ctx, scope).definitions)
				resize(&ctx.temp_context_heap, context_heap_reset)
			}

			insert_new_definition(ctx, .Temporary, scope, "this", structure.synthetic_this_var, "this")

			str.write_string(&ctx.result, "\n\n")
			str.write_string(&ctx.result, indent_str);
			str.write_string(&ctx.result, complete_deinitializer_name);
			str.write_string(&ctx.result, " :: proc(this : ^")
			str.write_string(&ctx.result, complete_structure_name);
			str.write_string(&ctx.result, ")\n")

			str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{")
			write_node_sequence(ctx, deinitializer.function_def.body_sequence[:], scope, .Temporary, member_indent_str)
			str.write_string(&ctx.result, indent_str); str.write_byte(&ctx.result, '}')
		}

		written_initializer := false
		synthetic_enum_index := 0
		for midx in structure.members {
			#partial switch ctx.ast[midx].kind {
				case .FunctionDefinition:
					if .IsForwardDeclared not_in ctx.ast[midx].function_def.flags { str.write_string(&ctx.result, "\n\n") }
					write_function(ctx, scope, scope_persistence, midx, complete_structure_name, structure_node, indent_str)

					written_initializer |= .IsCtor in ctx.ast[midx].function_def.flags
					requires_new_paragraph = true

				case .Struct, .Union:
					if len(ctx.ast[midx].structure.name) == 0 { break }

					str.write_string(&ctx.result, "\n\n")
					ctx.ast[midx].structure.name = slice.concatenate([][]Token{structure.name, ctx.ast[midx].structure.name})
					write_node(ctx, midx, scope_persistence, scope, indent_str)

					requires_new_paragraph = true

				case .Enum:
					str.write_string(&ctx.result, "\n\n")

					if len(ctx.ast[midx].structure.name) == 0 {
						ctx.ast[midx].structure.name = slice.concatenate([][]Token{structure.name, {Token{kind = .Identifier, source = fmt.tprintf("E%v", synthetic_enum_index)}}})
						synthetic_enum_index += 1
					}
					write_node(ctx, midx, scope_persistence, scope, indent_str)


					requires_new_paragraph = true
			}
		}

		if .HasImplicitCtor in structure.flags && ! written_initializer {
			str.write_string(&ctx.result, "\n\n")

			synth := AstNode{ kind = .FunctionDefinition, function_def = { flags = { .IsCtor } } }
			write_function_inner(ctx, scope, scope_persistence, &synth, 0, complete_structure_name, structure_node, indent_str)
		}

		return
	}

	push_structure_context :: proc(ctx : ^ConverterContext, containing_scope : ScopeIndex, scope_persistence : PersistenceKind, og_scope : ScopeIndex, complete_structure_name : string, node_index : AstNodeIndex) -> (structure_scope : ScopeIndex)
	{
		structure := &ctx.ast[node_index].structure
		structure_scope = containing_scope

		if structure.base_type != {} {
			// copy over defs from base type, using their location
			_, _, base_context := find_definition_for(ctx, containing_scope, structure.base_type)

			structure_scope = {
				index = transmute(uint) append_return_index(select_scope_heap(ctx, scope_persistence), Scope{
					parent      = containing_scope,
					node        = base_context.node,
					definitions = base_context.definitions, // make sure not to modify these! ok because we push another context right after
				}),
				persistence = scope_persistence,
			}
		}

		if len(structure.name) != 0 { // anonymous types don't have a name
			structure_scope = {
				index = transmute(uint) append_return_index(select_scope_heap(ctx, scope_persistence), Scope{ node = node_index, parent = structure_scope, complete_name = complete_structure_name }),
				persistence = scope_persistence,
			}
			get_scope(ctx, og_scope).definitions[last(structure.name).source] = structure_scope
			// no reset here, struct context might be relevant later on
		}

		for ti in structure.template_spec {
			push_node_context(ctx, structure_scope, .Temporary, complete_structure_name, ti)
		}

		for ti in structure.members {
			push_node_context(ctx, structure_scope, scope_persistence, complete_structure_name, ti)
		}

		return
	}

	push_enum_context :: proc(ctx : ^ConverterContext, containing_scope : ScopeIndex, scope_persistence : PersistenceKind, name_prefix : string, node_index : AstNodeIndex) -> (enum_scope : ScopeIndex)
	{
		enum_ := &ctx.ast[node_index].structure

		enum_name : string
		if len(enum_.name) > 0 {
			enum_name = fold_token_range(name_prefix, enum_.name)
		}
		else{
			enum_name = name_prefix

			enum_.name = make_one(Token{kind = .Identifier, source = enum_name})[:]
		}

		// We need to create the enum scope aswell, to be able to add members to it. it can later on be referenced.
		enum_scope = ScopeIndex {
			index = transmute(uint) append_return_index(select_scope_heap(ctx, scope_persistence), Scope{ node = node_index, parent = containing_scope, complete_name = enum_name }),
			persistence = scope_persistence,
		}
		get_scope(ctx, containing_scope).definitions[enum_name] = enum_scope

		for eid in enum_.members {
			enum_member := ctx.ast[eid]
			#partial switch enum_member.kind {
				case .VariableDeclaration:
					emember_name := enum_member.var_declaration.var_name.source
					synthetic_name := fmt.aprintf("%v.%v", enum_name, emember_name)

					emember_ctx := insert_new_definition(ctx, .Persistent, enum_scope, emember_name, eid, synthetic_name)
					get_scope(ctx, containing_scope).definitions[emember_name] = emember_ctx // add the member into the encompasing context aswell, enums bleed
			}
		}

		return
	}

	push_variable_context :: proc(ctx : ^ConverterContext, parent_scope : ScopeIndex, scope_persistence : PersistenceKind, name_prefix : string, node_index : AstNodeIndex) -> (variable_scope : ScopeIndex)
	{
		vardef := &ctx.ast[node_index].var_declaration

		complete_name := fold_token_range(name_prefix, { vardef.var_name })
		insert_new_definition(ctx, scope_persistence, parent_scope, vardef.var_name.source, node_index, complete_name)

		type := ctx.type_heap[vardef.type]
		if is_variant(type, AstTypeAuto) {
			assert(vardef.initializer_expression != {})
		}
		else {
			#partial switch t in type {
				case AstTypeInlineStructure:
					// Anonymous structure context. It's added after the var name which is wired, but that doesn't matter as its stored in a map.
					synthetic_name := fmt.tprintf(ANONYMOUS_STRUCT_NAME_FORMAT, ctx.next_anonymous_struct_index)
					insert_new_definition(ctx, scope_persistence, parent_scope, synthetic_name, AstNodeIndex(t), synthetic_name)
					ctx.next_anonymous_struct_index += 1
			}
		}

		return
	}

	push_node_context :: proc(ctx : ^ConverterContext, containing_scope : ScopeIndex, scope_persistence : PersistenceKind, name_prefix : string, node_index : AstNodeIndex) -> (new_scope : ScopeIndex)
	{
		node := &ctx.ast[node_index]
		#partial switch node.kind {
			case .Struct, .Union:
				structure_name := fold_token_range(name_prefix, node.structure.name)
				return push_structure_context(ctx, containing_scope, scope_persistence, containing_scope /*?*/, structure_name, node_index)

			case .Enum:
				structure_name := fold_token_range(name_prefix, node.structure.name)
				return push_enum_context(ctx, containing_scope, scope_persistence, structure_name, node_index)

			case .VariableDeclaration, .TemplateVariableDeclaration:
				name_prefix := .Static in node.var_declaration.flags ? name_prefix : ""
				push_variable_context(ctx, containing_scope, scope_persistence, name_prefix, node_index)
		}

		return
	}

	write_struct_union_type :: proc(ctx : ^ConverterContext, structure_node : ^AstNode, structure_node_index : AstNodeIndex, scope_ : ScopeIndex, scope_persistence : PersistenceKind, og_scope : ScopeIndex, indent_str, member_indent_str : string, complete_structure_name : string) -> (has_static_var_members : bool, scope : ScopeIndex)
	{
		structure := &structure_node.structure
		scope = scope_
		str.write_string(&ctx.result, "struct")

		base_type : struct {
			name : string,
			ctx : ^Scope,
		}
		if structure.base_type != {} {
			// copy over defs from base type, using their location
			_, _, base_type.ctx = find_definition_for(ctx, scope, structure.base_type)

			base_type.name = str.concatenate({ "__base_", str.to_lower(ctx.type_heap[structure.base_type].(AstTypeFragment).identifier.source, context.temp_allocator) })
			scope = {
				index = transmute(uint) append_return_index(select_scope_heap(ctx, scope_persistence), Scope{
					parent      = scope,
					node        = base_type.ctx.node,
					definitions = base_type.ctx.definitions, // make sure not to modify these! ok because we push another context right after
				}),
				persistence = scope_persistence,
			}
		}

		if len(structure.name) != 0 { // anonymous types don't have a name
			scope = {
				index = transmute(uint) append_return_index(select_scope_heap(ctx, scope_persistence), Scope{ node = structure_node_index, parent = scope, complete_name = complete_structure_name }),
				persistence = scope_persistence,
			}
			get_scope(ctx, og_scope).definitions[last(structure.name).source] = scope
			// no reset here, struct context might be relevant later on
		}

		if len(structure.template_spec) != 0 {
			str.write_byte(&ctx.result, '(')
			for ti, i in structure.template_spec {
				if i > 0 { str.write_string(&ctx.result, ", ") }
				str.write_byte(&ctx.result, '$')
				write_node(ctx, ti, .Temporary, scope)
			}
			str.write_byte(&ctx.result, ')')
		}

		str.write_string(&ctx.result, structure_node.kind == .Struct ? " {" : " #raw_union {")

		last_was_newline := false
		had_first_newline := false

		if structure.base_type != {} {
			str.write_byte(&ctx.result, '\n')
			str.write_string(&ctx.result, member_indent_str)
			str.write_string(&ctx.result, "using ")
			str.write_string(&ctx.result, base_type.name)
			str.write_string(&ctx.result, " : ")
			str.write_string(&ctx.result, base_type.ctx.complete_name)
			str.write_string(&ctx.result, ",\n")

			last_was_newline = true
			had_first_newline = true
		}

		SubsectionSectionData :: struct {
			member_stack : sa.Small_Array(64, AstNodeIndex),
			subsection_counter : int,
			member_indent_str : string,
		}
		subsection_data : SubsectionSectionData

		write_bitfield_subsection_and_reset :: proc(ctx : ^ConverterContext, subsection_data : ^SubsectionSectionData, scope : ScopeIndex, scope_persistence : PersistenceKind, indent_str : string)
		{
			if len(subsection_data.member_indent_str) == 0 {
				subsection_data.member_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
			}

			slice := sa.slice(&subsection_data.member_stack)

			required_bit_width := 0
			for ci in slice {
				member := ctx.ast[ci]
				if member.kind != .VariableDeclaration { continue }

				width := ctx.ast[member.var_declaration.width_expression]
				if width.kind == .LiteralInteger {
					v, ok := strconv.parse_i64_maybe_prefixed(width.literal.source)
					required_bit_width += (ok ? int(v) : 1)
				}
				else {
					required_bit_width += 1
				}
			}

			final_bit_width := 8 if required_bit_width <= 8 else 16 if required_bit_width <= 16 else 32 if required_bit_width <= 32 else 64;


			str.write_string(&ctx.result, indent_str);
			str.write_string(&ctx.result, "using _");
			fmt.sbprint(&ctx.result, subsection_data.subsection_counter); subsection_data.subsection_counter += 1
			str.write_string(&ctx.result, " : bit_field u");
			str.write_int(&ctx.result, final_bit_width)
			str.write_string(&ctx.result, " {\n");

			last_was_newline := true
			loop: for cii := 0; cii < len(slice); cii += 1 {
				ci := slice[cii]
				#partial switch ctx.ast[ci].kind {
					case .VariableDeclaration:
						if last_was_newline { str.write_string(&ctx.result, subsection_data.member_indent_str) }
						else { str.write_byte(&ctx.result, ' ') }
						write_node(ctx, ci, scope_persistence, scope)
						str.write_byte(&ctx.result, ',')

						last_was_newline = false

					case .Comment:
						if last_was_newline { str.write_string(&ctx.result, subsection_data.member_indent_str) }
						else { str.write_byte(&ctx.result, ' ') }
						write_node(ctx, ci, .Temporary, scope)

						last_was_newline = false

					case .NewLine:
						str.write_byte(&ctx.result, '\n')

						last_was_newline = true

						for cik := cii + 1; cik < len(slice); cik += 1 {
							if ctx.ast[slice[cik]].kind != .NewLine {
								continue loop
							}
						}
						break loop

					case:
						write_preproc_node(&ctx.result, ctx.ast[ci])
						last_was_newline = false
				}
			}

			if last_was_newline { str.write_string(&ctx.result, indent_str) }
			else { str.write_byte(&ctx.result, ' ') }
			str.write_string(&ctx.result, "},\n");

			sa.clear(&subsection_data.member_stack)
		}

		synthetic_enum_index := 0
		last_was_transfered := true
		loop: for cii := 0; cii < len(structure.members); cii += 1 {
			ci := structure.members[cii]
			member := &ctx.ast[ci]
			if member.attached { continue }


			#partial switch member.kind {
				case .VariableDeclaration:
					member := member.var_declaration
					if .Static in member.flags {
						has_static_var_members = true;
						last_was_transfered = false
						continue
					}

					last_was_transfered = true

					d := insert_new_definition(ctx, .Persistent, scope, member.var_name.source, ci, member.var_name.source)

					if member.width_expression != {} {
						sa.append(&subsection_data.member_stack, ci)
						continue
					}

					if sa.len(subsection_data.member_stack) > 0 {
						write_bitfield_subsection_and_reset(ctx, &subsection_data, scope, scope_persistence, member_indent_str)
					}

					if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
					else { str.write_byte(&ctx.result, ' ') }
					str.write_string(&ctx.result, member.var_name.source);
					str.write_string(&ctx.result, " : ")
					write_type(ctx, scope, scope_persistence, member.type, indent_str, member_indent_str)
					str.write_byte(&ctx.result, ',')

					last_was_newline = false

				case .FunctionDefinition, .OperatorDefinition:
					// dont write

					last_was_transfered = false

				case .Enum:
					// Don't write but insert deffinitions since they spill out into the parent scope...
					enum_prefix := complete_structure_name
					if len(member.structure.name) == 0 {
						enum_prefix = fmt.tprintf("%v_E%v", complete_structure_name, synthetic_enum_index)
						synthetic_enum_index += 1
					}
					push_enum_context(ctx, scope, scope_persistence, enum_prefix, ci)

					last_was_transfered = false

				case .Struct, .Union:
					if len(member.structure.name) != 0 {
						// always push scopes for nested structs
						inner_structure_name := fold_token_range(complete_structure_name, member.structure.name)
						push_structure_context(ctx, scope, scope_persistence, og_scope, inner_structure_name, ci)
						
						last_was_transfered = false;
						break
					}

					// write anonymous structs as using statements
					if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
					else { str.write_byte(&ctx.result, ' ') }

					str.write_string(&ctx.result, "using _")
					fmt.sbprint(&ctx.result, subsection_data.subsection_counter); subsection_data.subsection_counter += 1
					str.write_string(&ctx.result, " : ")
					inner_member_indent_str :=  str.concatenate({ member_indent_str, ONE_INDENT }, context.temp_allocator)
					write_struct_union_type(ctx, member, ci, scope, scope_persistence, og_scope, member_indent_str, inner_member_indent_str, "")
					str.write_byte(&ctx.result, ',')
					
					last_was_newline = false
					last_was_transfered = true

				case .Comment:
					last_was_transfered = true

					if sa.len(subsection_data.member_stack) > 0 {
						sa.append(&subsection_data.member_stack, ci)
						continue
					}

					if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
					else { str.write_byte(&ctx.result, ' ') }
					str.write_string(&ctx.result, member.literal.source)

					last_was_newline = false

				case .NewLine:
					if !last_was_transfered { continue }
					if cii == 0 && had_first_newline { continue }

					last_was_transfered = true
					had_first_newline = true

					if sa.len(subsection_data.member_stack) > 0 {
						sa.append(&subsection_data.member_stack, ci)
						continue
					}

					str.write_byte(&ctx.result, '\n')

					last_was_newline = true

					for cik := cii + 1; cik < len(structure.members); cik += 1 {
						node := ctx.ast[structure.members[cik]]
						#partial switch node.kind {
							case .NewLine:
								/**/
							case .FunctionDefinition:
								/**/
							case .Struct, .Union, .Enum:
								if len(node.structure.name) == 0 { continue loop }
							case .VariableDeclaration:
								continue loop
							case:
								if !node.attached { continue loop }
						}
					}
					break loop

				case:
					if sa.len(subsection_data.member_stack) > 0 {
						sa.append(&subsection_data.member_stack, ci)
						last_was_transfered = true
						continue
					}

					if write_preproc_node(&ctx.result, member^) {
						last_was_transfered = true
					}
					last_was_newline = false
			}
		}

		if sa.len(subsection_data.member_stack) > 0 {
			write_bitfield_subsection_and_reset(ctx, &subsection_data, scope, scope_persistence, member_indent_str)
		}

		if last_was_newline { str.write_string(&ctx.result, indent_str) }
		else { str.write_byte(&ctx.result, ' ') }
		str.write_byte(&ctx.result, '}')

		return
	}

	write_preproc_node :: proc(result : ^str.Builder, current_node : AstNode) -> bool
	{
		#partial switch current_node.kind {
			case .PreprocIf:
				str.write_string(result, "when ")
				last := last(current_node.token_sequence[:])
				if last.kind == .Comment { // put the comment after the brace so the brace does not get commented out
					write_token_range(result, current_node.token_sequence[:len(current_node.token_sequence) - 1], " ")
					str.write_string(result, " { ")
					str.write_string(result, last.source)
				}
				else {
					write_token_range(result, current_node.token_sequence[:], " ")
					str.write_string(result, " {")
				}

			case .PreprocElse:
				str.write_string(result, "} else ")
				if len(current_node.token_sequence) > 0 {
					str.write_string(result, "when ")
					last := last(current_node.token_sequence[:])
					if last.kind == .Comment { // put the comment after the brace so the brace does not get commented out
						write_token_range(result, current_node.token_sequence[:len(current_node.token_sequence) - 1], " ")
						str.write_string(result, " { ")
						str.write_string(result, last.source)
					}
					else {
						write_token_range(result, current_node.token_sequence[:], " ")
						str.write_string(result, " {")
					}
				}
				else {
					str.write_string(result, "{ // preproc else")
				}

			case .PreprocEndif:
				str.write_string(result, "} // preproc endif")

			case:
				return false
		}

		return true
	}

	write_function_type :: proc(ctx : ^ConverterContext, scope : ScopeIndex, scope_persistence : PersistenceKind, fn_node : AstNode, complete_structure_name : string, parent_type : ^AstNode) -> (arg_count : int)
	{
		fn_node := fn_node.function_def

		if .Inline in fn_node.flags {
			str.write_string(&ctx.result, "#force_inline ")
		}

		str.write_string(&ctx.result, "proc(")

		for ti in fn_node.template_spec {
			if arg_count > 0 { str.write_string(&ctx.result, ", ") }

			str.write_byte(&ctx.result, '$')
			write_node(ctx, ti, scope_persistence, scope)

			arg_count += 1
		}

		if parent_type != nil {
			if arg_count > 0 { str.write_string(&ctx.result, ", ") }

			str.write_string(&ctx.result, "this : ^")
			str.write_string(&ctx.result, complete_structure_name)
			if len(parent_type.structure.template_spec) > 0 {
				str.write_byte(&ctx.result, '(')
				for ti, i in parent_type.structure.template_spec {
					if i > 0 { str.write_string(&ctx.result, ", ") }

					type_var := ctx.ast[ti]
					assert_eq(type_var.kind, AstNodeKind.TemplateVariableDeclaration)

					str.write_byte(&ctx.result, '$')
					str.write_string(&ctx.result, type_var.var_declaration.var_name.source)
				}
				str.write_byte(&ctx.result, ')')
			}

			insert_new_definition(ctx, scope_persistence, scope, "this", parent_type.structure.synthetic_this_var, "this")

			arg_count += 1
		}

		for nidx in fn_node.arguments {
			if arg_count > 0 { str.write_string(&ctx.result, ", ") }

			#partial switch ctx.ast[nidx].kind {
				case .Varargs:
					str.write_string(&ctx.result, "args : ..[]any")

					arg_count += 1

				case .VariableDeclaration:
					arg := ctx.ast[nidx].var_declaration

					if arg.var_name.source != "" {
						if .IsForwardDeclared not_in fn_node.flags {
							insert_new_definition(ctx, scope_persistence, scope, arg.var_name.source, nidx, arg.var_name.source)
						}
		
						str.write_string(&ctx.result, arg.var_name.source)
					}
					else {
						str.write_byte(&ctx.result, '_') // fn args might not have a name
					}
					str.write_string(&ctx.result, " : ")
					write_type(ctx, scope, scope_persistence, arg.type, "", "")
	
					if arg.initializer_expression != {} {
						str.write_string(&ctx.result, " = ")
						write_node(ctx, arg.initializer_expression, scope_persistence, scope)
					}

					arg_count += 1

				case:
					panic(fmt.tprintf("Cannot convert %v to fn arg.", ctx.ast[nidx]))
			}
		}

		str.write_byte(&ctx.result, ')')

		if !is_variant(ctx.type_heap[fn_node.return_type], AstTypeVoid) {
			str.write_string(&ctx.result, " -> ")
			write_type(ctx, scope, scope_persistence, fn_node.return_type, "", "")
		}

		return
	}

	write_function :: proc(ctx : ^ConverterContext, scope : ScopeIndex, scope_persistence : PersistenceKind, function_node_idx : AstNodeIndex, complete_structure_name : string, parent_type : ^AstNode, indent_str : string, write_forward_declared := false)
	{
		parent_type := parent_type
		complete_structure_name := complete_structure_name
		scope := scope

		fn_node_ := &ctx.ast[function_node_idx]
		if (fn_node_.function_def.flags & {.IsCtor, .IsDtor}) != {} && parent_type == nil {
			_, type_context_idx, type_context := find_definition_for_name(ctx, scope, fn_node_.function_def.function_name[:], { .Type })

			parent_type = &ctx.ast[type_context.node]
			complete_structure_name = type_context.complete_name
			scope = type_context_idx
		}
		else if len(fn_node_.function_def.function_name) > 1 && parent_type == nil { // generic member function detection
			_, type_context_idx, type_context := try_find_definition_for_name(ctx, scope, fn_node_.function_def.function_name[:len(fn_node_.function_def.function_name) - 1], { .Type })
			if type_context != nil {
				parent_type = &ctx.ast[type_context.node]
				complete_structure_name = type_context.complete_name
				scope = type_context_idx
			}
		}

		write_function_inner(ctx, scope, scope_persistence, fn_node_, function_node_idx, complete_structure_name, parent_type, indent_str, write_forward_declared)
	}
	write_function_inner :: proc(ctx : ^ConverterContext, scope : ScopeIndex, scope_persistence : PersistenceKind, function_node_ : ^AstNode, function_node_idx : AstNodeIndex, complete_structure_name : string, parent_type : ^AstNode, indent_str : string, write_forward_declared := false)
	{
		fn_node := &function_node_.function_def

		overloaded_name : string

		function_name : TokenRange
		switch {
			case .IsCtor in fn_node.flags:
				overload_index := 0
				overload_count := 0
				for mi in parent_type.structure.members {
					member := ctx.ast[mi]
					if member.kind != .FunctionDefinition { continue }

					if .IsCtor in member.function_def.flags {
						if mi == function_node_idx { overload_index = overload_count }
						overload_count += 1
					}
				}

				if overload_count > 1 {
					overloaded_name = "init"
					function_name = { Token{ kind = .Identifier, source = "init" }, Token{ kind = .Identifier, source = fmt.tprint(overload_index) } }
				}
				else {
					function_name = { Token{ kind = .Identifier, source = "init" } }
				}

			case .IsDtor in fn_node.flags:
				function_name = { Token{ kind = .Identifier, source = "deinit" } }

			case complete_structure_name != "" && parent_type != nil && parent_type.kind != .Namespace:
				fn_baseanme := last(fn_node.function_name)

				overload_index := 0
				overload_count := 0
				for mi in parent_type.structure.members {
					member := ctx.ast[mi]
					if member.kind != .FunctionDefinition { continue }

					if last(member.function_def.function_name).source == fn_baseanme.source {
						if mi == function_node_idx { overload_index = overload_count }
						overload_count += 1
					}
				}

				if overload_count > 1 {
					overloaded_name = fn_baseanme.source
					function_name = { fn_baseanme^, Token{ kind = .Identifier, source = fmt.tprint(overload_index) } }
				}
				else {
					function_name = fn_node.function_name[len(fn_node.function_name) - 1:]
				}

			case:
				function_name = fn_node.function_name[:]
		}

		complete_name := fold_token_range(complete_structure_name, function_name)

		if overloaded_name != "" {
			insert_new_overload(ctx, overloaded_name, complete_name)
		}

		// fold attached comments form forward declaration. This also works when chaining forward declarations
		_, forward_declared_context_idx, forward_declared_context := try_find_definition_for_name(ctx, scope, function_name, { .Function })
		if forward_declared_context != nil {
			forward_declaration := ctx.ast[forward_declared_context.node]
			assert_eq(forward_declaration.kind, AstNodeKind.FunctionDefinition)

			forward_comments := forward_declaration.function_def.attached_comments
			inject_at(&fn_node.attached_comments, 0, ..forward_comments[:])
		}

		scope := scope
		if len(function_name) == 1 || overloaded_name != "" {
			scope = insert_new_definition(ctx, .Persistent, scope, function_name[0].source, function_node_idx, complete_name)
		}
		else {
			assert(forward_declared_context != nil)
			scope = forward_declared_context_idx
		}

		if .IsForwardDeclared in fn_node.flags && !write_forward_declared {
			return // Don't insert forward declarations, only insert the name context leaf node.
		}

		context_heap_reset := len(&ctx.temp_context_heap) // keep fn as leaf node, since expressions cen reference the name
		defer {
			clear(&get_scope(ctx, scope).definitions)
			resize(&ctx.temp_context_heap, context_heap_reset)
		}

		// write directly, they are marked for skipping in write_sequence
		last_attached_node_was_newline := false
		for aid in fn_node.attached_comments {
			write_node(ctx, aid, .Temporary, scope)
			last_attached_node_was_newline = ctx.ast[aid].kind == .NewLine
		}
		if len(fn_node.attached_comments) != 0 && !last_attached_node_was_newline { str.write_byte(&ctx.result, '\n'); }

		str.write_string(&ctx.result, indent_str);
		str.write_string(&ctx.result, complete_name);
		str.write_string(&ctx.result, " :: ");
		write_function_type(ctx, scope, scope_persistence, function_node_^, complete_structure_name, parent_type)

		if .IsForwardDeclared in fn_node.flags {
			return
		}

		body_sequence_count := len(fn_node.body_sequence)

		implicit_initializaitons : [dynamic]AstNodeIndex
		if .IsCtor in fn_node.flags && .HasImplicitCtor in parent_type.structure.flags {
			implicit_initializaitons = make([dynamic]AstNodeIndex, 0, 64, context.temp_allocator)
			for mi in parent_type.structure.members {
				member := ctx.ast[mi]
				if member.kind == .VariableDeclaration && member.var_declaration.initializer_expression != {} {
					append(&implicit_initializaitons, mi)
					body_sequence_count += 1
				}
			}
		}

		switch body_sequence_count {
			case 0:
				str.write_string(&ctx.result, " { }");

			case 1:
				str.write_string(&ctx.result, " { ");
				if len(implicit_initializaitons) != 0 {
					member := ctx.ast[implicit_initializaitons[0]].var_declaration
					str.write_string(&ctx.result, "this.")
					str.write_string(&ctx.result, member.var_name.source)
					str.write_string(&ctx.result, " = ")
					write_node(ctx, member.initializer_expression, scope_persistence, scope, indent_str)
				}
				else {
					write_node(ctx, fn_node.body_sequence[0], scope_persistence, scope, indent_str)
				}
				str.write_string(&ctx.result, " }");

			case:
				str.write_byte(&ctx.result, '\n')

				str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{")
				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)

				if len(implicit_initializaitons) != 0 {
					str.write_byte(&ctx.result, '\n')

					for mi in implicit_initializaitons {
						member := ctx.ast[mi].var_declaration

						str.write_string(&ctx.result, "this.")
						str.write_string(&ctx.result, member.var_name.source)
						str.write_string(&ctx.result, " = ")
						write_node(ctx, member.initializer_expression, scope_persistence, scope)

						str.write_byte(&ctx.result, '\n')
					}
				}
				else if len(fn_node.body_sequence) > 0 && ctx.ast[fn_node.body_sequence[0]].kind != .NewLine {
					str.write_byte(&ctx.result, '\n')
					str.write_string(&ctx.result, body_indent_str);
				}
				write_node_sequence(ctx, fn_node.body_sequence[:], scope, .Temporary, body_indent_str)

				if ctx.ast[last_or_nil(fn_node.body_sequence)].kind != .NewLine {
					str.write_byte(&ctx.result, '\n');
				}
				str.write_string(&ctx.result, indent_str);
				str.write_byte(&ctx.result, '}')
		}
	}

	write_token_range :: proc(result : ^str.Builder, r : TokenRange, glue := "_")
	{
		for t, i in r {
			if i != 0 { str.write_string(result, glue) }
			str.write_string(result, t.source)
		}
	}

	fold_token_range :: proc(prefix : string, r : TokenRange, glue := "_") -> string
	{
		complete_name := prefix
		for token in r {
			if len(complete_name) != 0 {
				complete_name = str.concatenate({complete_name, glue, token.source})
			}
			else {
				complete_name = token.source
			}
		}
		return complete_name
	}

	write_type :: proc(ctx : ^ConverterContext, scope : ScopeIndex, scope_persistence : PersistenceKind, type : AstTypeIndex, indent_str, member_indent_str : string)
	{
		for type := type; type != {}; {
			#partial switch frag in ctx.type_heap[type] {
				case AstTypePointer:
					if is_variant(ctx.type_heap[frag.destination_type], AstTypeVoid) {
						str.write_string(&ctx.result, "rawptr")
						return
					}
					else if f, is_frag := ctx.type_heap[frag.destination_type].(AstTypeFragment); is_frag && f.identifier.source == "FILE" {
						str.write_string(&ctx.result, "os.Handle")
						return
					}\
					// else if underlying_primitive, ok := ctx.type_heap[frag.destination_type].(AstTypePrimitive); ok && len(underlying_primitive.fragments) == 1 && underlying_primitive.fragments[0].source == "char" {
					// 	str.write_string(&ctx.result, "[^]u8")
					// 	return
					// }
					else if is_variant(ctx.type_heap[frag.destination_type], AstTypeFunction) {
						type = frag.destination_type // print a fnptr as jsut the function type 
					}
					else {
						str.write_byte(&ctx.result, '^')
						type = frag.destination_type
					}

				case AstTypeArray:
					str.write_byte(&ctx.result, '[')
					if frag.length_expression != {} {
						write_node(ctx, frag.length_expression, scope_persistence, scope, indent_str)
					}
					else {
						str.write_byte(&ctx.result, '^')
					}
					str.write_byte(&ctx.result, ']')
					type = frag.element_type

				case AstTypeFragment:
					// if frag.parent_fragment != {} {
					// 	write_type(ctx, scope, scope_persistence, frag.parent_fragment, indent_str, member_indent_str)
					// 	str.write_byte(&ctx.result, '_')
					// }
					switch frag.identifier.source {
						case "size_t":
							str.write_string(&ctx.result, "uint")

						case "intptr_t":
							str.write_string(&ctx.result, "uintptr")

						case "ptrdiff_t":
							str.write_string(&ctx.result, "int")

						case "typename", "class":
							str.write_string(&ctx.result, "typeid")

						case "va_list":
							str.write_string(&ctx.result, "[]any")

						case:
							_, _, type_ctx := try_find_definition_for(ctx, scope, type)
							if type_ctx != nil {
								str.write_string(&ctx.result, type_ctx.complete_name)
							}
							else {
								log.warn("Failed to find deffinition for type fragment", frag.identifier)
								str.write_string(&ctx.result, frag.identifier.source)
							}
					}

					if len(frag.generic_parameters) > 0 {
						str.write_byte(&ctx.result, '(')
						for g, i in frag.generic_parameters {
							if i > 0 { str.write_string(&ctx.result, ", ") }
							write_node(ctx, g, scope_persistence, scope, indent_str)
						}
						str.write_byte(&ctx.result, ')')
					}
					return

				case AstTypeInlineStructure:
					write_struct_union_type(ctx, &ctx.ast[frag], AstNodeIndex(frag), scope, scope_persistence, scope, indent_str, member_indent_str, "")
					return

				case AstTypeFunction:
					str.write_string(&ctx.result, "proc(")
					for ai, i in frag.arguments {
						if i > 0 { str.write_string(&ctx.result, ", ") }
						write_node(ctx, ai, scope_persistence, scope, indent_str)
					}
					str.write_byte(&ctx.result, ')')

					if !is_variant(ctx.type_heap[frag.return_type], AstTypeVoid) {
						str.write_string(&ctx.result, " -> ")
						write_type(ctx, scope, scope_persistence, frag.return_type, indent_str, member_indent_str)
					}
					return

				case AstTypePrimitive:
					transform_from_short :: proc(input : TokenRange, $prefix : string) -> string
					{
						if len(input) == 0 || input[0].kind != .Identifier { // short, short*
							return prefix+"16"
						}
						else if input[0].source == "int" { // short int
							return prefix+"16"
						}

						panic("Failed to transform "+prefix+" short");
					}

					transform_from_long :: proc(input : TokenRange, $prefix : string) -> string
					{
						if len(input) == 0 || input[0].kind != .Identifier { // long, long*
							return prefix+"32"
						}
						else if input[0].source == "int" { // long int
							return prefix+"32"
						}
						else if input[0].source == "long" { // long long
							if len(input) == 1 || input[1].kind != .Identifier { // long long, long long*
								return prefix+"64"
							}
							else if input[1].source == "int" { // long long int
								return prefix+"64"
							}
						}

						panic("Failed to transform "+prefix+" long");
					}

					input := frag.fragments
					switch input[0].source {
						case "signed":
							if len(input) == 1 {
								str.write_string(&ctx.result, "i32")
							}
							else {
								switch input[1].source {
									case "char":
										str.write_string(&ctx.result, "i8")

									case "int":
										str.write_string(&ctx.result, "i32")

									case "short":
										str.write_string(&ctx.result, transform_from_short(input[2:], "i"))

									case "long":
										str.write_string(&ctx.result, transform_from_long(input[2:], "i"))
								}
							}

						case "unsigned":
							if len(input) == 1 {
								str.write_string(&ctx.result, "u32")
							}
							else {
								switch input[1].source {
									case "char":
										str.write_string(&ctx.result, "u8")

									case "int":
										str.write_string(&ctx.result, "u32")

									case "short":
										str.write_string(&ctx.result, transform_from_short(input[2:], "u"))

									case "long":
										str.write_string(&ctx.result, transform_from_long(input[2:], "u"))
								}
							}

						case "char":
							str.write_string(&ctx.result, "u8") // funny implementation defined singnedness, interpret as unsiged

						case "int":
							str.write_string(&ctx.result, "i32")
	
						case "short":
							str.write_string(&ctx.result, transform_from_short(input[1:], "i"))

						case "long":
							str.write_string(&ctx.result, transform_from_long(input[1:], "i"))

						case "float":
							str.write_string(&ctx.result, "f32")

						case "double":
							str.write_string(&ctx.result, "f64")

						case "bool":
							str.write_string(&ctx.result, "bool")

						case:
							panic(fmt.tprint("Failed to transform", input[0]));
					}
					
					return

				case:
					panic(fmt.tprint("not implemented", type));
			}
		}
	}

	flatten_type :: proc(ctx : ^ConverterContext, type : AstTypeIndex, loc := #caller_location) -> (output : [dynamic]Token)
	{
		for type := type; type != {}; {
			#partial switch frag in ctx.type_heap[type] {
				case AstTypeFragment:
					inject_at(&output, 0, frag.identifier)
					type = frag.parent_fragment

				case AstTypePointer:
					type = frag.destination_type

				case AstTypeArray:
					type = frag.element_type

				case:
					panic(fmt.tprint("Cannof flatten type element", frag), loc);
			}
		}
		return
	}

	resolve_type :: proc(ctx : ^ConverterContext, current_node_index : AstNodeIndex, scope : ScopeIndex, loc := #caller_location) -> (raw_type : AstTypeIndex, type_context : ScopeIndex)
	{
		current_node := ctx.ast[current_node_index]
		#partial switch current_node.kind {
			case .Identifier:
				_, var_def_ctx_idx, var_def_ctx := find_definition_for_name(ctx, scope, current_node.identifier[:], loc = loc)

				var_def := ctx.ast[var_def_ctx.node]
				#partial switch var_def.kind {
					case .VariableDeclaration:
						return resolve_type(ctx, var_def_ctx.node, var_def_ctx.parent, loc)

					case .FunctionDefinition: //TODO(Rennorb) @explain
						fn_def := var_def.function_def

						_, type_context_idx, _ := try_find_definition_for_or_warn(ctx, scope, fn_def.return_type)

						return fn_def.return_type, type_context_idx

					case .Struct, .Union: // structure constructor     Rect(1, 2, 1, 2)
						struct_this := ctx.ast[var_def_ctx.node].structure.synthetic_this_var
						return ctx.ast[struct_this].var_declaration.type, var_def_ctx_idx

					case:
						panic(fmt.tprintf("[%v] Unexpected identifier type '%v' for %v: %#v", loc, var_def.kind, current_node.identifier, var_def_ctx))
				}
			
			case .ExprUnaryLeft:
				return resolve_type(ctx, current_node.unary_left.right, scope, loc)

			case .ExprUnaryRight:
				return resolve_type(ctx, current_node.unary_right.left, scope, loc)

			case .ExprIndex:
				expression_type, expression_type_context := resolve_type(ctx, current_node.index.array_expression, scope, loc)
				#partial switch frag in ctx.type_heap[expression_type] {
					case AstTypeArray:
						return frag.element_type, expression_type_context

					case AstTypePointer:
						if .Reference not_in frag.flags {
							return frag.destination_type, expression_type_context
						}
				}

				// assume the type is indexable and look for a matching operator
				structure_node := ctx.ast[get_scope(ctx, expression_type_context).node]
				assert(structure_node.kind == .Struct || structure_node.kind == .Union)

				for mi in structure_node.structure.members {
					member := ctx.ast[mi]
					if member.kind != .OperatorDefinition || member.operator_def.kind != .Index { continue }

					type := ctx.ast[member.operator_def.underlying_function].function_def.return_type
					_, return_type_context_idx, _ := try_find_definition_for_or_warn(ctx, expression_type_context, type)

					return type, return_type_context_idx
				}

				panic(fmt.tprintf("Index operator not found on %#v", structure_node))

			case .MemberAccess:
				member_access := current_node.member_access
				expr_type, expr_type_context_idx := resolve_type(ctx, member_access.expression, scope, loc)

				member := ctx.ast[member_access.member]
				#partial switch member.kind {
					case .Identifier:
						return resolve_type(ctx, member_access.member, expr_type_context_idx, loc)

					case .FunctionCall:
						fn_name_node := ctx.ast[member.function_call.expression]
						assert_eq(fn_name_node.kind, AstNodeKind.Identifier)
						fn_name := last(fn_name_node.identifier[:])

						expr_type_context := get_scope(ctx, expr_type_context_idx)
						fndef_idx := expr_type_context.definitions[fn_name.source]
						fndef_ctx := get_scope(ctx, fndef_idx)

						assert_eq(ctx.ast[fndef_ctx.node].kind, AstNodeKind.FunctionDefinition)
						fndef := ctx.ast[fndef_ctx.node].function_def

						_, type_context_idx, _ := find_definition_for(ctx, expr_type_context_idx, fndef.return_type)

						return fndef.return_type, type_context_idx

					case:
						panic(fmt.tprintf("Not implemented %v", member))
				}

			case .VariableDeclaration:
				def_node := current_node.var_declaration

				type := ctx.type_heap[def_node.type]

				#partial switch _ in  type {
					case AstTypeInlineStructure: // struct { int a } b;
						synthetic_struct_name := Token{ kind = .Identifier, source = fmt.tprintf(ANONYMOUS_STRUCT_NAME_FORMAT, ctx.next_anonymous_struct_index - 1) }
						_, type_context_idx, _ := try_find_definition_for_name(ctx, scope, {synthetic_struct_name}, {.Type})
						return def_node.type, type_context_idx
				}

				if is_variant(type, AstTypeAuto) {
					panic("auto resolver not implemented");
				}

				#partial switch _ in ctx.type_heap[def_node.type] {
					case AstTypePrimitive, AstTypeVoid:
						return def_node.type, {}
				}

				type_context_idx : ScopeIndex

				stemmed := stemm_type(ctx, def_node.type)
				#partial switch _ in ctx.type_heap[stemmed] {
					case AstTypePrimitive, AstTypeVoid:
						/**/
					case:
						type_context : ^Scope
						_, type_context_idx, type_context = try_find_definition_for(ctx, scope, def_node.type)
						if type_context_idx.index == 0 {
							log.warnf("Failed to find deffinition for %v", ctx.type_heap[def_node.type])
						}
						else {
							type_node := ctx.ast[type_context.node]
							if (type_node.kind == .Struct || type_node.kind == .Union) && len(type_node.structure.template_spec) != 0 {
								instance_key := format_instantiated_structure_name_key(ctx, stemmed)
								_, instance_context, ctx_requires_creation, _ := map_entry(&type_context.instantiations, instance_key)
								if ctx_requires_creation {
									log.debugf("[%v] Baking new generic type %v", def_node.var_name.location, instance_key)

									instance := bake_generic_structure(ctx, type_context.node, ctx.type_heap[stemmed].(AstTypeFragment))
									instance_context^ = generate_instantiated_structure_context(ctx, type_context_idx, instance)
								}
								type_context_idx = instance_context^
							}
						}
				}

				return def_node.type, type_context_idx

			case .FunctionCall:
				// technically not quite right, but thats also because of the structure of these nodes
				return resolve_type(ctx, current_node.function_call.expression, scope, loc)

			case .ExprCast:
				_, type_context_idx, _ := try_find_definition_for_or_warn(ctx, scope, current_node.cast_.type)

				return current_node.cast_.type, type_context_idx

			case .ExprBacketed:
				return resolve_type(ctx, current_node.inner, scope, loc)

			case:
				panic(fmt.tprintf("Not implemented %#v", current_node))
		}
	}

	generate_instantiated_structure_context :: proc(ctx : ^ConverterContext, generic_structure_context : ScopeIndex, instantiated_structure : AstNodeIndex) -> ScopeIndex
	{
		generic_context := get_scope(ctx, generic_structure_context)

		instantiated_context := generic_context^
		instantiated_context.node = instantiated_structure
		instantiated_context.definitions = map_clone(generic_context.definitions)
		instantiated_context_idx := ScopeIndex {
			index = transmute(uint) append_return_index(&ctx.context_heap, instantiated_context),
			persistence = .Persistent,
		}

		for mi in ctx.ast[instantiated_structure].structure.members {
			member := ctx.ast[mi]
			#partial switch member.kind {
				case .VariableDeclaration:
					if .Static in member.var_declaration.flags { continue }

					var_name := member.var_declaration.var_name.source
					insert_new_definition(ctx, .Persistent, instantiated_context_idx, var_name, mi, var_name)

				case .FunctionDefinition:
					fn_name := last(member.function_def.function_name).source
					insert_new_definition(ctx, .Persistent, instantiated_context_idx, fn_name, mi, fn_name)
			}
		}

		return instantiated_context_idx
	}

	format_instantiated_structure_name_key :: proc(ctx : ^ConverterContext, type : AstTypeIndex, b : ^str.Builder = nil) -> string
	{
		b := b
		b_ : str.Builder
		if b == nil { b = &b_ }

		switch frag in ctx.type_heap[type] {
			case AstTypeInlineStructure:
				unimplemented()
			case AstTypeFunction:
				unimplemented()
			case AstTypePointer:
				str.write_byte(b, '^')
				format_instantiated_structure_name_key(ctx, frag.destination_type, b)
			case AstTypeArray:
				str.write_byte(b, '[')
				str.write_byte(b, ']')
				format_instantiated_structure_name_key(ctx, frag.element_type, b)
			case AstTypeFragment:
				str.write_string(b, frag.identifier.source)
				if len(frag.generic_parameters) > 0 {
					str.write_byte(b, '(')
					for pi, i in frag.generic_parameters {
						if i > 0 { str.write_byte(b, ',') }
						param := ctx.ast[pi]
						if param.kind == .Type {
							format_instantiated_structure_name_key(ctx, param.type, b)
						}
					}
					str.write_byte(b, ')')
				}
			case AstTypePrimitive:
				for f, i in frag.fragments {
					if i > 0 { str.write_byte(b, ':') }
					str.write_string(b, f.source)
				}
			case AstTypeAuto:
				str.write_string(b, "auto")
			case AstTypeVoid:
				str.write_string(b, "void")
		}

		return str.to_string(b^)
	}

	bake_generic_structure :: proc(ctx : ^ConverterContext, structure : AstNodeIndex, parameter_source : AstTypeFragment) -> AstNodeIndex
	{
		#partial switch ctx.ast[structure].kind {
			case .Struct, .Union:
				assert(len(ctx.ast[structure].structure.template_spec) > 0)
				/*ok*/
			case: panic(fmt.tprintf("Unexpected astnode for baking: %#v", structure))
		}

		og_structure := ctx.ast[structure].structure

		replacements : map[string]AstNodeIndex
		for ti, i in og_structure.template_spec {
			template_var_def := ctx.ast[ti].var_declaration
			r : AstNodeIndex
			if i < len(parameter_source.generic_parameters) {
				r = parameter_source.generic_parameters[i]
			}
			else {
				assert(template_var_def.initializer_expression != 0)
				r = template_var_def.initializer_expression
			}
			replacements[template_var_def.var_name.source] = r
		}

		baked_members := slice.clone_to_dynamic(og_structure.members[:])
		for &mi in baked_members {
			member := ctx.ast[mi]
			#partial switch member.kind {
				case .VariableDeclaration:
					if baked_type, did_bake_type := bake_generic_type(ctx, member.var_declaration.type, replacements); did_bake_type {
						member.var_declaration.type = baked_type
						mi = cvt_append_node(ctx, member)
					}

				case .FunctionDefinition:
					// @hack dont care about arguments, we only care for the return type for now
					if baked_type, did_bake_type := bake_generic_type(ctx, member.function_def.return_type, replacements); did_bake_type {
						member.function_def.return_type = baked_type
						mi = cvt_append_node(ctx, member)
					}

				case .OperatorDefinition:
					fn_def := ctx.ast[member.operator_def.underlying_function]
					// @hack dont care about arguments, we only care for the return type for now
					if baked_type, did_bake_type := bake_generic_type(ctx, fn_def.function_def.return_type, replacements); did_bake_type {
						fn_def.function_def.return_type = baked_type
						member.operator_def.underlying_function = cvt_append_node(ctx, fn_def)
						mi = cvt_append_node(ctx, member)
					}
			}
		}
		
		baked := ctx.ast[structure]
		baked.structure = {
			template_spec = {},
			members = baked_members,
		}
		return cvt_append_node(ctx, baked)
	}

	bake_generic_type :: proc(ctx : ^ConverterContext, type : AstTypeIndex, replacements : map[string]AstNodeIndex, loc := #caller_location) -> (baked_type : AstTypeIndex, did_replace_fragments : bool)
	{
		baked_type = type
		switch frag in ctx.type_heap[type] {
			case AstTypePointer:
				baked_inner : AstTypeIndex
				baked_inner, did_replace_fragments = bake_generic_type(ctx, frag.destination_type, replacements, loc)
				if did_replace_fragments {
					clone := frag
					clone.destination_type = baked_inner
					baked_type = cvt_append_type(ctx, clone)
				}
				return

			case AstTypeArray:
				baked_inner : AstTypeIndex
				baked_inner, did_replace_fragments = bake_generic_type(ctx, frag.element_type, replacements, loc)
				if did_replace_fragments {
					clone := frag
					clone.element_type = baked_inner
					baked_type = cvt_append_type(ctx, clone)
				}
				return

			case AstTypeInlineStructure:
				unimplemented(loc = loc)

			case AstTypeFunction:
				unimplemented(loc = loc)

			case AstTypeFragment:
				if replacemnt, should_replace := replacements[frag.identifier.source]; should_replace {
					assert_node_kind(ctx.ast[replacemnt], .Type)
					baked_type = ctx.ast[replacemnt].type
					did_replace_fragments = true
					return
				}

				baked_parameters : [dynamic]AstNodeIndex
				for pi, pii in frag.generic_parameters {
					#partial switch ctx.ast[pi].kind {
						case .Type:
							baked_inner, did_replace_inner := bake_generic_type(ctx, ctx.ast[pi].type, replacements, loc)
							if did_replace_inner {
								did_replace_fragments = true
								if len(baked_parameters) != len(frag.generic_parameters) {
									baked_parameters = slice.clone_to_dynamic(frag.generic_parameters)
								}
								baked_parameters[pii] = cvt_append_node(ctx, AstNode{ kind = .Type, type = baked_inner })
						}
					}
				}

				if len(baked_parameters) != 0 {
					clone := frag
					clone.generic_parameters = baked_parameters[:]
					baked_type = cvt_append_type(ctx, clone)
				}
				return

			case AstTypeVoid, AstTypePrimitive, AstTypeAuto:
				baked_type = type
				return
		}
		unreachable()
	}
}

stemm_type :: proc(ctx : ^ConverterContext, type : AstTypeIndex, loc := #caller_location) -> AstTypeIndex
{
	type := type
	for type != {} {
		switch frag in ctx.type_heap[type] {
			case AstTypePointer:
				type = frag.destination_type
			case AstTypeArray:
				type = frag.element_type
			case AstTypeInlineStructure, AstTypeFunction, AstTypeFragment, AstTypePrimitive, AstTypeAuto, AstTypeVoid:
				return type
		}
	}
	unreachable()
}

type_references_type :: proc(ctx : ^ConverterContext, type : AstTypeIndex, other_types : []string, loc := #caller_location) -> bool
{
	type := ctx.type_heap[type]
	for type != nil {
		switch frag in type {
			case AstTypePointer:
				type = ctx.type_heap[frag.destination_type]

			case AstTypeArray:
				type = ctx.type_heap[frag.element_type]

			case AstTypeInlineStructure:
				unimplemented(loc = loc);

			case AstTypeFunction:
				unimplemented(loc = loc);

			case AstTypeFragment:
				for other in other_types {
					if frag.identifier.source == other { return true }
				}

				for pi in frag.generic_parameters {
					#partial switch ctx.ast[pi].kind {
						case .Type:
							if type_references_type(ctx, ctx.ast[pi].type, other_types, loc) { return true }
					}
				}
				type = ctx.type_heap[frag.parent_fragment]

			case AstTypeVoid, AstTypePrimitive, AstTypeAuto:
				return false
		}
	}
	return false
}


trim_newlines_start :: proc(ctx : ^ConverterContext, tokens : []AstNodeIndex) -> (trimmed : []AstNodeIndex)
{
	trimmed = tokens
	for len(trimmed) > 0 && ctx.ast[trimmed[0]].kind == .NewLine {
		trimmed = trimmed[1:]
	}
	return
}

trim_newlines_end :: proc(ctx : ^ConverterContext, tokens : []AstNodeIndex) -> (trimmed : []AstNodeIndex)
{
	trimmed = tokens
	for len(trimmed) > 0 && ctx.ast[last(trimmed)^].kind == .NewLine {
		trimmed = trimmed[0:len(trimmed) - 1]
	}
	return
}


trim_newlines :: proc(ctx : ^ConverterContext, tokens : []AstNodeIndex) -> (trimmed : []AstNodeIndex)
{
	return #force_inline trim_newlines_end(ctx, #force_inline trim_newlines_start(ctx, tokens))
}

write_shim :: proc(ctx : ^ConverterContext)
{
	str.write_string(&ctx.result, `package test

 pre_decr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ -= 1; return p }
 pre_incr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ += 1; return p }
post_decr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ -= 1; return }
post_incr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ += 1; return }

va_arg :: #force_inline proc(args : ^[]any, $T : typeid) -> (r : T) { r = (cast(T^) args[0])^; args^ = args[1:] }

`)

	write_overloads(ctx)
}

write_overloads :: proc(ctx : ^ConverterContext)
{
	for name, overloads in ctx.overload_resolver {
		str.write_byte(&ctx.result, '\n')
		str.write_string(&ctx.result, name)
		str.write_string(&ctx.result, " :: proc { ")
		for overloaded_name, i in overloads {
			if i > 0 { str.write_string(&ctx.result, ", ") }
			str.write_string(&ctx.result, overloaded_name)
		}
		str.write_string(&ctx.result, " }\n")
	}
}

ScopeIndex :: distinct SplitIndex
Scope :: struct {
	node : AstNodeIndex,
	parent : ScopeIndex,
	complete_name : string,
	definitions : map[string]ScopeIndex,
	instantiations : map[string]ScopeIndex,
}

get_scope :: #force_inline proc(ctx : ^ConverterContext, index : ScopeIndex) -> ^Scope
{
	return &select_scope_heap(ctx, index.persistence)[index.index]
}

select_scope_heap :: #force_inline proc(ctx : ^ConverterContext, persistence : PersistenceKind) -> ^[dynamic]Scope
{
	return persistence == .Persistent ? &ctx.context_heap : &ctx.temp_context_heap
}

insert_new_definition :: proc(ctx : ^ConverterContext, persistence : PersistenceKind, current_index : ScopeIndex, name : string, node : AstNodeIndex, complete_name : string) -> ScopeIndex
{
	heap := persistence == .Persistent ? &ctx.context_heap : &ctx.temp_context_heap
	idx := ScopeIndex { 
		index = transmute(uint) append_return_index(heap, Scope{ node = node, parent = current_index, complete_name = complete_name}),
		persistence = persistence,
	}
	get_scope(ctx, current_index).definitions[name] = idx
	return idx
}

insert_new_overload :: proc(ctx : ^ConverterContext, name, overload : string)
{
	_, overlaods, _, _ := map_entry(&ctx.overload_resolver, name)
	append(overlaods, overload)
}

DefinitionFilter :: bit_set[DefinitionKind]
DefinitionKind :: enum {
	Type,
	Function,
	Variable,
	Namespace,
}
DeffinitionFilterAll := all(DefinitionFilter)

find_definition_for_name :: proc(ctx : ^ConverterContext, start_context : ScopeIndex, compound_identifier : TokenRange, filter := DeffinitionFilterAll, loc := #caller_location) -> (found_context_tail_idx, found_context_head_idx : ScopeIndex, found_context_head : ^Scope)
{
	found_context_tail_idx, found_context_head_idx, found_context_head = try_find_definition_for_name(ctx, start_context, compound_identifier, filter)
	if found_context_head != nil { return }

	err := fmt.tprintf("%v : %v '%v' was not found in context", len(compound_identifier) > 0 ? compound_identifier[0].location : SourceLocation{}, filter, compound_identifier)
	log.error(err, location = loc)
	dump_context_stack(ctx, start_context, get_scope(ctx, start_context).complete_name)
	panic(err, loc)
}

try_find_definition_for_name :: proc(ctx : ^ConverterContext, start_context : ScopeIndex, compound_identifier : TokenRange, filter := DeffinitionFilterAll) -> (found_context_tail_idx, found_context_head_idx : ScopeIndex, found_context_head : ^Scope)
{
	if len(compound_identifier) == 0 { return }

	current_root_context_idx := start_context

	ctx_stack: for {
		current_context_idx := current_root_context_idx

		for segment in compound_identifier {
			current_context := get_scope(ctx, current_context_idx)
			child_idx, exists := current_context.definitions[segment.source]
			if !exists {
				if current_root_context_idx.index == 0 { break ctx_stack }
				current_root_context_idx = get_scope(ctx, current_root_context_idx).parent
				continue ctx_stack
			}

			current_context_idx = child_idx
		}

		current_context := get_scope(ctx, current_context_idx)
		if current_context.node != 0 {
			#partial switch ctx.ast[current_context.node].kind {
				case .Namespace:
					if .Namespace not_in filter {
						if current_root_context_idx.index == 0 { break ctx_stack }
						current_root_context_idx = get_scope(ctx, current_root_context_idx).parent
						continue ctx_stack
					}
				case .Struct, .Union, .Enum, .Type:
					if .Type not_in filter {
						if current_root_context_idx.index == 0 { break ctx_stack }
						current_root_context_idx = get_scope(ctx, current_root_context_idx).parent
						continue ctx_stack
					}
				case .FunctionDefinition, .OperatorDefinition:
					if .Function not_in filter {
						if current_root_context_idx.index == 0 { break ctx_stack }
						current_root_context_idx = get_scope(ctx, current_root_context_idx).parent
						continue ctx_stack
					}
				case .VariableDeclaration:
					is_type :: proc(ctx : ^ConverterContext, current_context : ^Scope) -> (is_type : bool)
					{
						type := ctx.ast[current_context.node].var_declaration.type
						// TODO
						return
					}
					if .Variable not_in filter && (.Type not_in filter || !is_type(ctx, current_context)) {
						if current_root_context_idx.index == 0 { break ctx_stack }
						current_root_context_idx = get_scope(ctx, current_root_context_idx).parent
						continue ctx_stack
					}
			}
		}
		
		return current_root_context_idx, current_context_idx, current_context
	}

	return
}

find_definition_for :: proc(ctx : ^ConverterContext, start_context : ScopeIndex, type : AstTypeIndex, loc := #caller_location) -> (found_context_tail_idx, found_context_head_idx : ScopeIndex, found_context : ^Scope)
{
	found_context_tail_idx, found_context_head_idx, found_context = try_find_definition_for(ctx, start_context, type)
	if found_context != nil { return }

	err := fmt.tprintf("Type not found in context: %#v", ctx.type_heap[type])
	log.error(err, location = loc)
	dump_context_stack(ctx, start_context, get_scope(ctx, start_context).complete_name)
	panic(err, loc)
}

try_find_definition_for_or_warn :: proc(ctx : ^ConverterContext, start_context : ScopeIndex, type : AstTypeIndex, loc := #caller_location) -> (found_context_tail_idx, found_context_head_idx : ScopeIndex, found_context : ^Scope)
{
	found_context_tail_idx, found_context_head_idx, found_context = try_find_definition_for(ctx, start_context, type)
	if found_context != nil { return }

	stemmed := stemm_type(ctx, type)
	#partial switch _ in ctx.type_heap[stemmed] {
		case AstTypePrimitive, AstTypeVoid:
			return
	}

	log.errorf("Type not found in context: %v", ctx.type_heap[type], location = loc)
	return
}

try_find_definition_for :: proc(ctx : ^ConverterContext, start_context : ScopeIndex, type : AstTypeIndex) -> (found_context_tail_idx, found_context_head_idx : ScopeIndex, found_context : ^Scope)
{
	flattened_type := make([dynamic]AstTypeFragment, context.temp_allocator)
	flaten_loop: for type := type; type != {}; {
		#partial switch frag in ctx.type_heap[type] {
			case AstTypeFragment:
				inject_at(&flattened_type, 0, frag)
				type = frag.parent_fragment

			case AstTypePointer:
				type = frag.destination_type

			case AstTypeArray:
				type = frag.element_type

			case:
				break flaten_loop
		}
	}

	if len(flattened_type) == 0 { return }

	current_root_context_idx := start_context

	ctx_stack: for {
		current_context_idx := current_root_context_idx

		for frag in flattened_type {
			current_context := get_scope(ctx, current_context_idx)
			child_idx, exists := current_context.definitions[frag.identifier.source]
			if !exists {
				if current_root_context_idx.index == 0 { break ctx_stack }
				current_root_context_idx = get_scope(ctx, current_root_context_idx).parent
				continue ctx_stack
			}

			current_context_idx = child_idx
		}

		current_context := get_scope(ctx, current_context_idx)
		if current_context.node != 0 {
			#partial switch ctx.ast[current_context.node].kind {
				case .Namespace, .Struct, .Union, .Enum, .Type, .TemplateVariableDeclaration, .Typedef:
					/**/

				case: // something else
					if current_root_context_idx.index == 0 { break ctx_stack }
					current_root_context_idx = get_scope(ctx, current_root_context_idx).parent
					continue ctx_stack
			}
		}
		
		return current_root_context_idx, current_context_idx, current_context
	}

	return
}

@(thread_local) current_scope_heap : ^[dynamic]Scope
@(thread_local) current_temp_scope_heap : ^[dynamic]Scope
fmt_scope_idx_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	node := transmute(^ScopeIndex)arg.data
	return fmt_name_ctx_idx(fi, node, verb)
}

fmt_name_ctx_idx :: proc(fi: ^fmt.Info, idx: ^ScopeIndex, verb: rune) -> bool
{
	if current_scope_heap == nil { return false }
	if idx == nil {
		io.write_string(fi.writer, "ScopeIndex <nil>")
		return true
	}
	if idx.index == 0 {
		io.write_string(fi.writer, "ScopeIndex 0")
		return true
	}


	fmt.wprintf(fi.writer, "ScopeIndex %v -> ", transmute(int) idx^)

	ctx := (idx.persistence == .Persistent ? current_scope_heap : current_temp_scope_heap)[idx.index]
	if len(ctx.definitions) == 0 {
		io.write_string(fi.writer, "<leaf>")
		return true
	}

	if fi.record_level > 3 {
		io.write_string(fi.writer, "{ ... }")
		return true
	}

	fmt.fmt_arg(fi, ctx , verb)
	return true
}




dump_context_stack :: proc(ctx : ^ConverterContext, scope_idx : ScopeIndex, name := "", indent := " ", return_at : ScopeIndex = {}, forward_only := false)
{
	scope := get_scope(ctx, scope_idx)
	
	old_opt := context.logger.options
	defer context.logger.options = old_opt 

	context.logger.options -= {.Line, .Procedure, .Short_File_Path, .Long_File_Path}
	
	if len(scope.definitions) == 0 {
		log.errorf("%-10v #%3v %v%v   -> %v | <leaf>", scope_idx.persistence, scope_idx.index, indent, name, scope.node >= 0 ? ctx.ast[scope.node].kind : AstNodeKind{});
	}
	else {
		log.errorf("%-10v #%3v %v%v   -> %v | %v children:", scope_idx.persistence, scope_idx.index, indent, name, scope.node >= 0 ? ctx.ast[scope.node].kind : AstNodeKind{}, len(scope.definitions));

		indent := str.concatenate({ indent, "  " }, context.temp_allocator)
		i := 0
		for name, didx in scope.definitions {
			if i > 20 {
				// log.errorf("<STOP !>")
				// return
			}
			dump_context_stack(ctx, didx, name, indent, scope_idx, forward_only)
			i += 1
		}
	}

	if scope.parent.index == 0 || scope.parent == return_at || forward_only { return }

	indent := str.concatenate({ indent, "  " }, context.temp_allocator)
	dump_context_stack(ctx, scope.parent, "<parent>", indent, scope_idx, forward_only)
}

ANONYMOUS_STRUCT_NAME_FORMAT :: "<AnonymousStructure%v>"


assert_node_kind :: proc(node : AstNode, kind : AstNodeKind, loc := #caller_location)
{
	if node.kind != kind {
		panic(fmt.tprintf("Expected %v, but got %#v.\n", kind, node), loc)
	}
}

cvt_append_type :: #force_inline proc(ctx : ^ConverterContext, frag : AstType) -> AstTypeIndex
{
	return transmute(AstTypeIndex) append_return_index(&ctx.type_heap, frag)
}

cvt_append_node :: #force_inline proc(ctx : ^ConverterContext, node : AstNode) -> AstNodeIndex
{
	return transmute(AstNodeIndex) append_return_index(&ctx.ast, node)
}


