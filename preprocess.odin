package program

import "core:mem"
import "core:fmt"

Input :: struct {
	tokens : []Token,
	used : bool,
}

PreProcContext :: struct {
	result  : ^[dynamic]Token,
	inputs  : map[string]Input,
	defines : map[string]Token,
}

preprocess :: proc(ctx : ^PreProcContext, entry_file : string)
{
	err := do_preprocess(ctx, &ctx.inputs[entry_file])
	if(err != nil) { panic(fmt.tprint("Preprocess failed at", err.?)) }
	do_preprocess :: proc(ctx : ^PreProcContext, input : ^Input) -> AstError
	{
		tokens := input.tokens
		reserve(ctx.result, len(tokens))

		for len(tokens) > 0 {
			current_token := tokens[0]
			tokens = tokens[1:]
			if current_token.kind != .Pound {
				append(ctx.result, current_token)
				continue
			}

			ident := eat_token_expect(&tokens, .Identifier) or_return

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

					#partial switch args[0].kind {
						case .LiteralString:
							str := args[0].source
							str = str[1:len(str) - 1] // strip of quotation marks

							included, found := &ctx.inputs[str]
							if !found {
								str := fmt.tprintf("Failed to find include %v in", str)
								for k, v in ctx.inputs {
									str = fmt.tprintf("%v\n%v => [%v]Token", str, k, len(v.tokens))
								}
								panic(str)
							}

							if !included.used {
								do_preprocess(ctx, included)
							}

						case:
							panic(fmt.tprint("Unknown include arg:", args[0]))
					}

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
						eat_token_expect(&tokens, .NewLine)
					}

					assert_eq(len(args), 1)

					assert_eq(args[0].source, "once")
					input.used = true


				case "define":
					append(ctx.result, Token{ kind = .PreprocDefine, location = ident.location })

				case "if":
					append(ctx.result, Token{ kind = .PreprocIf, location = ident.location })

				case "ifdef":
					append(ctx.result, Token{ kind = .PreprocIf, location = ident.location })
					append(ctx.result, Token{ kind = .Identifier, source = "defined", location = ident.location })
					append(ctx.result, Token{ kind = .BracketRoundOpen, source = "(", location = ident.location })
					defined_identifier := eat_token_expect(&tokens, .Identifier, false) or_return
					append(ctx.result, defined_identifier)
					append(ctx.result, Token{ kind = .BracketRoundClose, source = ")", location = ident.location })

				case "ifndef":
					append(ctx.result, Token{ kind = .PreprocIf, location = ident.location })
					append(ctx.result, Token{ kind = .Exclamationmark, source = "!", location = ident.location })
					append(ctx.result, Token{ kind = .Identifier, source = "defined", location = ident.location })
					append(ctx.result, Token{ kind = .BracketRoundOpen, source = "(", location = ident.location })
					defined_identifier := eat_token_expect(&tokens, .Identifier, false) or_return
					append(ctx.result, defined_identifier)
					append(ctx.result, Token{ kind = .BracketRoundClose, source = ")", location = ident.location })

				case "else":
					append(ctx.result, Token{ kind = .PreprocElse })

				case "elif":
					append(ctx.result, Token{ kind = .PreprocElse })

				case "endif":
					append(ctx.result, Token{ kind = .PreprocEndif })

				case:
					panic(fmt.tprint("Unknown preprocessor directive:", ident))
			}
		}

		return nil
	}
}
