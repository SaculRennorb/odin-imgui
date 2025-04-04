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


convert_and_format :: proc(result : ^str.Builder, nodes : []AstNode)
{
	if nodes[0].kind != nil {
		name_context_heap : [dynamic]NameContext
		current_name_context_heap = &name_context_heap
		append(&name_context_heap, NameContext{ parent = -1 })

		str.write_string(result, "package test\n\n")
		write_node({result, nodes, &name_context_heap}, 0, 0, "")
	}

	ConverterContext :: struct {
		result : ^str.Builder,
		ast : []AstNode,
		context_heap : ^[dynamic]NameContext,
	}

	write_node :: proc(ctx : ConverterContext, current_node_index : AstNodeIndex, name_context : NameContextIndex, indent_str := "", definition_prefix := "") -> (requires_termination, requires_new_paragraph, swallow_paragraph : bool)
	{
		write_node_sequence :: proc(ctx : ConverterContext, sequence : []AstNodeIndex, name_context : NameContextIndex, indent_str : string, definition_prefix := "")
		{
			previous_requires_termination := false
			previous_requires_new_paragraph := false
			should_swallow_paragraph := false
			previous_node_kind : AstNodeKind
			
			for cii := 0; cii < len(sequence); cii += 1 {
				ci := sequence[cii]
				if ctx.ast[ci].attached { continue }

				node_kind := ctx.ast[ci].kind
				if previous_requires_termination && node_kind != .NewLine { str.write_string(ctx.result, "; ") }
				if previous_requires_new_paragraph && len(sequence) > cii + 1 {
					if node_kind != .NewLine { str.write_string(ctx.result, "\n\n") }
					else if ctx.ast[sequence[cii + 1]].kind != .NewLine { str.write_byte(ctx.result, '\n') }
				}
				if node_kind != .NewLine && previous_node_kind == .NewLine {
					str.write_string(ctx.result, indent_str)
				}
				if should_swallow_paragraph {
					should_swallow_paragraph = false
					if ctx.ast[ci].kind == .NewLine {
						cii += 1
						ci = sequence[cii]
					}
					if ctx.ast[ci].kind == .NewLine { continue }
				}

				previous_requires_termination, previous_requires_new_paragraph, should_swallow_paragraph = write_node(ctx, ci, name_context, indent_str, definition_prefix)
				previous_node_kind = node_kind
			}
		}

		write_preproc_node :: proc(result : ^str.Builder, current_node : AstNode) -> bool
		{
			#partial switch current_node.kind {
				case .PreprocIf:
					str.write_string(result, "when ")
					write_token_range(result, current_node.token_sequence[:], " ")
					str.write_string(result, " {")
	
				case .PreprocElse:
					str.write_string(result, "} else ")
					if len(current_node.token_sequence) > 0 {
						write_token_range(result, current_node.token_sequence[:], " ")
						str.write_byte(result, ' ')
					}
					str.write_string(result, "{ // preproc else")
	
				case .PreprocEndif:
					str.write_string(result, "} // preproc endif")

				case:
					return false
			}

			return true
		}

		write_function :: proc(ctx : ConverterContext, name_context : NameContextIndex, function_node_idx : AstNodeIndex, complete_structure_name : string, is_member_fn : bool, indent_str : string)
		{
			fn_node := &ctx.ast[function_node_idx].function_def

			complete_name := fold_token_range(complete_structure_name, fn_node.function_name[:])

			assert_eq(len(fn_node.function_name), 1)
			// fold attached comments form forward declaration. This also works when chaining forward declarations
			_, forward_declared_context := try_find_definition_for_name(ctx.context_heap, name_context, fn_node.function_name[:])
			if forward_declared_context != nil {
				forward_declaration := ctx.ast[forward_declared_context.node]
				assert_eq(forward_declaration.kind, AstNodeKind.FunctionDefinition)

				forward_comments := forward_declaration.function_def.attached_comments
				inject_at(&fn_node.attached_comments, 0, ..forward_comments[:])
			}

			name_context := insert_new_definition(ctx.context_heap, name_context, last(fn_node.function_name[:]).source, function_node_idx, complete_name)

			if .ForwardDeclaration in fn_node.flags {
				return // Don't insert forward declarations, only insert the name context leaf node.
			}

			context_heap_reset := len(ctx.context_heap) // keep fn as leaf node, since expressions cen reference the name
			defer {
				clear(&ctx.context_heap[name_context].definitions)
				resize(ctx.context_heap, context_heap_reset)
			}

			// write directly, they are marked for skipping in write_sequence
			for aid in fn_node.attached_comments {
				write_node(ctx, aid, name_context)
			}

			str.write_string(ctx.result, indent_str);
			str.write_string(ctx.result, complete_name);
			str.write_string(ctx.result, " :: proc(")

			arg_count := 0

			for ti in fn_node.template_spec {
				if arg_count > 0 { str.write_string(ctx.result, ", ") }

				str.write_byte(ctx.result, '$')
				write_node(ctx, ti, name_context)
			}

			if is_member_fn {
				if arg_count > 0 { str.write_string(ctx.result, ", ") }

				str.write_string(ctx.result, "this : ^")
				str.write_string(ctx.result, complete_structure_name);

				insert_new_definition(ctx.context_heap, name_context, "this", -1, "this")

				arg_count += 1
			}

			for nidx in fn_node.arguments {
				if arg_count > 0 { str.write_string(ctx.result, ", ") }
				arg := ctx.ast[nidx].var_declaration

				insert_new_definition(ctx.context_heap, name_context, arg.var_name.source, nidx, arg.var_name.source)

				str.write_string(ctx.result, arg.var_name.source)
				str.write_string(ctx.result, " : ")
				write_type(ctx, ctx.ast[arg.type], name_context)

				if arg.initializer_expression != {} {
					str.write_string(ctx.result, " = ")
					write_node(ctx, arg.initializer_expression, name_context)
				}

				arg_count += 1
			}

			str.write_byte(ctx.result, ')')

			if fn_node.return_type != {} && ctx.ast[fn_node.return_type].type[0].source != "void" {
				str.write_string(ctx.result, " -> ")
				write_type(ctx, ctx.ast[fn_node.return_type], name_context)
			}

			switch len(fn_node.body_sequence) {
				case 0:
					str.write_string(ctx.result, " { }");

				case 1:
					str.write_string(ctx.result, " { ");
					write_node(ctx, fn_node.body_sequence[0], name_context)
					str.write_string(ctx.result, " }");

				case:
					str.write_byte(ctx.result, '\n')

					str.write_string(ctx.result, indent_str); str.write_string(ctx.result, "{")
					body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
					write_node_sequence(ctx, fn_node.body_sequence[:], name_context, body_indent_str)
					str.write_string(ctx.result, indent_str); str.write_byte(ctx.result, '}')
			}
		}


		ONE_INDENT :: "\t"
		current_node := &ctx.ast[current_node_index]
		#partial switch current_node.kind {
			case .NewLine:
				str.write_byte(ctx.result, '\n')

			case .Comment:
				str.write_string(ctx.result, current_node.literal.source)

			case .Sequence:
				write_node_sequence(ctx, current_node.sequence[:], name_context, indent_str)

			case .PreprocDefine:
				define := current_node.preproc_define

				str.write_string(ctx.result, define.name.source)
				str.write_string(ctx.result, " :: ")
				write_token_range(ctx.result, define.expansion_tokens, "")

				insert_new_definition(ctx.context_heap, 0, define.name.source, current_node_index, define.name.source)

			case .PreprocMacro:
				macro := current_node.preproc_macro

				str.write_string(ctx.result, macro.name.source)
				str.write_string(ctx.result, " :: #force_inline proc \"contextless\" (")
				for arg, i in macro.args {
					if i > 0 { str.write_string(ctx.result, ", ") }
					str.write_string(ctx.result, arg.source)
					str.write_string(ctx.result, " : ")
					fmt.sbprintf(ctx.result, "$T%v", i)
				}
				str.write_string(ctx.result, ") //TODO: validate those args are not by-ref\n")
				str.write_string(ctx.result, indent_str); str.write_string(ctx.result, "{\n")
				current_member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				last_broke_line := true
				for tok in macro.expansion_tokens {
					if last_broke_line { str.write_string(ctx.result, current_member_indent_str) }
					#partial switch tok.kind {
						case .Semicolon:
							str.write_string(ctx.result, ";\n")
							last_broke_line = true

						case:
							str.write_string(ctx.result, tok.source)
							last_broke_line = false
					}
				}
				str.write_string(ctx.result, indent_str); str.write_string(ctx.result, "}\n")

				insert_new_definition(ctx.context_heap, 0, macro.name.source, current_node_index, macro.name.source)

			case .FunctionDefinition:
				write_function(ctx, name_context, current_node_index, definition_prefix, false, indent_str)

				swallow_paragraph = .ForwardDeclaration in current_node.function_def.flags 

			case .Struct, .Union:
				member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				structure := &current_node.struct_or_union

				complete_structure_name := fold_token_range(definition_prefix, structure.name)

				og_name_context := name_context
				name_context := name_context

				_, forward_declared_context := try_find_definition_for_name(ctx.context_heap, name_context, structure.name)
				if forward_declared_context != nil {
					forward_declaration := ctx.ast[forward_declared_context.node]
					assert(forward_declaration.kind == .Struct || forward_declaration.kind == .Union)
	
					forward_comments := forward_declaration.struct_or_union.attached_comments
					inject_at(&structure.attached_comments, 0, ..forward_comments[:])
				}

				if structure.is_forward_declaration {
					name_context = transmute(NameContextIndex) append_return_index(ctx.context_heap, NameContext{ node = current_node_index, parent = name_context, complete_name = complete_structure_name })
					ctx.context_heap[og_name_context].definitions[last(structure.name).source] = name_context

					swallow_paragraph = true

					return
				}

				// write directly, they are marked for skipping in write_sequence
				for aid in structure.attached_comments {
					write_node(ctx, aid, name_context)
				}

				str.write_string(ctx.result, complete_structure_name);
				str.write_string(ctx.result, " :: struct")

				if len(structure.template_spec) != 0 {
					str.write_byte(ctx.result, '(')
					for ti, i in structure.template_spec {
						if i > 0 { str.write_string(ctx.result, ", ") }
						write_node(ctx, ti, name_context)
					}
					str.write_byte(ctx.result, ')')
				}

				str.write_string(ctx.result, current_node.kind == .Struct ? " {\n" : " #raw_union {\n")

				if structure.base_type != nil {
					// copy over defs from base type, using their location
					_, base_context := find_definition_for_name(ctx.context_heap, name_context, structure.base_type)

					base_member_name := str.concatenate({ "__base_", str.to_lower(structure.base_type[len(structure.base_type) - 1].source, context.temp_allocator) })
					name_context = transmute(NameContextIndex) append_return_index(ctx.context_heap, NameContext{
						parent      = name_context,
						node        = base_context.node,
						definitions = base_context.definitions, // make sure not to modify these! ok because we push another context right after
					})

					str.write_string(ctx.result, member_indent_str)
					str.write_string(ctx.result, "using ")
					str.write_string(ctx.result, base_member_name)
					str.write_string(ctx.result, " : ")
					str.write_string(ctx.result, base_context.complete_name)
					str.write_string(ctx.result, ",\n")
				}

				name_context = transmute(NameContextIndex) append_return_index(ctx.context_heap, NameContext{ node = current_node_index, parent = name_context, complete_name = complete_structure_name })
				ctx.context_heap[og_name_context].definitions[last(structure.name).source] = name_context
				// no reset here, struct context might be relevant later on

				BitfieldSectionData :: struct {
					member_stack : sa.Small_Array(64, AstNodeIndex),
					subsection_counter : int,
					member_indent_str : string,
				}
				bitfield_section_data : BitfieldSectionData

				write_bitfield_subsection_and_reset :: proc(ctx : ConverterContext, section_data : ^BitfieldSectionData, name_context : NameContextIndex, indent_str : string)
				{
					if len(section_data.member_indent_str) == 0 {
						section_data.member_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
					}

					str.write_string(ctx.result, indent_str);
					str.write_string(ctx.result, "using _");
					fmt.sbprint(ctx.result, section_data.subsection_counter);
					str.write_string(ctx.result, " : bit_field u8 {\n");

					for ci in sa.slice(&section_data.member_stack) {
						#partial switch ctx.ast[ci].kind {
							case .VariableDeclaration:
								str.write_string(ctx.result, section_data.member_indent_str);
								write_node(ctx, ci, name_context)
								str.write_byte(ctx.result, ',')

							case:
								write_node(ctx, ci, name_context)
						}
					}

					str.write_string(ctx.result, indent_str);
					str.write_string(ctx.result, "},\n");

					sa.clear(&section_data.member_stack)
				}

				has_static_var_members := false
				has_inplicit_initializer := false
				for cii := 0; cii < len(structure.members); cii += 1 {
					ci := structure.members[cii]
					#partial switch ctx.ast[ci].kind {
						case .VariableDeclaration:
							member := ctx.ast[ci].var_declaration
							if .Static in member.flags { has_static_var_members = true; continue }

							d := insert_new_definition(ctx.context_heap, name_context, member.var_name.source, ci, member.var_name.source)
							has_inplicit_initializer |= member.initializer_expression != {}

							if member.width_expression != {} {
								sa.append(&bitfield_section_data.member_stack, ci)
								
								// eat additional newlines an comments
								bitfield_loop: for ; cii + 1 < len(structure.members); cii += 1 {
									ci = structure.members[cii + 1]
									#partial switch ctx.ast[ci].kind {
										case .NewLine, .Comment:
											sa.append(&bitfield_section_data.member_stack, ci)
										case:
											break bitfield_loop
									}
								}
								continue
							}

							if sa.len(bitfield_section_data.member_stack) > 0 {
								write_bitfield_subsection_and_reset(ctx, &bitfield_section_data, name_context, member_indent_str)
							}

							str.write_string(ctx.result, member_indent_str);
							str.write_string(ctx.result, member.var_name.source);
							str.write_string(ctx.result, " : ")
							write_type(ctx, ctx.ast[member.type], name_context)
							str.write_string(ctx.result, ",\n")


						case .Comment:
							str.write_string(ctx.result, member_indent_str);
							str.write_string(ctx.result, ctx.ast[ci].literal.source)
							str.write_byte(ctx.result, '\n')

						case:
							if write_preproc_node(ctx.result, ctx.ast[ci]) {
								str.write_byte(ctx.result, '\n')
							}
					}
				}

				if sa.len(bitfield_section_data.member_stack) > 0 {
					write_bitfield_subsection_and_reset(ctx, &bitfield_section_data, name_context, member_indent_str)
				}

				str.write_string(ctx.result, indent_str); str.write_byte(ctx.result, '}')

				if has_static_var_members {
					str.write_byte(ctx.result, '\n')
					for midx in structure.members {
						if ctx.ast[midx].kind != .VariableDeclaration || .Static not_in ctx.ast[midx].var_declaration.flags { continue }
						member := ctx.ast[midx].var_declaration

						complete_member_name := fold_token_range(complete_structure_name, { member.var_name })
						insert_new_definition(ctx.context_heap, name_context, member.var_name.source, midx, complete_member_name)

						str.write_byte(ctx.result, '\n')
						str.write_string(ctx.result, indent_str);
						str.write_string(ctx.result, complete_member_name);
						str.write_string(ctx.result, " : ")
						write_type(ctx, ctx.ast[member.type], name_context)

						if member.initializer_expression != {} {
							str.write_string(ctx.result, " = ");
							write_node(ctx, member.initializer_expression, name_context)
						}
					}
				}

				if has_inplicit_initializer || structure.initializer != {} {
					initializer := ctx.ast[structure.initializer]

					complete_initializer_name := str.concatenate({ complete_structure_name, "_init" })
					name_context := insert_new_definition(ctx.context_heap, name_context, last(initializer.function_def.function_name[:]).source, structure.initializer, complete_initializer_name)
					context_heap_reset := len(ctx.context_heap) // keep fn as leaf node
					defer {
						clear(&ctx.context_heap[name_context].definitions)
						resize(ctx.context_heap, context_heap_reset)
					}

					insert_new_definition(ctx.context_heap, name_context, "this", -1, "this")

					str.write_string(ctx.result, "\n\n")
					str.write_string(ctx.result, indent_str);
					str.write_string(ctx.result, complete_initializer_name);
					str.write_string(ctx.result, " :: proc(this : ^")
					str.write_string(ctx.result, complete_structure_name);
					if initializer.kind == .FunctionDefinition {
						for nidx, i in initializer.function_def.arguments {
							str.write_string(ctx.result, ", ")
							arg := ctx.ast[nidx].var_declaration

							insert_new_definition(ctx.context_heap, name_context, arg.var_name.source, nidx, arg.var_name.source)

							str.write_string(ctx.result, arg.var_name.source)
							str.write_string(ctx.result, " : ")
							write_type(ctx, ctx.ast[arg.type], name_context)

							if arg.initializer_expression != {} {
								str.write_string(ctx.result, " = ")
								write_node(ctx, arg.initializer_expression, name_context)
							}
						}
					}
					str.write_string(ctx.result, ")\n")

					str.write_string(ctx.result, indent_str); str.write_string(ctx.result, "{\n")
					for ci in structure.members {
						if ctx.ast[ci].kind != .VariableDeclaration { continue }
						member := ctx.ast[ci].var_declaration
						if member.initializer_expression == {} { continue }

						str.write_string(ctx.result, member_indent_str);
						str.write_string(ctx.result, "this.")
						str.write_string(ctx.result, member.var_name.source)
						str.write_string(ctx.result, " = ")
						write_node(ctx, member.initializer_expression, name_context)
						str.write_byte(ctx.result, '\n')
					}
					if initializer.kind == .FunctionDefinition {
						write_node_sequence(ctx, initializer.function_def.body_sequence[:], name_context, member_indent_str)
						if ctx.ast[last(initializer.function_def.body_sequence[:])^].kind != .NewLine { str.write_byte(ctx.result, '\n') }
					}
					str.write_string(ctx.result, indent_str); str.write_byte(ctx.result, '}')
				}

				for midx in structure.members {
					#partial switch ctx.ast[midx].kind {
						case .FunctionDefinition:
							str.write_string(ctx.result, "\n\n")
							write_function(ctx, name_context, midx, complete_structure_name, true, indent_str)

							requires_new_paragraph = true

						case .Struct, .Union:
							str.write_string(ctx.result, "\n\n")
							ctx.ast[midx].struct_or_union.name = slice.concatenate([][]Token{structure.name, ctx.ast[midx].struct_or_union.name})
							write_node(ctx, midx, name_context, indent_str)

							requires_new_paragraph = true
					}
				}

			case .VariableDeclaration:
				vardef := current_node.var_declaration

				complete_name := fold_token_range(definition_prefix, { vardef.var_name })
				insert_new_definition(ctx.context_heap, name_context, vardef.var_name.source, current_node_index, complete_name)

				str.write_string(ctx.result, complete_name);
				str.write_string(ctx.result, " : ")
				write_type(ctx, ctx.ast[vardef.type], name_context)

				if vardef.width_expression != {} {
					str.write_string(ctx.result, " | ")
					write_node(ctx, vardef.width_expression, name_context)
				}

				if vardef.initializer_expression != {} {
					str.write_string(ctx.result, " = ")
					write_node(ctx, vardef.initializer_expression, name_context)
				}
				requires_termination = true

			case .Return:
				str.write_string(ctx.result, "return")

				if current_node.return_.expression != {} {
					str.write_byte(ctx.result, ' ')
					write_node(ctx, current_node.return_.expression, name_context)
				}

			case .LiteralBool, .LiteralFloat, .LiteralInteger, .LiteralString, .LiteralCharacter, .Continue, .Break:
				str.write_string(ctx.result, current_node.literal.source)

			case .LiteralNull:
				str.write_string(ctx.result, "nil")

			case .ExprUnaryLeft:
				switch current_node.unary_left.operator {
					case .Invert:
						str.write_byte(ctx.result, '!')
						write_node(ctx, current_node.unary_left.right, name_context)

					case .Dereference:
						write_node(ctx, current_node.unary_left.right, name_context)
						str.write_byte(ctx.result, '^')

					case .Minus:
						str.write_byte(ctx.result, '-')
						write_node(ctx, current_node.unary_left.right, name_context)

					case .Increment:
						str.write_string(ctx.result, "pre_incr(&")
						write_node(ctx, current_node.unary_left.right, name_context)
						str.write_string(ctx.result, ")")

					case .Decrement:
						str.write_string(ctx.result, "pre_decr(&")
						write_node(ctx, current_node.unary_left.right, name_context)
						str.write_string(ctx.result, ")")
				}

				requires_termination = true

			case .ExprUnaryRight:
				#partial switch current_node.unary_right.operator {
					case .Increment:
						write_node(ctx, current_node.unary_right.left, name_context)
						str.write_string(ctx.result, " += 1")

					case .Decrement:
						write_node(ctx, current_node.unary_right.left, name_context)
						str.write_string(ctx.result, " -= 1")
				}

				requires_termination = true

			case .ExprBinary:
				write_node(ctx, current_node.binary.left, name_context)
				str.write_byte(ctx.result, ' ')
				str.write_byte(ctx.result, u8(current_node.binary.operator))
				str.write_byte(ctx.result, ' ')
				write_node(ctx, current_node.binary.right, name_context)

				requires_termination = true

			case .MemberAccess:
				member := ctx.ast[current_node.member_access.member]
				if member.kind == .FunctionCall {
					fncall := member.function_call

					is_ptr := current_node.member_access.through_pointer
					this_root, this_context := resolve_type(ctx, current_node.member_access.expression, name_context)

					// maybe find basetype for this member
					this_idx := transmute(NameContextIndex) mem.ptr_sub(this_context, &ctx.context_heap[0])
					_, actual_member_context := find_definition_for_name(ctx.context_heap, this_idx, fncall.qualified_name[:])

					this_type := ctx.ast[ctx.context_heap[actual_member_context.parent].node]
					if this_type.kind != .Struct && this_type.kind != .Union {
						panic(fmt.tprintf("Unexpected this type %v", this_type))
					}

					str.write_string(ctx.result, actual_member_context.complete_name)
					str.write_byte(ctx.result, '(')
					if !is_ptr { str.write_byte(ctx.result, '&') }
					write_node(ctx, current_node.member_access.expression, name_context)
					for pidx, i in fncall.parameters {
						str.write_string(ctx.result, ", ")
						write_node(ctx, pidx, name_context)
					}
					str.write_byte(ctx.result, ')')
				}
				else {
					write_node(ctx, current_node.member_access.expression, name_context)
					str.write_byte(ctx.result, '.')
					write_node(ctx, current_node.member_access.member, name_context)
				}

				requires_termination = true

			case .ExprIndex:
				write_node(ctx, current_node.index.array_expression, name_context)
				str.write_byte(ctx.result, '[')
				write_node(ctx, current_node.index.index_expression, name_context)
				str.write_byte(ctx.result, ']')

			case .Identifier:
				_, def := find_definition_for_name(ctx.context_heap, name_context, current_node.identifier[:])
				parent := ctx.ast[ctx.context_heap[def.parent].node]

				if ((parent.kind == .Struct || parent.kind == .Union) && .Static not_in ctx.ast[def.node].var_declaration.flags) {
					str.write_string(ctx.result, "this.")
				}

				write_token_range(ctx.result, current_node.identifier[:])

			case .FunctionCall:
				fncall := current_node.function_call

				str.write_string(ctx.result, last(fncall.qualified_name[:]).source)
				str.write_byte(ctx.result, '(')
				for pidx, i in fncall.parameters {
					if i != 0 { str.write_string(ctx.result, ", ") }
					write_node(ctx, pidx, name_context)
				}
				str.write_byte(ctx.result, ')')

				requires_termination = true

			case .Namespace:
				ns := current_node.namespace

				complete_name := fold_token_range(definition_prefix, { ns.name })
				name_context := insert_new_definition(ctx.context_heap, name_context, ns.name.source, current_node_index, complete_name)

				write_node_sequence(ctx, ns.sequence[:], name_context, indent_str, complete_name)


			case .For, .While, .Do:
				loop := current_node.loop

				str.write_string(ctx.result, "for")
				if loop.initializer != {} || loop.loop_statement != {} {
					str.write_byte(ctx.result, ' ')
					if loop.initializer != {} { write_node(ctx, loop.initializer, name_context) }
					str.write_string(ctx.result, "; ")
					if loop.condition != {} { write_node(ctx, loop.condition, name_context) }
					str.write_string(ctx.result, "; ")
					if loop.loop_statement != {} { write_node(ctx, loop.loop_statement, name_context) }
				}
				else if loop.condition != {} && current_node.kind != .Do {
					str.write_byte(ctx.result, ' ')
					write_node(ctx, loop.condition, name_context)
				}
				str.write_string(ctx.result, " {")
				
				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				write_node_sequence(ctx, loop.body_sequence[:], name_context, body_indent_str)

				if loop.condition != {} && current_node.kind == .Do {
					str.write_byte(ctx.result, '\n')
					str.write_string(ctx.result, body_indent_str)
					str.write_string(ctx.result, "if !(")
					write_node(ctx, loop.condition, name_context)
					str.write_string(ctx.result, ") { break }\n")
				}

				str.write_string(ctx.result, indent_str); str.write_string(ctx.result, "}")

				requires_new_paragraph = true

			case:
				was_preproc := #force_inline write_preproc_node(ctx.result, current_node^)
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

	write_type :: proc(ctx : ConverterContext, r : AstNode, name_context : NameContextIndex)
	{
		type_tokens := r.type[:]

		converted_type_tokens := make([dynamic]TypeSegment, 0, len(type_tokens), context.temp_allocator)
		translate_type(&converted_type_tokens, ctx.ast, type_tokens)

		last_type_was_ident := false
		for _t in converted_type_tokens {
			switch t in _t {
				case _TypePtr:
					str.write_byte(ctx.result, '^')

				case _TypeFragment:
					if last_type_was_ident { str.write_byte(ctx.result, '_') }
					str.write_string(ctx.result, t.identifier.source)
					if len(t.generic_arguments) > 0 {
						str.write_byte(ctx.result, '(')
						for _, g in t.generic_arguments {
							str.write_string(ctx.result, g.source)
						}
						str.write_byte(ctx.result, ')')
					}

				case _TypeArray:
					str.write_byte(ctx.result, '[')
					write_token_range(ctx.result, t.length_expression[:], "")
					str.write_byte(ctx.result, ']')
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

	resolve_type :: proc(ctx : ConverterContext, current_node_index : AstNodeIndex, name_context : NameContextIndex) -> (root, leaf : ^NameContext)
	{
		current_node := ctx.ast[current_node_index]
		#partial switch current_node.kind {
			case .Identifier:
				_, var_def := find_definition_for_name(ctx.context_heap, name_context, current_node.identifier[:])
				assert_eq(ctx.ast[var_def.node].kind, AstNodeKind.VariableDeclaration)

				return resolve_type(ctx, var_def.node, var_def.parent)
			
			case .ExprUnaryLeft:
				return resolve_type(ctx, current_node.unary_left.right, name_context)

			case .ExprUnaryRight:
				return resolve_type(ctx, current_node.unary_right.left, name_context)

			case .MemberAccess:
				member_access := current_node.member_access
				_, this_context := resolve_type(ctx, member_access.expression, name_context)
				this_idx := transmute(NameContextIndex) mem.ptr_sub(this_context, &ctx.context_heap[0])

				member := ctx.ast[member_access.member]
				#partial switch member.kind {
					case .Identifier:
						return resolve_type(ctx, member_access.member, this_idx)

					case .FunctionCall:
						fndef_idx := this_context.definitions[last(member.function_call.qualified_name[:]).source]
						fndef_ctx := ctx.context_heap[fndef_idx]

						assert_eq(ctx.ast[fndef_ctx.node].kind, AstNodeKind.FunctionDefinition)
						fndef := ctx.ast[fndef_ctx.node].function_def

						return_type := ctx.ast[fndef.return_type].type

						stripped_type := make([dynamic]Token, 0, len(return_type), context.temp_allocator)
						strip_type(&stripped_type, return_type[:])

						return find_definition_for_name(ctx.context_heap, this_idx, stripped_type[:])

					case:
						panic(fmt.tprintf("Not implemented %v", member))
				}

			case .VariableDeclaration:
				def_node := current_node.var_declaration

				stripped_type := make([dynamic]Token, 0, len(ctx.ast[def_node.type].type), context.temp_allocator)
				strip_type(&stripped_type, ctx.ast[def_node.type].type[:])

				if last(stripped_type[:]).source == "auto" {
					panic("auto resolver not implemented");
				}

				return find_definition_for_name(ctx.context_heap, name_context, stripped_type[:])

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

					case "typename", "class":
						remaining_input = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "typeid" } })

					case:
						append(output, _TypeFragment{ identifier = input[0] })
						remaining_input = input[1:]
				}

			case .Class:
				remaining_input = input[1:]
				append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "typeid" } })

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
	root_context, name_context = try_find_definition_for_name(context_heap, current_index, compound_identifier)
	if name_context != nil { return }

	loc := runtime.Source_Code_Location{ compound_identifier[0].location.file_path, cast(i32) compound_identifier[0].location.row, cast(i32) compound_identifier[0].location.column, "" }
	dump_context_stack(context_heap[:], current_index)
	panic(fmt.tprintf("'%v' was not found in context", compound_identifier), loc)
}

try_find_definition_for_name :: proc(context_heap : ^[dynamic]NameContext, current_index : NameContextIndex, compound_identifier : TokenRange) -> (root_context, name_context : ^NameContext)
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

	return nil, nil
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
