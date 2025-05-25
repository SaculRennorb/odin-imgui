package program

import "core:os"
import "core:fmt"
import "core:log"
import str "core:strings"


main :: proc()
{
	context.logger = log.create_console_logger()

	input_map : map[string]Input
	tokenize_file :: proc(map_ :  ^map[string]Input, path : string)
	{
		content, ok := os.read_entire_file(str.concatenate({ "in/", path }, context.temp_allocator))
		if !ok { panic(fmt.tprintf("Failed to read %v", path)) }

		toks : [dynamic]Token
		tokenize(&toks, cast(string) content, path)

		map_[path] = { toks[:], false }
	}
	tokenize_file(&input_map, "imgui.h")
	tokenize_file(&input_map, "imgui.cpp")
	tokenize_file(&input_map, "imgui_internal.h")
	tokenize_file(&input_map, "imgui_draw.cpp")
	tokenize_file(&input_map, "imgui_tables.cpp")
	tokenize_file(&input_map, "imgui_widgets.cpp")
	tokenize_file(&input_map, "imconfig.h")

	ignored_identifiers := []string {
		"IM_MSVC_RUNTIME_CHECKS_OFF",
		"IM_MSVC_RUNTIME_CHECKS_RESTORE",
		"IM_VEC2_CLASS_EXTRA",
		"IM_VEC4_CLASS_EXTRA",
		"IMGUI_API",
		"IMGUI_CDECL",
	}

	preprocessed : [dynamic]Token
	preprocess(&{ result = &preprocessed, inputs = input_map, ignored_identifiers = ignored_identifiers }, "imgui.cpp")

	ast  : [dynamic]AstNode
	root_sequence := ast_parse_filescope_sequence(&{ ast = &ast }, preprocessed[:])

	converter_context : ConverterContext = { ast = ast[:], root_sequence = root_sequence[:] }
	replaced_names := [][2]string {
		{ "INT_MAX", "max(i32)" },
		{ "FLT_MAX", "max(f32)" },
		{ "FLT_MIN", "min(f32)" },
		{ "CP_UTF8", "win32.CP_UTF8" },
		{ "FILENAME_MAX", "win32.FILENAME_MAX" },
	}
	convert_and_format(&converter_context, replaced_names)
	os.write_entire_file("out/imgui_gen.odin", converter_context.result.buf[:])

	str.builder_reset(&converter_context.result)
	write_shim(&converter_context)
	os.write_entire_file("out/shim.odin", converter_context.result.buf[:])

	log.info("Done!")
}
