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

merge_ast :: proc(folded : ^[dynamic]AstNode, preprocessed : [][]AstNode)
{
	nodes_len := 0
	for s in preprocessed { nodes_len += len(s) }
	resize(folded, nodes_len)

	nodes_len = 0
	for s in preprocessed {
		copy(folded[nodes_len:], s)
		nodes_len += len(s)
	}
}

convert_and_format :: proc(result : ^str.Builder, nodes : []AstNode)
{
	if nodes[0].kind != nil {
		context_stack : [dynamic]NameContext
		append(&context_stack, NameContext{}) // root context
		
		str.write_string(result, "package test\n\n")
		print_node(result, nodes, 0, &context_stack, -1)
	}

	print_node :: proc(result : ^str.Builder, ast : []AstNode, current_node_index : AstNodeIndex, context_stack : ^[dynamic]NameContext, indent := 0, prefix := "") -> (requires_termination, requires_new_paragraph : bool)
	{
		ONE_INDENT :: "\t"
		current_node := ast[current_node_index]
		#partial switch current_node.kind {
			case .NewLine:
				str.write_byte(result, '\n')

			case .Sequence:
				previous_requires_termination := false
				previous_requires_new_paragraph := false
				for ci, cii in current_node.sequence {
					node_type := ast[ci].kind
					if previous_requires_termination && node_type != .NewLine { str.write_string(result, "; ") }
					if previous_requires_new_paragraph && len(current_node.sequence) > cii + 1 {
						if node_type != .NewLine { str.write_string(result, "\n\n") }
						else if ast[current_node.sequence[cii + 1]].kind != .NewLine { str.write_byte(result, '\n') }
					}

					previous_requires_termination, previous_requires_new_paragraph = print_node(result, ast, ci, context_stack, indent + 1)
				}

			case .FunctionDefinition:
				current_indent_str := str.repeat(ONE_INDENT, indent, context.temp_allocator)
				current_member_indent_str := str.concatenate({ current_indent_str, ONE_INDENT }, context.temp_allocator)
				fndef := current_node.function_def

				last(context_stack[:]).definitions[last(fndef.function_name).source] = current_node_index

				name_context := append_return_ptr(context_stack, NameContext{})
				defer pop(context_stack)

				print_token_range(result, fndef.function_name); str.write_string(result, " :: proc(")
				for nidx, i in fndef.arguments {
					if i != 0 { str.write_string(result, ", ") }
					arg := ast[nidx].var_declaration

					name_context.definitions[arg.var_name.source] = arg.type

					str.write_string(result, arg.var_name.source)
					str.write_string(result, " : ")
					print_type(result, ast, ast[arg.type])

					if arg.initializer_expression != {} {
						str.write_string(result, " = ")
						print_node(result, ast, arg.initializer_expression, context_stack)
					}
				}
				str.write_byte(result, ')')
				if fndef.return_type != {} && ast[fndef.return_type].type[0].source != "void" {
					str.write_string(result, " -> ")
					print_type(result, ast, ast[fndef.return_type])
				}
				str.write_byte(result, '\n')
				str.write_string(result, current_indent_str); str.write_string(result, "{\n")

				for ci in fndef.body_sequence {
					str.write_string(result, current_member_indent_str)
					print_node(result, ast, ci, context_stack, indent + 1)
					str.write_byte(result, '\n')
				}
				str.write_string(result, current_indent_str); str.write_byte(result, '}')

			case .Struct, .Union:
				current_indent_str := str.repeat(ONE_INDENT, indent, context.temp_allocator)
				current_member_indent_str := str.concatenate({ current_indent_str, ONE_INDENT }, context.temp_allocator)
				structure := current_node.struct_or_union

				last(context_stack[:]).definitions[last(structure.name).source] = current_node_index

				context_stack_reset := len(context_stack)
				defer resize(context_stack, context_stack_reset)

				str.write_string(result, current_indent_str);
				print_token_range(result, structure.name)
				str.write_string(result, current_node.kind == .Struct ? " :: struct {\n" : " :: struct #raw_union {\n")

				if structure.base_type != nil {
					definition, _ := find_definition_for_name(ast, context_stack[:], structure.base_type)
					append(context_stack, structure_to_context(ast, definition^)) // @perf: this has already been done at some point and is repeated work

					str.write_string(result, current_member_indent_str)
					str.write_string(result, "using __base_")
					str.write_string(result, str.to_lower(structure.base_type[len(structure.base_type) - 1].source, context.temp_allocator))
					str.write_string(result, " : ")
					print_token_range(result, structure.base_type)
					str.write_string(result, ",\n")
				}

				name_context := append_return_ptr(context_stack, NameContext{ is_structure = true }) // after the base type

				has_inplicit_initializer := false
				for ci in structure.members {
					if ast[ci].kind != .VariableDeclaration { continue }
					member := ast[ci].var_declaration

					name_context.definitions[member.var_name.source] = ci

					str.write_string(result, current_member_indent_str);
					str.write_string(result, member.var_name.source);
					str.write_string(result, " : ")
					print_type(result, ast, ast[member.type])
					str.write_string(result, ",\n")

					has_inplicit_initializer |= member.initializer_expression != {}
				}
				
				str.write_string(result, current_indent_str); str.write_byte(result, '}')

				if has_inplicit_initializer || structure.initializer != {} {
					initializer := ast[structure.initializer]

					name_context := append_return_ptr(context_stack, NameContext{})
					defer pop(context_stack)

					name_context.definitions["this"] = current_node_index

					str.write_string(result, "\n\n")
					str.write_string(result, current_indent_str);
					print_token_range(result, structure.name)
					str.write_string(result, "_init :: proc(this : ^")
					print_token_range(result, structure.name)
					if initializer.kind == .FunctionDefinition {
						for nidx, i in initializer.function_def.arguments {
							str.write_string(result, ", ")
							arg := ast[nidx].var_declaration

							name_context.definitions[arg.var_name.source] = nidx

							str.write_string(result, arg.var_name.source)
							str.write_string(result, " : ")
							print_type(result, ast, ast[arg.type])
		
							if arg.initializer_expression != {} {
								str.write_string(result, " = ")
								print_node(result, ast, arg.initializer_expression, context_stack)
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
						print_node(result, ast, member.initializer_expression, context_stack)
						str.write_byte(result, '\n')
					}
					if initializer.kind == .FunctionDefinition {
						for ci in initializer.function_def.body_sequence {
							str.write_string(result, current_member_indent_str)
							print_node(result, ast, ci, context_stack, indent + 1)
							str.write_byte(result, '\n')
						}
					}
					str.write_string(result, current_indent_str); str.write_byte(result, '}')
				}

				for midx in structure.members {
					#partial switch ast[midx].kind {
						case .FunctionDefinition:
							member_fn := ast[midx].function_def

							name_context := append_return_ptr(context_stack, NameContext{ })
							defer pop(context_stack)

							name_context.definitions["this"] = current_node_index

							str.write_string(result, "\n\n")
							str.write_string(result, current_indent_str);
							print_token_range(result, structure.name)
							str.write_byte(result, '_');
							assert(len(member_fn.function_name) == 1)
							str.write_string(result, member_fn.function_name[0].source);
							str.write_string(result, " :: proc(this : ^")
							print_token_range(result, structure.name)
							for nidx, i in member_fn.arguments {
								str.write_string(result, ", ")
								arg := ast[nidx].var_declaration

								name_context.definitions[arg.var_name.source] = nidx

								str.write_string(result, arg.var_name.source)
								str.write_string(result, " : ")
								print_type(result, ast, ast[arg.type])
			
								if arg.initializer_expression != {} {
									str.write_string(result, " = ")
									print_node(result, ast, arg.initializer_expression, context_stack)
								}
							}
							str.write_byte(result, ')')

							if member_fn.return_type != {} && ast[member_fn.return_type].type[0].source != "void" {
								str.write_string(result, " -> ")
								print_type(result, ast, ast[member_fn.return_type])
							}

							str.write_byte(result, '\n')

							str.write_string(result, current_indent_str); str.write_string(result, "{\n")
							for ci in member_fn.body_sequence {
								str.write_string(result, current_member_indent_str)
								print_node(result, ast, ci, context_stack, indent + 1)
								str.write_byte(result, '\n')
							}
							str.write_string(result, current_indent_str); str.write_byte(result, '}')

							requires_new_paragraph = true

						case .Struct, .Union:
							str.write_string(result, "\n\n")
							ast[midx].struct_or_union.name = slice.concatenate([][]Token{structure.name, ast[midx].struct_or_union.name})
							print_node(result, ast, midx, context_stack, indent)

							requires_new_paragraph = true
					}
				}

			case .VariableDeclaration:
				vardef := current_node.var_declaration

				context_stack[len(context_stack) - 1].definitions[vardef.var_name.source] = current_node_index

				str.write_string(result, vardef.var_name.source)
				str.write_string(result, " : ")
				print_type(result, ast, ast[vardef.type])

				if vardef.initializer_expression != {} {
					str.write_string(result, " = ")
					print_node(result, ast, vardef.initializer_expression, context_stack)
				}
				requires_termination = true

			case .Return:
				str.write_string(result, "return")

				if current_node.return_.expression != {} {
					str.write_byte(result, ' ')
					print_node(result, ast, current_node.return_.expression, context_stack)
				}

			case .LiteralBool, .LiteralFloat, .LiteralInteger, .LiteralString, .LiteralCharacter, .Continue, .Break:
				str.write_string(result, current_node.literal.source)

			case .LiteralNull:
				str.write_string(result, "nil")

			case .ExprUnary:
				switch current_node.unary.operator {
					case .Invert:
						str.write_byte(result, '!')
						print_node(result, ast, current_node.unary.right, context_stack)

					case .Dereference:
						print_node(result, ast, current_node.unary.right, context_stack)
						str.write_byte(result, '^')

					case .Minus:
						str.write_byte(result, '-')
						print_node(result, ast, current_node.unary.right, context_stack)
				}

				requires_termination = true

			case .ExprBinary:
				print_node(result, ast, current_node.binary.left, context_stack)
				str.write_byte(result, ' ')
				str.write_byte(result, u8(current_node.binary.operator))
				str.write_byte(result, ' ')
				print_node(result, ast, current_node.binary.right, context_stack)

				requires_termination = true

			case .MemberAccess:
				member := ast[current_node.member_access.member]
				if member.kind == .FunctionCall {
					fncall := member.function_call;

					this_type : ^AstNode
					is_ptr : bool
					expr := ast[current_node.member_access.expression]
					if expr.kind == .Identifier {
						var, _ := find_definition_for_name(ast, context_stack[:], expr.identifier)
						assert_eq(var.kind, AstNodeKind.VariableDeclaration)

						last_type_segment := last(ast[var.var_declaration.type].type[:])
						is_ptr = last_type_segment.kind == .Star || last_type_segment.kind == .Ampersand

						// check if the function actually exists on this type, if not climb base types
						this_type_sequence := ast[var.var_declaration.type].type[:]
						this_context := context_stack[:]
						base_loop: for {
							this_type, this_context = find_definition_for_name(ast, this_context, this_type_sequence)
							assert(this_type.kind == .Struct || this_type.kind == .Union, fmt.tprintf("Unexpected %v", this_type))

							for midx in this_type.struct_or_union.members {
								if ast[midx].kind == .FunctionDefinition {
									if last(ast[midx].function_def.function_name).source == last(fncall.qualified_name).source {
										break base_loop
									}
								}
							}

							this_type_sequence = this_type.struct_or_union.base_type
						}
					}
					else { // expression
						panic("not implemented")
					}

					print_token_range(result, this_type.struct_or_union.name)
					str.write_byte(result, '_')
					assert(len(fncall.qualified_name) == 1)
					str.write_string(result, fncall.qualified_name[0].source)

					str.write_byte(result, '(')
					if !is_ptr { str.write_byte(result, '&') }
					print_node(result, ast, current_node.member_access.expression, context_stack)
					for pidx, i in fncall.parameters {
						str.write_string(result, ", ")
						print_node(result, ast, pidx, context_stack)
					}
					str.write_byte(result, ')')
				}
				else {
					print_node(result, ast, current_node.member_access.expression, context_stack)
					str.write_byte(result, '.')
					print_node(result, ast, current_node.member_access.member, context_stack)
				}

				requires_termination = true

			case .ExprIndex:
				print_node(result, ast, current_node.index.array_expression, context_stack)
				str.write_byte(result, '[')
				print_node(result, ast, current_node.index.index_expression, context_stack)
				str.write_byte(result, ']')

			case .Identifier:
				_, name_context := find_definition_for_name(ast, context_stack[:], current_node.identifier)

				if last(name_context).is_structure {
					str.write_string(result, "this.")
				}

				print_token_range(result, current_node.identifier)

			case .FunctionCall:
				fncall := current_node.function_call

				str.write_string(result, last(fncall.qualified_name).source)
				str.write_byte(result, '(')
				for pidx, i in fncall.parameters {
					if i != 0 { str.write_string(result, ", ") }
					print_node(result, ast, pidx, context_stack)
				}
				str.write_byte(result, ')')

				requires_termination = true

			case:
				log.error("Unknown ast node:", current_node)
				runtime.trap();
		}
		return
	}

	print_token_range :: proc(result : ^str.Builder, r : TokenRange, glue := "_")
	{
		for t, i in r {
			if i != 0 { str.write_string(result, glue) }
			str.write_string(result, t.source)
		}
	}

	print_type :: proc(result : ^str.Builder, ast : []AstNode, r : AstNode)
	{
		type_tokens := r.type[:]
		converted_type_tokens := make([dynamic]Token, 0, len(type_tokens), context.temp_allocator)
		translate_type(&converted_type_tokens, ast, type_tokens)

		print_token_range(result, converted_type_tokens[:], "")
	}

	translate_type :: proc(output : ^[dynamic]Token, ast : []AstNode, input : TokenRange)
	{
		remaining_input := input

		transform_from_short :: proc(output : ^[dynamic]Token, input : TokenRange, $prefix : string) -> (remaining_input : TokenRange)
		{
			if len(input) == 0 || input[0].kind != .Identifier { // short, short*
				remaining_input = input
				append(output, Token{ kind = .Identifier, source = prefix+"16" })
			}
			else if input[0].source == "int" { // short int
				remaining_input = input[1:]
				append(output, Token{ kind = .Identifier, source = prefix+"16" })
			}
			else {
				panic("Failed to transform "+prefix+" short");
			}

			return
		}

		transform_from_long :: proc(output : ^[dynamic]Token, input : TokenRange, $prefix : string) -> (remaining_input : TokenRange)
		{
			if len(input) == 0 || input[0].kind != .Identifier { // long, long*
				remaining_input = input
				append(output, Token{ kind = .Identifier, source = prefix+"32" })
			}
			else if input[0].source == "int" { // long int 
				remaining_input = input[1:]
				append(output, Token{ kind = .Identifier, source = prefix+"32" })
			}
			else if input[0].source == "long" { // long long 
				if len(input) == 1 || input[1].kind != .Identifier { // long long, long long*
					remaining_input = input[2:]
					append(output, Token{ kind = .Identifier, source = prefix+"64" })
				}
				else if input[1].source == "int" { // long long int
					remaining_input = input[3:]
					append(output, Token{ kind = .Identifier, source = prefix+"64" })
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
								append(output, Token{ kind = .Identifier, source = "i8" })

							case "int":
								remaining_input = input[2:]
								append(output, Token{ kind = .Identifier, source = "i32" })

							case "short":
								remaining_input = transform_from_short(output, input[2:], "i")
							
							case "long":
								remaining_input = transform_from_long(output, input[2:], "i")
						}

					case "unsigned":
						switch input[1].source {
							case "char":
								remaining_input = input[2:]
								append(output, Token{ kind = .Identifier, source = "u8" })

							case "int":
								remaining_input = input[2:]
								append(output, Token{ kind = .Identifier, source = "u32" })

							case "short":
								remaining_input = transform_from_short(output, input[2:], "u")
							
							case "long":
								remaining_input = transform_from_long(output, input[2:], "u")
						}

					case "char":
						remaining_input = input[1:]
						append(output, Token{ kind = .Identifier, source = "u8" }) // funny implementation defined singnedness, interpret as unsigned

					case "int":
						remaining_input = input[1:]
						append(output, Token{ kind = .Identifier, source = "i32" })

					case "short":
						remaining_input = transform_from_short(output, input[1:], "i")

					case "long":
						remaining_input = transform_from_long(output, input[1:], "i")

					case "float":
						remaining_input = input[1:]
						append(output, Token{ kind = .Identifier, source = "f32" })

					case "double":
						remaining_input = input[1:]
						append(output, Token{ kind = .Identifier, source = "f64" })

					case:
						append(output, input[0])
						remaining_input = input[1:]
				}
			
			case .Star:
				remaining_input = input[1:]
				inject_at(output, 0, Token{ kind = .Circumflex, source = "^" })

			case .AstNode: // used for array expression for now
				inject_index := 0
				inject_at(output, inject_index, Token{ kind = .BracketSquareOpen, source = "[" }); inject_index += 1
				transform_expression(output, &inject_index, ast, transmute(AstNodeIndex) input[0].location.column)
				transform_expression :: proc(output : ^[dynamic]Token, insert_at : ^int, ast : []AstNode, current_node_index : AstNodeIndex)
				{
					node := ast[current_node_index]
					#partial switch node.kind {
						case .LiteralBool, .LiteralCharacter, .LiteralFloat, .LiteralInteger, .LiteralString:
							inject_at(output, insert_at^, node.literal); insert_at^ += 1
						case .ExprUnary:
							switch node.unary.operator {
								case .Minus:
									inject_at(output, insert_at^, Token{ kind = .Minus, source = "-" }); insert_at^ += 1
									transform_expression(output, insert_at, ast, node.unary.right)
								case .Dereference:
									transform_expression(output, insert_at, ast, node.unary.right)
									inject_at(output, insert_at^, Token{ kind = .Minus, source = "^" }); insert_at^ += 1
								case .Invert:
									inject_at(output, insert_at^, Token{ kind = .Minus, source = "!" }); insert_at^ += 1
									transform_expression(output, insert_at, ast, node.unary.right)
							}
						case .ExprBinary:
							transform_expression(output, insert_at, ast, node.binary.left)
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
							inject_at(output, insert_at^, t); insert_at^ += 1
							transform_expression(output, insert_at, ast, node.binary.right)
					}
				}
				inject_at(output, inject_index, Token{ kind = .BracketSquareClose, source = "]" })
				remaining_input = input[1:]


			case:
				append(output, input[0])
				remaining_input = input[1:]
		}

		if(len(remaining_input) > 0) { translate_type(output, ast, remaining_input) }
	}
}

NameContext :: struct {
	definitions : map[string]AstNodeIndex,
	is_structure : bool,
}

find_definition_for_name :: proc(ast : []AstNode, context_stack : []NameContext, compound_identifier : TokenRange) -> (declaration : ^AstNode, final_context : []NameContext)
{
	stack: #reverse for &cc, ci in context_stack[:len(context_stack) - len(compound_identifier) + 1] {
		nidx : AstNodeIndex; found : bool
		for identifier, ii in compound_identifier {
			nidx, found = context_stack[ci + ii].definitions[identifier.source]
			if !found { continue stack }
		}
		return &ast[nidx], context_stack[:ci + 1]
	}

	loc := runtime.Source_Code_Location{ compound_identifier[0].location.file_path, cast(i32) compound_identifier[0].location.row, cast(i32) compound_identifier[0].location.column, "" }
	panic(fmt.tprintf("%v..'%v' was not found in context %#v.", len(compound_identifier) - 1, last(compound_identifier).source, context_stack), loc)
}

structure_to_context :: proc(ast : []AstNode, structure : AstNode) -> (name_context : NameContext) {
	name_context.is_structure = true
	for midx in structure.struct_or_union.members {
		member := ast[midx]
		#partial switch member.kind {
			case .Struct, .Union:
				name_context.definitions[last(member.struct_or_union.name).source] = midx

			case .FunctionDefinition:
				name_context.definitions[last(member.function_def.function_name).source] = midx

			case .VariableDeclaration:
				name_context.definitions[member.var_declaration.var_name.source] = midx

			case:
				panic(fmt.tprintf("Trying to convert unknown member type %v.", member))
		}
	}
	return
}
