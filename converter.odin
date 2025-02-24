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
	if nodes[0].type != nil {
		context_stack : [dynamic]NameContext
		
		str.write_string(result, "package test\n\n")
		print_node(result, nodes, 0, &context_stack, -1)
	}

	print_node :: proc(result : ^str.Builder, ast : []AstNode, current_node_index : AstNodeIndex, context_stack : ^[dynamic]NameContext, indent := 0, prefix := "")
	{
		ONE_INDENT :: "\t"
		current_node := ast[current_node_index]
		#partial switch current_node.type {
			case .Sequence:
				for ci in current_node.sequence {
					print_node(result, ast, ci, context_stack, indent + 1)
				}

			case .FunctionDefinition:
				current_indent_str := str.repeat(ONE_INDENT, indent, context.temp_allocator)
				current_member_indent_str := str.concatenate({ current_indent_str, ONE_INDENT }, context.temp_allocator)
				fndef := current_node.function_def

				name_context := append_return_ptr(context_stack, NameContext{})
				defer pop(context_stack)

				print_token_range(result, fndef.function_name); str.write_string(result, " :: proc(")
				for nidx, i in fndef.arguments {
					if i != 0 { str.write_string(result, ", ") }
					arg := ast[nidx].var_declaration

					name_context.variables[arg.var_name.source] = arg.type

					str.write_string(result, arg.var_name.source)
					str.write_string(result, " : ")
					print_type(result, ast[arg.type])

					if arg.initializer_expression != {} {
						str.write_string(result, " = ")
						print_node(result, ast, arg.initializer_expression, context_stack)
					}
				}
				str.write_byte(result, ')')
				if fndef.return_type != {} && ast[fndef.return_type].type_declaration.segments[0].source != "void" {
					str.write_string(result, " -> ")
					print_type(result, ast[fndef.return_type])
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

				name_context := append_return_ptr(context_stack, NameContext{ is_structure = true })
				defer pop(context_stack)

				str.write_string(result, current_indent_str);
				print_token_range(result, structure.name)
				str.write_string(result, current_node.type == .Struct ? " :: struct {\n" : " :: struct #raw_union {\n")

				if structure.base_type != nil {
					str.write_string(result, current_member_indent_str)
					str.write_string(result, "using __base_")
					str.write_string(result, str.to_lower(structure.base_type[len(structure.base_type) - 1].source, context.temp_allocator))
					str.write_string(result, " : ")
					print_token_range(result, structure.base_type)
					str.write_string(result, ",\n")

					//TODO(Rennorb) @completeness: Inherit base member names
				}

				has_inplicit_initializer := false
				for ci in structure.members {
					if ast[ci].type != .VariableDeclaration { continue }
					member := ast[ci].var_declaration

					name_context.variables[member.var_name.source] = ci

					str.write_string(result, current_member_indent_str);
					str.write_string(result, member.var_name.source);
					str.write_string(result, " : ")
					print_type(result, ast[member.type])
					str.write_string(result, ",\n")

					has_inplicit_initializer |= member.initializer_expression != {}
				}
				
				str.write_string(result, current_indent_str); str.write_byte(result, '}')

				if has_inplicit_initializer || structure.initializer != {} {
					initializer := ast[structure.initializer]

					name_context := append_return_ptr(context_stack, NameContext{})
					defer pop(context_stack)

					name_context.variables["this"] = current_node_index

					str.write_string(result, "\n\n")
					str.write_string(result, current_indent_str);
					print_token_range(result, structure.name)
					str.write_string(result, "_init :: proc(this : ^")
					print_token_range(result, structure.name)
					if initializer.type == .FunctionDefinition {
						for nidx, i in initializer.function_def.arguments {
							str.write_string(result, ", ")
							arg := ast[nidx].var_declaration

							name_context.variables[arg.var_name.source] = nidx

							str.write_string(result, arg.var_name.source)
							str.write_string(result, " : ")
							print_type(result, ast[arg.type])
		
							if arg.initializer_expression != {} {
								str.write_string(result, " = ")
								print_node(result, ast, arg.initializer_expression, context_stack)
							}
						}
					}
					str.write_string(result, ")\n")

					str.write_string(result, current_indent_str); str.write_string(result, "{\n")
					for ci in structure.members {
						if ast[ci].type != .VariableDeclaration { continue }
						member := ast[ci].var_declaration
						if member.initializer_expression == {} { continue }

						str.write_string(result, current_member_indent_str);
						str.write_string(result, "this.")
						str.write_string(result, member.var_name.source)
						str.write_string(result, " = ")
						print_node(result, ast, member.initializer_expression, context_stack)
						str.write_byte(result, '\n')
					}
					if initializer.type == .FunctionDefinition {
						for ci in initializer.function_def.body_sequence {
							str.write_string(result, current_member_indent_str)
							print_node(result, ast, ci, context_stack, indent + 1)
							str.write_byte(result, '\n')
						}
					}
					str.write_string(result, current_indent_str); str.write_byte(result, '}')
				}

				for midx in structure.members {
					#partial switch ast[midx].type {
						case .FunctionDefinition:
							member_fn := ast[midx].function_def

							name_context := append_return_ptr(context_stack, NameContext{ })
							defer pop(context_stack)

							name_context.variables["this"] = current_node_index

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

								name_context.variables[arg.var_name.source] = nidx

								str.write_string(result, arg.var_name.source)
								str.write_string(result, " : ")
								print_type(result, ast[arg.type])
			
								if arg.initializer_expression != {} {
									str.write_string(result, " = ")
									print_node(result, ast, arg.initializer_expression, context_stack)
								}
							}
							str.write_byte(result, ')')

							if member_fn.return_type != {} && ast[member_fn.return_type].type_declaration.segments[0].source != "void" {
								str.write_string(result, " -> ")
								print_type(result, ast[member_fn.return_type])
							}

							str.write_byte(result, '\n')

							str.write_string(result, current_indent_str); str.write_string(result, "{\n")
							for ci in member_fn.body_sequence {
								str.write_string(result, current_member_indent_str)
								print_node(result, ast, ci, context_stack, indent + 1)
								str.write_byte(result, '\n')
							}
							str.write_string(result, current_indent_str); str.write_byte(result, '}')
					
						case .Struct, .Union:
							str.write_string(result, "\n\n")
							ast[midx].struct_or_union.name = slice.concatenate([][]Token{structure.name, ast[midx].struct_or_union.name})
							print_node(result, ast, midx, context_stack, indent)
					}
				}

			case .VariableDeclaration:
				vardef := current_node.var_declaration

				context_stack[len(context_stack) - 1].variables[vardef.var_name.source] = current_node_index

				str.write_string(result, vardef.var_name.source)
				str.write_string(result, " : ")
				print_type(result, ast[vardef.type])

				if vardef.initializer_expression != {} {
					str.write_string(result, " = ")
					print_node(result, ast, vardef.initializer_expression, context_stack)
				}

			case .Return:
				str.write_string(result, "return")

				if current_node.return_.expression != {} {
					str.write_byte(result, ' ')
					print_node(result, ast, current_node.return_.expression, context_stack)
				}

			case .LiteralBool, .LiteralFloat, .LiteralInteger, .LiteralString, .LiteralCharacter:
				str.write_string(result, current_node.literal.source)

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

			case .ExprBinary:
				print_node(result, ast, current_node.binary.left, context_stack)
				str.write_byte(result, ' ')
				str.write_byte(result, u8(current_node.binary.operator))
				str.write_byte(result, ' ')
				print_node(result, ast, current_node.binary.right, context_stack)

			case .Identifier:
				if len(current_node.identifier) == 1 {
					tok := current_node.identifier[0]
					_, name_context := find_declaration_for_name(ast, context_stack, tok.source)

					if name_context.is_structure {
						str.write_string(result, "this.")
						str.write_string(result, tok.source)
						return
					}
				}

				print_token_range(result, current_node.identifier)

			case:
				log.error("Unknown ast node:", current_node)
				runtime.trap();
		}
	}

	print_token_range :: proc(result : ^str.Builder, r : TokenRange, glue := "_")
	{
		for t, i in r {
			if i != 0 { str.write_string(result, glue) }
			str.write_string(result, t.source)
		}
	}

	print_type :: proc(result : ^str.Builder, r : AstNode)
	{
		type_tokens := r.type_declaration.segments[:]
		converted_type_tokens := make([dynamic]Token, 0, len(type_tokens), context.temp_allocator)
		translate_type(&converted_type_tokens, type_tokens)

		print_token_range(result, converted_type_tokens[:], "")
	}

	translate_type :: proc(output : ^[dynamic]Token, input : TokenRange)
	{
		remaining_input := input

		transform_from_short :: proc(output : ^[dynamic]Token, input : TokenRange, $prefix : string) -> (remaining_input : TokenRange)
		{
			if len(input) == 0 || input[0].type != .Identifier { // short, short*
				remaining_input = input
				append(output, Token{ type = .Identifier, source = prefix+"16" })
			}
			else if input[0].source == "int" { // short int
				remaining_input = input[1:]
				append(output, Token{ type = .Identifier, source = prefix+"16" })
			}
			else {
				panic("Failed to transform "+prefix+" short");
			}

			return
		}

		transform_from_long :: proc(output : ^[dynamic]Token, input : TokenRange, $prefix : string) -> (remaining_input : TokenRange)
		{
			if len(input) == 0 || input[0].type != .Identifier { // long, long*
				remaining_input = input
				append(output, Token{ type = .Identifier, source = prefix+"32" })
			}
			else if input[0].source == "int" { // long int 
				remaining_input = input[1:]
				append(output, Token{ type = .Identifier, source = prefix+"32" })
			}
			else if input[0].source == "long" { // long long 
				if len(input) == 1 || input[1].type != .Identifier { // long long, long long*
					remaining_input = input[2:]
					append(output, Token{ type = .Identifier, source = prefix+"64" })
				}
				else if input[1].source == "int" { // long long int
					remaining_input = input[3:]
					append(output, Token{ type = .Identifier, source = prefix+"64" })
				}
			}
			else {
				panic("Failed to transform "+prefix+" long");
			}
			return
		}

		#partial switch input[0].type {
			case .Identifier:
				switch input[0].source {
					case "const":
						remaining_input = input[1:]

					case "signed":
						switch input[1].source {
							case "char":
								remaining_input = input[2:]
								append(output, Token{ type = .Identifier, source = "i8" })

							case "int":
								remaining_input = input[2:]
								append(output, Token{ type = .Identifier, source = "i32" })

							case "short":
								remaining_input = transform_from_short(output, input[2:], "i")
							
							case "long":
								remaining_input = transform_from_long(output, input[2:], "i")
						}

					case "unsigned":
						switch input[1].source {
							case "char":
								remaining_input = input[2:]
								append(output, Token{ type = .Identifier, source = "u8" })

							case "int":
								remaining_input = input[2:]
								append(output, Token{ type = .Identifier, source = "u32" })

							case "short":
								remaining_input = transform_from_short(output, input[2:], "u")
							
							case "long":
								remaining_input = transform_from_long(output, input[2:], "u")
						}

					case "char":
						remaining_input = input[1:]
						append(output, Token{ type = .Identifier, source = "u8" }) // funny implementation defined singnedness, interpret as unsigned

					case "int":
						remaining_input = input[1:]
						append(output, Token{ type = .Identifier, source = "i32" })

					case "short":
						remaining_input = transform_from_short(output, input[1:], "i")

					case "long":
						remaining_input = transform_from_long(output, input[1:], "i")

					case "float":
						remaining_input = input[1:]
						append(output, Token{ type = .Identifier, source = "f32" })

					case "double":
						remaining_input = input[1:]
						append(output, Token{ type = .Identifier, source = "f64" })

					case:
						append(output, input[0])
						remaining_input = input[1:]
				}
			
			case .Star:
				remaining_input = input[1:]
				inject_at(output, 0, Token{ type = .Circumflex, source = "^" })

			case:
				append(output, input[0])
				remaining_input = input[1:]
		}

		if(len(remaining_input) > 0) { translate_type(output, remaining_input) }
	}
}

NameContext :: struct {
	variables : map[string]AstNodeIndex,
	is_structure : bool,
}

find_declaration_for_name :: proc(ast : []AstNode, context_stack : ^[dynamic]NameContext, name : string) -> (declaration : ^AstNode, final_context : ^NameContext)
{
	#reverse for &cc in context_stack {
		if nidx, found := cc.variables[name]; found {
			return &ast[nidx], &cc
		}
	}

	panic(fmt.tprintf("'%v' was not found in context %#v.", name, context_stack))
}

