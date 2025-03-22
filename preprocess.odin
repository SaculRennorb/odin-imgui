package program

import "core:mem"
import "core:fmt"

preprocess :: proc(result : ^[dynamic]Token, inputs : map[string][]Token, entry_file : string)
{
	err := do_preprocess(result, inputs, inputs[entry_file])
	if(err != nil) { panic(fmt.tprint("Preprocess failed at", err.?)) }
	do_preprocess :: proc(result : ^[dynamic]Token, inputs : map[string][]Token, tokens : []Token) -> AstError
	{
		tokens := tokens
		reserve(result, len(tokens))

		for len(tokens) > 0 {
			current_token := tokens[0]
			tokens = tokens[1:]
			if current_token.kind != .Pound {
				append(result, current_token)
				continue
			}

			ident := eat_token_expect(&tokens, .Identifier) or_return

			args : []Token
			{
				args_start := tokens
				for {
					tokens = tokens[1:]
					if tokens[0].kind == .NewLine { break }
				}
				args = slice_from_se(raw_data(args_start), raw_data(tokens))
			}

			switch ident.source {
				case "include":
					#partial switch args[0].kind {
						case .LiteralString:
							str := args[0].source
							str = str[1:len(str) - 1] // strip of quotation marks

							included_stream, found := inputs[str]
							if !found {
								str := fmt.tprintf("Failed to find include %v in", str)
								for k, v in inputs {
									str = fmt.tprintf("%v\n%v => [%v]Token", str, k, len(v))
								}
								panic(str)
							}
							do_preprocess(result, inputs, included_stream)

						case:
							panic(fmt.tprint("Unknown include arg:", args[0]))
					}
			}
		}

		return nil
	}
}