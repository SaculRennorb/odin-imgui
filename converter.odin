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
	ast : []AstNode,
	root_sequence : []AstNodeIndex,
	context_heap : [dynamic]NameContext,
	overload_resolver : map[string][dynamic]string,
}

convert_and_format :: proc(ctx : ^ConverterContext)
{
	ONE_INDENT :: "\t"

	if len(ctx.root_sequence) != 0 {
		current_name_context_heap = &ctx.context_heap
		append(&ctx.context_heap, NameContext{ parent = -1 })

		str.write_string(&ctx.result, "package test\n\n")
		write_node_sequence(ctx, ctx.root_sequence, 0, "")
	}

	write_node :: proc(ctx : ^ConverterContext, current_node_index : AstNodeIndex, name_context : NameContextIndex, indent_str := "", definition_prefix := "") -> (requires_termination, requires_new_paragraph, swallow_paragraph : bool)
	{
		current_node := &ctx.ast[current_node_index]
		#partial switch current_node.kind {
			case .NewLine:
				str.write_byte(&ctx.result, '\n')

			case .Comment:
				str.write_string(&ctx.result, current_node.literal.source)

			case .Sequence:
				if current_node.sequence.braced { str.write_byte(&ctx.result, '{') }
				write_node_sequence(ctx, current_node.sequence.members[:], name_context, indent_str)
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
				if len(define.expansion_tokens) == 0 || define.expansion_tokens[0].kind == .Comment  {
					str.write_string(&ctx.result, "true")
				}
				write_token_range(&ctx.result, define.expansion_tokens, "")

				insert_new_definition(&ctx.context_heap, 0, define.name.source, current_node_index, define.name.source)

			case .Typedef:
				define := current_node.typedef

				if type_node := ctx.ast[define.type]; type_node.kind == .Type {
					str.write_string(&ctx.result, define.name.source)
					str.write_string(&ctx.result, " :: ")
					write_type_node(ctx, type_node, name_context)

					insert_new_definition(&ctx.context_heap, 0, define.name.source, current_node_index, define.name.source)
				}
				else {
					write_function(ctx, name_context, define.type, "", nil, "", true)
				}

			case .Type:
				write_type(ctx, current_node.type[:], name_context)

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
					}

					arg_count += 1
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

				insert_new_definition(&ctx.context_heap, 0, macro.name.source, current_node_index, macro.name.source)

			case .FunctionDefinition:
				write_function(ctx, name_context, current_node_index, definition_prefix, nil, indent_str)

				swallow_paragraph = .ForwardDeclaration in current_node.function_def.flags 

			case .Struct, .Union:
				member_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				swallow, new_para := write_struct_union(ctx, current_node, current_node_index, name_context, indent_str, member_indent_str, definition_prefix)
				swallow_paragraph |= swallow
				requires_new_paragraph |= new_para

			case .Enum:
				structure := &current_node.structure

				complete_structure_name := fold_token_range(definition_prefix, structure.name)

				og_name_context := name_context
				name_context := name_context

				_, forward_declared_context := try_find_definition_for_name(ctx, name_context, structure.name)
				if forward_declared_context != nil {
					forward_declaration := ctx.ast[forward_declared_context.node]
					assert_eq(forward_declaration.kind, AstNodeKind.Enum)
	
					forward_comments := forward_declaration.structure.attached_comments
					inject_at(&structure.attached_comments, 0, ..forward_comments[:])
				}

				// enums spill out members into parent context, don'T replace the name_context for members
				structure_name_context := transmute(NameContextIndex) append_return_index(&ctx.context_heap, NameContext{ node = current_node_index, parent = name_context, complete_name = complete_structure_name })
				ctx.context_heap[og_name_context].definitions[last(structure.name).source] = structure_name_context

				if structure.is_forward_declaration {
					swallow_paragraph = true
					return
				}

				// write directly, they are marked for skipping in write_sequence
				for aid in structure.attached_comments {
					write_node(ctx, aid, name_context)
				}

				str.write_string(&ctx.result, complete_structure_name);
				str.write_string(&ctx.result, " :: enum ")

				if structure.base_type != nil {
					write_type(ctx, structure.base_type, name_context)
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

							d := insert_new_definition(&ctx.context_heap, name_context, member.var_name.source, ci, member.var_name.source)

							if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
							else { str.write_byte(&ctx.result, ' ') }
							str.write_string(&ctx.result, member.var_name.source)

							if member.initializer_expression != {} {
								str.write_string(&ctx.result, " = ")
								write_node(ctx, member.initializer_expression, name_context)
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

				str.write_string(&ctx.result, indent_str); str.write_byte(&ctx.result, '}')

			case .VariableDeclaration:
				vardef := current_node.var_declaration

				complete_name := fold_token_range(definition_prefix, { vardef.var_name })
				insert_new_definition(&ctx.context_heap, name_context, vardef.var_name.source, current_node_index, complete_name)

				str.write_string(&ctx.result, complete_name);

				if ctx.ast[vardef.type].kind == .Type && ctx.ast[vardef.type].type[0].source == "auto" {
					assert(vardef.initializer_expression != {})
					
					str.write_string(&ctx.result, " := ")
					write_node(ctx, vardef.initializer_expression, name_context, indent_str)
				}
				else {
					str.write_string(&ctx.result, " : ")
					write_type_node(ctx, ctx.ast[vardef.type], name_context)

					if vardef.width_expression != {} {
						str.write_string(&ctx.result, " | ")
						write_node(ctx, vardef.width_expression, name_context)
					}

					if vardef.initializer_expression != {} {
						str.write_string(&ctx.result, " = ")
						write_node(ctx, vardef.initializer_expression, name_context, indent_str)
					}
				}

				requires_termination = true

			case .LambdaDefinition:
				lambda := current_node.lambda_def
				function_ := &ctx.ast[lambda.underlying_function]
				function := &function_.function_def

				if len(lambda.captures) == 0 {
					name_reset := len(ctx.context_heap)
					name_context := insert_new_definition(&ctx.context_heap, name_context, "__", current_node_index, "__")
					defer resize(&ctx.context_heap, name_reset)

					write_function_type(ctx, name_context, function_^, "", nil)

					switch len(function.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { }");

						case 1:
							str.write_string(&ctx.result, " { ");
							write_node(ctx, function.body_sequence[0], name_context)
							str.write_string(&ctx.result, " }");

						case:
							str.write_byte(&ctx.result, '\n')

							str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{")
							body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
							write_node_sequence(ctx, function.body_sequence[:], name_context, body_indent_str)
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
								
								capture_type, _ := resolve_type(ctx, ci, name_context)
								type := make([dynamic]TypeSegment, 0, len(capture_type), context.temp_allocator)
								capture_type_ := capture_type[:]
								translate_type(&type, ctx.ast, &capture_type_)
								write_type_inner(ctx, type[:], name_context)
								
								str.write_string(&ctx.result, ", ")

							case .ExprUnaryLeft:
								assert_eq(c.unary_left.operator, AstUnaryOp.AddressOf)
								
								c := ctx.ast[c.unary_left.right]
								str.write_string(&ctx.result, last(c.identifier).source)
								str.write_string(&ctx.result, " : ")
								
								capture_type, _ := resolve_type(ctx, c.unary_left.right, name_context)
								type := make([dynamic]TypeSegment, 0, len(capture_type), context.temp_allocator)
								capture_type_ := capture_type[:]
								translate_type(&type, ctx.ast, &capture_type_)
								str.write_byte(&ctx.result, '^')
								write_type_inner(ctx, type[:], name_context)

								str.write_string(&ctx.result, ", ")
						}
					}

					str.write_string(&ctx.result, indent_str)
					str.write_string(&ctx.result, "}\n")


					// function def
					name_reset := len(ctx.context_heap)
					name_context := insert_new_definition(&ctx.context_heap, name_context, function_name, current_node_index, function_name)
					defer resize(&ctx.context_heap, name_reset)

					str.write_string(&ctx.result, indent_str)
					str.write_string(&ctx.result, function_name)
					str.write_string(&ctx.result, " :: proc(")
					str.write_string(&ctx.result, "__l : ^")
					str.write_string(&ctx.result, captures_struct_name)
					for ai in function.arguments {
						str.write_string(&ctx.result, ", ")
						write_node(ctx, ai, name_context)
					}
					str.write_byte(&ctx.result, ')')

					switch len(function.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { }")

						case 1:
							str.write_string(&ctx.result, " { using __l; ")
							write_node(ctx, function.body_sequence[0], name_context)
							str.write_string(&ctx.result, " }\n")

						case:
							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "{\n")
							str.write_string(&ctx.result, member_indent_str)
							str.write_string(&ctx.result, "using __l")
							write_node_sequence(ctx, function.body_sequence[:], name_context, member_indent_str)

							if ctx.ast[last(function.body_sequence)^].kind == .NewLine { str.write_string(&ctx.result, indent_str) }
							str.write_string(&ctx.result, "}\n")
					}

				}
				requires_termination = true

			case .Return:
				str.write_string(&ctx.result, "return")

				if current_node.return_.expression != {} {
					str.write_byte(&ctx.result, ' ')
					write_node(ctx, current_node.return_.expression, name_context)
				}

			case .LiteralBool, .LiteralFloat, .LiteralInteger, .LiteralString, .LiteralCharacter, .Continue, .Break:
				str.write_string(&ctx.result, current_node.literal.source)

				requires_termination = true

			case .LiteralNull:
				str.write_string(&ctx.result, "nil")

				requires_termination = true

			case .ExprUnaryLeft:
				switch current_node.unary_left.operator {
					case .AddressOf, .Plus, .Minus:
						str.write_byte(&ctx.result, byte(current_node.unary_left.operator))
						write_node(ctx, current_node.unary_left.right, name_context)

					case .Invert:
						str.write_byte(&ctx.result, '!')
						write_node(ctx, current_node.unary_left.right, name_context)

					case .Dereference:
						write_node(ctx, current_node.unary_left.right, name_context)
						str.write_byte(&ctx.result, '^')

					case .Increment:
						str.write_string(&ctx.result, "pre_incr(&")
						write_node(ctx, current_node.unary_left.right, name_context)
						str.write_byte(&ctx.result, ')')

					case .Decrement:
						str.write_string(&ctx.result, "pre_decr(&")
						write_node(ctx, current_node.unary_left.right, name_context)
						str.write_byte(&ctx.result, ')')
				}

				requires_termination = true

			case .ExprUnaryRight:
				#partial switch current_node.unary_right.operator {
					case .Increment:
						str.write_string(&ctx.result, "post_incr(&")
						write_node(ctx, current_node.unary_right.left, name_context)
						str.write_byte(&ctx.result, ')')

					case .Decrement:
						str.write_string(&ctx.result, "post_decr(&")
						write_node(ctx, current_node.unary_right.left, name_context)
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
						case:
							str.write_byte(&ctx.result, u8(operator))
					}
				}

				right := ctx.ast[binary.right]
				right_switch: #partial switch right.kind {
					case .ExprBinary:
						#partial switch right.binary.operator {
							case .Assign, .AssignAdd, .AssignBitAnd, .AssignBitOr, .AssignBitXor, .AssignDivide, .AssignModulo, .AssignMultiply, .AssignShiftLeft, .AssignShiftRight, .AssignSubtract:
								write_node(ctx, binary.right, name_context)
								str.write_string(&ctx.result, "; ")

								write_node(ctx, binary.left, name_context)
								str.write_byte(&ctx.result, ' ')
								write_op(ctx, binary.operator)
								str.write_byte(&ctx.result, ' ')
								write_node(ctx, right.binary.left, name_context)

								break right_switch
							}

						fallthrough

					case:
						write_node(ctx, binary.left, name_context)
						str.write_byte(&ctx.result, ' ')
						write_op(ctx, binary.operator)
						str.write_byte(&ctx.result, ' ')
						write_node(ctx, binary.right, name_context)
				}

				requires_termination = true

			case .ExprBacketed:
				str.write_byte(&ctx.result, '(')
				write_node(ctx, current_node.inner, name_context)
				str.write_byte(&ctx.result, ')')

				requires_termination = true

			case .ExprCast:
				if current_node.cast_.kind == .Static {
					str.write_string(&ctx.result, "cast(")
				}
				else {
					str.write_string(&ctx.result, "transmute(")
				}
				write_type_node(ctx, ctx.ast[current_node.cast_.type], name_context)
				str.write_string(&ctx.result, ") ")
				write_node(ctx, current_node.cast_.expression, name_context)

				requires_termination = true

			case .MemberAccess:
				member := ctx.ast[current_node.member_access.member]

				expression_type, expression_type_context_idx := resolve_type(ctx, current_node.member_access.expression, name_context)
				expression_type_context := ctx.context_heap[expression_type_context_idx]

				if member.kind == .FunctionCall {
					fncall := member.function_call

					expression_type_node := ctx.ast[expression_type_context.node]
					structure_name : []Token
					#partial switch expression_type_node.kind { // TODO(Rennorb) @cleanup
						case .Struct, .Union:
							structure_name = expression_type_node.structure.name
						case .VariableDeclaration:
							structure_name = {expression_type_node.var_declaration.var_name}
					}

					fn_name_expr := ctx.ast[member.function_call.expression]
					assert_eq(fn_name_expr.kind, AstNodeKind.Identifier)
					fn_name := last(fn_name_expr.identifier[:]).source

					if len(structure_name) > 0 && last(structure_name).source == fn_name {
						str.write_string(&ctx.result, member.function_call.is_destructor ? "deinit" : "init")
					}
					else {
						if expression_type_context.parent != -1 {
							containing_scope := ctx.ast[ctx.context_heap[expression_type_context.parent].node]
							if containing_scope.kind == .Namespace {
								str.write_string(&ctx.result, containing_scope.namespace.name.source)
								str.write_byte(&ctx.result, '_')
							}

							write_token_range(&ctx.result, fn_name_expr.identifier[:])
						}
						else if fn_name == "init" && len(fncall.arguments) == 1 { // likely a initializer call for a primitive type
							write_node(ctx, current_node.member_access.expression, name_context)
							str.write_string(&ctx.result, " = ")
							write_node(ctx, fncall.arguments[0], name_context)

							requires_termination = true
							break
						}
						else{
							write_token_range(&ctx.result, fn_name_expr.identifier[:])
						}
					}

					str.write_byte(&ctx.result, '(')
					if !current_node.member_access.through_pointer { str.write_byte(&ctx.result, '&') }
					write_node(ctx, current_node.member_access.expression, name_context)
					for aidx, i in fncall.arguments {
						str.write_string(&ctx.result, ", ")
						write_node(ctx, aidx, name_context)
					}
					str.write_byte(&ctx.result, ')')
				}
				else {
					write_node(ctx, current_node.member_access.expression, name_context)
					str.write_byte(&ctx.result, '.')

					_, actual_member_context := find_definition_for_name(ctx, expression_type_context_idx, member.identifier[:])

					this_type := ctx.ast[expression_type_context.node]
					if this_type.kind != .Struct && this_type.kind != .Union && this_type.kind != .Enum {
						panic(fmt.tprintf("Unexpected expression type %#v for %v", this_type, member.identifier))
					}

					str.write_string(&ctx.result, actual_member_context.complete_name)
				}

				requires_termination = true

			case .ExprIndex:
				write_node(ctx, current_node.index.array_expression, name_context)
				str.write_byte(&ctx.result, '[')
				write_node(ctx, current_node.index.index_expression, name_context)
				str.write_byte(&ctx.result, ']')

				requires_termination = true

			case .ExprTenary:
				write_node(ctx, current_node.tenary.condition, name_context)
				str.write_string(&ctx.result, " ? ")
				write_node(ctx, current_node.tenary.true_expression, name_context)
				str.write_string(&ctx.result, " : ")
				write_node(ctx, current_node.tenary.false_expression, name_context)

				requires_termination = true

			case .Identifier:
				_, def := find_definition_for_name(ctx, name_context, current_node.identifier[:])
				parent := ctx.ast[ctx.context_heap[def.parent].node]

				if ((parent.kind == .Struct || parent.kind == .Union) && .Static not_in ctx.ast[def.node].var_declaration.flags) {
					str.write_string(&ctx.result, "this.")
				}

				write_token_range(&ctx.result, current_node.identifier[:])

			case .FunctionCall:
				fncall := current_node.function_call

				if expr := ctx.ast[fncall.expression]; expr.kind == .Identifier {
					// @hardcoded: Print indents directly so we don't have to add all std functions to the name resolver.
					fn_name := last(expr.identifier[:]).source
					// convert some top level function names
					switch fn_name {
						case "sizeof":
							str.write_string(&ctx.result, "size_of")

						case:
							str.write_string(&ctx.result, fn_name)
					}
				}
				else {
					write_node(ctx, fncall.expression, name_context)
				}
				str.write_byte(&ctx.result, '(')
				for aidx, i in fncall.arguments {
					if i != 0 { str.write_string(&ctx.result, ", ") }
					write_node(ctx, aidx, name_context)
				}
				str.write_byte(&ctx.result, ')')

				requires_termination = true

			case .CompoundInitializer:
				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)

				body := current_node.compound_initializer.values[:]
				str.write_byte(&ctx.result, '{')
				write_node_sequence(ctx, body, name_context, body_indent_str, termination = ",", always_terminate = true)
				if len(body) > 0 && ctx.ast[last(body)^].kind == .NewLine { str.write_string(&ctx.result, indent_str) }
				str.write_byte(&ctx.result, '}')

				requires_termination = true

			case .Namespace:
				ns := current_node.namespace

				complete_name := fold_token_range(definition_prefix, { ns.name })
				name_context := insert_new_definition(&ctx.context_heap, name_context, ns.name.source, current_node_index, complete_name)

				write_node_sequence(ctx, ns.sequence[:], name_context, indent_str, complete_name)


			case .For, .While, .Do:
				loop := current_node.loop

				str.write_string(&ctx.result, "for")
				if !loop.is_foreach {
					if loop.initializer != {} || loop.loop_statement != {} {
						str.write_byte(&ctx.result, ' ')
						if loop.initializer != {} { write_node(ctx, loop.initializer, name_context) }
						str.write_string(&ctx.result, "; ")
						if loop.condition != {} { write_node(ctx, loop.condition, name_context) }
						str.write_string(&ctx.result, "; ")
						if loop.loop_statement != {} { write_node(ctx, loop.loop_statement, name_context) }
					}
					else if loop.condition != {} && current_node.kind != .Do {
						str.write_byte(&ctx.result, ' ')
						write_node(ctx, loop.condition, name_context)
					}
				}
				else {
					str.write_byte(&ctx.result, ' ')
					initializer := ctx.ast[loop.initializer]
					assert_eq(initializer.kind, AstNodeKind.VariableDeclaration)
					str.write_string(&ctx.result, initializer.var_declaration.var_name.source)
					str.write_string(&ctx.result, " in ")
					write_node(ctx, loop.loop_statement, name_context)
				}

				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				if loop.condition != {} && current_node.kind == .Do {
					switch len(loop.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { if !(")
							write_node(ctx, loop.condition, name_context)
							str.write_string(&ctx.result, ") { break } }")
	
						case 1:
							str.write_string(&ctx.result, " {\n")

							str.write_string(&ctx.result, body_indent_str)
							write_node(ctx, loop.body_sequence[0], name_context)

							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, body_indent_str)
							str.write_string(&ctx.result, "if !(")
							write_node(ctx, loop.condition, name_context)
							str.write_string(&ctx.result, ") { break }\n")

							str.write_string(&ctx.result, indent_str)
							str.write_byte(&ctx.result, '}')
	
						case:
							str.write_string(&ctx.result, " {")

							write_node_sequence(ctx, loop.body_sequence[:], name_context, body_indent_str)

							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, body_indent_str)
							str.write_string(&ctx.result, "if !(")
							write_node(ctx, loop.condition, name_context)
							str.write_string(&ctx.result, ") { break }\n")

							str.write_string(&ctx.result, indent_str)
							str.write_byte(&ctx.result, '}')
					}
				}
				else {
					switch len(loop.body_sequence) {
						case 0:
							str.write_string(&ctx.result, " { }")

						case 1:
							str.write_string(&ctx.result, " { ")
							write_node(ctx, loop.body_sequence[0], name_context)
							str.write_string(&ctx.result, " }")

						case:
							str.write_string(&ctx.result, " {")

							write_node_sequence(ctx, loop.body_sequence[:], name_context, body_indent_str)

							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "}")
					}
				}

				requires_termination = true
				requires_new_paragraph = true

			case .Branch:
				branch := current_node.branch

				str.write_string(&ctx.result, "if ")
				write_node(ctx, branch.condition, name_context)

				body_indent_str : string

				switch len(branch.true_branch_sequence) {
					case 0:
						str.write_string(&ctx.result, " { }")

					case 1:
						context_heap_reset := len(&ctx.context_heap)

						str.write_string(&ctx.result, " { ")
						write_node(ctx, branch.true_branch_sequence[0], name_context)
						str.write_string(&ctx.result, " }")

						resize(&ctx.context_heap, context_heap_reset)

					case:
						context_heap_reset := len(&ctx.context_heap)
						name_context := insert_new_definition(&ctx.context_heap, name_context, "", branch.condition, "")
						
						str.write_string(&ctx.result, " {")
						body_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
						write_node_sequence(ctx, branch.true_branch_sequence[:], name_context, body_indent_str)
						if ctx.ast[last(branch.true_branch_sequence[:])^].kind == .NewLine {
							str.write_string(&ctx.result, indent_str);
						}
						str.write_byte(&ctx.result, '}')

						resize(&ctx.context_heap, context_heap_reset)
				}

				switch len(branch.false_branch_sequence) {
					case 0:
						 /**/

					case 1:
						context_heap_reset := len(&ctx.context_heap)

						if ctx.ast[branch.false_branch_sequence[0]].kind == .Branch { // else if chaining
							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "else ")
							write_node(ctx, branch.false_branch_sequence[0], name_context, indent_str)
						}
						else {
							str.write_byte(&ctx.result, '\n')
							str.write_string(&ctx.result, indent_str)
							str.write_string(&ctx.result, "else { ")
							write_node(ctx, branch.false_branch_sequence[0], name_context)
							if ctx.ast[last(branch.false_branch_sequence[:])^].kind == .NewLine {
								str.write_string(&ctx.result, indent_str);
							}
							str.write_string(&ctx.result, " }")
						}

						resize(&ctx.context_heap, context_heap_reset)

					case:
						context_heap_reset := len(&ctx.context_heap)
						name_context := insert_new_definition(&ctx.context_heap, name_context, "", branch.condition, "")

						str.write_byte(&ctx.result, '\n')
						str.write_string(&ctx.result, indent_str)
						str.write_string(&ctx.result, "else {")
						if body_indent_str == "" { body_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator) }
						write_node_sequence(ctx, branch.false_branch_sequence[:], name_context, body_indent_str)
						str.write_string(&ctx.result, indent_str)
						str.write_byte(&ctx.result, '}')

						resize(&ctx.context_heap, context_heap_reset)
				}

				requires_termination = true

			case .Switch:
				switch_ := current_node.switch_

				str.write_string(&ctx.result, "switch ")
				write_node(ctx, switch_.expression, name_context)

				str.write_string(&ctx.result, " {\n")
				
				case_body_indent_str := str.concatenate({ indent_str, ONE_INDENT, ONE_INDENT }, context.temp_allocator)
				case_indent_str := case_body_indent_str[:len(case_body_indent_str) - len(ONE_INDENT)]

				for case_, case_i in switch_.cases {
					str.write_string(&ctx.result, case_indent_str)
					str.write_string(&ctx.result, "case")
					if case_.match_expression != {} {
						str.write_byte(&ctx.result, ' ')
						write_node(ctx, case_.match_expression, name_context)
					}
					str.write_byte(&ctx.result, ':')

					write_node_sequence(ctx, case_.body_sequence[:], name_context, case_body_indent_str)

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
					write_node(ctx, aidx, name_context)
				}
				str.write_byte(&ctx.result, ')')

				requires_termination = true

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

	write_node_sequence :: proc(ctx : ^ConverterContext, sequence : []AstNodeIndex, name_context : NameContextIndex, indent_str : string, definition_prefix := "", termination := ";", always_terminate := false)
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

			previous_requires_termination, previous_requires_new_paragraph, should_swallow_paragraph = write_node(ctx, ci, name_context, indent_str, definition_prefix)
			previous_node_kind = node_kind
		}
	}

	write_struct_union :: proc(ctx : ^ConverterContext, structure_node : ^AstNode, structure_node_index : AstNodeIndex, name_context : NameContextIndex, indent_str, member_indent_str : string, definition_prefix := "") -> (swallow_paragraph, requires_new_paragraph : bool)
	{
		structure := &structure_node.structure

		complete_structure_name := fold_token_range(definition_prefix, structure.name)

		og_name_context := name_context
		name_context := name_context

		_, forward_declared_context := try_find_definition_for_name(ctx, name_context, structure.name)
		if forward_declared_context != nil {
			forward_declaration := ctx.ast[forward_declared_context.node]
			assert(forward_declaration.kind == .Struct || forward_declaration.kind == .Union)

			forward_comments := forward_declaration.structure.attached_comments
			inject_at(&structure.attached_comments, 0, ..forward_comments[:])
		}

		if structure.is_forward_declaration {
			name_context = transmute(NameContextIndex) append_return_index(&ctx.context_heap, NameContext{ node = structure_node_index, parent = name_context, complete_name = complete_structure_name })
			ctx.context_heap[og_name_context].definitions[last(structure.name).source] = name_context

			swallow_paragraph = true

			return
		}

		// write directly, they are marked for skipping in write_sequence
		for aid in structure.attached_comments {
			write_node(ctx, aid, name_context)
		}

		str.write_string(&ctx.result, complete_structure_name);
		str.write_string(&ctx.result, " :: ")

		has_static_var_members, has_inplicit_initializer, nc := write_struct_union_type(ctx, structure_node, structure_node_index, name_context, og_name_context, indent_str, member_indent_str, complete_structure_name)
		name_context = nc

		if has_static_var_members {
			str.write_byte(&ctx.result, '\n')
			for midx in structure.members {
				if ctx.ast[midx].kind != .VariableDeclaration || .Static not_in ctx.ast[midx].var_declaration.flags { continue }
				member := ctx.ast[midx].var_declaration

				complete_member_name := fold_token_range(complete_structure_name, { member.var_name })
				insert_new_definition(&ctx.context_heap, name_context, member.var_name.source, midx, complete_member_name)

				str.write_byte(&ctx.result, '\n')
				str.write_string(&ctx.result, indent_str);
				str.write_string(&ctx.result, complete_member_name);
				str.write_string(&ctx.result, " : ")
				write_type_node(ctx, ctx.ast[member.type], name_context)

				if member.initializer_expression != {} {
					str.write_string(&ctx.result, " = ");
					write_node(ctx, member.initializer_expression, name_context)
				}
			}
		}

		if has_inplicit_initializer || (structure.initializer != {} && .ForwardDeclaration not_in ctx.ast[structure.initializer].function_def.flags) {
			initializer := ctx.ast[structure.initializer]

			complete_initializer_name := str.concatenate({ complete_structure_name, "_init" })
			name_context := insert_new_definition(&ctx.context_heap, name_context, "init", structure.initializer, complete_initializer_name)
			insert_new_overload(ctx, "init", complete_initializer_name)

			context_heap_reset := len(&ctx.context_heap) // keep fn as leaf node
			defer {
				clear(&ctx.context_heap[name_context].definitions)
				resize(&ctx.context_heap, context_heap_reset)
			}

			insert_new_definition(&ctx.context_heap, name_context, "this", -1, "this")

			str.write_string(&ctx.result, "\n\n")
			str.write_string(&ctx.result, indent_str);
			str.write_string(&ctx.result, complete_initializer_name);
			str.write_string(&ctx.result, " :: proc(this : ^")
			str.write_string(&ctx.result, complete_structure_name);
			if len(structure.template_spec) > 0 {
				str.write_byte(&ctx.result, '(')
				for ti, i in structure.template_spec {
					if i > 0 { str.write_string(&ctx.result, ", ") }

					type_var := ctx.ast[ti]
					assert_eq(type_var.kind, AstNodeKind.VariableDeclaration)

					str.write_byte(&ctx.result, '$')
					str.write_string(&ctx.result, type_var.var_declaration.var_name.source)
				}
				str.write_byte(&ctx.result, ')')
			}
			if initializer.kind == .FunctionDefinition && .ForwardDeclaration not_in initializer.function_def.flags {
				for nidx, i in initializer.function_def.arguments {
					str.write_string(&ctx.result, ", ")
					arg := ctx.ast[nidx].var_declaration

					insert_new_definition(&ctx.context_heap, name_context, arg.var_name.source, nidx, arg.var_name.source)

					str.write_string(&ctx.result, arg.var_name.source)
					str.write_string(&ctx.result, " : ")
					write_type_node(ctx, ctx.ast[arg.type], name_context)

					if arg.initializer_expression != {} {
						str.write_string(&ctx.result, " = ")
						write_node(ctx, arg.initializer_expression, name_context)
					}
				}
			}
			str.write_string(&ctx.result, ")\n")

			str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{\n")
			for ci in structure.members {
				if ctx.ast[ci].kind != .VariableDeclaration { continue }
				member := ctx.ast[ci].var_declaration
				if member.initializer_expression == {} { continue }

				str.write_string(&ctx.result, member_indent_str);
				str.write_string(&ctx.result, "this.")
				str.write_string(&ctx.result, member.var_name.source)
				str.write_string(&ctx.result, " = ")
				write_node(ctx, member.initializer_expression, name_context)
				str.write_byte(&ctx.result, '\n')
			}
			if initializer.kind == .FunctionDefinition && .ForwardDeclaration not_in initializer.function_def.flags && len(initializer.function_def.body_sequence) > 0 {
				write_node_sequence(ctx, initializer.function_def.body_sequence[:], name_context, member_indent_str)
				if ctx.ast[last(initializer.function_def.body_sequence[:])^].kind != .NewLine { str.write_byte(&ctx.result, '\n') }
			}
			str.write_string(&ctx.result, indent_str); str.write_byte(&ctx.result, '}')
		}

		if (structure.deinitializer != {} && .ForwardDeclaration not_in ctx.ast[structure.deinitializer].function_def.flags) {
			deinitializer := ctx.ast[structure.deinitializer]

			complete_deinitializer_name := str.concatenate({ complete_structure_name, "_deinit" })
			name_context := insert_new_definition(&ctx.context_heap, name_context, last(deinitializer.function_def.function_name[:]).source, structure.deinitializer, complete_deinitializer_name)
			insert_new_overload(ctx, "deinit", complete_deinitializer_name)

			context_heap_reset := len(&ctx.context_heap) // keep fn as leaf node
			defer {
				clear(&ctx.context_heap[name_context].definitions)
				resize(&ctx.context_heap, context_heap_reset)
			}

			insert_new_definition(&ctx.context_heap, name_context, "this", -1, "this")

			str.write_string(&ctx.result, "\n\n")
			str.write_string(&ctx.result, indent_str);
			str.write_string(&ctx.result, complete_deinitializer_name);
			str.write_string(&ctx.result, " :: proc(this : ^")
			str.write_string(&ctx.result, complete_structure_name);
			str.write_string(&ctx.result, ")\n")

			str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{")
			write_node_sequence(ctx, deinitializer.function_def.body_sequence[:], name_context, member_indent_str)
			str.write_string(&ctx.result, indent_str); str.write_byte(&ctx.result, '}')
		}

		for midx in structure.members {
			#partial switch ctx.ast[midx].kind {
				case .FunctionDefinition:
					str.write_string(&ctx.result, "\n\n")
					write_function(ctx, name_context, midx, complete_structure_name, structure_node, indent_str)

					requires_new_paragraph = true

				case .Struct, .Union:
					if len(ctx.ast[midx].structure.name) == 0 { break }

					str.write_string(&ctx.result, "\n\n")
					ctx.ast[midx].structure.name = slice.concatenate([][]Token{structure.name, ctx.ast[midx].structure.name})
					write_node(ctx, midx, name_context, indent_str)

					requires_new_paragraph = true
			}
		}

		return
	}

	write_struct_union_type :: proc(ctx : ^ConverterContext, structure_node : ^AstNode, structure_node_index : AstNodeIndex, name_context_ : NameContextIndex, og_name_context : NameContextIndex, indent_str, member_indent_str : string, complete_structure_name : string) -> (has_static_var_members, has_inplicit_initializer : bool, name_context : NameContextIndex)
	{
		structure := &structure_node.structure
		str.write_string(&ctx.result, "struct")

		if len(structure.template_spec) != 0 {
			str.write_byte(&ctx.result, '(')
			for ti, i in structure.template_spec {
				if i > 0 { str.write_string(&ctx.result, ", ") }
				str.write_byte(&ctx.result, '$')
				write_node(ctx, ti, name_context)
			}
			str.write_byte(&ctx.result, ')')
		}

		str.write_string(&ctx.result, structure_node.kind == .Struct ? " {" : " #raw_union {")

		last_was_newline := false
		had_first_newline := false

		name_context = name_context_
		if structure.base_type != nil {
			// copy over defs from base type, using their location
			_, base_context := find_definition_for_name(ctx, name_context, structure.base_type)

			base_member_name := str.concatenate({ "__base_", str.to_lower(structure.base_type[len(structure.base_type) - 1].source, context.temp_allocator) })
			name_context = transmute(NameContextIndex) append_return_index(&ctx.context_heap, NameContext{
				parent      = name_context,
				node        = base_context.node,
				definitions = base_context.definitions, // make sure not to modify these! ok because we push another context right after
			})

			str.write_byte(&ctx.result, '\n')
			str.write_string(&ctx.result, member_indent_str)
			str.write_string(&ctx.result, "using ")
			str.write_string(&ctx.result, base_member_name)
			str.write_string(&ctx.result, " : ")
			str.write_string(&ctx.result, base_context.complete_name)
			str.write_string(&ctx.result, ",\n")

			last_was_newline = true
			had_first_newline = true
		}

		if len(structure.name) != 0 { // anonymous types don't have a name
			name_context = transmute(NameContextIndex) append_return_index(&ctx.context_heap, NameContext{ node = structure_node_index, parent = name_context, complete_name = complete_structure_name })
			ctx.context_heap[og_name_context].definitions[last(structure.name).source] = name_context
			// no reset here, struct context might be relevant later on
		}

		SubsectionSectionData :: struct {
			member_stack : sa.Small_Array(64, AstNodeIndex),
			subsection_counter : int,
			member_indent_str : string,
		}
		subsection_data : SubsectionSectionData

		write_bitfield_subsection_and_reset :: proc(ctx : ^ConverterContext, subsection_data : ^SubsectionSectionData, name_context : NameContextIndex, indent_str : string)
		{
			if len(subsection_data.member_indent_str) == 0 {
				subsection_data.member_indent_str = str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
			}

			str.write_string(&ctx.result, indent_str);
			str.write_string(&ctx.result, "using _");
			fmt.sbprint(&ctx.result, subsection_data.subsection_counter); subsection_data.subsection_counter += 1
			str.write_string(&ctx.result, " : bit_field u8 {\n");

			last_was_newline := true
			slice := sa.slice(&subsection_data.member_stack)
			loop: for cii := 0; cii < len(slice); cii += 1 {
				ci := slice[cii]
				#partial switch ctx.ast[ci].kind {
					case .VariableDeclaration:
						if last_was_newline { str.write_string(&ctx.result, subsection_data.member_indent_str) }
						else { str.write_byte(&ctx.result, ' ') }
						write_node(ctx, ci, name_context)
						str.write_byte(&ctx.result, ',')

						last_was_newline = false

					case .Comment:
						if last_was_newline { str.write_string(&ctx.result, subsection_data.member_indent_str) }
						else { str.write_byte(&ctx.result, ' ') }
						write_node(ctx, ci, name_context)

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

					d := insert_new_definition(&ctx.context_heap, name_context, member.var_name.source, ci, member.var_name.source)
					has_inplicit_initializer |= member.initializer_expression != {}

					if member.width_expression != {} {
						sa.append(&subsection_data.member_stack, ci)
						continue
					}

					if sa.len(subsection_data.member_stack) > 0 {
						write_bitfield_subsection_and_reset(ctx, &subsection_data, name_context, member_indent_str)
					}

					if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
					else { str.write_byte(&ctx.result, ' ') }
					str.write_string(&ctx.result, member.var_name.source);
					str.write_string(&ctx.result, " : ")
					write_type_node(ctx, ctx.ast[member.type], name_context)
					str.write_byte(&ctx.result, ',')

					last_was_newline = false

				case .Enum, .FunctionDefinition, .OperatorDefinition:
					// dont write

					last_was_transfered = false

				case .Struct, .Union:
					if len(member.structure.name) != 0 { last_was_transfered = false; break }

					// write anonymous structs as using statements
					if last_was_newline { str.write_string(&ctx.result, member_indent_str) }
					else { str.write_byte(&ctx.result, ' ') }

					str.write_string(&ctx.result, "using _")
					fmt.sbprint(&ctx.result, subsection_data.subsection_counter); subsection_data.subsection_counter += 1
					str.write_string(&ctx.result, " : ")
					inner_member_indent_str :=  str.concatenate({ member_indent_str, ONE_INDENT }, context.temp_allocator)
					write_struct_union_type(ctx, member, ci, name_context, og_name_context, member_indent_str, inner_member_indent_str, "")
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
							case .Struct, .Union:
								if len(node.structure.name) == 0 { continue loop }
							case .Enum:
								if len(node.enum_.name) == 0 { continue loop }
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
			write_bitfield_subsection_and_reset(ctx, &subsection_data, name_context, member_indent_str)
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

	write_function_type :: proc(ctx : ^ConverterContext, name_context : NameContextIndex, fn_node : AstNode, complete_structure_name : string, parent_type : ^AstNode) -> (arg_count : int)
	{
		fn_node := fn_node.function_def

		if .Inline in fn_node.flags {
			str.write_string(&ctx.result, "#force_inline ")
		}

		str.write_string(&ctx.result, "proc(")

		for ti in fn_node.template_spec {
			if arg_count > 0 { str.write_string(&ctx.result, ", ") }

			str.write_byte(&ctx.result, '$')
			write_node(ctx, ti, name_context)

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
					assert_eq(type_var.kind, AstNodeKind.VariableDeclaration)

					str.write_byte(&ctx.result, '$')
					str.write_string(&ctx.result, type_var.var_declaration.var_name.source)
				}
				str.write_byte(&ctx.result, ')')
			}

			insert_new_definition(&ctx.context_heap, name_context, "this", -1, "this")

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
						if .ForwardDeclaration not_in fn_node.flags {
							insert_new_definition(&ctx.context_heap, name_context, arg.var_name.source, nidx, arg.var_name.source)
						}
		
						str.write_string(&ctx.result, arg.var_name.source)
					}
					else {
						str.write_byte(&ctx.result, '_') // fn args might not have a name
					}
					str.write_string(&ctx.result, " : ")
					write_type_node(ctx, ctx.ast[arg.type], name_context)
	
					if arg.initializer_expression != {} {
						str.write_string(&ctx.result, " = ")
						write_node(ctx, arg.initializer_expression, name_context)
					}

					arg_count += 1

				case:
					panic(fmt.tprintf("Cannot convert %v to fn arg.", ctx.ast[nidx]))
			}
		}

		str.write_byte(&ctx.result, ')')

		if fn_node.return_type != {} {
			return_type := ctx.ast[fn_node.return_type].type
			if len(return_type) > 1 || return_type[0].source != "void" {
				str.write_string(&ctx.result, " -> ")
				write_type_node(ctx, ctx.ast[fn_node.return_type], name_context)
			}
		}

		return
	}

	write_function :: proc(ctx : ^ConverterContext, name_context : NameContextIndex, function_node_idx : AstNodeIndex, complete_structure_name : string, parent_type : ^AstNode, indent_str : string, write_forward_declared := false)
	{
		fn_node_ := &ctx.ast[function_node_idx]
		fn_node := &fn_node_.function_def

		complete_name := fold_token_range(complete_structure_name, fn_node.function_name[:])

		// fold attached comments form forward declaration. This also works when chaining forward declarations
		_, forward_declared_context := try_find_definition_for_name(ctx, name_context, fn_node.function_name[:], { .Function })
		if forward_declared_context != nil {
			forward_declaration := ctx.ast[forward_declared_context.node]
			assert_eq(forward_declaration.kind, AstNodeKind.FunctionDefinition)

			forward_comments := forward_declaration.function_def.attached_comments
			inject_at(&fn_node.attached_comments, 0, ..forward_comments[:])
		}

		name_context := name_context
		if len(fn_node.function_name) == 1 {
			name_context = insert_new_definition(&ctx.context_heap, name_context, last(fn_node.function_name[:]).source, function_node_idx, complete_name)
		}
		else {
			assert(forward_declared_context != nil)
			name_context = transmute(NameContextIndex) mem.ptr_sub(forward_declared_context, &ctx.context_heap[0])
		}

		if .ForwardDeclaration in fn_node.flags && !write_forward_declared {
			return // Don't insert forward declarations, only insert the name context leaf node.
		}

		context_heap_reset := len(&ctx.context_heap) // keep fn as leaf node, since expressions cen reference the name
		defer {
			clear(&ctx.context_heap[name_context].definitions)
			resize(&ctx.context_heap, context_heap_reset)
		}

		// write directly, they are marked for skipping in write_sequence
		for aid in fn_node.attached_comments {
			write_node(ctx, aid, name_context)
		}

		str.write_string(&ctx.result, indent_str);
		str.write_string(&ctx.result, complete_name);
		str.write_string(&ctx.result, " :: ");
		write_function_type(ctx, name_context, fn_node_^, complete_structure_name, parent_type)

		if .ForwardDeclaration in fn_node.flags {
			return
		}

		switch len(fn_node.body_sequence) {
			case 0:
				str.write_string(&ctx.result, " { }");

			case 1:
				str.write_string(&ctx.result, " { ");
				write_node(ctx, fn_node.body_sequence[0], name_context)
				str.write_string(&ctx.result, " }");

			case:
				str.write_byte(&ctx.result, '\n')

				str.write_string(&ctx.result, indent_str); str.write_string(&ctx.result, "{")
				body_indent_str := str.concatenate({ indent_str, ONE_INDENT }, context.temp_allocator)
				write_node_sequence(ctx, fn_node.body_sequence[:], name_context, body_indent_str)
				str.write_string(&ctx.result, indent_str); str.write_byte(&ctx.result, '}')
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

	write_type_node :: proc(ctx : ^ConverterContext, r : AstNode, name_context : NameContextIndex)
	{
		#partial switch r.kind {
			case .Type:
				write_type(ctx, r.type[:], name_context)

			case .FunctionDefinition:
				write_function_type(ctx, 0 /*hopefully not relevant*/, r, "", nil)
		}
	}

	write_type :: proc(ctx : ^ConverterContext, type_tokens : []Token, name_context : NameContextIndex)
	{
		type_tokens := type_tokens
		type_segemnts := make([dynamic]TypeSegment, 0, len(type_tokens), context.temp_allocator)
		translate_type(&type_segemnts, ctx.ast, &type_tokens)
		write_type_inner(ctx, type_segemnts[:], name_context)
	}

	write_type_inner :: proc(ctx : ^ConverterContext, type_segemnts : []TypeSegment, name_context : NameContextIndex)
	{
		last_type_was_ident := false
		for _ti := 0; _ti < len(type_segemnts); _ti += 1 {
			_t := type_segemnts[_ti]
			switch t in _t {
				case _TypePtr:
					if _ti + 1 < len(type_segemnts) {
						next := type_segemnts[_ti + 1]
						if next, ok := next.(_TypeFragment); ok && next.identifier.source == "void" {
							str.write_string(&ctx.result, "uintptr")
							_ti += 1
							break
						}
					}

					// else
					str.write_byte(&ctx.result, '^')

				case _TypeMultiptr:
					str.write_string(&ctx.result, "[^]")

				case _TypeFragment:
					if last_type_was_ident { str.write_byte(&ctx.result, '_') }
					str.write_string(&ctx.result, t.identifier.source)
					if len(t.generic_arguments) > 0 {
						str.write_byte(&ctx.result, '(')
						for g, i in t.generic_arguments {
							if i > 0 { str.write_string(&ctx.result, ", ") }
							write_type_inner(ctx, g[:], name_context)
						}
						str.write_byte(&ctx.result, ')')
					}

					last_type_was_ident = true

				case _TypeArray:
					str.write_byte(&ctx.result, '[')
					write_node(ctx, t.length_expression, name_context)
					str.write_byte(&ctx.result, ']')
			}
		}
	}

	strip_type :: proc(input : TokenRange) -> (output : [dynamic]Token)
	{
		output = make([dynamic]Token, 0, len(input))

		generic_depth := 0
		for token in input {
			#partial switch token.kind {
				case .Identifier:
					if generic_depth == 0 && token.source != "const" {
						append(&output, token)
					}
					
				case .BracketTriangleOpen:
					generic_depth += 1
				case .BracketTriangleClose:
					generic_depth -= 1
			}
		}

		return
	}

	resolve_type :: proc(ctx : ^ConverterContext, current_node_index : AstNodeIndex, name_context : NameContextIndex) -> (raw_type : TokenRange, type_context : NameContextIndex)
	{
		current_node := ctx.ast[current_node_index]
		#partial switch current_node.kind {
			case .Identifier:
				_, var_def := find_definition_for_name(ctx, name_context, current_node.identifier[:])
				assert_eq(ctx.ast[var_def.node].kind, AstNodeKind.VariableDeclaration)

				return resolve_type(ctx, var_def.node, var_def.parent)
			
			case .ExprUnaryLeft:
				return resolve_type(ctx, current_node.unary_left.right, name_context)

			case .ExprUnaryRight:
				return resolve_type(ctx, current_node.unary_right.left, name_context)

			case .ExprIndex:
				indexed_type, expression_context := resolve_type(ctx, current_node.index.array_expression, name_context)
				if last(indexed_type).kind == .Star {
					// ptr index
					return indexed_type[:len(indexed_type) - 1], expression_context // slice of one layer of 
				}
				else { // assume the type is indexable and look for a matchin operator
					indexed_type_stripped := strip_type(indexed_type)
					_, structure_def := find_definition_for_name(ctx, name_context, indexed_type_stripped[:])
					structure_node := ctx.ast[structure_def.node]
					assert(structure_node.kind == .Struct || structure_node.kind == .Union)

					for mi in structure_node.structure.members {
						member := ctx.ast[mi]
						if member.kind != .OperatorDefinition || member.operator_def.kind != .Index { continue }

						ri := ctx.ast[member.operator_def.underlying_function].function_def.return_type
						type := ctx.ast[ri].type[:]
						type_stripped := strip_type(type)
						_, type_context := find_definition_for_name(ctx, name_context, type_stripped[:])

						return type, transmute(NameContextIndex) mem.ptr_sub(type_context, &ctx.context_heap[0])
					}
				}

			case .MemberAccess:
				member_access := current_node.member_access
				expr_type, expr_type_context_idx := resolve_type(ctx, member_access.expression, name_context)

				member := ctx.ast[member_access.member]
				#partial switch member.kind {
					case .Identifier:
						return resolve_type(ctx, member_access.member, expr_type_context_idx)

					case .FunctionCall:
						fn_name_node := ctx.ast[member.function_call.expression]
						assert_eq(fn_name_node.kind, AstNodeKind.Identifier)
						fn_name := last(fn_name_node.identifier[:]).source

						fndef_idx := ctx.context_heap[expr_type_context_idx].definitions[fn_name]
						fndef_ctx := ctx.context_heap[fndef_idx]

						assert_eq(ctx.ast[fndef_ctx.node].kind, AstNodeKind.FunctionDefinition)
						fndef := ctx.ast[fndef_ctx.node].function_def

						type := ctx.ast[fndef.return_type].type[:]
						type_stripped := strip_type(type)
						_, type_context := find_definition_for_name(ctx, name_context, type_stripped[:])

						return type, transmute(NameContextIndex) mem.ptr_sub(type_context, &ctx.context_heap[0])

					case:
						panic(fmt.tprintf("Not implemented %v", member))
				}

			case .VariableDeclaration:
				def_node := current_node.var_declaration

				type := ctx.ast[def_node.type].type[:]

				if type[0].source == "auto" {
					panic("auto resolver not implemented");
				}

				type_stripped := strip_type(type)
				_, type_context := try_find_definition_for_name(ctx, name_context, type_stripped[:], {.Type}) // can be builtin type

				return type, type_context != nil ? transmute(NameContextIndex) mem.ptr_sub(type_context, &ctx.context_heap[0]) : 0

			case:
				panic(fmt.tprintf("Not implemented %#v", current_node))
		}

		unreachable();
	}
}

translate_type :: proc(output : ^[dynamic]TypeSegment, ast : []AstNode, input : ^TokenRange)
{
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

	try_atach_generic_parameters :: proc(params : ^[dynamic][dynamic]TypeSegment, ast : []AstNode, input : ^TokenRange)
	{
		next, ns := peek_token(input)
		if next.kind != .BracketTriangleOpen { return }

		input^ = ns
		for {
			next, ns = peek_token(input)
			#partial switch next.kind {
				case .BracketTriangleClose:
					input^ = ns
					return

				case .Comma:
					input^ = ns
					continue

				case:
					p : [dynamic]TypeSegment
					translate_type(&p, ast, input)
					append(params, p)
			}
		}
	}

	for len(input) > 0 {
		#partial switch input[0].kind {
			case .Identifier:
				switch input[0].source {
					case "const":
						input^ = input[1:]

					case "signed":
						switch input[1].source {
							case "char":
								input^ = input[2:]
								append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "i8" } })

							case "int":
								input^ = input[2:]
								append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "i32" } })

							case "short":
								input^ = transform_from_short(output, input[2:], "i")

							case "long":
								input^ = transform_from_long(output, input[2:], "i")
						}

					case "unsigned":
						switch input[1].source {
							case "char":
								input^ = input[2:]
								append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "u8" } })

							case "int":
								input^ = input[2:]
								append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "u32" } })

							case "short":
								input^ = transform_from_short(output, input[2:], "u")

							case "long":
								input^ = transform_from_long(output, input[2:], "u")
						}

					case "char":
						input^ = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "u8" } }) // funny implementation defined singnedness, interpret as unsigned

					case "int":
						input^ = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "i32" } })

					case "short":
						input^ = transform_from_short(output, input[1:], "i")

					case "long":
						input^ = transform_from_long(output, input[1:], "i")

					case "float":
						input^ = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "f32" } })

					case "double":
						input^ = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "f64" } })

					case "size_t":
						input^ = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "uint" } })

					case "ptrdiff_t":
						input^ = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "int" } })

					case "typename", "class":
						input^ = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "typeid" } })

					case "va_list":
						input^ = input[1:]
						append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "[]any" } })

					case:
						frag := _TypeFragment{ identifier = input[0] }
						input^ = input[1:]
						try_atach_generic_parameters(&frag.generic_arguments, ast, input)
						append(output, frag)
				}

			case .Class:
				input^ = input[1:]
				append(output, _TypeFragment{ identifier = Token{ kind = .Identifier, source = "typeid" } })

			case .Star, .Ampersand:
				input^ = input[1:]
				inject_at(output, 0, _TypePtr{})

			case .AstNode: // used for array expression for now
				if input[0].location.column != {} {
					length_expression := transmute(AstNodeIndex) input[0].location.column
					inject_at(output, 0, _TypeArray{ length_expression })
				}
				else{
					inject_at(output, 0, _TypeMultiptr{})
				}
				input^ = input[1:]

			case .StaticScopingOperator:
				input^ = input[1:]
				// just eat the token and dont copy it over

			case:
				return
		}
	}
}


write_shim :: proc(ctx : ^ConverterContext)
{
	str.write_string(&ctx.result, `package test

defined :: #force_inline proc "contextless" ($I) -> bool { I }

 pre_decr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ -= 1; return p }
 pre_incr :: #force_inline proc "contextless" (p : ^$T) -> (new : T) { p^ += 1; return p }
post_decr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ -= 1; return }
post_incr :: #force_inline proc "contextless" (p : ^$T) -> (old : T) { old = p; p^ += 1; return }

va_arg :: #force_inline proc(args : ^[]any, $T : typeid) -> (r : T) { r = (cast(T^) args[0])^; args^ = args[1:] }

`)

	for name, overloads in ctx.overload_resolver {
		str.write_byte(&ctx.result, '\n')
		str.write_string(&ctx.result, name)
		str.write_string(&ctx.result, " :: proc {")
		for overloaded_name, i in overloads {
			if i > 0 { str.write_string(&ctx.result, ", ") }
			str.write_string(&ctx.result, overloaded_name)
		}
		str.write_string(&ctx.result, "}\n")
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
}
DeffinitionFilterAll := all(DefinitionFilter)

find_definition_for_name :: proc(ctx : ^ConverterContext, current_index : NameContextIndex, compound_identifier : TokenRange, filter := DeffinitionFilterAll, loc := #caller_location) -> (root_context, name_context : ^NameContext)
{
	root_context, name_context = try_find_definition_for_name(ctx, current_index, compound_identifier, filter)
	if name_context != nil { return }

	dump_context_stack(ctx, current_index, ctx.context_heap[current_index].complete_name)
	panic(fmt.tprintf("%v : %v '%v' was not found in context", compound_identifier[0].location, filter, compound_identifier), loc)
}

try_find_definition_for_name :: proc(ctx : ^ConverterContext, current_index : NameContextIndex, compound_identifier : TokenRange, filter := DeffinitionFilterAll) -> (root_context, name_context : ^NameContext)
{
	im_root_context := &ctx.context_heap[current_index]

	ctx_stack: for {
		current_context := im_root_context

		for segment in compound_identifier {
			child_idx, exists := current_context.definitions[segment.source]
			if !exists {
				if im_root_context.parent == -1 { break ctx_stack }
				im_root_context = &ctx.context_heap[im_root_context.parent]
				continue ctx_stack
			}

			
			current_context = &ctx.context_heap[child_idx]
		}

		if current_context.node != -1 {
			#partial switch ctx.ast[current_context.node].kind {
				case .Struct, .Union, .Enum, .Type:
					if .Type not_in filter {
						if im_root_context.parent == -1 { break ctx_stack }
						im_root_context = &ctx.context_heap[im_root_context.parent]
						continue ctx_stack
					}
				case .FunctionDefinition, .OperatorDefinition:
					if .Function not_in filter {
						if im_root_context.parent == -1 { break ctx_stack }
						im_root_context = &ctx.context_heap[im_root_context.parent]
						continue ctx_stack
					}
				case .VariableDeclaration:
					is_type :: proc(ctx : ^ConverterContext, current_context : ^NameContext) -> (is_type : bool)
					{
						ti := ctx.ast[current_context.node].var_declaration.type
						type := ctx.ast[ti].type[:]
						translated : [dynamic]TypeSegment
						translate_type(&translated, ctx.ast, &type)
						_, is_type = translated[0].(_TypeFragment)
						delete(translated)
						return
					}
					if .Variable not_in filter && (.Type not_in filter || !is_type(ctx, current_context)) {
						if im_root_context.parent == -1 { break ctx_stack }
						im_root_context = &ctx.context_heap[im_root_context.parent]
						continue ctx_stack
					}
			}
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




dump_context_stack :: proc(ctx : ^ConverterContext, name_context_idx : NameContextIndex, name := "", indent := " ", return_at : NameContextIndex = -1)
{
	name_context := ctx.context_heap[name_context_idx]
	
	fmt.eprintf("#%3v %v%v\t\t-> %v | ", transmute(int)name_context_idx, indent, name, name_context.node >= 0 ? ctx.ast[name_context.node].kind : AstNodeKind{});

	if len(name_context.definitions) == 0 {
		fmt.eprintf("<leaf>\n");
	}
	else {
		fmt.eprintf("%v children:\n", len(name_context.definitions))

		indent := str.concatenate({ indent, "  " }, context.temp_allocator)
		for name, didx in name_context.definitions {
			dump_context_stack(ctx, didx, name, indent, name_context_idx)
		}
	}

	if name_context.parent == -1 || name_context.parent == return_at { return }

	indent := str.concatenate({ indent, "  " }, context.temp_allocator)
	dump_context_stack(ctx, name_context.parent, "<parent>", indent, name_context_idx)
}


_TypePtr :: struct {}
_TypeMultiptr :: struct {}
_TypeArray :: struct {
	length_expression : AstNodeIndex,
}

_TypeFragment :: struct {
	identifier : Token,
	generic_arguments : [dynamic][dynamic]TypeSegment,
}

TypeSegment :: union #no_nil { _TypePtr, _TypeMultiptr, _TypeArray, _TypeFragment }
Type :: []TypeSegment
