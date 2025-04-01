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


convert_and_format :: proc(result : ^str.Builder, nodes : []AstNode)
{
	if nodes[0].kind != nil {
		name_context_heap : [dynamic]NameContext
		current_name_context_heap = &name_context_heap
		append(&name_context_heap, NameContext{ parent = -1 })

		str.write_string(result, "package test\n\n")
		write_node(result, nodes, 0, &name_context_heap, 0, -1)
	}

	write_node :: proc(result : ^str.Builder, ast : []AstNode, current_node_index : AstNodeIndex, context_heap : ^[dynamic]NameContext, name_context : NameContextIndex, indent := 0, definition_prefix := "") -> (requires_termination, requires_new_paragraph : bool)
	{
		write_node_sequence :: proc(result : ^str.Builder, ast : []AstNode, sequence : []AstNodeIndex, context_heap : ^[dynamic]NameContext, name_context : NameContextIndex, indent : int, definition_prefix := "")
		{
			previous_requires_termination := false
			previous_requires_new_paragraph := false
			for ci, cii in sequence {
				node_type := ast[ci].kind
				if previous_requires_termination && node_type != .NewLine { str.write_string(result, "; ") }
				if previous_requires_new_paragraph && len(sequence) > cii + 1 {
					if node_type != .NewLine { str.write_string(result, "\n\n") }
					else if ast[sequence[cii + 1]].kind != .NewLine { str.write_byte(result, '\n') }
				}

				previous_requires_termination, previous_requires_new_paragraph = write_node(result, ast, ci, context_heap, name_context, indent, definition_prefix)
			}
		}

		write_preproc_node :: proc(result : ^str.Builder, current_node : AstNode, indent : int) -> bool
		{
			#partial switch current_node.kind {
				case .PreprocIf:
					current_indent_str := str.repeat(ONE_INDENT, max(0, indent - 1), context.temp_allocator)
	
					str.write_string(result, current_indent_str)
					str.write_string(result, "when ")
					write_token_range(result, current_node.token_sequence[:], " ")
					str.write_string(result, " {")
	
				case .PreprocElse:
					current_indent_str := str.repeat(ONE_INDENT, max(0, indent - 1), context.temp_allocator)
	
					str.write_string(result, current_indent_str)
					str.write_string(result, "} else ")
					if len(current_node.token_sequence) > 0 {
						write_token_range(result, current_node.token_sequence[:], " ")
						str.write_byte(result, ' ')
					}
					str.write_string(result, "{ // preproc else")
	
				case .PreprocEndif:
					current_indent_str := str.repeat(ONE_INDENT, max(0, indent - 1), context.temp_allocator)
	
					str.write_string(result, current_indent_str)
					str.write_string(result, "} // preproc endif")

				case:
					return false
			}

			return true
		}

		ONE_INDENT :: "\t"
		current_node := ast[current_node_index]
		#partial switch current_node.kind {
			case .NewLine:
				str.write_byte(result, '\n')

			case .Sequence:
				write_node_sequence(result, ast, current_node.sequence[:], context_heap, name_context, indent + 1)

			case .PreprocDefine:
				current_indent_str := str.repeat(ONE_INDENT, indent, context.temp_allocator)
				define := current_node.preproc_define

				str.write_string(result, current_indent_str)
				str.write_string(result, define.name.source)
				str.write_string(result, " :: ")
				write_token_range(result, define.expansion_tokens, "")

				insert_new_definition(context_heap, 0, define.name.source, current_node_index, define.name.source)

			case .PreprocMacro:
				current_indent_str := str.repeat(ONE_INDENT, indent, context.temp_allocator)
				current_member_indent_str := str.concatenate({ current_indent_str, ONE_INDENT }, context.temp_allocator)
				macro := current_node.preproc_macro

				str.write_string(result, current_indent_str)
				str.write_string(result, macro.name.source)
				str.write_string(result, " :: #force_inline proc \"contextless\" (")
				for arg, i in macro.args {
					if i > 0 { str.write_string(result, ", ") }
					str.write_string(result, arg.source)
					str.write_string(result, " : ")
					fmt.sbprintf(result, "$T%v", i)
				}
				str.write_string(result, ") //TODO: validate those args are not by-ref\n")
				str.write_string(result, current_indent_str); str.write_string(result, "{\n")
				last_broke_line := true
				for tok in macro.expansion_tokens {
					if last_broke_line { str.write_string(result, current_member_indent_str) }
					#partial switch tok.kind {
						case .Semicolon:
							str.write_string(result, ";\n")
							last_broke_line = true

						case:
							str.write_string(result, tok.source)
							last_broke_line = false
					}
				}
				str.write_string(result, current_indent_str); str.write_string(result, "}\n")

				insert_new_definition(context_heap, 0, macro.name.source, current_node_index, macro.name.source)

			case .FunctionDefinition:
				current_indent_str := str.repeat(ONE_INDENT, indent, context.temp_allocator)
				current_member_indent_str := str.concatenate({ current_indent_str, ONE_INDENT }, context.temp_allocator)
				fndef := current_node.function_def

				complete_name := fold_token_range(definition_prefix, fndef.function_name[:])
				assert(len(fndef.function_name) == 1)
				name_context := insert_new_definition(context_heap, name_context, last(fndef.function_name[:]).source, current_node_index, complete_name)
				name_ctx_reset := len(context_heap) // keep fn as leaf node
				defer { // reset, function content is never again relevant after its body
					clear(&context_heap[name_context].definitions)
					resize(context_heap, name_ctx_reset)
				}

				str.write_string(result, complete_name); str.write_string(result, " :: proc(")
				for nidx, i in fndef.arguments {
					if i != 0 { str.write_string(result, ", ") }
					arg := ast[nidx].var_declaration

					insert_new_definition(context_heap, name_context, arg.var_name.source, nidx, arg.var_name.source)

					str.write_string(result, arg.var_name.source)
					str.write_string(result, " : ")
					write_type(result, ast, ast[arg.type], context_heap, name_context)

					if arg.initializer_expression != {} {
						str.write_string(result, " = ")
						write_node(result, ast, arg.initializer_expression, context_heap, name_context)
					}
				}
				str.write_byte(result, ')')
				if fndef.return_type != {} && ast[fndef.return_type].type[0].source != "void" {
					str.write_string(result, " -> ")
					write_type(result, ast, ast[fndef.return_type], context_heap, name_context)
				}
				str.write_byte(result, '\n')
				str.write_string(result, current_indent_str); str.write_string(result, "{\n")

				for ci in fndef.body_sequence {
					str.write_string(result, current_member_indent_str)
					write_node(result, ast, ci, context_heap, name_context, indent + 1)
					str.write_byte(result, '\n')
				}
				str.write_string(result, current_indent_str); str.write_byte(result, '}')

			case .Struct, .Union:
				current_indent_str := str.repeat(ONE_INDENT, indent, context.temp_allocator)
				current_member_indent_str := str.concatenate({ current_indent_str, ONE_INDENT }, context.temp_allocator)
				structure := current_node.struct_or_union

				str.write_string(result, current_indent_str);
				complete_structure_name := fold_token_range(definition_prefix, structure.name)
				str.write_string(result, complete_structure_name);
				str.write_string(result, current_node.kind == .Struct ? " :: struct {\n" : " :: struct #raw_union {\n")

				og_name_context := name_context
				name_context := name_context

				if structure.base_type != nil {
					// copy over defs from base type, using their location
					_, base_context := find_definition_for_name(context_heap, name_context, structure.base_type)

					base_member_name := str.concatenate({ "__base_", str.to_lower(structure.base_type[len(structure.base_type) - 1].source, context.temp_allocator) })
					name_context = transmute(NameContextIndex) append_return_index(context_heap, NameContext{
						parent      = name_context,
						node        = base_context.node,
						definitions = base_context.definitions, // make sure not to modify these! ok because we push another context right after
					})

					str.write_string(result, current_member_indent_str)
					str.write_string(result, "using ")
					str.write_string(result, base_member_name)
					str.write_string(result, " : ")
					str.write_string(result, base_context.complete_name)
					str.write_string(result, ",\n")
				}

				name_context = transmute(NameContextIndex) append_return_index(context_heap, NameContext{ node = current_node_index, parent = name_context, complete_name = complete_structure_name })
				context_heap[og_name_context].definitions[last(structure.name).source] = name_context
				// no reset here, struct context might be relevant later on

				has_static_var_members := false
				has_inplicit_initializer := false
				for ci in structure.members {
					#partial switch ast[ci].kind {
						case .VariableDeclaration:
							member := ast[ci].var_declaration
							if .Static in member.flags { has_static_var_members = true; continue }

							d := insert_new_definition(context_heap, name_context, member.var_name.source, ci, member.var_name.source)

							str.write_string(result, current_member_indent_str);
							str.write_string(result, member.var_name.source);
							str.write_string(result, " : ")
							write_type(result, ast, ast[member.type], context_heap, name_context)
							str.write_string(result, ",\n")

							has_inplicit_initializer |= member.initializer_expression != {}

						case:
							if write_preproc_node(result, ast[ci], indent) {
								str.write_byte(result, '\n')
							}
					}
				}

				str.write_string(result, current_indent_str); str.write_byte(result, '}')

				if has_static_var_members {
					str.write_byte(result, '\n')
					for midx in structure.members {
						if ast[midx].kind != .VariableDeclaration || .Static not_in ast[midx].var_declaration.flags { continue }
						member := ast[midx].var_declaration

						complete_member_name := fold_token_range(complete_structure_name, { member.var_name })
						insert_new_definition(context_heap, name_context, member.var_name.source, midx, complete_member_name)

						str.write_byte(result, '\n')
						str.write_string(result, current_indent_str);
						str.write_string(result, complete_member_name);
						str.write_string(result, " : ")
						write_type(result, ast, ast[member.type], context_heap, name_context)

						if member.initializer_expression != {} {
							str.write_string(result, " = ");
							write_node(result, ast, member.initializer_expression, context_heap, name_context)
						}
					}
				}

				if has_inplicit_initializer || structure.initializer != {} {
					initializer := ast[structure.initializer]

					complete_initializer_name := str.concatenate({ complete_structure_name, "_init" })
					name_context := insert_new_definition(context_heap, name_context, last(initializer.function_def.function_name[:]).source, structure.initializer, complete_initializer_name)
					context_heap_reset := len(context_heap) // keep fn as leaf node
					defer {
						clear(&context_heap[name_context].definitions)
						resize(context_heap, context_heap_reset)
					}

					insert_new_definition(context_heap, name_context, "this", -1, "this")

					str.write_string(result, "\n\n")
					str.write_string(result, current_indent_str);
					str.write_string(result, complete_initializer_name);
					str.write_string(result, " :: proc(this : ^")
					str.write_string(result, complete_structure_name);
					if initializer.kind == .FunctionDefinition {
						for nidx, i in initializer.function_def.arguments {
							str.write_string(result, ", ")
							arg := ast[nidx].var_declaration

							insert_new_definition(context_heap, name_context, arg.var_name.source, nidx, arg.var_name.source)

							str.write_string(result, arg.var_name.source)
							str.write_string(result, " : ")
							write_type(result, ast, ast[arg.type], context_heap, name_context)

							if arg.initializer_expression != {} {
								str.write_string(result, " = ")
								write_node(result, ast, arg.initializer_expression, context_heap, name_context)
							}
						}
					}
					str.write_string(result, ")\n")

					str.write_string(result, current_indent_str); str.write_string(result, "{\n")
					for ci in structure.members {
						if ast[ci].kind != .VariableDeclaration { continue }
						member := ast[ci].var_declaration
						if member.initializer_expression == {} { continue }

						str.write_string(result, current_member_indent_str);
						str.write_string(result, "this.")
						str.write_string(result, member.var_name.source)
						str.write_string(result, " = ")
						write_node(result, ast, member.initializer_expression, context_heap, name_context)
						str.write_byte(result, '\n')
					}
					if initializer.kind == .FunctionDefinition {
						for ci in initializer.function_def.body_sequence {
							str.write_string(result, current_member_indent_str)
							write_node(result, ast, ci, context_heap, name_context, indent + 1)
							str.write_byte(result, '\n')
						}
					}
					str.write_string(result, current_indent_str); str.write_byte(result, '}')
				}

				for midx in structure.members {
					#partial switch ast[midx].kind {
						case .FunctionDefinition:
							member_fn := ast[midx].function_def

							complete_name := fold_token_range(complete_structure_name, member_fn.function_name[:])
							assert(len(member_fn.function_name) == 1)
							name_context := insert_new_definition(context_heap, name_context, last(member_fn.function_name[:]).source, midx, complete_name)
							context_heap_reset := len(context_heap) // keep fn as leaf node
							defer {
								clear(&context_heap[name_context].definitions)
								resize(context_heap, context_heap_reset)
							}

							insert_new_definition(context_heap, name_context, "this", -1, "this")

							str.write_string(result, "\n\n")
							str.write_string(result, current_indent_str);
							str.write_string(result, complete_name);
							str.write_string(result, " :: proc(this : ^")
							str.write_string(result, complete_structure_name);
							for nidx, i in member_fn.arguments {
								str.write_string(result, ", ")
								arg := ast[nidx].var_declaration

								insert_new_definition(context_heap, name_context, arg.var_name.source, nidx, arg.var_name.source)

								str.write_string(result, arg.var_name.source)
								str.write_string(result, " : ")
								write_type(result, ast, ast[arg.type], context_heap, name_context)

								if arg.initializer_expression != {} {
									str.write_string(result, " = ")
									write_node(result, ast, arg.initializer_expression, context_heap, name_context)
								}
							}
							str.write_byte(result, ')')

							if member_fn.return_type != {} && ast[member_fn.return_type].type[0].source != "void" {
								str.write_string(result, " -> ")
								write_type(result, ast, ast[member_fn.return_type], context_heap, name_context)
							}

							str.write_byte(result, '\n')

							str.write_string(result, current_indent_str); str.write_string(result, "{\n")
							for ci in member_fn.body_sequence {
								str.write_string(result, current_member_indent_str)
								write_node(result, ast, ci, context_heap, name_context, indent + 1)
								str.write_byte(result, '\n')
							}
							str.write_string(result, current_indent_str); str.write_byte(result, '}')

							requires_new_paragraph = true

						case .Struct, .Union:
							str.write_string(result, "\n\n")
							ast[midx].struct_or_union.name = slice.concatenate([][]Token{structure.name, ast[midx].struct_or_union.name})
							write_node(result, ast, midx, context_heap, name_context, indent)

							requires_new_paragraph = true
					}
				}

			case .VariableDeclaration:
				vardef := current_node.var_declaration

				complete_name := fold_token_range(definition_prefix, { vardef.var_name })
				insert_new_definition(context_heap, name_context, vardef.var_name.source, current_node_index, complete_name)

				str.write_string(result, complete_name);
				str.write_string(result, " : ")
				write_type(result, ast, ast[vardef.type], context_heap, name_context)

				if vardef.initializer_expression != {} {
					str.write_string(result, " = ")
					write_node(result, ast, vardef.initializer_expression, context_heap, name_context)
				}
				requires_termination = true

			case .Return:
				str.write_string(result, "return")

				if current_node.return_.expression != {} {
					str.write_byte(result, ' ')
					write_node(result, ast, current_node.return_.expression, context_heap, name_context)
				}

			case .LiteralBool, .LiteralFloat, .LiteralInteger, .LiteralString, .LiteralCharacter, .Continue, .Break:
				str.write_string(result, current_node.literal.source)

			case .LiteralNull:
				str.write_string(result, "nil")

			case .ExprUnaryLeft:
				switch current_node.unary_left.operator {
					case .Invert:
						str.write_byte(result, '!')
						write_node(result, ast, current_node.unary_left.right, context_heap, name_context)

					case .Dereference:
						write_node(result, ast, current_node.unary_left.right, context_heap, name_context)
						str.write_byte(result, '^')

					case .Minus:
						str.write_byte(result, '-')
						write_node(result, ast, current_node.unary_left.right, context_heap, name_context)

					case .Increment:
						str.write_string(result, "pre_incr(&")
						write_node(result, ast, current_node.unary_left.right, context_heap, name_context)
						str.write_string(result, ")")

					case .Decrement:
						str.write_string(result, "pre_decr(&")
						write_node(result, ast, current_node.unary_left.right, context_heap, name_context)
						str.write_string(result, ")")
				}

				requires_termination = true

			case .ExprUnaryRight:
				#partial switch current_node.unary_right.operator {
					case .Increment:
						write_node(result, ast, current_node.unary_right.left, context_heap, name_context)
						str.write_string(result, " += 1")

					case .Decrement:
						write_node(result, ast, current_node.unary_right.left, context_heap, name_context)
						str.write_string(result, " -= 1")
				}

				requires_termination = true

			case .ExprBinary:
				write_node(result, ast, current_node.binary.left, context_heap, name_context)
				str.write_byte(result, ' ')
				str.write_byte(result, u8(current_node.binary.operator))
				str.write_byte(result, ' ')
				write_node(result, ast, current_node.binary.right, context_heap, name_context)

				requires_termination = true

			case .MemberAccess:
				member := ast[current_node.member_access.member]
				if member.kind == .FunctionCall {
					fncall := member.function_call

					is_ptr := current_node.member_access.through_pointer
					this_root, this_context := resolve_type(ast, current_node.member_access.expression, context_heap, name_context)

					// maybe find basetype for this member
					this_idx := transmute(NameContextIndex) mem.ptr_sub(this_context, &context_heap[0])
					_, actual_member_context := find_definition_for_name(context_heap, this_idx, fncall.qualified_name[:])

					this_type := ast[context_heap[actual_member_context.parent].node]
					if this_type.kind != .Struct && this_type.kind != .Union {
						panic(fmt.tprintf("Unexpected this type %v", this_type))
					}

					str.write_string(result, actual_member_context.complete_name)
					str.write_byte(result, '(')
					if !is_ptr { str.write_byte(result, '&') }
					write_node(result, ast, current_node.member_access.expression, context_heap, name_context)
					for pidx, i in fncall.parameters {
						str.write_string(result, ", ")
						write_node(result, ast, pidx, context_heap, name_context)
					}
					str.write_byte(result, ')')
				}
				else {
					write_node(result, ast, current_node.member_access.expression, context_heap, name_context)
					str.write_byte(result, '.')
					write_node(result, ast, current_node.member_access.member, context_heap, name_context)
				}

				requires_termination = true

			case .ExprIndex:
				write_node(result, ast, current_node.index.array_expression, context_heap, name_context)
				str.write_byte(result, '[')
				write_node(result, ast, current_node.index.index_expression, context_heap, name_context)
				str.write_byte(result, ']')

			case .Identifier:
				_, def := find_definition_for_name(context_heap, name_context, current_node.identifier[:])
				parent := ast[context_heap[def.parent].node]

				if ((parent.kind == .Struct || parent.kind == .Union) && .Static not_in ast[def.node].var_declaration.flags) {
					str.write_string(result, "this.")
				}

				write_token_range(result, current_node.identifier[:])

			case .FunctionCall:
				fncall := current_node.function_call

				str.write_string(result, last(fncall.qualified_name[:]).source)
				str.write_byte(result, '(')
				for pidx, i in fncall.parameters {
					if i != 0 { str.write_string(result, ", ") }
					write_node(result, ast, pidx, context_heap, name_context)
				}
				str.write_byte(result, ')')

				requires_termination = true

			case .Namespace:
				ns := current_node.namespace

				complete_name := fold_token_range(definition_prefix, { ns.name })
				name_context := insert_new_definition(context_heap, name_context, ns.name.source, current_node_index, complete_name)

				write_node_sequence(result, ast, ns.sequence[:], context_heap, name_context, indent, complete_name)


			case .For, .While, .Do:
				loop := current_node.loop

				current_indent_str := str.repeat(ONE_INDENT, indent, context.temp_allocator)
				current_member_indent_str := str.concatenate({ current_indent_str, ONE_INDENT }, context.temp_allocator)

				str.write_string(result, "for")
				if loop.initializer != {} || loop.loop_statement != {} {
					str.write_byte(result, ' ')
					if loop.initializer != {} { write_node(result, ast, loop.initializer, context_heap, name_context) }
					str.write_string(result, "; ")
					if loop.condition != {} { write_node(result, ast, loop.condition, context_heap, name_context) }
					str.write_string(result, "; ")
					if loop.loop_statement != {} { write_node(result, ast, loop.loop_statement, context_heap, name_context) }
				}
				else if loop.condition != {} && current_node.kind != .Do {
					str.write_byte(result, ' ')
					write_node(result, ast, loop.condition, context_heap, name_context)
				}
				str.write_string(result, " {\n")
				
				for ci in loop.body_sequence {
					str.write_string(result, current_member_indent_str)
					write_node(result, ast, ci, context_heap, name_context, indent + 1)
					str.write_byte(result, '\n')
				}

				if loop.condition != {} && current_node.kind == .Do {
					str.write_byte(result, '\n')
					str.write_string(result, current_member_indent_str)
					str.write_string(result, "if !(")
					write_node(result, ast, loop.condition, context_heap, name_context)
					str.write_string(result, ") { break }\n")
				}

				str.write_string(result, current_indent_str); str.write_string(result, "}")

				requires_new_paragraph = true

			case:
				was_preproc := #force_inline write_preproc_node(result, current_node, indent)
				if was_preproc {
					break
				}

				log.error("Unknown ast node:", current_node)
				runtime.trap();
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

	write_type :: proc(result : ^str.Builder, ast : []AstNode, r : AstNode, context_heap : ^[dynamic]NameContext, name_context : NameContextIndex)
	{
		type_tokens := r.type[:]

		converted_type_tokens := make([dynamic]TypeSegment, 0, len(type_tokens), context.temp_allocator)
		translate_type(&converted_type_tokens, ast, type_tokens)

		last_type_was_ident := false
		for _t in converted_type_tokens {
			switch t in _t {
				case _TypePtr:
					str.write_byte(result, '^')

				case _TypeFragment:
					if last_type_was_ident { str.write_byte(result, '_') }
					str.write_string(result, t.identifier.source)
					if len(t.generic_arguments) > 0 {
						str.write_byte(result, '(')
						for _, g in t.generic_arguments {
							str.write_string(result, g.source)
						}
						str.write_byte(result, ')')
					}

				case _TypeArray:
					str.write_byte(result, '[')
					write_token_range(result, t.length_expression[:], "")
					str.write_byte(result, ']')
			}
			_, last_type_was_ident = _t.(_TypeFragment)
		}
	}

	strip_type :: proc(output : ^[dynamic]Token, input : TokenRange)
	{
		generic_depth := 0
		for token in input {
			#partial switch token.kind {
				case .Identifier:
					if generic_depth == 0 {
						append(output, token)
					}
					
				case .BracketTriangleOpen:
					generic_depth += 1
				case .BracketTriangleClose:
					generic_depth -= 1
			}
		}
	}

	resolve_type :: proc(ast : []AstNode, current_node_index : AstNodeIndex, context_heap : ^[dynamic]NameContext, name_context : NameContextIndex) -> (root, leaf : ^NameContext)
	{
		current_node := ast[current_node_index]
		#partial switch current_node.kind {
			case .Identifier:
				_, var_def := find_definition_for_name(context_heap, name_context, current_node.identifier[:])
				assert_eq(ast[var_def.node].kind, AstNodeKind.VariableDeclaration)

				return resolve_type(ast, var_def.node, context_heap, var_def.parent)
			
			case .ExprUnaryLeft:
				return resolve_type(ast, current_node.unary_left.right, context_heap, name_context)

			case .ExprUnaryRight:
				return resolve_type(ast, current_node.unary_right.left, context_heap, name_context)

			case .MemberAccess:
				member_access := current_node.member_access
				_, this_context := resolve_type(ast, member_access.expression, context_heap, name_context)
				this_idx := transmute(NameContextIndex) mem.ptr_sub(this_context, &context_heap[0])

				member := ast[member_access.member]
				#partial switch member.kind {
					case .Identifier:
						return resolve_type(ast, member_access.member, context_heap, this_idx)

					case .FunctionCall:
						fndef_idx := this_context.definitions[last(member.function_call.qualified_name[:]).source]
						fndef_ctx := context_heap[fndef_idx]

						assert_eq(ast[fndef_ctx.node].kind, AstNodeKind.FunctionDefinition)
						fndef := ast[fndef_ctx.node].function_def

						return_type := ast[fndef.return_type].type

						stripped_type := make([dynamic]Token, 0, len(return_type), context.temp_allocator)
						strip_type(&stripped_type, return_type[:])

						return find_definition_for_name(context_heap, this_idx, stripped_type[:])

					case:
						panic(fmt.tprintf("Not implemented %v", member))
				}

			case .VariableDeclaration:
				def_node := current_node.var_declaration

				stripped_type := make([dynamic]Token, 0, len(ast[def_node.type].type), context.temp_allocator)
				strip_type(&stripped_type, ast[def_node.type].type[:])

				if last(stripped_type[:]).source == "auto" {
					panic("auto resolver not implemented");
				}

				return find_definition_for_name(context_heap, name_context, stripped_type[:])

			// case .FunctionCall:
			// 	fncall := current_node.function_call
			// 	fncall.

			case:
				panic(fmt.tprintf("Not implemented %v", current_node))
		}

		unreachable();
	}

	translate_type :: proc(output : ^[dynamic]TypeSegment, ast : []AstNode, input : TokenRange)
	{
		remaining_input := input

		transform_from_short :: proc(output : ^[dynamic]TypeSegment, input : TokenRange, $prefix : string) -> (remaining_input : TokenRange)
		{
			if len(input) == 0 || input[0].kind != .Identifier { // short, short*
				remaining_input = input
				append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = prefix+"16" } })
			}
			else if input[0].source == "int" { // short int
				remaining_input = input[1:]
				append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = prefix+"16" } })
			}
			else {
				panic("Failed to transform "+prefix+" short");
			}

			return
		}

		transform_from_long :: proc(output : ^[dynamic]TypeSegment, input : TokenRange, $prefix : string) -> (remaining_input : TokenRange)
		{
			if len(input) == 0 || input[0].kind != .Identifier { // long, long*
				remaining_input = input
				append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = prefix+"32" } })
			}
			else if input[0].source == "int" { // long int
				remaining_input = input[1:]
				append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = prefix+"32" } })
			}
			else if input[0].source == "long" { // long long
				if len(input) == 1 || input[1].kind != .Identifier { // long long, long long*
					remaining_input = input[1:]
					append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = prefix+"64" } })
				}
				else if input[1].source == "int" { // long long int
					remaining_input = input[2:]
					append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = prefix+"64" } })
				}
			}
			else {
				panic("Failed to transform "+prefix+" long");
			}
			return
		}

		#partial switch input[0].kind {
			case .Identifier:
				switch input[0].source {
					case "const":
						remaining_input = input[1:]

					case "signed":
						switch input[1].source {
							case "char":
								remaining_input = input[2:]
								append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "i8" } })

							case "int":
								remaining_input = input[2:]
								append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "i32" } })

							case "short":
								remaining_input = transform_from_short(output, input[2:], "i")

							case "long":
								remaining_input = transform_from_long(output, input[2:], "i")
						}

					case "unsigned":
						switch input[1].source {
							case "char":
								remaining_input = input[2:]
								append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "u8" } })

							case "int":
								remaining_input = input[2:]
								append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "u32" } })

							case "short":
								remaining_input = transform_from_short(output, input[2:], "u")

							case "long":
								remaining_input = transform_from_long(output, input[2:], "u")
						}

					case "char":
						remaining_input = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "u8" } }) // funny implementation defined singnedness, interpret as unsigned

					case "int":
						remaining_input = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "i32" } })

					case "short":
						remaining_input = transform_from_short(output, input[1:], "i")

					case "long":
						remaining_input = transform_from_long(output, input[1:], "i")

					case "float":
						remaining_input = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "f32" } })

					case "double":
						remaining_input = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "f64" } })

					case:
						append(output, _TypeFragment{ identifier = input[0] })
						remaining_input = input[1:]
				}

			case .Star:
				remaining_input = input[1:]
				inject_at(output, 0, _TypePtr{})

			case .AstNode: // used for array expression for now
				length_expression : [dynamic]Token
				transform_expression(&length_expression, ast, transmute(AstNodeIndex) input[0].location.column)
				transform_expression :: proc(output : ^[dynamic]Token, ast : []AstNode, current_node_index : AstNodeIndex)
				{
					node := ast[current_node_index]
					#partial switch node.kind {
						case .LiteralBool, .LiteralCharacter, .LiteralFloat, .LiteralInteger, .LiteralString:
							append(output, node.literal)
						case .ExprUnaryLeft:
							switch node.unary_left.operator {
								case .Minus:
									append(output, Token{ kind = .Minus, source = "-" })
									transform_expression(output, ast, node.unary_left.right)
								case .Dereference:
									transform_expression(output, ast, node.unary_left.right)
									append(output, Token{ kind = .Minus, source = "^" })
								case .Invert:
									append(output, Token{ kind = .Minus, source = "!" })
									transform_expression(output, ast, node.unary_left.right)
								case .Increment:
									transform_expression(output, ast, node.unary_left.right)
									append(output, Token{ kind = .PrefixIncrement, source = " += " })
									append(output, Token{ kind = .LiteralInteger, source = "1 /*TODO: was prefix*/" })
								case .Decrement:
									transform_expression(output, ast, node.unary_left.right)
									append(output, Token{ kind = .PrefixIncrement, source = " -= " })
									append(output, Token{ kind = .LiteralInteger, source = "1 /*TODO: was prefix*/" })
							}
						case .ExprUnaryRight:
							#partial switch node.unary_right.operator {
								case .Increment:
									transform_expression(output, ast, node.unary_right.left)
									append(output, Token{ kind = .PrefixIncrement, source = " += " })
									append(output, Token{ kind = .LiteralInteger, source = "1" })
								case .Decrement:
									transform_expression(output, ast, node.unary_right.left)
									append(output, Token{ kind = .PrefixIncrement, source = " -= " })
									append(output, Token{ kind = .LiteralInteger, source = "1" })
							}
						case .ExprBinary:
							transform_expression(output, ast, node.binary.left)
							t := Token{ kind = TokenKind(node.binary.operator) }
							switch node.binary.operator {
								case .Assign:   t.source = "="
								case .Plus:     t.source = "+"
								case .Minus:    t.source = "-"
								case .Times:    t.source = "*"
								case .Divide:   t.source = "/"
								case .And:      t.source = "&"
								case .Or:       t.source = "|"
								case .Xor:      t.source = "~"
								case .Less:     t.source = "<"
								case .Greater:  t.source = ">"
								case .LogicAnd: t.source = "&&"
								case .LogicOr:  t.source = "||"
								case .Equals:   t.source = "=="
								case .NotEquals:t.source = "!="
								case .LessEq:   t.source = "<="
								case .GreaterEq:t.source = ">="
							}
							append(output, t)
							transform_expression(output, ast, node.binary.right)
					}
				}
				inject_at(output, 0, _TypeArray{ length_expression })
				remaining_input = input[1:]

			case:
				remaining_input = input[1:]
		}

		if(len(remaining_input) > 0) { translate_type(output, ast, remaining_input) }
	}
}

NameContextIndex :: distinct int
NameContext :: struct {
	node : AstNodeIndex,
	parent : NameContextIndex,
	complete_name : string,
	definitions : map[string]NameContextIndex,
}

insert_new_definition :: proc(context_heap : ^[dynamic]NameContext, current_index : NameContextIndex, name : string, node : AstNodeIndex, complete_name : string) -> NameContextIndex
{
	idx := transmute(NameContextIndex) append_return_index(context_heap, NameContext{ node = node, parent = current_index, complete_name = complete_name})
	context_heap[current_index].definitions[name] = idx
	return idx
}

find_definition_for_name :: proc(context_heap : ^[dynamic]NameContext, current_index : NameContextIndex, compound_identifier : TokenRange) -> (root_context, name_context : ^NameContext)
{
	im_root_context := &context_heap[current_index]

	ctx_stack: for {
		current_context := im_root_context

		for segment in compound_identifier {
			child_idx, exists := current_context.definitions[segment.source]
			if !exists {
				if im_root_context.parent == -1 { break ctx_stack }

				im_root_context = &context_heap[im_root_context.parent]

				continue ctx_stack
			}

			current_context = &context_heap[child_idx]
		}

		return im_root_context, current_context
	}

	loc := runtime.Source_Code_Location{ compound_identifier[0].location.file_path, cast(i32) compound_identifier[0].location.row, cast(i32) compound_identifier[0].location.column, "" }
	dump_context_stack(context_heap[:], current_index)
	panic(fmt.tprintf("'%v' was not found in context", compound_identifier), loc)
}

@(thread_local) current_name_context_heap : ^[dynamic]NameContext
fmt_name_ctx_idx_a : fmt.User_Formatter : proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool
{
	node := transmute(^NameContextIndex)arg.data
	return fmt_name_ctx_idx(fi, node, verb)
}

fmt_name_ctx_idx :: proc(fi: ^fmt.Info, idx: ^NameContextIndex, verb: rune) -> bool
{
	if current_name_context_heap == nil { return false }
	if idx == nil {
		io.write_string(fi.writer, "NameContextIndex <nil>")
		return true
	}
	if idx^ == -1 {
		io.write_string(fi.writer, "NameContextIndex -1")
		return true
	}


	fmt.wprintf(fi.writer, "NameContextIndex %v -> ", transmute(int) idx^)

	ctx := current_name_context_heap[idx^]
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




dump_context_stack :: proc(context_heap : []NameContext, name_context_idx : NameContextIndex, name := "", indent := " ", return_at : NameContextIndex = -1)
{
	name_context := context_heap[name_context_idx]
	
	fmt.eprintf("#%v %v%v -> ", transmute(int)name_context_idx, indent, name);

	if len(name_context.definitions) == 0 {
		fmt.eprintf("<leaf>\n");
	}
	else {
		fmt.eprintf("%v children:\n", len(name_context.definitions))

		indent := str.concatenate({ indent, "  " }, context.temp_allocator)
		for name, didx in name_context.definitions {
			dump_context_stack(context_heap, didx, name, indent, name_context_idx)
		}
	}

	if name_context.parent == -1 || name_context.parent == return_at { return }

	indent := str.concatenate({ indent, "  " }, context.temp_allocator)
	dump_context_stack(context_heap, name_context.parent, "<parent>", indent, name_context_idx)
}


_TypePtr :: struct {}
_TypeArray :: struct {
	length_expression : [dynamic]Token,
}
_TypeFragment :: struct {
	identifier : Token,
	generic_arguments : map[string]Token,
}

TypeSegment :: union #no_nil { _TypePtr, _TypeArray, _TypeFragment }
Type :: []TypeSegment
