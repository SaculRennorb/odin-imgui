package program

import "core:mem"
import "core:fmt"
import "core:strings"
import "core:log"

Input :: struct {
	tokens : []Token,
	used : bool,
}

PreProcRemoveIfData :: struct {
	name : string,
	inverted : bool,
}

PreProcContext :: struct {
	result  : ^[dynamic]Token,
	inputs  : map[string]Input,
	defines : map[string]Token,
	ignored_identifiers : []string,
	removed_ifs : []PreProcRemoveIfData,  //TODO(Rennorb) @brittle: Only works for simple ifs for now.
}

preprocess :: proc(ctx : ^PreProcContext, entry_file : string)
{
	err := do_preprocess(ctx, &ctx.inputs[entry_file])
	if(err != nil) { panic(fmt.tprint("Preprocess failed at", err.?)) }
	do_preprocess :: proc(ctx : ^PreProcContext, input : ^Input) -> Maybe(AstErrorFrame)
	{
		tokens := input.tokens
		reserve(ctx.result, len(tokens))

		current_branch_depth := 0
		skip_until_branch_depth_returns_to := -1

		loop: for len(tokens) > 0 {
			current_token := tokens[0]
			tokens = tokens[1:]

			if current_token.kind != .Pound {
				if skip_until_branch_depth_returns_to != -1 { continue loop }

				if current_token.kind == .Identifier {
					for ignored in ctx.ignored_identifiers {
						if current_token.source == ignored {
							continue loop // skip appending the ignored token if it is not part of a preproc statement
						}
					}
				}

				append(ctx.result, current_token)
				continue
			}

			ident := eat_token(&tokens) // cleanup

			switch ident.source {
				case "if":
					current_branch_depth += 1

					n, ns := peek_token(&tokens, false)
					if nn, nns := peek_token(&ns, false); nn.kind == .NewLine {
						for to_remove in ctx.removed_ifs {
							if !to_remove.inverted && n.source == to_remove.name {
								tokens = nns
								skip_until_branch_depth_returns_to = current_branch_depth - 1
								continue loop
							}
						}
					}

					append(ctx.result, Token{ kind = .PreprocIf, location = ident.location })

				case "ifdef":
					current_branch_depth += 1

					n, ns := peek_token(&tokens, false)
					if nn, nns := peek_token(&ns, false); nn.kind == .NewLine {
						for to_remove in ctx.removed_ifs {
							if !to_remove.inverted && n.source == to_remove.name {
								skip_until_branch_depth_returns_to = current_branch_depth - 1
								continue loop
							}
						}
					}

					append(ctx.result, Token{ kind = .PreprocIf, location = ident.location })
					defined_identifier := eat_token_expect_direct(&tokens, .Identifier, false) or_return
					append(ctx.result, defined_identifier)
					append(ctx.result, Token{ kind = .Comment, source = "// @gen ifdef", location = ident.location })

				case "ifndef":
					current_branch_depth += 1

					n, ns := peek_token(&tokens, false)
					if nn, nns := peek_token(&ns, false); nn.kind == .NewLine {
						for to_remove in ctx.removed_ifs {
							if to_remove.inverted && n.source == to_remove.name {
								tokens = nns
								skip_until_branch_depth_returns_to = current_branch_depth - 1
								continue loop
							}
						}
					}

					append(ctx.result, Token{ kind = .PreprocIf, location = ident.location })
					append(ctx.result, Token{ kind = .Exclamationmark, source = "!", location = ident.location })
					defined_identifier := eat_token_expect_direct(&tokens, .Identifier, false) or_return
					append(ctx.result, defined_identifier)
					append(ctx.result, Token{ kind = .Comment, source = "// @gen ifndef", location = ident.location })

				case "else":
					append(ctx.result, Token{ kind = .PreprocElse, location = ident.location })

				case "elif":
					append(ctx.result, Token{ kind = .PreprocElse, location = ident.location })

				case "endif":
					current_branch_depth -= 1

					if skip_until_branch_depth_returns_to != -1 {
						if current_branch_depth > skip_until_branch_depth_returns_to { continue loop }
						skip_until_branch_depth_returns_to = -1
						continue loop // dont write the endif even if we are good now
					}

					append(ctx.result, Token{ kind = .PreprocEndif, location = ident.location })

				case:
					if skip_until_branch_depth_returns_to != -1 { continue loop }

					switch ident.source {
						case "include":
							args : []Token
							{
								args_start := tokens
								for {
									tokens = tokens[1:]
									if tokens[0].kind == .NewLine { break }
								}
								args = slice_from_se(raw_data(args_start), raw_data(tokens))
		
								tokens = tokens[1:]
								eat_token_expect(&tokens, .NewLine)
							}
		
							include_path : string
							#partial switch args[0].kind {
								case .LiteralString:
									include_path = args[0].source
									include_path = include_path[1:len(include_path) - 1] // strip of quotation marks
		
								case .BracketTriangleOpen:
									//include_path := args[1].source
									continue loop // just skip system includes
		
								case:
									panic(fmt.tprint("Unknown include arg:", args[0]))
							}
		
		
							included, found := &ctx.inputs[include_path]
							if !found {
								str := fmt.tprintf("%v\nFailed to find include %v for %v in", args, include_path, ident.location)
								for k, v in ctx.inputs {
									str = fmt.tprintf("  %v\n%v => [%v]Token", str, k, len(v.tokens))
								}
								panic(str)
							}
		
							if !included.used {
								log.info("Including token stream from", include_path, "invoked at", ident.location)
								do_preprocess(ctx, included) or_return
							}
							continue loop
		
						case "pragma":
							args : []Token
							{
								args_start := tokens
								for {
									tokens = tokens[1:]
									if tokens[0].kind == .NewLine { break }
								}
								args = slice_from_se(raw_data(args_start), raw_data(tokens))
		
								tokens = tokens[1:]
								eat_token_expect(&tokens, .NewLine) // maybe eat second newline
							}
		
							switch args[0].source {
								case "once":
									input.used = true
									continue loop
		
								case "warning", "clang", "GCC": // pragma warning push
									/* just ignore */
									continue loop
		
								case "comment":
									// #pragma comment(lib, "user32")
									// just ignore for now 
									continue loop
		
								case:
									panic(fmt.tprintf("Unknown pragma: %v at %v", args, ident.location))
							}
		
						case "define":
							append(ctx.result, Token{ kind = .PreprocDefine, location = ident.location })
		
						case "undef":
							append(ctx.result, Token{ kind = .PreprocUndefine, location = ident.location })
		
						case "error":
							args : []Token
							{
								args_start := tokens
								for {
									tokens = tokens[1:]
									if tokens[0].kind == .NewLine { break }
								}
								args = slice_from_se(raw_data(args_start), raw_data(tokens))
							}
		
							str := "// warning"
							for arg in args {
								str = strings.concatenate({ str, " ", arg.source })
							}
		
							append(ctx.result, Token{ kind = .Comment, source = str, location = args[0].location })
		
						case:
							panic(fmt.tprint("Unknown preprocessor directive:", ident))
					}
			}

			// copy over remaining line
			for len(tokens) > 0 {
				t := tokens[0]
				append(ctx.result, t)
				tokens = tokens[1:]
				if t.kind == .NewLine { break }
			}
		}

		return nil
	}
}
