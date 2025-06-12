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
	tokenize_file(&input_map, "imstb_textedit.h")
	tokenize_file(&input_map, "misc/freetype/imgui_freetype.h")
	tokenize_file(&input_map, "misc/freetype/imgui_freetype.cpp")
	
	{
		//tokenize_file(&input_map, "imconfig.h")
		input_map["imconfig.h"] = { {}, false}
	}

	{
		toks : [dynamic]Token
		tokenize(&toks, #load("init_shim.cpp"), "init_shim.cpp")
		input_map["init_shim.cpp"] = { toks[:], false}
	}
	{
		toks : [dynamic]Token
		tokenize(&toks, #load("win32_type_shim.cpp"), "win32_type_shim.cpp")
		input_map["win32_type_shim.cpp"] = { toks[:], false}
	}

	ignored_identifiers := []string {
		"IM_MSVC_RUNTIME_CHECKS_OFF",
		"IM_MSVC_RUNTIME_CHECKS_RESTORE",
		"IMGUI_API",
		"IMGUI_CDECL",
	}

	removed_ifs := []PreProcRemoveIfData {
		{ "IMGUI_DISABLE_OBSOLETE_FUNCTIONS", true },
		{ "IM_VEC2_CLASS_EXTRA", false },
		{ "IM_VEC4_CLASS_EXTRA", false },
		{ "0", false },
		{ "false", false },
		{ "true", true },
	}

	preprocessed : [dynamic]Token
	preprocess(&{ result = &preprocessed, inputs = input_map, ignored_identifiers = ignored_identifiers, removed_ifs = removed_ifs }, "init_shim.cpp")

	ast  : [dynamic]AstNode
	ast_context : AstContext = { ast = &ast }
	root_sequence := ast_parse_filescope_sequence(&ast_context, preprocessed[:])

	converter_context : ConverterContext = { ast = ast, type_heap = ast_context.type_heap, root_sequence = root_sequence[:] }
	replaced_names := [][2]string {
		{ "INT_MAX", "max(i32)" },
		{ "FLT_MAX", "max(f32)" },
		{ "FLT_MIN", "min(f32)" },
		{ "CP_UTF8", "win32.CP_UTF8" },
		{ "FILENAME_MAX", "win32.FILENAME_MAX" },
		{ "CF_UNICODETEXT", "win32.CF_UNICODETEXT" },
		{ "GMEM_MOVEABLE", "win32.GMEM_MOVEABLE" },
		{ "SW_SHOWDEFAULT", "win32.SW_SHOWDEFAULT" },
		{ "CFS_FORCE_POSITION", "win32.CFS_FORCE_POSITION" },
		{ "CFS_CANDIDATEPOS", "win32.CFS_CANDIDATEPOS" },

		{ "kPasteboardClipboard", "ios.kPasteboardClipboard" },
		{ "kCFAllocatorDefault", "ios.kCFAllocatorDefault" },
		{ "noErr", "ios.noErr" },

		{ "stdout", "stdout" }, // TODO
		{ "stdin" , "stdin"  }, // TODO
		{ "stderr", "stderr" }, // TODO
		{ "SEEK_END", "SEEK_END" }, // TODO
		{ "SEEK_SET", "SEEK_SET" }, // TODO
	}
	convert_and_format(&converter_context, replaced_names)
	os.write_entire_file("out/imgui_gen.odin", converter_context.result.buf[:])

	str.builder_reset(&converter_context.result)
	write_shim(&converter_context)
	os.write_entire_file("out/shim.odin", converter_context.result.buf[:])

	log.info("Done!")
}
