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
	overload_resolver : map[string][dynamic]string,
	synthetic_struct_index : int,
}

convert_and_format :: proc(ctx : ^ConverterContext, implicit_names : [][2]string)
{
	ONE_INDENT :: "\t"

	if len(ctx.root_sequence) != 0 {
		current_ast = &ctx.ast
		current_types = &ctx.type_heap

		for pair in implicit_names {
			idx := cvt_append_node(ctx, { kind = .PreprocDefine, preproc_define = {
				name = { kind = .Identifier, source = pair[0] },
				expansion_tokens = { { kind = .Identifier, source = pair[1] } }
			}})
			ctx.ast[0].sequence.declared_names[pair[0]] = idx
		}



		str.write_string(&ctx.result, "package test\n\n")
		write_node_sequence(ctx, ctx.root_sequence, 0, "")
	}

	@(require_results)
	write_node :: proc(ctx : ^ConverterContext, current_node_index : AstNodeIndex, scope_node : AstNodeIndex, indent_str := "") -> (did_clobber : bool, requires_termination, requires_new_paragraph, swallow_paragraph : bool)
	{
		current_node := &ctx.ast[current_node_index]
		node_kind_switch: #partial switch current_node.kind {
			case .NewLine:
				str.write_byte(&ctx.result, '\n')

			case .Comment:
				str.write_string(&ctx.result, current_node.literal.source)

			case .Sequence:
				sequence := &current_node.sequence
				sequence.parent_scope = scope_node

				if sequence.braced { str.write_byte(&ctx.result, '{') }
				write_node_sequence(ctx, sequence.members[:], current_node_index, indent_str)
				if sequence.braced {
					if len(sequence.members) > 1 && ctx.ast[last(sequence.members[:])^].kind == .NewLine {
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
								//push_name(ctx, define.name.source, { parent = { index = 0, persistence = .Persistent }, node = current_node_index })
						}

					case:
						write_token_range(&ctx.result, define.expansion_tokens, "")
				}

				cvt_get_declared_names(ctx, 0)[define.name.source] = current_node_index

			case .Typedef:
				typedef := current_node.typedef

				type := &ctx.ast[typedef.type]
				#partial switch type.kind {
					case .Type:
						str.write_string(&ctx.result, typedef.name.source)
						str.write_string(&ctx.result, " :: ")
						//TODO maybe bake
						cvt_get_declared_names(ctx, scope_node)[typedef.name.source] = current_node_index
						#partial switch t in ctx.type_heap[type.type] {
							case AstTypeInlineStructure:
								ctx.ast[t].structure.parent_scope = scope_node
						}

						did_clobber = write_type(ctx, scope_node, type.type, indent_str, indent_str)

					case .Struct, .Union:
						if typedef.name.source != get_simple_name_string(ctx, type.structure.name) {
							// Only push this name if its not the same as they type itself, otherwise this will case lookup issues.
							// Also a typedefed named struct is the same as a normal struct declaration, we don't care about that detail.
							cvt_get_declared_names(ctx, scope_node)[typedef.name.source] = current_node_index
							
							if type.structure.name == 0 {
								if scope_node != 0 {
									write_complete_name_string(ctx, &ctx.result, scope_node)
									str.write_byte(&ctx.result, '_')
								}
								str.write_string(&ctx.result, typedef.name.source)
							}
							else {
								unimplemented("Struct typeddef aliasing not implemented")
							}
						}

						#partial switch scope := &ctx.ast[scope_node]; scope.kind {
							case .Struct, .Union, .Enum:
								type.structure.parent_scope = scope_node
								type.structure.parent_structure = scope_node

							case .FunctionDefinition:
								type.structure.parent_scope = scope_node
						}
						did_clobber, _, _, _ = write_node(ctx, typedef.type, scope_node, indent_str)

					case .FunctionDefinition:
						str.write_string(&ctx.result, typedef.name.source)
						cvt_get_declared_names(ctx, scope_node)[typedef.name.source] = current_node_index
						#partial switch scope := &ctx.ast[scope_node]; scope.kind {
							case .Struct, .Union, .Enum:
								type.structure.parent_scope = scope_node
								type.structure.parent_structure = scope_node

							case .FunctionDefinition:
								type.structure.parent_scope = scope_node
						}
						did_clobber, _, _, _ = write_node(ctx, typedef.type, scope_node, indent_str)

					case:
						unreachable()
				}

			case .Type:
				did_clobber = write_type(ctx, scope_node, current_node.type, indent_str, indent_str)

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

				cvt_get_declared_names(ctx, 0)[macro.name.source] = current_node_index 

			case .FunctionDefinition:
				current_node.function_def.parent_scope = scope_node
				if current_node.function_def.function_name != 0 {
					if ctx.ast[current_node.function_def.function_name].identifier.parent == 0 {
						#partial switch ctx.ast[scope_node].kind {
							case .Struct, .Union, .Enum, .Namespace:
								current_node.function_def.parent_structure = scope_node
						}
					}
					else {
						parent, _ := find_definition_for_name(ctx, scope_node, ctx.ast[current_node.function_def.function_name].identifier.parent)
						#partial switch ctx.ast[parent].kind {
							case .Struct, .Union, .Enum, .Namespace:
								current_node.function_def.parent_structure = parent
						}
					}
				}

				did_clobber = write_function(ctx, current_node_index, indent_str)

				swallow_paragraph = .IsForwardDeclared in current_node.function_def.flags 

			case .Struct, .Union:
				current_node.structure.parent_scope = scope_node
				if current_node.structure.name != 0 {
					if ctx.ast[current_node.structure.name].identifier.parent == 0 {
						#partial switch ctx.ast[scope_node].kind {
							case .Struct, .Union, .Enum:
								current_node.structure.parent_structure = scope_node
						}
					}
					else {
						parent, _ := find_definition_for_name(ctx, scope_node, ctx.ast[current_node.structure.name].identifier.parent)
						#partial switch ctx.ast[parent].kind {
							case .Struct, .Union, .Enum, .Namespace:
								current_node.structure.parent_structure = parent
						}
					}
				}

				member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				clobber, swallow, new_para := write_struct_union(ctx, current_node, current_node_index, indent_str, member_indent_str)
				did_clobber |= clobber
				swallow_paragraph |= swallow
				requires_new_paragraph |= new_para

			case .Enum:
				structure := &current_node.structure
				structure.parent_scope = scope_node
				if current_node.structure.name != 0 {
					if ctx.ast[current_node.structure.name].identifier.parent == 0 {
						#partial switch ctx.ast[scope_node].kind {
							case .Struct, .Union, .Enum:
								structure.parent_structure = scope_node
						}
					}
					else {
						parent, _ := find_definition_for_name(ctx, scope_node, ctx.ast[current_node.function_def.function_name].identifier.parent)
						#partial switch ctx.ast[parent].kind {
							case .Struct, .Union, .Enum, .Namespace:
								current_node.function_def.parent_structure = parent
						}
					}
				}

				forward_declared_idx, _ := try_find_definition_for_name(ctx, scope_node, structure.name, {.Type})
				if forward_declared_idx != 0 {
					forward_declaration := ctx.ast[forward_declared_idx]
					assert_node_kind(forward_declaration, .Enum)
	
					forward_comments := forward_declaration.structure.attached_comments
					inject_at(&structure.attached_comments, 0, ..forward_comments[:])
				}

				if structure.name != 0 {
					ident := ctx.ast[structure.name].identifier
					cvt_get_declared_names(ctx, scope_node)[ident.token.source] = current_node_index
				}

				if .IsForwardDeclared in structure.flags {
					swallow_paragraph = true
					return
				}

				if structure.name == 0 {
					synthetic_name := fmt.aprintf("E%v", ctx.synthetic_struct_index)
					ctx.synthetic_struct_index += 1

					ident := append_simple_identifier(ctx, { kind = .Identifier, source = synthetic_name })

					current_node = &ctx.ast[current_node_index]
					structure = &current_node.structure

					structure.name = ident
				}

				complete_structure_name := get_complete_name_string(ctx, current_node_index)

				// write directly, they are marked for skipping in write_sequence
				for aid in structure.attached_comments {
					c, _, _, _ := write_node(ctx, aid, current_node_index); did_clobber |= c
				}

				str.write_string(&ctx.result, complete_structure_name);
				str.write_string(&ctx.result, " :: enum ")

				if structure.base_type != {} {
					// base type uses parent scope for lookups
					did_clobber |= write_type(ctx, scope_node, structure.base_type, indent_str, indent_str)
				}
				else {
					str.write_string(&ctx.result, "i32")
				}

				str.write_string(&ctx.result, " {")

				bleed_scope := structure.parent_structure != 0 ? structure.parent_structure : structure.parent_scope

				member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				last_was_newline := false
				for cii := 0; cii < len(structure.members); cii += 1 {
					ci := structure.members[cii]
					#partial switch ctx.ast[ci].kind {
						case .VariableDeclaration:
							member := &ctx.ast[ci].var_declaration
							member.parent_structure = current_node_index

							structure.declared_names[member.var_name.source] = ci
							cvt_get_declared_names(ctx, bleed_scope)[member.var_name.source] = ci // enum names bleed to outer scope

							if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
							else { str.write_byte(&ctx.result, ' ') }
							str.write_string(&ctx.result, member.var_name.source)

							if member.initializer_expression != {} {
								str.write_string(&ctx.result, " = ")
								c, _, _, _ := write_node(ctx, member.initializer_expression, current_node_index); did_clobber |= c
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
				cvt_get_declared_names(ctx, scope_node)[vardef.var_name.source] = current_node_index

				did_clobber = write_variable_declaration(ctx, scope_node, current_node_index, indent_str, true)

				requires_termination = true

			case .LambdaDefinition:
				lambda := current_node.lambda_def
				function_ := &ctx.ast[lambda.underlying_function]
				function := &function_.function_def

				if len(lambda.captures) == 0 {
					c, _ := write_function_type(ctx, function_, lambda.underlying_function); did_clobber |= c

					switch len(function.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { }");

						case 1:
							str.write_string(&ctx.result, " { ");
							c, _, _, _ := write_node(ctx, function.body_sequence[0], current_node_index); did_clobber |= c
							str.write_string(&ctx.result, " }");

						case:
							str.write_byte(&ctx.result, '\n')

							str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{")
							body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
							write_node_sequence(ctx, function.body_sequence[:], current_node_index, body_indent_str)
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
								str.write_string(&ctx.result, c.identifier.token.source)
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
								str.write_string(&ctx.result, c.identifier.token.source)
								str.write_string(&ctx.result, " : ")

								capture_type, _ := resolve_type(ctx, ci, scope_node)
								did_clobber |= write_type(ctx, scope_node, capture_type, "", "")

								str.write_string(&ctx.result, ", ")

							case .ExprUnaryLeft:
								assert_eq(c.unary_left.operator, AstUnaryOp.AddressOf)
								
								str.write_string(&ctx.result, get_simple_name_string(ctx, c.unary_left.right))
								str.write_string(&ctx.result, " : ")
								
								capture_type, _ := resolve_type(ctx, c.unary_left.right, scope_node)
								str.write_byte(&ctx.result, '^')
								did_clobber |= write_type(ctx, scope_node, capture_type, "", "")

								str.write_string(&ctx.result, ", ")
						}
					}

					str.write_string(&ctx.result, indent_str)
					str.write_string(&ctx.result, "}\n")


					// function def
					str.write_string(&ctx.result, indent_str)
					str.write_string(&ctx.result, function_name)
					str.write_string(&ctx.result, " :: proc(")
					str.write_string(&ctx.result, "__l : ^")
					str.write_string(&ctx.result, captures_struct_name)
					for ai in function.arguments {
						str.write_string(&ctx.result, ", ")
						c, _, _, _ := write_node(ctx, ai, current_node_index); did_clobber |= c
					}
					str.write_byte(&ctx.result, ')')

					switch len(function.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { }")

						case 1:
							str.write_string(&ctx.result, " { using __l; ")
							c, _, _, _ := write_node(ctx, function.body_sequence[0], current_node_index); did_clobber |= c
							str.write_string(&ctx.result, " }\n")

						case:
							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "{\n")
							str.write_string(&ctx.result, member_indent_str)
							str.write_string(&ctx.result, "using __l")
							write_node_sequence(ctx, function.body_sequence[:], current_node_index, member_indent_str)

							if ctx.ast[last(function.body_sequence)^].kind == .NewLine { str.write_string(&ctx.result, indent_str) }
							str.write_string(&ctx.result, "}\n")
					}

				}
				requires_termination = true

			case .Return:
				str.write_string(&ctx.result, "return")

				if current_node.return_.expression != {} {
					str.write_byte(&ctx.result, ' ')
					did_clobber, _, _, _ = write_node(ctx, current_node.return_.expression, scope_node)
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
				operator_switch: switch current_node.unary_left.operator {
					case .AddressOf, .Plus, .Minus, .Invert:
						str.write_byte(&ctx.result, byte(current_node.unary_left.operator))
						did_clobber, _, _, _ = write_node(ctx, current_node.unary_left.right, scope_node)

					case .Not:
						// convert simple negations into type correct comparisons
						type, _ := resolve_type(ctx, current_node.unary_left.right, scope_node)
						if type > 0 { // @hack :ExplicitBuiltinTypes
			
							requires_brackets := true
							condition := current_node.unary_left.right
							#partial switch ctx.ast[condition].kind {
								case .Identifier, .ExprBacketed, .ExprIndex, .ExprUnaryLeft, .ExprUnaryRight, .MemberAccess, .FunctionCall:
									requires_brackets = false
							}
			
							#partial switch frag in ctx.type_heap[type] {
								case (AstTypePrimitive):
									if frag.fragments[0].source == "bool" {
										/* ok, can write the given type */
										break
									}
									else {
										if requires_brackets { str.write_byte(&ctx.result, '(') }
										did_clobber, _, _, _ = write_node(ctx, condition, scope_node)
										if requires_brackets { str.write_byte(&ctx.result, ')') }
										str.write_string(&ctx.result, " == 0")
										break operator_switch
									}
			
								case (AstTypePointer):
									if requires_brackets { str.write_byte(&ctx.result, '(') }
									did_clobber, _, _, _ = write_node(ctx, condition, scope_node)
									if requires_brackets { str.write_byte(&ctx.result, ')') }
									str.write_string(&ctx.result, " == nil")
									break operator_switch
			
								case (AstTypeFragment):
									if requires_brackets { str.write_byte(&ctx.result, '(') }
									did_clobber, _, _, _ = write_node(ctx, condition, scope_node)
									if requires_brackets { str.write_byte(&ctx.result, ')') }
									str.write_string(&ctx.result, is_imgui_scalar(frag.identifier.source) ? " == 0" : " == {}")
									break operator_switch

								case (AstTypeInlineStructure):
									if requires_brackets { str.write_byte(&ctx.result, '(') }
									did_clobber, _, _, _ = write_node(ctx, condition, scope_node)
									if requires_brackets { str.write_byte(&ctx.result, ')') }
									str.write_string(&ctx.result, " == {}")
									break operator_switch
							}
						}

						str.write_byte(&ctx.result, '!')
						c, _, _, _ := write_node(ctx, current_node.unary_left.right, scope_node); did_clobber |= c

					case .Dereference:
						inspected_expression := current_node.unary_left.right
						multipointer_test_loop: for {
							expr := ctx.ast[inspected_expression];
							#partial switch expr.kind {
								case .ExprBacketed:
									inspected_expression = expr.inner
									continue multipointer_test_loop

								case .ExprBinary:
									tl, nl := resolve_type(ctx, expr.binary.left, scope_node)
									tr, nr := resolve_type(ctx, expr.binary.right, scope_node)
									etype, _ := get_resulting_type_for_binary_expr(tl, nl, tr, nr)
									assert(is_variant(ctx.type_heap[etype], AstTypePointer))

									if etype == tl && ctx.ast[expr.binary.left].kind != .ExprBinary {
										c, _, _, _ := write_node(ctx, expr.binary.left, scope_node); did_clobber |= c
										str.write_byte(&ctx.result, '[')
										c, _, _, _ = write_node(ctx, expr.binary.right, scope_node); did_clobber |= c
										str.write_byte(&ctx.result, ']')
									}
									else if etype == tr && ctx.ast[expr.binary.right].kind != .ExprBinary {
										c, _, _, _ := write_node(ctx, expr.binary.right, scope_node); did_clobber |= c
										str.write_byte(&ctx.result, '[')
										c, _, _, _ = write_node(ctx, expr.binary.left, scope_node); did_clobber |= c
										str.write_byte(&ctx.result, ']')
									}
									else {
										break multipointer_test_loop
									}

									break node_kind_switch

								case:
									break multipointer_test_loop
							}
							break
						}

						c, _, _, _ := write_node(ctx, current_node.unary_left.right, scope_node); did_clobber |= c
						str.write_byte(&ctx.result, '^')

					case .Increment:
						str.write_string(&ctx.result, "pre_incr(&")
						did_clobber, _, _, _ = write_node(ctx, current_node.unary_left.right, scope_node)
						str.write_byte(&ctx.result, ')')

					case .Decrement:
						str.write_string(&ctx.result, "pre_decr(&")
						did_clobber, _, _, _ = write_node(ctx, current_node.unary_left.right, scope_node)
						str.write_byte(&ctx.result, ')')
				}

				requires_termination = true

			case .ExprUnaryRight:
				#partial switch current_node.unary_right.operator {
					case .Increment:
						str.write_string(&ctx.result, "post_incr(&")
						did_clobber, _, _, _ = write_node(ctx, current_node.unary_right.left, scope_node)
						str.write_byte(&ctx.result, ')')

					case .Decrement:
						str.write_string(&ctx.result, "post_decr(&")
						did_clobber, _, _, _ = write_node(ctx, current_node.unary_right.left, scope_node)
						str.write_byte(&ctx.result, ')')
				}

				requires_termination = true

			case .ExprBinary:
				requires_termination = true

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
				// split chain assignments into individual ones
				// a = b = c    ->     b = c; a = b
				if right.kind == .ExprBinary {
					#partial switch right.binary.operator {
						case .Assign, .AssignAdd, .AssignBitAnd, .AssignBitOr, .AssignBitXor, .AssignDivide, .AssignModulo, .AssignMultiply, .AssignShiftLeft, .AssignShiftRight, .AssignSubtract:
							c, _, _, _ := write_node(ctx, binary.right, scope_node); did_clobber |= c
							str.write_string(&ctx.result, "; ")

							c, _, _, _ = write_node(ctx, binary.left, scope_node); did_clobber |= c
							str.write_byte(&ctx.result, ' ')
							write_op(ctx, binary.operator)
							str.write_byte(&ctx.result, ' ')
							c, _, _, _ = write_node(ctx, right.binary.left, scope_node); did_clobber |= c

							break node_kind_switch
					}
				}

				#partial switch binary.operator {
					case .Assign:
						left_type_idx, left_type_ctx := resolve_type(ctx, binary.left, scope_node)
						left_type := ctx.type_heap[left_type_idx]
						// short circuit pointer to ref assignments and vice versa
						if right.kind == .ExprUnaryLeft {
							if right.unary_left.operator == .Dereference {
								right_type_idx, _ := resolve_type(ctx, right.unary_left.right, scope_node)
								right_type := ctx.type_heap[right_type_idx]

								if rptr, is_ptr := right_type.(AstTypePointer); is_ptr && .Reference not_in rptr.flags { // ? = *p
									if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference in lptr.flags { // r = *p
										c, _, _, _ := write_node(ctx, binary.left, scope_node); did_clobber |= c
										str.write_string(&ctx.result, " = ")
										c, _, _, _ = write_node(ctx, right.unary_left.right, scope_node); did_clobber |= c
										break node_kind_switch
									}
								}
							}
							else if right.unary_left.operator == .AddressOf && ctx.ast[right.unary_left.right].kind != .ExprIndex {
								right_type_idx, _ := resolve_type(ctx, right.unary_left.right, scope_node)
								right_type := ctx.type_heap[right_type_idx]

								if rptr, is_ptr := right_type.(AstTypePointer); is_ptr && .Reference in rptr.flags { // ? = &r
									if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference not_in lptr.flags { // p = &r
										c, _, _, _ := write_node(ctx, binary.left, scope_node); did_clobber |= c
										str.write_string(&ctx.result, " = ")
										c, _, _, _ = write_node(ctx, right.unary_left.right, scope_node); did_clobber |= c
										break node_kind_switch
									}
								}
							}
						}

						// deref assign to references   r = v  -> p^ = v, except when its a[i] = v
						if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference in lptr.flags && ctx.ast[binary.left].kind != .ExprIndex {
							c, _, _, _ := write_node(ctx, binary.left, scope_node); did_clobber |= c
							str.write_string(&ctx.result, "^ = ")
							c, _, _, _ = write_node(ctx, binary.right, scope_node); did_clobber |= c
							break node_kind_switch
						}

					// rewrite
					// a == 0    ->   a == nil    if a is a pointer type
					// a == 0    ->   a == {}    if a is not a numeric type
					case .Equals, .NotEquals:
						eq := binary.operator == .Equals

						if nl := &ctx.ast[binary.left]; \
								nl.kind == .LiteralInteger && nl.literal.source == "0" {
							type, _ := resolve_type(ctx, binary.right, scope_node)
							if type > 0 { // @hack :ExplicitBuiltinTypes
								#partial switch frag in ctx.type_heap[type] {
									case (AstTypePointer):
										str.write_string(&ctx.result, eq ? "nil == " : "nil != ")
										did_clobber, _, _, _ = write_node(ctx, binary.right, scope_node)
										break node_kind_switch

									case (AstTypeFragment):
										str.write_string(&ctx.result, is_imgui_scalar(frag.identifier.source) ? "0" : "{}")
										str.write_string(&ctx.result, eq ? " == " : " != ")
										did_clobber, _, _, _ = write_node(ctx, binary.right, scope_node)
										break node_kind_switch

									case (AstTypeInlineStructure):
										str.write_string(&ctx.result, eq ? "{} == " : "{} != ")
										did_clobber, _, _, _ = write_node(ctx, binary.right, scope_node)
										break node_kind_switch
								}
							}
						}
						else if nl := &ctx.ast[binary.right]; \
								nl.kind == .LiteralInteger && nl.literal.source == "0" {

							type, _ := resolve_type(ctx, binary.left, scope_node)
							if type > 0 { // @hack :ExplicitBuiltinTypes
								#partial switch frag in ctx.type_heap[type] {
									case (AstTypePointer):
										did_clobber, _, _, _ = write_node(ctx, binary.left, scope_node)
										str.write_string(&ctx.result, eq ? " == nil" : " != nil")
										break node_kind_switch

									case (AstTypeFragment):
										did_clobber, _, _, _ = write_node(ctx, binary.left, scope_node)
										if is_imgui_scalar(frag.identifier.source) {
											str.write_string(&ctx.result, eq ? " == 0" : " != 0")
										}
										else {
											str.write_string(&ctx.result, eq ? " == {}" : " != {}")
										}
										break node_kind_switch

									case (AstTypeInlineStructure):
										did_clobber, _, _, _ = write_node(ctx, binary.left, scope_node)
										str.write_string(&ctx.result, eq ? " == {}" : " != {}")
										break node_kind_switch
								}
							}
						}
				}

				// default binary expression     a op b
				c, _, _, _ := write_node(ctx, binary.left, scope_node); did_clobber |= c
				str.write_byte(&ctx.result, ' ')
				write_op(ctx, binary.operator)
				str.write_byte(&ctx.result, ' ')
				c, _, _, _ = write_node(ctx, binary.right, scope_node); did_clobber |= c


			case .ExprBacketed:
				str.write_byte(&ctx.result, '(')
				did_clobber, _, _, _ = write_node(ctx, current_node.inner, scope_node)
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
					did_clobber |= write_type(ctx, scope_node, current_node.cast_.type, indent_str, indent_str)
					str.write_string(&ctx.result, ") ")
				}

				c, _, _, _ := write_node(ctx, current_node.cast_.expression, scope_node); did_clobber |= c

				requires_termination = true

			case .MemberAccess:
				member := ctx.ast[current_node.member_access.member]

				expression_type, expression_type_node := resolve_type(ctx, current_node.member_access.expression, scope_node)

				if member.kind == .FunctionCall {
					fncall := member.function_call

					structure_name := get_simple_name_string(ctx, expression_type_node)

					fn_name_expr := ctx.ast[member.function_call.expression]
					assert_node_kind(fn_name_expr, .Identifier)
					fn_name := fn_name_expr.identifier.token.source

					if structure_name == fn_name {
						str.write_string(&ctx.result, member.function_call.is_destructor ? "deinit" : "init")
					}
					else {
						if fn_name == "init" && is_variant(ctx.type_heap[expression_type], AstTypePrimitive) {
							c, _, _, _ := write_node(ctx, current_node.member_access.expression, scope_node); did_clobber |= c
							str.write_string(&ctx.result, " = ")
							c, _, _, _ = write_node(ctx, fncall.arguments[0], scope_node); did_clobber |= c

							requires_termination = true
							break
						}
						else {
							expression_type_node := maybe_follow_typedef(ctx, scope_node /*@correctness wrong*/, expression_type_node)

							if containing_scope_idx := cvt_get_parent_scope(ctx, expression_type_node)^; containing_scope_idx != 0 {
								containing_scope := ctx.ast[containing_scope_idx]
								if containing_scope.kind == .Namespace {
									str.write_string(&ctx.result, containing_scope.namespace.name.source)
									str.write_byte(&ctx.result, '_')
								}
	
								write_folded_identifier(ctx, &ctx.result, member.function_call.expression)
							}
							else{
								write_folded_identifier(ctx, &ctx.result, member.function_call.expression)
							}
						}
					}

					str.write_byte(&ctx.result, '(')
					for aidx in fncall.template_arguments {
						c, _, _, _ := write_node(ctx, aidx, scope_node); did_clobber |= c
						str.write_string(&ctx.result, ", ")
					}
					if !current_node.member_access.through_pointer { str.write_byte(&ctx.result, '&') }
					c, _, _, _ := write_node(ctx, current_node.member_access.expression, scope_node); did_clobber |= c
					for aidx in fncall.arguments {
						str.write_string(&ctx.result, ", ")
						c, _, _, _ = write_node(ctx, aidx, scope_node); did_clobber |= c
					}
					str.write_byte(&ctx.result, ')')
				}
				else { // field access
					did_clobber, _, _, _ = write_node(ctx, current_node.member_access.expression, scope_node)
					str.write_byte(&ctx.result, '.')

					expression_type_node := maybe_follow_typedef(ctx, scope_node /*@correctness wrong*/, expression_type_node)

					member_definition_idx, _ := try_find_definition_for_name(ctx, expression_type_node, current_node.member_access.member)

					expr_type := ctx.ast[expression_type_node]
					if expr_type.kind != .Struct && expr_type.kind != .Union && expr_type.kind != .Enum \
						&& expr_type.kind != .TemplateVariableDeclaration {
						panic(fmt.tprintf("Unexpected expression type accessing %v on %#v", member.identifier, expr_type))
					}


					if member_definition_idx != 0 {
						str.write_string(&ctx.result, get_simple_name_string(ctx, member_definition_idx))
					}
					else {
						log.warn("failed to resolve type for", member.identifier) // fix for incomplete generic resolver
						write_folded_identifier(ctx, &ctx.result, current_node.member_access.member)
					}
				}

				requires_termination = true

			case .ExprIndex:
				c, _, _, _ := write_node(ctx, current_node.index.array_expression, scope_node); did_clobber |= c
				str.write_byte(&ctx.result, '[')
				c, _, _, _ = write_node(ctx, current_node.index.index_expression, scope_node); did_clobber |= c
				str.write_byte(&ctx.result, ']')

				requires_termination = true

			case .ExprTenary:
				did_clobber |= write_condition_maybe_translated(ctx, scope_node, current_node.tenary.condition)
				str.write_string(&ctx.result, " ? ")
				c, _, _, _ := write_node(ctx, current_node.tenary.true_expression, scope_node); did_clobber |= c
				str.write_string(&ctx.result, " : ")
				c, _, _, _ = write_node(ctx, current_node.tenary.false_expression, scope_node); did_clobber |= c

				requires_termination = true

			case .Identifier:
				definition_index, parent_index := find_definition_for_name(ctx, scope_node, current_node_index)
				definition := ctx.ast[definition_index]
				parent := ctx.ast[parent_index]

				if definition.kind != .TemplateVariableDeclaration && (parent.kind == .Struct || parent.kind == .Union) && .Static not_in definition.var_declaration.flags {
					str.write_string(&ctx.result, "this.")
				}
				else if parent.kind == .Enum && scope_node != parent_index { // prefix the enum, but not if we are using it within the same enum
					write_complete_name_string(ctx, &ctx.result, parent_index)
					str.write_byte(&ctx.result, '.')
					str.write_string(&ctx.result, current_node.identifier.token.source)

					requires_termination = true
					break	
				}

				write_folded_identifier(ctx, &ctx.result, current_node_index)

				requires_termination = true

			case .FunctionCall:
				fncall := current_node.function_call

				definition : AstNodeIndex
				if expr := ctx.ast[fncall.expression]; expr.kind == .Identifier {
					// convert some top level function names
					simple_name := get_simple_name_string(ctx, expr)
					switch simple_name {
						case "sizeof":
							str.write_string(&ctx.result, "size_of")

						case "offsetof":
							assert_eq(len(fncall.arguments), 2)

							str.write_string(&ctx.result, "offset_of")
							str.write_byte(&ctx.result, '(')
							
							c, _, _, _ := write_node(ctx, fncall.arguments[0], scope_node); did_clobber |= c
							
							str.write_string(&ctx.result, ", ")

							ident := ctx.ast[fncall.arguments[1]].identifier
							assert_eq(ident.parent, 0)
							str.write_string(&ctx.result, ident.token.source)
							
							str.write_byte(&ctx.result, ')')

							requires_termination = true	
							break node_kind_switch

						case:
							definition, _ = try_find_definition_for_name(ctx, scope_node, fncall.expression)
							if definition != 0 {
								write_complete_name_string(ctx, &ctx.result, definition)
							}
							else {
								str.write_string(&ctx.result, simple_name)
							}
					}
				}
				else {
					c, _, _, _ := write_node(ctx, fncall.expression, scope_node); did_clobber |= c
				}
				str.write_byte(&ctx.result, '(')
				arg_index := 0
				for aidx in fncall.template_arguments {
					if arg_index != 0 { str.write_string(&ctx.result, ", ") }
					c, _, _, _ := write_node(ctx, aidx, scope_node); did_clobber |= c
					arg_index += 1
				}
				if definition != 0 {
					definition_node := ctx.ast[definition]
					if definition_node.kind == .FunctionDefinition && .Static not_in definition_node.function_def.flags {
						#partial switch ctx.ast[definition_node.function_def.parent_structure].kind {
							case .Struct, .Union:
								if arg_index != 0 { str.write_string(&ctx.result, ", ") }
								str.write_string(&ctx.result, "this")
								arg_index += 1
						}
					}
				}
				for aidx in fncall.arguments {
					if arg_index != 0 { str.write_string(&ctx.result, ", ") }
					c, _, _, _ := write_node(ctx, aidx, scope_node); did_clobber |= c
					arg_index += 1
				}
				str.write_byte(&ctx.result, ')')

				requires_termination = true

			case .CompoundInitializer:
				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)

				body := current_node.compound_initializer.values[:]
				str.write_byte(&ctx.result, '{')
				write_node_sequence(ctx, body, scope_node, body_indent_str, termination = ",", always_terminate = true)
				if len(body) > 0 && ctx.ast[last(body)^].kind == .NewLine { str.write_string(&ctx.result, indent_str) }
				str.write_byte(&ctx.result, '}')

				requires_termination = true

			case .Namespace:
				ns := &current_node.namespace
				ns.parent_scope = scope_node

				if ns.name.source != "" {
					// try merging the namespace with an existing one
					previous_declaration, _ := try_find_definition_for_name_preflattened(ctx, scope_node, { ns.name.source }, { .Namespace })
					if previous_declaration != 0 {
						prev := &ctx.ast[previous_declaration].namespace
						//NOTE(Rennorb): Future writes to this namespace invalidate the old map, but I think this is fine?
						ns.declared_names = prev.declared_names
						ns.merged_member_sequence = prev.merged_member_sequence
					}

					cvt_get_declared_names(ctx, scope_node)[ns.name.source] = current_node_index
				}

				append(&ns.merged_member_sequence, ..ns.member_sequence[:])

				write_node_sequence(ctx, trim_newlines_start(ctx, ns.member_sequence[:]), current_node_index, indent_str)

				swallow_paragraph = true


			case .For, .While, .Do:
				loop := &current_node.loop
				loop.parent_scope = scope_node

				condition_node : AstNode

				str.write_string(&ctx.result, "for")
				if !loop.is_foreach {
					if len(loop.initializer) != 0 || len(loop.loop_statement) != 0 {
						str.write_byte(&ctx.result, ' ')
						if len(loop.initializer) != 0 { did_clobber |= write_node_sequence_merged(ctx, loop.initializer[:], current_node_index) }
						str.write_string(&ctx.result, "; ")
						if len(loop.condition) != 0 {
							assert_eq(len(loop.condition), 1)
							did_clobber |= write_condition_maybe_translated(ctx, current_node_index, loop.condition[0])
						}
						str.write_string(&ctx.result, "; ")
						if len(loop.loop_statement) != 0 { did_clobber |= write_node_sequence_merged(ctx, loop.loop_statement[:], current_node_index) }
					}
					else if len(loop.condition) != 0 && current_node.kind != .Do {
						assert_eq(len(loop.condition), 1)
						condition_node = ctx.ast[loop.condition[0]]
						if condition_node.kind != .VariableDeclaration {
							str.write_byte(&ctx.result, ' ')
							did_clobber |= write_condition_maybe_translated(ctx, current_node_index, loop.condition[0])
						}
					}
				}
				else { // foreach
					str.write_byte(&ctx.result, ' ')
					
					assert_eq(len(loop.initializer), 1)
					initializer := ctx.ast[loop.initializer[0]]
					assert_node_kind(initializer, .VariableDeclaration)
					str.write_string(&ctx.result, initializer.var_declaration.var_name.source)

					loop.declared_names[initializer.var_declaration.var_name.source] = loop.initializer[0]
					
					str.write_string(&ctx.result, " in ")
					
					assert_eq(len(loop.loop_statement), 1)
					c, _, _, _ := write_node(ctx, loop.loop_statement[0], current_node_index); did_clobber |= c
				}

				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				if len(loop.condition) != 0 && current_node.kind == .Do {
					assert_eq(len(loop.condition), 1)
					switch len(loop.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { if !(")
							did_clobber |= write_condition_maybe_translated(ctx, current_node_index, loop.condition[0])
							str.write_string(&ctx.result, ") { break } }")
	
						case 1:
							str.write_string(&ctx.result, " {\n")

							str.write_string(&ctx.result, body_indent_str)
							c, _, _, _ := write_node(ctx, loop.body_sequence[0], current_node_index); did_clobber |= c

							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, body_indent_str)
							str.write_string(&ctx.result, "if !(")
							did_clobber |= write_condition_maybe_translated(ctx, current_node_index, loop.condition[0])
							str.write_string(&ctx.result, ") { break }\n")

							str.write_string(&ctx.result, indent_str)
							str.write_byte(&ctx.result, '}')
	
						case:
							str.write_string(&ctx.result, " {")

							write_node_sequence(ctx, loop.body_sequence[:], current_node_index, body_indent_str)

							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, body_indent_str)
							str.write_string(&ctx.result, "if !(")
							did_clobber |= write_condition_maybe_translated(ctx, current_node_index, loop.condition[0])
							str.write_string(&ctx.result, ") { break }\n")

							str.write_string(&ctx.result, indent_str)
							str.write_byte(&ctx.result, '}')
					}
				}
				else if condition_node.kind == .VariableDeclaration {
					str.write_string(&ctx.result, " {\n")

					str.write_string(&ctx.result, body_indent_str)
					c, _, _, _ := write_node(ctx, loop.condition[0], current_node_index); did_clobber |= c
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

							write_node_sequence(ctx, loop.body_sequence[:], current_node_index, body_indent_str)

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
							c, _, _, _ := write_node(ctx, loop.body_sequence[0], current_node_index); did_clobber |= c
							str.write_string(&ctx.result, " }")

						case:
							str.write_string(&ctx.result, " {")

							write_node_sequence(ctx, loop.body_sequence[:], current_node_index, body_indent_str)

							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "}")
					}
				}

				requires_termination = true
				requires_new_paragraph = true

			case .Branch:
				requires_termination = true

				branch := &current_node.branch
				branch.parent_scope = scope_node

				str.write_string(&ctx.result, "if ")
				switch len(branch.condition) {
					case 1:
						if ctx.ast[branch.condition[0]].kind == .VariableDeclaration {
							// These nodes are written within the branch scope because they are valid for the body of the branch only
							c, _, _, _ := write_node(ctx, branch.condition[0], current_node_index); did_clobber |= c
							str.write_string(&ctx.result, "; ")
							str.write_string(&ctx.result, ctx.ast[branch.condition[0]].var_declaration.var_name.source)
						}
						else {
							did_clobber |= write_condition_maybe_translated(ctx, current_node_index, branch.condition[0])
						}

					case 2:
						if ctx.ast[branch.condition[0]].kind == .VariableDeclaration && ctx.ast[branch.condition[1]].kind != .VariableDeclaration {
							// These nodes are written within the branch scope because they are valid for the body of the branch only
							c, _, _, _ := write_node(ctx, branch.condition[0], current_node_index); did_clobber |= c
							str.write_string(&ctx.result, "; ")
							did_clobber |= write_condition_maybe_translated(ctx, current_node_index, branch.condition[1])
							break
						}

					fallthrough

					case:
						panic(fmt.tprintf("Cant convert branch condition %#v", branch.condition))
				}

				body_indent_str : string

				if branch.true_branch == 0 {
					str.write_string(&ctx.result, " { }")
					return
				}

				if did_clobber { branch = &ctx.ast[current_node_index].branch }

				if true_branch := &ctx.ast[branch.true_branch]; true_branch.kind != .Sequence {
					str.write_string(&ctx.result, " { ")
					c, _, _, _ := write_node(ctx, branch.true_branch, current_node_index); did_clobber |= c
					str.write_string(&ctx.result, " }")
				}
				else {
					true_branch.sequence.parent_scope = current_node_index
					switch len(true_branch.sequence.members) {
						case 0:
							str.write_string(&ctx.result, " { }")
	
						case 1:
							str.write_string(&ctx.result, " { ")
							c, _, _, _ := write_node(ctx, true_branch.sequence.members[0], current_node_index); did_clobber |= c
							str.write_string(&ctx.result, " }")
	
						case:
							str.write_string(&ctx.result, " {")
							body_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
							write_node_sequence(ctx, true_branch.sequence.members[:], branch.true_branch, body_indent_str)
							if ctx.ast[last(true_branch.sequence.members[:])^].kind == .NewLine {
								str.write_string(&ctx.result, indent_str);
							}
							str.write_byte(&ctx.result, '}')
					}
				}

				if branch.false_branch == 0 {
					return
				}

				if did_clobber { branch = &ctx.ast[current_node_index].branch }

				@(require_results)
				write_single_else_detect_chaining :: proc(ctx : ^ConverterContext, scope_node : AstNodeIndex, node : AstNodeIndex, kind : AstNodeKind, indent_str : string) -> (did_clobber : bool)
				{
					if ctx.ast[node].kind == .Branch { // else if chaining
						str.write_byte(&ctx.result, '\n')
						str.write_string(&ctx.result, indent_str)
						str.write_string(&ctx.result, "else ")
						did_clobber, _, _, _ := write_node(ctx, node, scope_node, indent_str)
					}
					else {
						str.write_byte(&ctx.result, '\n')
						str.write_string(&ctx.result, indent_str)
						str.write_string(&ctx.result, "else { ")
						did_clobber, _, _, _ = write_node(ctx, node, scope_node)
						str.write_string(&ctx.result, " }")
					}
					return
				}

				if false_branch := &ctx.ast[branch.false_branch]; false_branch.kind != .Sequence {
					did_clobber |= write_single_else_detect_chaining(ctx, current_node_index, branch.false_branch, false_branch.kind, indent_str)
				}
				else {
					false_branch.sequence.parent_scope = current_node_index
					switch len(false_branch.sequence.members) {
						case 0:
							 /**/
	
						case 1:
							else_idx := false_branch.sequence.members[0]
							did_clobber |= write_single_else_detect_chaining(ctx, current_node_index, else_idx, ctx.ast[else_idx].kind, indent_str)
	
						case:
							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "else {")
							if body_indent_str == "" { body_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator) }
							write_node_sequence(ctx, false_branch.sequence.members[:], branch.false_branch, body_indent_str)
							str.write_string(&ctx.result, indent_str)
							str.write_byte(&ctx.result, '}')
					}
				}


			case .Switch:
				switch_ := current_node.switch_

				str.write_string(&ctx.result, "switch ")
				c, _, _, _ := write_node(ctx, switch_.expression, scope_node); did_clobber |= c

				str.write_string(&ctx.result, " {\n")
				
				case_body_indent_str := str.concatenate({ indent_str, ONE_INDENT, ONE_INDENT }, context.temp_allocator)
				case_indent_str := case_body_indent_str[:len(case_body_indent_str) - len(ONE_INDENT)]

				for case_, case_i in switch_.cases {
					str.write_string(&ctx.result, case_indent_str)
					str.write_string(&ctx.result, "case")
					if case_.match_expression != {} {
						str.write_byte(&ctx.result, ' ')
						c, _, _, _ := write_node(ctx, case_.match_expression, scope_node); did_clobber |= c
					}
					str.write_byte(&ctx.result, ':')

					write_node_sequence(ctx, case_.body_sequence[:], scope_node, case_body_indent_str)

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
					c, _, _, _ := write_node(ctx, aidx, scope_node); did_clobber |= c
				}
				str.write_byte(&ctx.result, ')')

				requires_termination = true

			case .UsingNamespace:
				namespace, _ := find_definition_for_name(ctx, scope_node, current_node_index, { .Namespace })
				
				// assume we are already in a scope_node, its time to pull in namespace members
				current_scope := cvt_get_declared_names(ctx, scope_node)
				for def_name, def in cvt_get_declared_names(ctx, namespace) {
					current_scope[def_name] = def
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

	@(require_results)
	write_node_sequence_merged :: proc(ctx : ^ConverterContext, sequence : []AstNodeIndex, scope_node : AstNodeIndex) -> (did_clobber : bool)
	{
		if len(sequence) < 2 {
			c, _, _, _ := write_node(ctx, sequence[0], scope_node); did_clobber |= c
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
					cvt_get_declared_names(ctx, scope_node)[decl.var_name.source] = si
				}

				str.write_string(&ctx.result, " : ")

				did_clobber |= write_type(ctx, scope_node, type, "", "")

				str.write_string(&ctx.result, " = ")

				for si, i in sequence {
					decl := &ctx.ast[si].var_declaration
					if i > 0 { str.write_string(&ctx.result, ", ") }
					if decl.initializer_expression != {} {
						c, _, _, _ := write_node(ctx, decl.initializer_expression, scope_node); did_clobber |= c
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
									c, _, _, _ := write_node(ctx, binary.left, scope_node); did_clobber |= c

								case:
									panic(fmt.tprintf("Invalid binary operator for sequence merge: ", binary.operator))
							}

						case .ExprUnaryLeft:
							unary := &ctx.ast[si].unary_left
							#partial switch unary.operator {
								case .Decrement:
									fallthrough
								case .Increment:
									c, _, _, _ := write_node(ctx, unary.right, scope_node); did_clobber |= c
								case:
									panic(fmt.tprintf("Invalid unary left operator for sequence merge: ", unary.operator))
							}

						case .ExprUnaryRight:
							unary := &ctx.ast[si].unary_right
							#partial switch unary.operator {
								case .Decrement:
									fallthrough
								case .Increment:
									c, _, _, _ := write_node(ctx, unary.left, scope_node); did_clobber |= c
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
									c, _, _, _ := write_node(ctx, binary.right, scope_node); did_clobber |= c

								case .AssignAdd, .AssignSubtract, .AssignDivide, .AssignModulo, .AssignBitAnd, .AssignBitOr, .AssignBitXor, .AssignMultiply:
									c, _, _, _ := write_node(ctx, binary.left, scope_node); did_clobber |= c
									str.write_byte(&ctx.result, ' ');
									str.write_byte(&ctx.result, cast(byte) (binary.operator - cast(AstBinaryOp) TokenKind._MirroredBinaryOperators));
									str.write_byte(&ctx.result, ' ')
									c, _, _, _ = write_node(ctx, binary.right, scope_node); did_clobber |= c

								case .AssignShiftLeft, .AssignShiftRight:
									c, _, _, _ := write_node(ctx, binary.left, scope_node); did_clobber |= c
									str.write_string(&ctx.result, binary.operator == .AssignShiftLeft ? " << " : " >> ")
									c, _, _, _ = write_node(ctx, binary.right, scope_node); did_clobber |= c

								case:
									panic(fmt.tprintf("Invalid binary operator for sequence merge: ", binary.operator))
							}

						case .ExprUnaryLeft:
							unary := &ctx.ast[si].unary_left
							#partial switch unary.operator {
								case .Decrement:
									c, _, _, _ := write_node(ctx, unary.right, scope_node); did_clobber |= c
									str.write_string(&ctx.result, " - 1")

								case .Increment:
									c, _, _, _ := write_node(ctx, unary.right, scope_node); did_clobber |= c
									str.write_string(&ctx.result, " + 1")

								case:
									panic(fmt.tprintf("Invalid unary left operator for sequence merge: ", unary.operator))
							}

						case .ExprUnaryRight:
							unary := &ctx.ast[si].unary_right
							#partial switch unary.operator {
								case .Decrement:
									c, _, _, _ := write_node(ctx, unary.left, scope_node); did_clobber |= c
									str.write_string(&ctx.result, " - 1")

								case .Increment:
									c, _, _, _ := write_node(ctx, unary.left, scope_node); did_clobber |= c
									str.write_string(&ctx.result, " + 1")

								case:
									panic(fmt.tprintf("Invalid unary left operator for sequence merge: ", unary.operator))
							}
					}
				}

			case:
				panic(fmt.tprintf("Invalid node kind for sequence merge: ", kind))
		}
		return
	}

	write_node_sequence :: proc(ctx : ^ConverterContext, sequence : []AstNodeIndex, elements_scope_node : AstNodeIndex, indent_str : string, termination := ";", always_terminate := false)
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

				write_node_sequence(ctx, sequence[cii + 1:], elements_scope_node, member_indent_str, termination, always_terminate)

				str.write_byte(&ctx.result, '\n')
				str.write_string(&ctx.result, member_indent_str)
				str.write_string(&ctx.result, "break\n")
				str.write_string(&ctx.result, indent_str)
				str.write_string(&ctx.result, "}\n")

				return
			}

			_, previous_requires_termination, previous_requires_new_paragraph, should_swallow_paragraph = write_node(ctx, ci, elements_scope_node, indent_str)
			previous_node_kind = node_kind
		}
	}

	@(require_results)
	write_struct_union :: proc(ctx : ^ConverterContext, structure_node : ^AstNode, structure_node_index : AstNodeIndex, indent_str, member_indent_str : string) -> (did_clobber : bool, swallow_paragraph, requires_new_paragraph : bool)
	{
		structure := &structure_node.structure

		complete_structure_name := structure.name != 0 ? get_complete_name_string(ctx, structure_node^, context.temp_allocator) : ""

		parent_scope := structure.parent_scope

		forward_declared_name, _ := try_find_definition_for_name(ctx, parent_scope, structure.name)
		if forward_declared_name != 0 {
			forward_declaration := ctx.ast[forward_declared_name]
			if forward_declaration.kind != .Struct && forward_declaration.kind != .Union {
				panic(fmt.tprintf("[%v] Found forward declared struct of unexpected type %v @ %v", cvt_get_location(ctx, structure_node_index), forward_declaration.kind, cvt_get_location(ctx, forward_declared_name)))
			}

			if .IsForwardDeclared in structure.flags && .IsForwardDeclared not_in forward_declaration.structure.flags {
				if len(structure.attached_comments) != 0 {
					log.warnf("Skipping a forward declaration for '%v' after already writing a proper declaration, but that forward decl had attached comments:", get_simple_name_string(ctx, structure.name))
					for ci in structure.attached_comments {
						if ctx.ast[ci].kind == .Comment {
							log.warn('\t', ctx.ast[ci].literal.source, sep = "")
						}
					}
				}

				swallow_paragraph = true
				return
			}
			else {
				forward_comments := forward_declaration.structure.attached_comments
				inject_at(&structure.attached_comments, 0, ..forward_comments[:])
			}
		}

		if structure.name != 0 {
			name := ctx.ast[structure.name].identifier.token.source
			cvt_get_declared_names(ctx, parent_scope)[name] = structure_node_index
		}

		if .IsForwardDeclared in structure.flags {
			swallow_paragraph = true
			return
		}

		// write directly, they are marked for skipping in write_sequence
		for aid in structure.attached_comments {
			c, _, _, _ := write_node(ctx, aid, 0); did_clobber |= c
		}

		str.write_string(&ctx.result, complete_structure_name);
		str.write_string(&ctx.result, " :: ")

		c, has_static_var_members := write_struct_union_type(ctx, structure_node, structure_node_index, indent_str, member_indent_str); did_clobber |= c

		if has_static_var_members {
			str.write_byte(&ctx.result, '\n')
			for midx in structure.members {
				if ctx.ast[midx].kind != .VariableDeclaration || .Static not_in ctx.ast[midx].var_declaration.flags { continue }
				member := ctx.ast[midx].var_declaration

				// name already got inserted by write_struct_union_type

				str.write_byte(&ctx.result, '\n')
				str.write_string(&ctx.result, indent_str)
				str.write_string(&ctx.result, complete_structure_name)
				str.write_byte(&ctx.result, '_')
				str.write_string(&ctx.result, member.var_name.source)
				str.write_string(&ctx.result, " : ")
				did_clobber |= write_type(ctx, structure_node_index, member.type, indent_str, indent_str)

				if member.initializer_expression != {} {
					str.write_string(&ctx.result, " = ");
					c, _, _, _ := write_node(ctx, member.initializer_expression, structure_node_index); did_clobber |= c
				}
			}
		}

		if structure.deinitializer != 0 {
			deinitializer := &ctx.ast[structure.deinitializer].function_def
			if .IsForwardDeclared not_in deinitializer.flags {
				deinitializer.parent_scope = structure_node_index
				deinitializer.parent_structure = structure_node_index
	
				complete_deinitializer_name := str.concatenate({ complete_structure_name, "_deinit" })
				insert_new_overload(ctx, "deinit", complete_deinitializer_name)
	
				deinitializer.declared_names["this"] = structure.synthetic_this_var
	
				str.write_string(&ctx.result, "\n\n")
				str.write_string(&ctx.result, indent_str);
				str.write_string(&ctx.result, complete_deinitializer_name);
				str.write_string(&ctx.result, " :: proc(this : ^")
				str.write_string(&ctx.result, complete_structure_name);
				str.write_string(&ctx.result, ")\n")
	
				str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{")
				write_node_sequence(ctx, deinitializer.body_sequence[:], structure.deinitializer, member_indent_str)
				str.write_string(&ctx.result, indent_str); str.write_byte(&ctx.result, '}')
			}
		}

		written_initializer := false
		synthetic_enum_index := 0
		for midx in structure.members {
			#partial switch ctx.ast[midx].kind {
				case .FunctionDefinition:
					fn_def := &ctx.ast[midx].function_def
					fn_def.parent_scope = structure_node_index
					fn_def.parent_structure = structure_node_index

					if .IsForwardDeclared not_in fn_def.flags { str.write_string(&ctx.result, "\n\n") }
					did_clobber |= write_function(ctx, midx, indent_str)

					written_initializer |= .IsCtor in fn_def.flags
					requires_new_paragraph = true

				case .Struct, .Union:
					structure := &ctx.ast[midx].structure
					structure.parent_scope = structure_node_index
					structure.parent_structure = structure_node_index

					if structure.name == 0 { break }

					str.write_string(&ctx.result, "\n\n")
					c, _, _, _ := write_node(ctx, midx, structure_node_index, indent_str); did_clobber |= c

					requires_new_paragraph = true

				case .Enum:
					structure := &ctx.ast[midx].structure
					structure.parent_scope = structure_node_index
					structure.parent_structure = structure_node_index

					str.write_string(&ctx.result, "\n\n")
					c, _, _, _ := write_node(ctx, midx, structure_node_index, indent_str); did_clobber |= c

					requires_new_paragraph = true
			}
		}

		if .HasImplicitCtor in structure.flags && ! written_initializer {
			str.write_string(&ctx.result, "\n\n")

			synth_ctor_name := append_simple_identifier(ctx, ctx.ast[structure.name].identifier.token) // remove potential parents
			// also invalidates the structure pointer, but its no longer used from here on so its ok

			synth := AstNode{ kind = .FunctionDefinition, function_def = {
				parent_scope = structure_node_index,
				parent_structure = structure_node_index,
				function_name = synth_ctor_name,
				flags = { .IsCtor },
			}}
			did_clobber |= write_function_inner(ctx, &synth, 0, indent_str)
		}

		return
	}

	@(require_results)
	write_variable_declaration :: proc(ctx : ^ConverterContext, scope_node : AstNodeIndex, node : AstNodeIndex, indent_str : string, write_initializer : bool) -> (did_clobber : bool)
	{
		vardef := ctx.ast[node].var_declaration

		if vardef.var_name.source != "" {
			str.write_string(&ctx.result, vardef.var_name.source);
		}
		else { // can be empty for fn args
			str.write_byte(&ctx.result, '_');
		}

		type_idx := vardef.type
		type := ctx.type_heap[type_idx]
		if is_variant(type, AstTypeAuto) {
			assert(vardef.initializer_expression != {})

			//TODO generic detection
			
			str.write_string(&ctx.result, " := ")
			c, _, _, _ := write_node(ctx, vardef.initializer_expression, scope_node, indent_str); did_clobber |= c
		}
		else {
			str.write_string(&ctx.result, " : ")

			#partial switch t in type {
				case AstTypeInlineStructure:
					cvt_get_parent_scope(ctx, AstNodeIndex(t))^ = node

				case:
					stemmed := stemm_type(ctx, type_idx)
					frag, is_frag := ctx.type_heap[stemmed].(AstTypeFragment)
					if !is_frag || len(frag.generic_parameters) == 0 { break }

					stemmed_type_idx := find_definition_for(ctx, scope_node, stemmed, false)
					#partial switch stemmed_node := &ctx.ast[stemmed_type_idx]; stemmed_node.kind {
						case .Struct, .Union:
							type_key := format_complete_type_string(ctx, type_idx) // @perf duplicates work for pointer to structure
							
							if instantiation, instance_exists := stemmed_node.structure.generic_instantiations[type_key]; !instance_exists {
								log.debugf("[%v] baking generic %v", frag.identifier.location, type_key)

								replacements := extract_generic_arguments(ctx, scope_node, stemmed)
								baked_structure := bake_generic_structure(ctx, stemmed_type_idx, scope_node, replacements)
								ctx.ast[stemmed_type_idx].structure.generic_instantiations[type_key] = baked_structure
	
								current_node := &ctx.ast[node]
								vardef = current_node.var_declaration
								did_clobber = true
							}
					}
			}

			did_clobber |= write_type(ctx, scope_node, type_idx, indent_str, indent_str)

			if vardef.width_expression != {} {
				str.write_string(&ctx.result, " | ")
				c, _, _, _ := write_node(ctx, vardef.width_expression, scope_node); did_clobber |= c
			}

			if write_initializer && vardef.initializer_expression != {} {
				str.write_string(&ctx.result, " = ")

				expression_morph: {
					initializer := ctx.ast[vardef.initializer_expression]
					// short circuit pointer to ref assignments and vice versa
					if initializer.kind == .ExprUnaryLeft {
						if initializer.unary_left.operator == .Dereference {
							right_type_idx, _ := resolve_type(ctx, initializer.unary_left.right, scope_node)
							right_type := ctx.type_heap[right_type_idx]

							if rptr, is_ptr := right_type.(AstTypePointer); is_ptr && .Reference not_in rptr.flags { // ? = *p
								left_type := ctx.type_heap[type_idx]

								if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference in lptr.flags { // r = *pq
									c, _, _, _ := write_node(ctx, initializer.unary_left.right, scope_node); did_clobber |= c
									break expression_morph
								}
							}
						}
						else if initializer.unary_left.operator == .AddressOf && ctx.ast[initializer.unary_left.right].kind != .ExprIndex { // exclude = &a[b]
							right_type_idx, _ := resolve_type(ctx, initializer.unary_left.right, scope_node)
							right_type := ctx.type_heap[right_type_idx]

							if rptr, is_ptr := right_type.(AstTypePointer); is_ptr && .Reference in rptr.flags { // ? = &r
								left_type := ctx.type_heap[type_idx]

								if lptr, is_ptr := left_type.(AstTypePointer); is_ptr && .Reference not_in lptr.flags { // p = &r
									c, _, _, _ := write_node(ctx, initializer.unary_left.right, scope_node); did_clobber |= c
									break expression_morph
								}
							}
						}
					}

					c, _, _, _ := write_node(ctx, vardef.initializer_expression, scope_node, indent_str); did_clobber |= c
				}
			}
		}

		return
	}

	@(require_results)
	write_struct_union_type :: proc(ctx : ^ConverterContext, structure_node : ^AstNode, structure_node_index : AstNodeIndex, indent_str, member_indent_str : string) -> (did_clobber : bool, has_static_var_members : bool)
	{
		structure_node := structure_node
		structure := &structure_node.structure
		scope_node := structure.parent_scope
		str.write_string(&ctx.result, "struct")

		base_type : AstNodeIndex
		if structure.base_type != {} {
			// copy over defs from base type, using their location
			base_type = find_definition_for(ctx, scope_node, structure.base_type)

			for k, v in cvt_get_declared_names(ctx, base_type) {
				structure.declared_names[k] = v
			}
		}

		if len(structure.template_spec) != 0 {
			str.write_byte(&ctx.result, '(')
			for ti, i in structure.template_spec {
				if i > 0 { str.write_string(&ctx.result, ", ") }
				str.write_byte(&ctx.result, '$')
				c, _, _, _ := write_node(ctx, ti, structure_node_index); did_clobber |= c
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
			str.write_string(&ctx.result, str.concatenate({ "__base_", str.to_lower(ctx.type_heap[structure.base_type].(AstTypeFragment).identifier.source, context.temp_allocator) }))
			str.write_string(&ctx.result, " : ")
			write_complete_name_string(ctx, &ctx.result, ctx.ast[base_type].structure.name)
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

		@(require_results)
		write_bitfield_subsection_and_reset :: proc(ctx : ^ConverterContext, subsection_data : ^SubsectionSectionData, scope_node : AstNodeIndex, indent_str : string) -> (did_clobber : bool)
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

						// name was already inserted by outer loop
						did_clobber |= write_variable_declaration(ctx, scope_node, ci, subsection_data.member_indent_str, false)

						str.write_byte(&ctx.result, ',')

						last_was_newline = false

					case .Comment:
						if last_was_newline { str.write_string(&ctx.result, subsection_data.member_indent_str) }
						else { str.write_byte(&ctx.result, ' ') }
						c, _, _, _ := write_node(ctx, ci, scope_node); did_clobber |= c

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
			return
		}

		bleed_scope := structure.name != 0 ? -1 : (structure.parent_structure != 0 ? structure.parent_structure : structure.parent_scope)

		synthetic_enum_index := 0
		last_was_transfered := true
		loop: for cii := 0; cii < len(structure.members); cii += 1 {
			ci := structure.members[cii]
			member := &ctx.ast[ci]
			if member.attached { continue }


			#partial switch member.kind {
				case .VariableDeclaration:
					member := member.var_declaration
					structure.declared_names[member.var_name.source] = ci
					// Bleed members of anonymous structures into parent scope.
					//TODO(rennorb) @corectness: Does this also apply to static variables ?
					if bleed_scope != -1 {
						log.debugf("bleeding %v into parent scope %v", member.var_name.source, get_simple_name_string(ctx, bleed_scope))
						cvt_get_declared_names(ctx, bleed_scope)[member.var_name.source] = ci
					}

					if .Static in member.flags {
						has_static_var_members = true;
						last_was_transfered = false
						continue
					}

					last_was_transfered = true


					if member.width_expression != 0 {
						sa.append(&subsection_data.member_stack, ci)
						continue
					}

					if sa.len(subsection_data.member_stack) > 0 {
						did_clobber := write_bitfield_subsection_and_reset(ctx, &subsection_data, structure_node_index, member_indent_str)
						if did_clobber {
							structure_node := ctx.ast[structure_node_index]
							structure := &structure_node.structure
						}
					}

					if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
					else { str.write_byte(&ctx.result, ' ') }

					did_clobber := write_variable_declaration(ctx, structure_node_index, ci, subsection_data.member_indent_str, false)
					if did_clobber {
						structure_node := ctx.ast[structure_node_index]
						structure := &structure_node.structure
					}

					str.write_byte(&ctx.result, ',')

					last_was_newline = false

				case .FunctionDefinition:
					// dont write, only add the name to the scope
					function_def := &ctx.ast[ci].function_def
					if function_def.function_name != 0 {
						name := get_identifier_string(ctx, function_def.function_name)
						// make sure to not overwrite forward declaration, but declare if we havent already
						if _, slot, not_declared, _ := map_entry(&structure.declared_names, name); not_declared {
							slot^ = ci
						}
					}

					last_was_transfered = false

				case .OperatorDefinition:
					// dont write

					last_was_transfered = false

				case .Enum:
					// Don't write but insert definitions since they spill out into the parent scope...
					inner_structure := &ctx.ast[ci].structure
					inner_structure.parent_scope = structure_node_index
					inner_structure.parent_structure = structure_node_index

					if inner_structure.name != 0 {
						name := ctx.ast[inner_structure.name].identifier.token.source
						// make sure to not overwrite forward declaration, but declare if we havent already
						if _, slot, not_declared, _ := map_entry(&structure.declared_names, name); not_declared {
							slot^ = ci
						}
					}

					for midx in inner_structure.members {
						#partial switch inner_member := &ctx.ast[midx]; inner_member.kind {
							case .VariableDeclaration:
								inner_member.var_declaration.parent_structure = ci
								structure.declared_names[inner_member.var_declaration.var_name.source] = midx
						}
					}

					if inner_structure.name == 0 {
						synthetic_name := fmt.aprintf("E%v", ctx.synthetic_struct_index)
						ctx.synthetic_struct_index += 1
	
						ident := append_simple_identifier(ctx, { kind = .Identifier, source = synthetic_name })
	
						structure_node = &ctx.ast[structure_node_index]
						structure = &structure_node.structure
	
						ctx.ast[ci].structure.name = ident // inner enum
					}

					last_was_transfered = false

				case .Struct, .Union:
					inner_structure := &ctx.ast[ci].structure
					inner_structure.parent_scope = structure_node_index
					inner_structure.parent_structure = structure_node_index

					if member.structure.name != 0 {
						// always push scopes for nested structs so further variables can use the name
						// make sure to not overwrite forward declaration, but declare if we havent already
						name := ctx.ast[inner_structure.name].identifier.token.source
						if _, slot, not_declared, _ := map_entry(&structure.declared_names, name); not_declared {
							slot^ = ci
						}

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
					did_clobber, _ = write_struct_union_type(ctx, member, ci, member_indent_str, inner_member_indent_str)
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
						member_node_idx := structure.members[cik]
						node := ctx.ast[member_node_idx]
						#partial switch node.kind {
							case .NewLine:
								/**/
							case .FunctionDefinition:
								// dont skip completely, but add the name to the scope
								if node.function_def.function_name != 0 {
									structure.declared_names[get_identifier_string(ctx, node.function_def.function_name)] = member_node_idx
								}

							case .Struct, .Union, .Enum:
								if node.structure.name == 0 { continue loop }

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
			_ = write_bitfield_subsection_and_reset(ctx, &subsection_data, scope_node, member_indent_str)
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

	@(require_results)
	write_function_type :: proc(ctx : ^ConverterContext, fn_node : ^AstNode, fn_node_index : AstNodeIndex) -> (did_clobber : bool, arg_count : int)
	{
		fn_node := &fn_node.function_def

		if .Inline in fn_node.flags {
			str.write_string(&ctx.result, "#force_inline ")
		}

		str.write_string(&ctx.result, "proc(")

		for ti in fn_node.template_spec {
			if arg_count > 0 { str.write_string(&ctx.result, ", ") }

			str.write_byte(&ctx.result, '$')
			c, _, _, _ := write_node(ctx, ti, fn_node_index); did_clobber |= c

			arg_count += 1
		}

		
		if fn_node.parent_structure != 0 && ctx.ast[fn_node.parent_structure].kind != .Namespace {
			if arg_count > 0 { str.write_string(&ctx.result, ", ") }
			
			str.write_string(&ctx.result, "this : ^")
			write_folded_complete_name(ctx, &ctx.result, fn_node.parent_structure)

			parent_type := &ctx.ast[fn_node.parent_structure].structure
			if len(parent_type.template_spec) > 0 {
				str.write_byte(&ctx.result, '(')
				for ti, i in parent_type.template_spec {
					if i > 0 { str.write_string(&ctx.result, ", ") }

					type_var := ctx.ast[ti]
					assert_eq(type_var.kind, AstNodeKind.TemplateVariableDeclaration)

					str.write_byte(&ctx.result, '$')
					str.write_string(&ctx.result, type_var.var_declaration.var_name.source)
				}
				str.write_byte(&ctx.result, ')')
			}

			fn_node.declared_names["this"] = parent_type.synthetic_this_var

			arg_count += 1
		}

		for aidx in fn_node.arguments {
			if arg_count > 0 { str.write_string(&ctx.result, ", ") }

			#partial switch ctx.ast[aidx].kind {
				case .Varargs:
					str.write_string(&ctx.result, "args : ..[]any")

					arg_count += 1

				case .VariableDeclaration:
					arg := ctx.ast[aidx].var_declaration

					if arg.var_name.source != "" {
						if .IsForwardDeclared not_in fn_node.flags { // dont insert the name if this does not have the actual function body
							fn_node.declared_names[arg.var_name.source] = aidx
						}
					}

					_ = write_variable_declaration(ctx, fn_node_index, aidx, "", true)

					arg_count += 1

				case:
					panic(fmt.tprintf("Cannot convert %v to fn arg.", ctx.ast[aidx]))
			}
		}

		str.write_byte(&ctx.result, ')')

		if !is_variant(ctx.type_heap[fn_node.return_type], AstTypeVoid) {
			str.write_string(&ctx.result, " -> ")
			did_clobber |= write_type(ctx, fn_node_index, fn_node.return_type, "", "")
		}

		return
	}

	@(require_results)
	write_function :: proc(ctx : ^ConverterContext, function_node_idx : AstNodeIndex, indent_str : string, write_forward_declared := false) -> (did_clobber : bool)
	{
		fn_node_ := &ctx.ast[function_node_idx]
		fn_node := &fn_node_.function_def
		if (fn_node.flags & {.IsCtor, .IsDtor}) != {} && fn_node.parent_structure == 0 && fn_node.function_name != 0 {
			if struct_name := ctx.ast[fn_node.function_name].identifier.parent; struct_name != 0 {
				parent_struct_idx, _ := find_definition_for_name(ctx, fn_node.parent_scope, struct_name, { .Type })
				fn_node.parent_structure = parent_struct_idx
			}
		}
		else if fn_node.function_name != 0 && fn_node.parent_structure == 0 { // generic member function detection
			if struct_name := ctx.ast[fn_node.function_name].identifier.parent; struct_name != 0 {
				parent_node_idx, _ := try_find_definition_for_name(ctx, function_node_idx, struct_name, { .Type, .Namespace })
				if parent_node_idx != 0 {
					if ctx.ast[parent_node_idx].kind != .Namespace { // only set parent type if its a structure
						fn_node.parent_structure = parent_node_idx
					}
				}
			}
		}

		return write_function_inner(ctx, fn_node_, function_node_idx, indent_str, write_forward_declared)
	}
	@(require_results)
	write_function_inner :: proc(ctx : ^ConverterContext, function_node_ : ^AstNode, function_node_idx : AstNodeIndex, indent_str : string, write_forward_declared := false) -> (did_clobber : bool)
	{
		fn_node := &function_node_.function_def
		parent_type := fn_node.parent_structure == 0 ? nil : &ctx.ast[fn_node.parent_structure]

		format_function_type :: proc(ctx : ^ConverterContext, fn_node : ^type_of(AstNode{}.function_def)) -> string
		{
			type_name := str.builder_make(context.temp_allocator)
			write_complete_type(ctx, &type_name, fn_node.return_type)
			if fn_node.function_name != 0 {
				str.write_string(&type_name, get_identifier_string(ctx, fn_node.function_name))
			}
			str.write_byte(&type_name, '(')
			for argi, i in fn_node.arguments {
				if i > 0 { str.write_byte(&type_name, ',') }
				write_complete_type(ctx, &type_name, ctx.ast[argi].var_declaration.type)
			}
			str.write_byte(&type_name, ')')

			return str.to_string(type_name)
		}

		function_type_name := format_function_type(ctx, fn_node)

		overloaded_name : string
		flat_function_name : [dynamic]string
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

				flat_name := fold_complete_name(ctx, function_node_^, context.temp_allocator)
				replaced_fn_name := "init"
				if overload_count > 1 {
					overloaded_name = "init"
					replaced_fn_name = fmt.tprintf("init_%v", overload_index)
				}

				if len(flat_name) >= 2 && flat_name[len(flat_name) - 2] == flat_name[len(flat_name) - 1] {
					flat_name[len(flat_name) - 1] = replaced_fn_name
				}
				else {
					append(&flat_name, replaced_fn_name)
				}

				flat_function_name = flat_name

			case .IsDtor in fn_node.flags:
				flat_name := fold_complete_name(ctx, function_node_^, context.temp_allocator)
				last(flat_name)^ = "deinit"
				flat_function_name = flat_name

			case:
				fn_baseanme := get_identifier_string(ctx, fn_node.function_name)

				overload_index := 0
				overload_count := 0

				scope_members : [dynamic]AstNodeIndex

				parent_idx := fn_node.parent_structure != 0 ? fn_node.parent_structure : fn_node.parent_scope
				#partial switch parent := ctx.ast[parent_idx]; parent.kind {
					case .Struct, .Enum, .Union:
						scope_members = parent.structure.members
					case .Namespace:
						scope_members = parent.namespace.merged_member_sequence
					case .Sequence:
						scope_members = parent.sequence.members
					case:
						unreachable()
				}

				seen_members := make_map(map[string]struct{}, context.temp_allocator)

				for mi in scope_members {
					member := ctx.ast[mi]
					if member.kind != .FunctionDefinition { continue }

					if get_identifier_string(ctx, member.function_def.function_name) == fn_baseanme {
						// @perf
						// Cannot just compare the indices, because when looking for forward declaraions we might not find the actual node.
						member_type_name := format_function_type(ctx, &member.function_def)
						_ ,_, new_entry, _ := map_entry(&seen_members, member_type_name)
						if new_entry {
							if member_type_name == function_type_name { overload_index = overload_count }
							overload_count += 1
						}
					}
				}

				flat_name := fold_complete_name(ctx, function_node_^, context.temp_allocator)

				if overload_count > 1 {
					overloaded_name = fn_baseanme
					last(flat_name)^ = fmt.tprintf("%v_%v", fn_baseanme, overload_index)
				}
				flat_function_name = flat_name
		}

		joined_name := str.join(flat_function_name[:], "_")

		if overloaded_name != "" {
			insert_new_overload(ctx, overloaded_name, joined_name)
		}

		last(flat_function_name)^ = function_type_name

		// fold attached comments form forward declaration. This also works when chaining forward declarations
		forward_declared_name, _ := try_find_definition_for_name(ctx, fn_node.parent_scope, flat_function_name[:], { .Function })

		if forward_declared_name != 0 && \
		 // Prevent detecting member function as its own forward declaration.
		 // This can could happen, because the type writer for fucntions already inserts the name of the fucntion into the structure scope without actually calling this function here (so it can be referenced by later variables).
		 forward_declared_name != function_node_idx {
			forward_declaration := ctx.ast[forward_declared_name]

			if .IsForwardDeclared in fn_node.flags && .IsForwardDeclared not_in forward_declaration.structure.flags {
				if len(fn_node.attached_comments) != 0 {
					fn_loc := fn_node.function_name != 0 ? ctx.ast[fn_node.function_name].identifier.token.location : {}
					log.warnf("[%v] Skipping a forward declaration for '%v' after already writing a proper declaration, but that forward decl had attached comments:", fn_loc, get_identifier_string(ctx, fn_node.function_name))
					for ci in fn_node.attached_comments {
						if ctx.ast[ci].kind == .Comment {
							log.warn("  ", ctx.ast[ci].literal.source, sep = "")
						}
					}
				}

				return
			}
			else {
				forward_comments := forward_declaration.function_def.attached_comments
				inject_at(&fn_node.attached_comments, 0, ..forward_comments[:])

				// copy over default args from forward declaration
				for argni, argi in forward_declaration.function_def.arguments {
					farg := &ctx.ast[argni].var_declaration
					if farg.initializer_expression != 0 {
						arg := &ctx.ast[fn_node.arguments[argi]];
						assert_node_kind(arg^, .VariableDeclaration)
						arg.var_declaration.initializer_expression = farg.initializer_expression
					}
				}
			}
		}

		if fn_node.function_name != 0 {
			function_scope := fn_node.parent_structure != 0 ? fn_node.parent_structure : fn_node.parent_scope
			scope := cvt_get_declared_names(ctx, function_scope)
			scope[get_identifier_string(ctx, fn_node.function_name)] = function_node_idx
			scope[function_type_name] = function_node_idx
		}

		if .IsForwardDeclared in fn_node.flags && !write_forward_declared {
			return
		}

		// write directly, they are marked for skipping in write_sequence
		last_attached_node_was_newline := false
		for aid in fn_node.attached_comments {
			c, _, _, _ := write_node(ctx, aid, function_node_idx); did_clobber |= c
			last_attached_node_was_newline = ctx.ast[aid].kind == .NewLine
		}
		if len(fn_node.attached_comments) != 0 && !last_attached_node_was_newline { str.write_byte(&ctx.result, '\n'); }

		str.write_string(&ctx.result, indent_str);
		str.write_string(&ctx.result, joined_name);
		str.write_string(&ctx.result, " :: ");
		c, _ := write_function_type(ctx, function_node_, function_node_idx); did_clobber |= c

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
					c, _, _, _ := write_node(ctx, member.initializer_expression, function_node_idx, indent_str); did_clobber |= c
				}
				else {
					c, _, _, _ := write_node(ctx, fn_node.body_sequence[0], function_node_idx, indent_str); did_clobber |= c
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
						c, _, _, _ := write_node(ctx, member.initializer_expression, function_node_idx); did_clobber |= c

						str.write_byte(&ctx.result, '\n')
					}
				}
				else if len(fn_node.body_sequence) > 0 && ctx.ast[fn_node.body_sequence[0]].kind != .NewLine {
					str.write_byte(&ctx.result, '\n')
					str.write_string(&ctx.result, body_indent_str);
				}
				write_node_sequence(ctx, fn_node.body_sequence[:], function_node_idx, body_indent_str)

				if ctx.ast[last_or_nil(fn_node.body_sequence)].kind != .NewLine {
					str.write_byte(&ctx.result, '\n');
				}
				str.write_string(&ctx.result, indent_str);
				str.write_byte(&ctx.result, '}')
		}
		return
	}

	write_token_range :: proc(result : ^str.Builder, r : TokenRange, glue := "_")
	{
		for t, i in r {
			if i != 0 { str.write_string(result, glue) }
			str.write_string(result, t.source)
		}
	}

	@(require_results)
	write_type :: proc(ctx : ^ConverterContext, scope_node : AstNodeIndex, type : AstTypeIndex, indent_str, member_indent_str : string) -> (did_clobber : bool)
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
						c, _, _, _ := write_node(ctx, frag.length_expression, scope_node, indent_str); did_clobber |= c
					}
					else {
						str.write_byte(&ctx.result, '^')
					}
					str.write_byte(&ctx.result, ']')
					type = frag.element_type

				case AstTypeFragment:
					// if frag.parent_fragment != {} {
					// 	write_type(ctx, scope_node, frag.parent_fragment, indent_str, member_indent_str)
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
							type_name_idx := try_find_definition_for(ctx, scope_node, type)
							if type_name_idx != 0 {
								write_complete_name_string(ctx, &ctx.result, type_name_idx)
							}
							else {
								log.warn("Failed to find definition for type fragment", frag.identifier)
								str.write_string(&ctx.result, frag.identifier.source)
							}
					}

					if len(frag.generic_parameters) > 0 {
						str.write_byte(&ctx.result, '(')
						for g, i in frag.generic_parameters {
							if i > 0 { str.write_string(&ctx.result, ", ") }
							c, _, _, _ := write_node(ctx, g, scope_node, indent_str); did_clobber |= c
						}
						str.write_byte(&ctx.result, ')')
					}
					return

				case AstTypeInlineStructure:
					c, _ := write_struct_union_type(ctx, &ctx.ast[frag], AstNodeIndex(frag), indent_str, member_indent_str); did_clobber |= c
					return 

				case AstTypeFunction:
					str.write_string(&ctx.result, "proc(")
					for ai, i in frag.arguments {
						if i > 0 { str.write_string(&ctx.result, ", ") }
						c, _, _, _ := write_node(ctx, ai, scope_node, indent_str); did_clobber |= c
					}
					str.write_byte(&ctx.result, ')')

					if !is_variant(ctx.type_heap[frag.return_type], AstTypeVoid) {
						str.write_string(&ctx.result, " -> ")
						did_clobber |= write_type(ctx, scope_node, frag.return_type, indent_str, member_indent_str)
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
		return
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

	resolve_type :: proc(ctx : ^ConverterContext, current_node_index : AstNodeIndex, scope_node : AstNodeIndex, loc := #caller_location) -> (raw_type : AstTypeIndex, type_node : AstNodeIndex)
	{
		current_node := ctx.ast[current_node_index]
		#partial switch current_node.kind {
			case .Identifier:
				definition_idx, deffinition_parent_idx := find_definition_for_name(ctx, scope_node, current_node_index, loc = loc)

				definition := ctx.ast[definition_idx]
				#partial switch definition.kind {
					case .VariableDeclaration:
						return resolve_type(ctx, definition_idx, deffinition_parent_idx, loc)

					case .FunctionDefinition: //TODO(Rennorb) @explain
						fn_def := definition.function_def

						type_name_idx := try_find_definition_for_or_warn(ctx, scope_node, fn_def.return_type)

						return fn_def.return_type, type_name_idx

					case .Struct, .Union: // structure constructor     Rect(1, 2, 1, 2)
						struct_this := definition.structure.synthetic_this_var
						return ctx.ast[struct_this].var_declaration.type, definition_idx

					case .PreprocMacro:
						// not feasable in general

						switch definition.preproc_macro.name.source {  // @hack
							case "ImDrawCmd_HeaderCompare":
								return TYPE_LIT_INT32, {}
							case "stb__in2", "stb__in3", "stb__in4":
								return TYPE_LIT_INT32, {}
							case "STB_TEXT_HAS_SELECTION":
								return TYPE_LIT_BOOL, {}
							case "IM_BITARRAY_TESTBIT":
								return TYPE_LIT_BOOL, {}
						}
						

						panic(fmt.tprintf("[%v] Unexpected identifier type '%v' for %v: %#v", loc, definition.kind, current_node.identifier, definition_idx))

					case .PreprocDefine:
						// @hack
						switch definition.preproc_define.name.source {
							case "INT_MAX":    return TYPE_LIT_INT32, {}
							case "INT_MIN":    return TYPE_LIT_INT32, {}
							case "UINT_MAX":   return TYPE_LIT_INT32, {}
							case "UINT_MIN":   return TYPE_LIT_INT32, {}
							case "LLONG_MAX":  return TYPE_LIT_INT64, {}
							case "LLONG_MIN":  return TYPE_LIT_INT64, {}
							case "ULLONG_MAX": return TYPE_LIT_INT64, {}
							case "FLT_MAX":    return TYPE_LIT_FLOAT32, {}
							case "FLT_MIN":    return TYPE_LIT_FLOAT32, {}
							case "DBL_MAX":    return TYPE_LIT_FLOAT64, {}
							case "DBL_MIN":    return TYPE_LIT_FLOAT64, {}
						}

						only_token : TokenKind
						for t in definition.preproc_define.expansion_tokens {
							#partial switch t.kind {
								case .Comment:
									/* ignore */
								case:
									if only_token != {} { only_token = {}; break }
									only_token = t.kind
							}
						}

						#partial switch only_token {
							case .LiteralNull: return TYPE_LIT_NULL, {}
							case .LiteralBool: return TYPE_LIT_BOOL, {}
							case .LiteralInteger: return TYPE_LIT_INT32, {}
							case .LiteralFloat: return TYPE_LIT_BOOL, {}
							case .LiteralCharacter: return TYPE_LIT_CHAR, {}
							case .LiteralString: return TYPE_LIT_STRING, {}
						}

						fallthrough

					case:
						panic(fmt.tprintf("[%v] Unexpected identifier type '%v' for %v: %#v", loc, definition.kind, current_node.identifier, definition_idx))
				}
			
			case .ExprUnaryLeft:
				#partial switch current_node.unary_left.operator {
					case .Not:
						return TYPE_LIT_BOOL, {}

					case .Dereference:
						right_type, tn := resolve_type(ctx, current_node.unary_left.right, scope_node, loc)
						return ctx.type_heap[right_type].(AstTypePointer).destination_type, tn

					case:
						return resolve_type(ctx, current_node.unary_left.right, scope_node, loc)
				}

			case .ExprUnaryRight:
				return resolve_type(ctx, current_node.unary_right.left, scope_node, loc)

			case .ExprIndex:
				expression_type, expression_type_idx := resolve_type(ctx, current_node.index.array_expression, scope_node, loc)
				#partial switch frag in ctx.type_heap[expression_type] {
					case AstTypeArray:
						return frag.element_type, expression_type_idx

					case AstTypePointer:
						if .Reference not_in frag.flags {
							return frag.destination_type, expression_type_idx
						}
				}

				// assume the type is indexable and look for a matching operator
				//NOTE(Rennorb) @completeness: We are not doing friendoperators cpp, no shot.
				structure_node := ctx.ast[expression_type_idx]
				assert(structure_node.kind == .Struct || structure_node.kind == .Union)

				for mi in structure_node.structure.members {
					member := ctx.ast[mi]
					if member.kind != .OperatorDefinition || member.operator_def.kind != .Index { continue }

					type := ctx.ast[member.operator_def.underlying_function].function_def.return_type
					return_type_idx := try_find_definition_for_or_warn(ctx, expression_type_idx, type)

					return type, return_type_idx
				}

				panic(fmt.tprintf("Index operator not found on %#v", structure_node))

			case .MemberAccess:
				member_access := current_node.member_access
				expr_type, expr_type_idx := resolve_type(ctx, member_access.expression, scope_node, loc)

				expr_type_idx = maybe_follow_typedef(ctx, scope_node /* @correctness: wrong */, expr_type_idx)

				member := ctx.ast[member_access.member]
				#partial switch member.kind {
					case .Identifier:
						return resolve_type(ctx, member_access.member, expr_type_idx, loc)

					case .FunctionCall:
						fn_name_node := ctx.ast[member.function_call.expression]
						assert_node_kind(fn_name_node, .Identifier)
						fn_name := get_identifier_string(ctx, member.function_call.expression)

						structure := &ctx.ast[expr_type_idx]
						assert(structure.kind == .Struct || structure.kind == .Union)
						fndef_idx := structure.structure.declared_names[fn_name]

						fndef := ctx.ast[fndef_idx]
						#partial switch fndef.kind {
							case .FunctionDefinition:
								return_type_idx := find_definition_for(ctx, fndef_idx, fndef.function_def.return_type)
								return fndef.function_def.return_type, return_type_idx

							case .VariableDeclaration:
								type := ctx.type_heap[fndef.var_declaration.type]
								if p, is_ptr := type.(AstTypePointer); is_ptr {
									if fn, is_fn := ctx.type_heap[p.destination_type].(AstTypeFunction); is_fn {
										return_type_idx := find_definition_for(ctx, expr_type_idx, fn.return_type)
										return fn.return_type, return_type_idx
									}
								}

								fallthrough
							case:
								panic(fmt.tprintf("Expected function, got %#v", fndef))
						}

					case:
						panic(fmt.tprintf("Not implemented %v", member))
				}

			case .VariableDeclaration:
				def_node := current_node.var_declaration

				#partial switch t in ctx.type_heap[def_node.type] {
					case AstTypeInlineStructure: // struct { int a } b;
						return def_node.type, AstNodeIndex(t)

					case AstTypeAuto:
						panic("auto resolver not implemented");

					case AstTypePrimitive, AstTypeVoid:
						return def_node.type, {}
				}

				type_definition_idx := try_find_definition_for(ctx, scope_node, def_node.type)

				return def_node.type, type_definition_idx

			case .FunctionCall:
				// technically not quite right, but thats also because of the structure of these nodes
				return resolve_type(ctx, current_node.function_call.expression, scope_node, loc)

			case .ExprCast:
				type_definition_idx := try_find_definition_for_or_warn(ctx, scope_node, current_node.cast_.type)

				return current_node.cast_.type, type_definition_idx

			case .ExprBacketed:
				return resolve_type(ctx, current_node.inner, scope_node, loc)

			case .ExprBinary:
				#partial switch current_node.binary.operator {
					case .LogicAnd, .LogicOr, .Equals, .NotEquals, .Less, .LessEq, .Greater, .GreaterEq:
						return TYPE_LIT_BOOL, {}

					case:
						tl, nl := resolve_type(ctx, current_node.binary.left, scope_node, loc)
						tr, nr := resolve_type(ctx, current_node.binary.right, scope_node, loc)
						return get_resulting_type_for_binary_expr(tl, nl, tr, nr)
				}

			case .ExprTenary:
				return resolve_type(ctx, current_node.tenary.true_expression, scope_node, loc)

			case .Type:
				raw_type := current_node.type
				stemmed := stemm_type(ctx, raw_type)
				stemmed_type_definition_idx := find_definition_for(ctx, scope_node, stemmed)
				return raw_type, stemmed_type_definition_idx

			case .LiteralNull: return TYPE_LIT_NULL, {}
			case .LiteralBool: return TYPE_LIT_BOOL, {}
			case .LiteralInteger: return str.ends_with(current_node.literal.source, "LL") || str.ends_with(current_node.literal.source, "ll") ? TYPE_LIT_INT64 : TYPE_LIT_INT32, {}
			case .LiteralFloat: return str.ends_with(current_node.literal.source, "L") || str.ends_with(current_node.literal.source, "l") ? TYPE_LIT_FLOAT64 : TYPE_LIT_FLOAT32, {}
			case .LiteralCharacter: return TYPE_LIT_CHAR, {}
			case .LiteralString: return TYPE_LIT_STRING, {}

			case:
				panic(fmt.tprintf("Not implemented %#v", current_node))
		}
	}

	is_imgui_scalar :: proc(name : string) -> bool {
		switch name {
			case "uint", "ImGuiID", "ImS8", "ImU8", "ImS16", "ImU16", "ImS32", "ImU32", "ImS64", "ImU64":
				return true
			case:
				return false;
		}
	}

	@(require_results)
	write_condition_maybe_translated :: proc(ctx : ^ConverterContext, scope_node, condition : AstNodeIndex) -> (did_clobber : bool)
	{
		condition_node := &ctx.ast[condition]

		requires_brackets := true
		#partial switch condition_node.kind {
			case .Identifier, .ExprBacketed, .ExprIndex, .ExprUnaryLeft, .ExprUnaryRight, .MemberAccess, .FunctionCall:
				requires_brackets = false
		}

		type, _ := resolve_type(ctx, condition, scope_node)
		//TODO(Rennorb) @correctness: doesnt follow typedefs

		if type > 0{
			#partial switch frag in ctx.type_heap[type] {
				case (AstTypePrimitive):
					if frag.fragments[0].source == "bool" {
						/* ok, can write the given type */
						break
					}
					else {
						if requires_brackets { str.write_byte(&ctx.result, '(') }
						did_clobber, _, _, _ = write_node(ctx, condition, scope_node)
						if requires_brackets { str.write_byte(&ctx.result, ')') }
						str.write_string(&ctx.result, " != 0")
						return
					}

				case (AstTypePointer):
					if requires_brackets { str.write_byte(&ctx.result, '(') }
					did_clobber, _, _, _ = write_node(ctx, condition, scope_node)
					if requires_brackets { str.write_byte(&ctx.result, ')') }
					str.write_string(&ctx.result, " != nil")
					return

				case (AstTypeFragment):
					if requires_brackets { str.write_byte(&ctx.result, '(') }
					did_clobber, _, _, _ = write_node(ctx, condition, scope_node)
					if requires_brackets { str.write_byte(&ctx.result, ')') }
					str.write_string(&ctx.result, is_imgui_scalar(frag.identifier.source) ? " != 0" : " != {}")
					return

				case (AstTypeInlineStructure):
					if requires_brackets { str.write_byte(&ctx.result, '(') }
					did_clobber, _, _, _ = write_node(ctx, condition, scope_node)
					if requires_brackets { str.write_byte(&ctx.result, ')') }
					str.write_string(&ctx.result, " != {}")
					return
			}
		}

		c, _, _, _ := write_node(ctx, condition, scope_node); did_clobber |= c
		return
	}

	get_resulting_type_for_binary_expr :: proc(t1 : AstTypeIndex, n1 : AstNodeIndex, t2 : AstTypeIndex, n2 : AstNodeIndex) -> (AstTypeIndex, AstNodeIndex)
	{
		switch {
			case t1 == TYPE_LIT_INT32 && t2 == TYPE_LIT_CHAR: return TYPE_LIT_INT32, {}
			case t1 == TYPE_LIT_CHAR && t2 == TYPE_LIT_INT32: return TYPE_LIT_INT32, {}

			case t1 == TYPE_LIT_INT64 && t2 == TYPE_LIT_CHAR: return TYPE_LIT_INT64, {}
			case t1 == TYPE_LIT_INT64 && t2 == TYPE_LIT_INT32: return TYPE_LIT_INT64, {}
			case t1 == TYPE_LIT_CHAR  && t2 == TYPE_LIT_INT64: return TYPE_LIT_INT64, {}
			case t1 == TYPE_LIT_INT32 && t2 == TYPE_LIT_INT64: return TYPE_LIT_INT64, {}

			case t1 == TYPE_LIT_FLOAT32 && t2 == TYPE_LIT_CHAR:  return TYPE_LIT_FLOAT32, {}
			case t1 == TYPE_LIT_FLOAT32 && t2 == TYPE_LIT_INT32: return TYPE_LIT_FLOAT32, {}
			case t1 == TYPE_LIT_FLOAT32 && t2 == TYPE_LIT_INT64: return TYPE_LIT_FLOAT32, {}
			case t2 == TYPE_LIT_CHAR    && t1 == TYPE_LIT_FLOAT32: return TYPE_LIT_FLOAT32, {}
			case t2 == TYPE_LIT_INT32   && t1 == TYPE_LIT_FLOAT32: return TYPE_LIT_FLOAT32, {}
			case t2 == TYPE_LIT_INT64   && t1 == TYPE_LIT_FLOAT32: return TYPE_LIT_FLOAT32, {}

			case t1 == TYPE_LIT_FLOAT64 && t2 == TYPE_LIT_CHAR:    return TYPE_LIT_FLOAT64, {}
			case t1 == TYPE_LIT_FLOAT64 && t2 == TYPE_LIT_INT32:   return TYPE_LIT_FLOAT64, {}
			case t1 == TYPE_LIT_FLOAT64 && t2 == TYPE_LIT_INT64:   return TYPE_LIT_FLOAT64, {}
			case t1 == TYPE_LIT_FLOAT64 && t2 == TYPE_LIT_FLOAT32: return TYPE_LIT_FLOAT64, {}
			case t2 == TYPE_LIT_CHAR    && t1 == TYPE_LIT_FLOAT64: return TYPE_LIT_FLOAT64, {}
			case t2 == TYPE_LIT_INT32   && t1 == TYPE_LIT_FLOAT64: return TYPE_LIT_FLOAT64, {}
			case t2 == TYPE_LIT_INT64   && t1 == TYPE_LIT_FLOAT64: return TYPE_LIT_FLOAT64, {}
			case t2 == TYPE_LIT_FLOAT32 && t1 == TYPE_LIT_FLOAT64: return TYPE_LIT_FLOAT64, {}

			case t1 >= 0: return t1, n1 // a + 1   where a = int*
			case t2 >= 0: return t2, n2 // 1 + a   where a = int*
		}
		return t1, n1
	}

	TemplateReplacements :: map[string]AstNodeIndex

	extract_generic_arguments :: proc(ctx : ^ConverterContext, scope_node : AstNodeIndex, stemmed_arg_source : AstTypeIndex, loc := #caller_location) -> TemplateReplacements
	{
		frag, is_frag := ctx.type_heap[stemmed_arg_source].(AstTypeFragment)
		assert(is_frag, "wrong type fragment passed", loc)
		og_struct_idx := find_definition_for(ctx, scope_node, stemmed_arg_source, false, loc = loc)
		og_structure := ctx.ast[og_struct_idx].structure

		replacements : TemplateReplacements
		for ti, i in og_structure.template_spec {
			template_var_def := ctx.ast[ti].var_declaration
			r : AstNodeIndex
			if i < len(frag.generic_parameters) {
				r = frag.generic_parameters[i]
			}
			else {
				assert(template_var_def.initializer_expression != 0)
				r = template_var_def.initializer_expression
			}
			replacements[template_var_def.var_name.source] = r
		}
		return replacements
	}

	bake_generic_structure :: proc(ctx : ^ConverterContext, structure : AstNodeIndex, scope_node : AstNodeIndex, replacements : TemplateReplacements) -> AstNodeIndex
	{
		#partial switch ctx.ast[structure].kind {
			case .Struct, .Union:
				assert(len(ctx.ast[structure].structure.template_spec) > 0)
				/*ok*/
			case:
				panic(fmt.tprintf("Unexpected astnode for baking: %#v", structure))
		}

		og_structure := ctx.ast[structure].structure

		baked_members := slice.clone_to_dynamic(og_structure.members[:])
		baked_declared_names := map_clone(og_structure.declared_names)
		for &mi in baked_members {
			member := ctx.ast[mi]
			#partial switch member.kind {
				case .VariableDeclaration:
					if baked_type, did_bake_type := bake_generic_type(ctx, member.var_declaration.type, replacements); did_bake_type {
						member.var_declaration.type = baked_type
						mi = cvt_append_node(ctx, member)
						baked_declared_names[member.var_declaration.var_name.source] = mi
					}

				case .FunctionDefinition:
					// @hack dont care about arguments, we only care for the return type for now
					if baked_type, did_bake_type := bake_generic_type(ctx, member.function_def.return_type, replacements); did_bake_type {
						member.function_def.return_type = baked_type
						mi = cvt_append_node(ctx, member)
						baked_declared_names[get_simple_name_string(ctx, member.function_def.function_name)] = mi
					}

				case .OperatorDefinition:
					fn_def := ctx.ast[member.operator_def.underlying_function]
					// @hack dont care about arguments, we only care for the return type for now
					if baked_type, did_bake_type := bake_generic_type(ctx, fn_def.function_def.return_type, replacements); did_bake_type {
						fn_def.function_def.return_type = baked_type
						member.operator_def.underlying_function = cvt_append_node(ctx, fn_def)
						mi = cvt_append_node(ctx, member)
					}

				case .Struct, .Union, .Enum:
					unimplemented()
			}
		}
		
		baked := ctx.ast[structure]
		baked.structure.template_spec = {}
		baked.structure.members = baked_members
		baked.structure.declared_names = baked_declared_names

		//TODO @completeness: modify the thisvar type to have the generic parameters

		// @hack pull in types just in case we reference a local type from a different scope.
		// The fix for this would be to reference types by the canonical name, but we dont do that so...
		for k, v in replacements {
			#partial switch node := &ctx.ast[v]; node.kind {
				case .Type:
					stemmed := stemm_type(ctx, node.type)
					if !is_variant(ctx.type_heap[stemmed], AstTypeFragment) { break }

					def_idx := find_definition_for(ctx, scope_node, stemmed, filter = { .Type, .Variable }) // @hack becasue constants sometimes get parsed as types

					name : []string = { get_simple_name_string(ctx, def_idx) }
					if def, _ := try_find_definition_for_name(ctx, structure, name, { .Type }); def == 0 { // cant see this def from the structure
						log.debugf("baking external type %v into scope of %v with template args %v", name[0], get_simple_name_string(ctx, structure), replacements)
						baked.structure.declared_names[get_simple_name_string(ctx, def_idx)] = def_idx
					}
			}
		}

		return cvt_append_node(ctx, baked)
	}

	bake_generic_type :: proc(ctx : ^ConverterContext, type : AstTypeIndex, replacements : TemplateReplacements, loc := #caller_location) -> (baked_type : AstTypeIndex, did_replace_fragments : bool)
	{
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

find_definition_for :: proc(ctx : ^ConverterContext, start_context_node : AstNodeIndex, type : AstTypeIndex, resolve_generic := true, filter := DefinitionFilter{ .Type }, loc := #caller_location) -> (definition : AstNodeIndex)
{
	definition = try_find_definition_for(ctx, start_context_node, type, resolve_generic, filter, loc)
	if definition != 0 { return }

	err := fmt.tprintf("Type not found in context: %#v", ctx.type_heap[type])
	log.error(err, location = loc)
	// n := get_scope(ctx, start_context).name
	// dump_context_stack(ctx, start_context, n.index == 0 ? get_simple_name_string(ctx, n) : "")
	panic(err, loc)
}

try_find_definition_for_or_warn :: proc(ctx : ^ConverterContext, start_context_node : AstNodeIndex, type : AstTypeIndex, resolve_generic := true, loc := #caller_location) -> (definition : AstNodeIndex)
{
	definition = try_find_definition_for(ctx, start_context_node, type, resolve_generic)
	if definition != 0 { return }

	stemmed := stemm_type(ctx, type)
	#partial switch _ in ctx.type_heap[stemmed] {
		case AstTypePrimitive, AstTypeVoid:
			return
	}

	log.errorf("Type not found in context: %v", ctx.type_heap[type], location = loc)
	return
}

try_find_definition_for :: proc(ctx : ^ConverterContext, start_scope_node : AstNodeIndex, type : AstTypeIndex, resolve_generic := true, filter := DefinitionFilter{ .Type }, loc := #caller_location) -> (definition : AstNodeIndex)
{
	flattened_type := make([dynamic]string, context.temp_allocator)
	flaten_loop: for type := type; type != {}; {
		#partial switch frag in ctx.type_heap[type] {
			case AstTypeFragment:
				inject_at(&flattened_type, 0, frag.identifier.source) // TODO(Rennorb) @explain: Why is this reversed
				type = frag.parent_fragment

			case AstTypePointer:
				type = frag.destination_type

			case AstTypeArray:
				type = frag.element_type

			case AstTypePrimitive: // @hack with the type shim
				inject_at(&flattened_type, 0, last(frag.fragments).source)
				break flaten_loop

			case:
				break flaten_loop
		}
	}

	if len(flattened_type) == 0 { return }

	definition, _ = try_find_definition_for_name_preflattened(ctx, start_scope_node, flattened_type[:], filter, loc)

	if resolve_generic {
		stemmed := stemm_type(ctx, type)
		if frag, is_frag := ctx.type_heap[stemmed].(AstTypeFragment); is_frag && len(frag.generic_parameters) > 0 {
			#partial switch def := &ctx.ast[definition]; def.kind {
				case .Struct, .Union, .Enum:
					key := format_complete_type_string(ctx, type)
					if baked, exists := def.structure.generic_instantiations[key]; exists {
						definition = baked
					}
			}
		}
	}

	return
}

format_complete_type_string :: proc(ctx : ^ConverterContext, type : AstTypeIndex, include_const_qualifiers := false, alloc := context.allocator) -> string
{
	sb := str.builder_make(alloc)
	write_complete_type_idx(ctx, &sb, type, include_const_qualifiers)
	return str.to_string(sb)
}

write_complete_type :: proc { write_complete_type_idx }

write_complete_type_idx :: proc(ctx : ^ConverterContext, sb : ^str.Builder, type : AstTypeIndex, include_const_qualifiers := false)
{
	switch frag in ctx.type_heap[type] {
		case AstTypeInlineStructure:
			str.write_string(sb, "#s")

		case AstTypeFunction:
			write_complete_type_idx(ctx, sb, frag.return_type)
			str.write_byte(sb, '(')
			for aidx, i in frag.arguments {
				if i > 0 { str.write_byte(sb, ',') }
				write_complete_type_idx(ctx, sb, ctx.ast[aidx].var_declaration.type)
			}
			str.write_byte(sb, ')')

		case AstTypePointer:
			if include_const_qualifiers && .Const in frag.flags {
				str.write_string(sb, "c:")
			}
			str.write_byte(sb, '^')
			write_complete_type_idx(ctx, sb, frag.destination_type)

		case AstTypeArray:
			str.write_byte(sb, '[')
			str.write_byte(sb, ']')
			write_complete_type_idx(ctx, sb, frag.element_type)

		case AstTypeFragment:
			if frag.parent_fragment != 0 {
				write_complete_type_idx(ctx, sb, frag.parent_fragment)
				str.write_byte(sb, '_')
			}

			if frag.identifier.source == "ImGui" { break }

			str.write_string(sb, frag.identifier.source)
			if len(frag.generic_parameters) > 0 {
				str.write_byte(sb, '(')
				for pi, i in frag.generic_parameters {
					if i > 0 { str.write_byte(sb, ',') }
					if param := ctx.ast[pi]; param.kind == .Type {
						write_complete_type_idx(ctx, sb, param.type)
					}
				}
				str.write_byte(sb, ')')
			}

		case AstTypePrimitive:
			if include_const_qualifiers && .Const in frag.flags {
				str.write_string(sb, "c:")
			}
			for f, i in frag.fragments {
				if i > 0 { str.write_byte(sb, ':') }
				str.write_string(sb, f.source)
			}

		case AstTypeAuto:
			str.write_string(sb, "auto")

		case AstTypeVoid:
			str.write_string(sb, "void")
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
	//ensure stable order
	names := make([]string, len(ctx.overload_resolver), context.temp_allocator)
	i := 0
	for name, _ in ctx.overload_resolver {
		names[i] = name; i += 1
	}
	slice.sort(names)

	for name in names {
		str.write_byte(&ctx.result, '\n')
		str.write_string(&ctx.result, name)
		str.write_string(&ctx.result, " :: proc { ")
		for overloaded_name, i in ctx.overload_resolver[name] {
			if i > 0 { str.write_string(&ctx.result, ", ") }
			str.write_string(&ctx.result, overloaded_name)
		}
		str.write_string(&ctx.result, " }\n")
	}
}

get_simple_name_string :: proc { get_simple_name_string_idx, get_simple_name_string_node }

get_simple_name_string_idx :: proc(ctx : ^ConverterContext, node : AstNodeIndex) -> string
{
	return #force_inline get_simple_name_string_node(ctx, ctx.ast[node]) 
}

get_simple_name_string_node :: proc(ctx : ^ConverterContext, node : AstNode) -> string
{
	#partial switch node.kind {
		case .Struct, .Enum, .Union:
			if node := ctx.ast[node.structure.name]; node.kind == .Identifier {
				return node.identifier.token.source
			}
		case .VariableDeclaration, .TemplateVariableDeclaration:
			return node.var_declaration.var_name.source

		case .FunctionDefinition:
			if node := ctx.ast[node.function_def.function_name]; node.kind == .Identifier {
				return node.identifier.token.source
			}

		case .PreprocMacro:
			return node.preproc_macro.name.source

		case .Identifier:
			return node.identifier.token.source

		case .PreprocDefine:
			return node.preproc_define.name.source

		case .Namespace:
			return node.namespace.name.source

		case .Type:
			type := ctx.type_heap[node.type]
			for {
				switch frag in type {
					case AstTypeInlineStructure:
						return ""

					case AstTypeFunction:
						return frag.name.source

					case AstTypePointer:
						type = ctx.type_heap[frag.destination_type]

					case AstTypeArray:
						type = ctx.type_heap[frag.element_type]

					case AstTypeFragment:
						return frag.identifier.source

					case AstTypePrimitive:
						return frag.fragments[0].source //TODO @correctness

					case AstTypeAuto:
						return frag.token.source

					case AstTypeVoid:
						return frag.token.source
				}
			}
	}
	return ""
}


get_complete_name_string :: proc { get_complete_name_string_idx, get_complete_name_string_node }

get_complete_name_string_idx :: #force_inline proc(ctx : ^ConverterContext, node : AstNodeIndex, alloc := context.allocator) -> string
{
	return get_complete_name_string_node(ctx, ctx.ast[node], alloc)
}

get_complete_name_string_node :: proc(ctx : ^ConverterContext, node : AstNode, alloc := context.allocator) -> string
{
	sb := str.builder_make(alloc)
	write_complete_name_string_node(ctx, &sb, node)
	return str.to_string(sb)
}

write_complete_name_string :: proc { write_complete_name_string_idx, write_complete_name_string_node }

write_complete_name_string_idx :: #force_inline proc(ctx : ^ConverterContext, sb : ^str.Builder, node : AstNodeIndex)
{
	write_complete_name_string_node(ctx, sb, ctx.ast[node])
}

write_complete_name_string_node :: proc(ctx : ^ConverterContext, sb : ^str.Builder, node : AstNode)
{
	is_not_imgui_namespace :: proc(ctx : ^ConverterContext, node : AstNodeIndex) -> bool
	{
		n := ctx.ast[node]
		return n.kind != .Namespace || n.namespace.name.source != "ImGui"
	}

	#partial switch node.kind {
		case .Struct, .Enum, .Union:
			if node.structure.parent_structure != 0 && is_not_imgui_namespace(ctx, node.structure.parent_structure) {
				write_complete_name_string_idx(ctx, sb, node.structure.parent_structure)
				str.write_byte(sb, '_')
			}
			else if ctx.ast[node.structure.parent_scope].kind == .Namespace && is_not_imgui_namespace(ctx, node.structure.parent_scope) {
				write_complete_name_string_idx(ctx, sb, node.structure.parent_scope)
				str.write_byte(sb, '_')
			}
			if node.structure.name != 0 {
				str.write_string(sb, ctx.ast[node.structure.name].identifier.token.source)
			}

		case .Namespace:
			if ctx.ast[node.namespace.parent_scope].kind == .Namespace && is_not_imgui_namespace(ctx, node.namespace.parent_scope) {
				write_complete_name_string_idx(ctx, sb, node.structure.parent_scope)
				str.write_byte(sb, '_')
			}
			if node.namespace.name.source != "" {
				str.write_string(sb, node.namespace.name.source)
			}

		case .FunctionDefinition:
			if node.function_def.parent_structure != 0 && is_not_imgui_namespace(ctx, node.function_def.parent_structure) {
				write_complete_name_string_idx(ctx, sb, node.function_def.parent_structure)
				str.write_byte(sb, '_')
			}
			else if ctx.ast[node.function_def.parent_scope].kind == .Namespace && is_not_imgui_namespace(ctx, node.function_def.parent_scope) {
				write_complete_name_string_idx(ctx, sb, node.namespace.parent_scope)
				str.write_byte(sb, '_')
			}
			if node.function_def.function_name != 0 {
				str.write_string(sb, ctx.ast[node.function_def.function_name].identifier.token.source)
			}

		case .PreprocMacro:
			str.write_string(sb, node.preproc_macro.name.source)

		case .VariableDeclaration, .TemplateVariableDeclaration:
			str.write_string(sb, node.var_declaration.var_name.source)

		case .PreprocDefine:
			str.write_string(sb, node.preproc_define.name.source)

		case .Typedef:
			str.write_string(sb, node.typedef.name.source)

		case .Identifier:
			str.write_string(sb, node.identifier.token.source)
	}
}

fold_complete_name :: proc { fold_complete_name_node, fold_complete_name_idx }

fold_complete_name_idx :: #force_inline proc(ctx : ^ConverterContext, node : AstNodeIndex, alloc := context.allocator) -> (destination : [dynamic]string)
{
	return fold_complete_name_node(ctx, ctx.ast[node], alloc)
}

fold_complete_name_node :: #force_inline proc(ctx : ^ConverterContext, node : AstNode, alloc := context.allocator) -> (destination : [dynamic]string)
{
	destination.allocator = alloc
	append_folded_complete_name_node(ctx, &destination, node)
	return
}

append_folded_complete_name :: proc { append_folded_complete_name_node, append_folded_complete_name_idx }

append_folded_complete_name_idx :: #force_inline proc(ctx : ^ConverterContext, destination : ^[dynamic]string, node : AstNodeIndex)
{
	append_folded_complete_name_node(ctx, destination, ctx.ast[node])
}

append_folded_complete_name_node :: proc(ctx : ^ConverterContext, destination : ^[dynamic]string, node : AstNode)
{
	is_not_imgui_namespace :: proc(ctx : ^ConverterContext, node : AstNodeIndex) -> bool
	{
		n := &ctx.ast[node]
		return n.kind != .Namespace || n.namespace.name.source != "ImGui"
	}

	// @correctness @hack: This is a bit of a hack, and could run into issues in complex cases
	has_simple_name :: proc(ctx : ^ConverterContext, name : AstNodeIndex) -> bool
	{
		return name == 0 || ctx.ast[name].identifier.parent == 0
	}

	#partial switch node.kind {
		case .Struct, .Enum, .Union:
			if node.structure.parent_structure != 0 && is_not_imgui_namespace(ctx, node.structure.parent_structure) {
				if has_simple_name(ctx, node.structure.name) {
					append_folded_complete_name(ctx, destination, node.structure.parent_structure)
				}
			}
			else if ctx.ast[node.structure.parent_scope].kind == .Namespace && is_not_imgui_namespace(ctx, node.structure.parent_scope) {
				append_folded_complete_name(ctx, destination, node.structure.parent_scope)
			}
			if node.structure.name != 0 {
				append_folded_complete_name(ctx, destination, node.structure.name)
			}

		case .FunctionDefinition:
			if node.function_def.parent_structure != 0 && is_not_imgui_namespace(ctx, node.function_def.parent_structure) {
				if has_simple_name(ctx, node.function_def.function_name) {
					append_folded_complete_name(ctx, destination, node.function_def.parent_structure)
				}
			}
			else if ctx.ast[node.function_def.parent_scope].kind == .Namespace && is_not_imgui_namespace(ctx, node.function_def.parent_scope) {
				append_folded_complete_name(ctx, destination, node.function_def.parent_scope)
			}
			if node.function_def.function_name != 0 {
				append_folded_complete_name(ctx, destination, node.function_def.function_name)
			}

		case .Namespace:
			if ctx.ast[node.namespace.parent_scope].kind == .Namespace && is_not_imgui_namespace(ctx, node.namespace.parent_scope) {
				append_folded_complete_name(ctx, destination, node.namespace.parent_scope)
			}
			append(destination, node.namespace.name.source)

		case .VariableDeclaration, .TemplateVariableDeclaration:
			append(destination, node.var_declaration.var_name.source)

		case .Typedef:
			append(destination, node.typedef.name.source)

		case .Identifier:
			if node.identifier.parent != 0 {
				append_folded_complete_name(ctx, destination, node.identifier.parent)
			}

			if node.identifier.token.source == "ImGui" { break }

			append(destination, node.identifier.token.source)
	}
}

append_folded_complete_name_type_idx :: proc(ctx : ^ConverterContext, destination : ^[dynamic]string, type : AstTypeIndex)
{
	switch frag in ctx.type_heap[type] {
		case (AstTypeInlineStructure):
			append(destination, fmt.tprintf("s#%v", int(frag)))

		case (AstTypeFunction):
			if frag.name.source != "" {
				append(destination, frag.name.source)
			}
			else {
				append(destination, fmt.tprintf("f#%v", int(type)))
			}

		case (AstTypePointer):
			append(destination, "^")
			append_folded_complete_name_type_idx(ctx, destination, frag.destination_type)

		case (AstTypeArray):
			//TODO(Rennorb) @correctness @completeness: This techincally needs to use the array length as different types,
			// ignored for now.
			append(destination, "[]")
			append_folded_complete_name_type_idx(ctx, destination, frag.element_type)

		case (AstTypeFragment):
			append_folded_complete_name_type_idx(ctx, destination, frag.parent_fragment)

			if frag.identifier.source == "ImGui" { break }

			if .Const in frag.flags {
				append(destination, "c")
			}
			append(destination, frag.identifier.source)

		case (AstTypePrimitive):
			if .Const in frag.flags {
				append(destination, "c")
			}
			for f in frag.fragments {
				append(destination, f.source)
			}

		case (AstTypeAuto):
			append(destination, "auto")

		case (AstTypeVoid):
			append(destination, "void")
	}
}

write_folded_complete_name :: proc { write_folded_complete_name_node, write_folded_complete_name_idx }

write_folded_complete_name_idx :: #force_inline proc(ctx : ^ConverterContext, sb : ^str.Builder, node : AstNodeIndex)
{
	write_folded_complete_name_node(ctx, sb, ctx.ast[node])
}

write_folded_complete_name_node :: proc(ctx : ^ConverterContext, sb : ^str.Builder, node : AstNode)
{
	// @correctness @hack: This is a bit of a hack, and could run into issues in complex cases
	has_simple_name :: proc(ctx : ^ConverterContext, name : AstNodeIndex) -> bool
	{
		return name == 0 || ctx.ast[name].identifier.parent == 0
	}

	#partial switch node.kind {
		case .Struct, .Enum, .Union:
			if node.structure.parent_structure != 0 {
				if has_simple_name(ctx, node.structure.name) {
					write_folded_complete_name(ctx, sb, node.structure.parent_structure)
					str.write_byte(sb, '_')
				}
			}
			else if ctx.ast[node.structure.parent_scope].kind == .Namespace {
				write_folded_complete_name(ctx, sb, node.structure.parent_scope)
				str.write_byte(sb, '_')
			}
			if node.structure.name != 0 {
				write_folded_complete_name(ctx, sb, node.structure.name)
			}
		case .FunctionDefinition:
			if node.function_def.parent_structure != 0 {
				if has_simple_name(ctx, node.function_def.function_name) {
					write_folded_complete_name(ctx, sb, node.function_def.parent_structure)
					str.write_byte(sb, '_')
				}
			}
			else if ctx.ast[node.function_def.parent_scope].kind == .Namespace {
				write_folded_complete_name(ctx, sb, node.function_def.parent_scope)
				str.write_byte(sb, '_')
			}
			if node.function_def.function_name != 0 {
				write_folded_complete_name(ctx, sb, node.function_def.function_name)
			}
		case .Namespace:
			if ctx.ast[node.namespace.parent_scope].kind == .Namespace {
				write_folded_complete_name(ctx, sb, node.namespace.parent_scope)
				str.write_byte(sb, '_')
			}
			str.write_string(sb, node.namespace.name.source)
		case .VariableDeclaration, .TemplateVariableDeclaration:
			str.write_string(sb, node.var_declaration.var_name.source)
		case.Typedef:
			str.write_string(sb, node.typedef.name.source)
		case.Identifier:
			if node.identifier.parent != 0 {
				write_folded_complete_name(ctx, sb, node.identifier.parent)
				str.write_byte(sb, '_')
			}

			if node.identifier.token.source == "ImGui" { break }

			str.write_string(sb, node.identifier.token.source)
	}
}

insert_new_overload :: proc(ctx : ^ConverterContext, name, overload : string)
{
	_, overloads, _, _ := map_entry(&ctx.overload_resolver, name)
	for o in overloads {  // @perf
		if o == overload { return }
	}
	append(overloads, overload)
}

get_identifier_string :: #force_inline proc(ctx : ^ConverterContext, identifier : AstNodeIndex) -> string
{
	return ctx.ast[identifier].identifier.token.source
}

flatten_identifier :: proc(ctx : ^ConverterContext, identifier : AstNodeIndex, alloc := context.allocator) -> [dynamic]string
{
	arr := make([dynamic]string, alloc)
	identifier := identifier
	for identifier != 0 {
		frag := ctx.ast[identifier].identifier
		inject_at(&arr, 0, frag.token.source)
		identifier =frag.parent
	}
	return arr
}

fold_identifier :: proc(ctx : ^ConverterContext, identifier : AstNodeIndex, glue := "_", alloc := context.allocator) -> string
{
	sb := str.builder_make(alloc)
	write_folded_identifier(ctx, &sb, identifier, glue)
	return str.to_string(sb)
}

write_folded_identifier :: proc(ctx : ^ConverterContext, sb : ^str.Builder, identifier : AstNodeIndex, glue := "_")
{
	if identifier == 0 { return }
	node := &ctx.ast[identifier].identifier
	if node.parent != 0 {
		write_folded_identifier(ctx, sb, node.parent, glue)
		str.write_string(sb, glue)
	}
	str.write_string(sb, node.token.source)
}

DefinitionFilter :: bit_set[DefinitionKind]
DefinitionKind :: enum {
	Type,
	Function,
	Variable,
	Namespace,
}
definitionFilterAll := all(DefinitionFilter)

find_definition_for_name :: proc(ctx : ^ConverterContext, initial_scope_node : AstNodeIndex, name : AstNodeIndex, filter := definitionFilterAll, loc := #caller_location) -> (definition : AstNodeIndex, containing_scope : AstNodeIndex)
{
	definition, containing_scope = try_find_definition_for_name(ctx, initial_scope_node, name, filter)
	if definition != 0 { return }

	err := fmt.tprintf("%v : %v '%v' was not found in context", ctx.ast[name].identifier.token.location, filter, fold_identifier(ctx, name, "::"))
	log.error(err, location = loc)
	log.errorf("scope: %#v", initial_scope_node, location = loc)
	panic(err, loc)
}

try_find_definition_for_name :: proc { try_find_definition_for_name_index, try_find_definition_for_name_preflattened }

try_find_definition_for_name_index :: proc(ctx : ^ConverterContext, initial_scope_node : AstNodeIndex, name : AstNodeIndex, filter := definitionFilterAll, loc := #caller_location) -> (definition : AstNodeIndex, containing_scope : AstNodeIndex)
{
	if name == 0 { return }
	name := ctx.ast[name]
	assert(name.kind == .Identifier || name.kind == .UsingNamespace, loc = loc)

	flattened_name := make([dynamic]string, context.temp_allocator) // this is ordered tail_to_head
	for {
		inject_at(&flattened_name, 0, name.identifier.token.source)
		if name.identifier.parent == 0 { break }
		name = ctx.ast[name.identifier.parent]
	}

	return try_find_definition_for_name_preflattened(ctx, initial_scope_node, flattened_name[:], filter)
}

try_find_definition_for_name_preflattened :: proc(ctx : ^ConverterContext, initial_scope_node : AstNodeIndex, flattened_name : []string, filter := definitionFilterAll, loc := #caller_location) -> (definition : AstNodeIndex, containing_scope : AstNodeIndex)
{
	//TODO @cleanup
	maybe_find_definition :: proc(ctx : ^ConverterContext, scope : AstNodeIndex, flattened_name : []string, filter : DefinitionFilter) -> (definition : AstNodeIndex, containing_scope : AstNodeIndex)
	{
		node, found := cvt_get_declared_names(ctx, scope)[flattened_name[0]]
		wrong_type: if found {
			if len(flattened_name) < 2 {
				#partial switch definition_node := ctx.ast[node]; definition_node.kind {
					case .Namespace:
						if .Namespace not_in filter { break wrong_type }
					case .Struct, .Union, .Enum, .Type:
						if .Type      not_in filter { break wrong_type }
					case .FunctionDefinition, .OperatorDefinition:
						if .Function  not_in filter { break wrong_type }
					case .VariableDeclaration:
						if .Variable  not_in filter { break wrong_type }
						if definition_node.var_declaration.parent_structure != 0 && ctx.ast[definition_node.var_declaration.parent_structure].kind == .Enum {
							// return the actual enum in case we detected a enum member from its standalone identifier in its parent scope 
							// e.g. enum A { B };  void fn(){ int a = B; }
							// This B would be detected as in the root scope, becasue the identifier bled into the enums parent scope
							// but that is not the true parent scope of the ident.
							return node, definition_node.var_declaration.parent_structure
						}
				}
				return node, scope
			}
			else {
				return maybe_find_definition(ctx, node, flattened_name[1:], filter)
			}
		}

		if scope == 0 { return }


		#partial switch scope_node := ctx.ast[scope]; scope_node.kind {
			case .Struct, .Enum, .Union:
				definition, containing_scope = maybe_find_definition(ctx, scope_node.structure.parent_scope, flattened_name, filter)

				if definition == 0 && scope_node.structure.parent_structure != 0 {
					definition, containing_scope = maybe_find_definition(ctx, scope_node.structure.parent_structure, flattened_name, filter)
				}

			case .FunctionDefinition:
				definition, containing_scope = maybe_find_definition(ctx, scope_node.function_def.parent_scope, flattened_name, filter)

				if definition == 0 && scope_node.function_def.parent_structure != 0 {
					definition, containing_scope = maybe_find_definition(ctx, scope_node.function_def.parent_structure, flattened_name, filter)
				}
			
			case .Sequence:
				definition, containing_scope = maybe_find_definition(ctx, scope_node.sequence.parent_scope, flattened_name, filter)

			case .Namespace:
				definition, containing_scope = maybe_find_definition(ctx, scope_node.namespace.parent_scope, flattened_name, filter)

			case .Branch:
				definition, containing_scope = maybe_find_definition(ctx, scope_node.branch.parent_scope, flattened_name, filter)

			case .For, .While, .Do:
				definition, containing_scope = maybe_find_definition(ctx, scope_node.loop.parent_scope, flattened_name, filter)
		}

		return
	}

	definition, containing_scope = maybe_find_definition(ctx, initial_scope_node, flattened_name, filter)

	if definition != 0 {
		#partial switch ctx.ast[definition].kind {
			case .Namespace:
				if .Namespace not_in filter {
					return 0, 0
					// if current_head_scope_idx == 0 { return 0, 0 }
					// current_head_scope_idx = cvt_get_parent_scope(ctx, current_head_scope_idx)^
					// continue ctx_stack
				}
			case .Struct, .Union, .Enum, .Type:
				if .Type not_in filter {
					return 0, 0
					// if current_head_scope_idx == 0 { return 0, 0 }
					// current_head_scope_idx = cvt_get_parent_scope(ctx, current_head_scope_idx)^
					// continue ctx_stack
				}
			case .FunctionDefinition, .OperatorDefinition:
				if .Function not_in filter {
					return 0, 0
					// if current_head_scope_idx == 0 { return 0, 0 }
					// current_head_scope_idx = cvt_get_parent_scope(ctx, current_head_scope_idx)^
					// continue ctx_stack
				}
			case .VariableDeclaration:
				if .Variable not_in filter {
					return 0, 0
					// if current_head_scope_idx == 0 { return 0, 0 }
					// current_head_scope_idx = cvt_get_parent_scope(ctx, current_head_scope_idx)^
					// continue ctx_stack
				}
		}
		return
	}
	return 0, 0
}

maybe_follow_typedef :: proc(ctx : ^ConverterContext, containing_scope : AstNodeIndex, maybe_typedef_node : AstNodeIndex) -> (destination : AstNodeIndex)
{
	node := &ctx.ast[maybe_typedef_node]
	if node.kind != .Typedef { return maybe_typedef_node }

	type := &ctx.ast[node.typedef.type]
	#partial switch type.kind {
		case .Struct, .Union, .Enum:
			return node.typedef.type

		case .Type:
			return find_definition_for(ctx, containing_scope, type.type)
	}

	return maybe_typedef_node
}


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


cvt_get_declared_names :: proc(ctx : ^ConverterContext, scope_index : AstNodeIndex, loc := #caller_location) -> ^map[string]AstNodeIndex
{
	scope_node := &ctx.ast[scope_index]
	#partial switch scope_node.kind {
		case .Sequence:
			return &scope_node.sequence.declared_names
		case .For, .While, .Do:
			return &scope_node.loop.declared_names
		case .Namespace:
			return &scope_node.namespace.declared_names
		case .Struct, .Enum, .Union:
			return &scope_node.structure.declared_names
		case .LambdaDefinition:
			return cvt_get_declared_names(ctx, scope_node.lambda_def.underlying_function) // TODO @correctness @completeness: Add proper scoping for lambda captures, wil lneed additional scope o nthe lambda itself probably.+
		case .FunctionDefinition:
			return &scope_node.function_def.declared_names
		case .Branch:
			return &scope_node.branch.declared_names
		case .VariableDeclaration:
			type := ctx.type_heap[scope_node.var_declaration.type]
			if struct_idx, is_inline := type.(AstTypeInlineStructure); is_inline {
				return &ctx.ast[struct_idx].structure.declared_names
			}
			fallthrough
		case:
			panic(fmt.tprintf("[%v] %v is not a valid scope node.", cvt_get_location(ctx, scope_index), scope_node.kind), loc)
		}
}

cvt_get_parent_scope :: proc(ctx : ^ConverterContext, target_node : AstNodeIndex, loc := #caller_location) -> ^AstNodeIndex
{
	node := &ctx.ast[target_node]
	#partial switch node.kind {
		case .Sequence:
			return &node.sequence.parent_scope
		case .For, .While, .Do:
			return &node.loop.parent_scope
		case .Namespace:
			return &node.namespace.parent_scope
		case .Struct, .Enum, .Union:
			return &node.structure.parent_scope
		case .FunctionDefinition:
			return &node.function_def.parent_scope
		case .Branch:
			return &node.branch.parent_scope
		case:
			panic(fmt.tprintf("%v is not a valid scope node.\n%#v", node.kind, node), loc)
	}
}

cvt_get_location :: proc(ctx : ^$Ctx, target_node : AstNodeIndex, loc := #caller_location) -> SourceLocation
{
	node := &ctx.ast[target_node]
	#partial switch node.kind {
		case .Identifier:
			return node.identifier.token.location
		case .Sequence:
			if len(node.sequence.members) > 0 {
				return cvt_get_location(ctx, node.sequence.members[0], loc)
			}
		case .For, .While, .Do:
			if len(node.loop.body_sequence) > 0 {
				return cvt_get_location(ctx, node.loop.body_sequence[0], loc)
			}
		case .Namespace:
			if node.namespace.name.location.file_path != "" {
				return node.namespace.name.location
			}
			else if len(node.namespace.member_sequence) > 0 {
				return cvt_get_location(ctx, node.namespace.member_sequence[0], loc)
			}
		case .Struct, .Enum, .Union:
			if node.structure.name != 0 {
				return cvt_get_location(ctx, node.structure.name, loc)
			}
			else if len(node.structure.members) > 0 {
				return cvt_get_location(ctx, node.structure.members[0], loc)
			}
		case .FunctionDefinition:
			if node.function_def.function_name != 0 {
				return cvt_get_location(ctx, node.function_def.function_name, loc)
			}
			else if len(node.function_def.body_sequence) > 0 {
				return cvt_get_location(ctx, node.function_def.body_sequence[0], loc)
			}
		case .Branch:
			return cvt_get_location(ctx, node.branch.condition[0], loc)
		case .Typedef:
			return node.typedef.name.location
		case .VariableDeclaration:
			return node.var_declaration.var_name.location
		}
	return {}
}
