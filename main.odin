package program

import "core:os"
import "core:fmt"
import str "core:strings"


main :: proc()
{
	input_map : map[string]Input
	tokenize_file(&input_map, "imgui.h")

	preprocessed : [dynamic]Token
	preprocess(&{ result = &preprocessed, inputs = input_map }, "imgui.h")

	ast  : [dynamic]AstNode
	ast_parse_filescope_sequence(&ast, preprocessed[:])

	result : str.Builder
	convert_and_format(&result, ast[:])

	os.write_entire_file("/out/imgui_gen.odin", result.buf[:])


	tokenize_file :: proc(map_ :  ^map[string]Input, path : string)
	{
		content, ok := os.read_entire_file(str.concatenate({ "in/", path }, context.temp_allocator))
		if !ok { panic(fmt.tprintf("Failed to read %v", path)) }

		toks : [dynamic]Token
		tokenize(&toks, cast(string) content, path)

		map_[path] = { toks[:], false }
	}
}




