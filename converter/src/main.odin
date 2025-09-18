package program

import "core:os"
import "core:fmt"
import "core:log"
import str "core:strings"


IMGUI_PATH :: #directory + "../../imgui/"

main :: proc()
{
	context.logger = log.create_console_logger()

	process_main_files()
	process_dx11_backend()
	process_win32_backend()

	log.info("Done!")
}

tokenize_file :: proc(map_ :  ^map[string]Input, path : string, alias : string = "")
{
	full_path := str.concatenate({ IMGUI_PATH + "in/", path }, context.temp_allocator)
	content, ok := os.read_entire_file(full_path)
	if !ok { panic(fmt.tprintf("Failed to read %v from %v", path, full_path)) }

	toks : [dynamic]Token
	tokenize(&toks, cast(string) content, path)

	map_[alias == "" ? path : alias] = { toks[:], false }
}

process_main_files :: proc()
{
	input_map : map[string]Input

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
		tokenize(&toks, `
			//
			// shim
			//
			#define int int
			#define bool bool
			//
			// win32
			//
			#include "win32_type_shim.cpp"
			//
			// imgui.cpp
			//
			#include "imgui.cpp"
			//
			// imgui_draw.cpp
			//
			#include "imgui_draw.cpp"
			//
			// imgui_widgets.cpp
			//
			#include "imgui_widgets.cpp"
			//
			// imgui_tables.cpp
			//
			#include "imgui_tables.cpp"

		`, "init_shim.cpp")
		input_map["init_shim.cpp"] = { toks[:], false}
	}
	{
		toks : [dynamic]Token
		tokenize(&toks, #load(IMGUI_PATH + "/win32_type_shim.cpp"), "win32_type_shim.cpp")
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
		{ "INT_MIN", "min(i32)" },
		{ "UINT_MAX", "max(u32)" },
		{ "UINT_MIN", "min(u32)" },
		{ "LLONG_MAX", "max(i64)" },
		{ "LLONG_MIN", "min(i64)" },
		{ "ULLONG_MAX", "max(u64)" },
		{ "FLT_MAX", "max(f32)" },
		{ "FLT_MIN", "min(f32)" },
		{ "DBL_MAX", "max(f64)" },
		{ "DBL_MIN", "min(f64)" },
		{ "CP_UTF8", "win32.CP_UTF8" },
		{ "FILENAME_MAX", "win32.FILENAME_MAX" },
		{ "CF_UNICODETEXT", "win32.CF_UNICODETEXT" },
		{ "GMEM_MOVEABLE", "win32.GMEM_MOVEABLE" },
		{ "SW_SHOWDEFAULT", "win32.SW_SHOWDEFAULT" },
		{ "CFS_FORCE_POSITION", "win32.CFS_FORCE_POSITION" },
		{ "CFS_CANDIDATEPOS", "win32.CFS_CANDIDATEPOS" },

		// { "stbrp_rect", "stbrp.rect" },
		// { "stbrp_coord", "stbrp.coord" },
		// { "stbrp_context", "stbrp.context" },

		// { "stbtt_pack_context", "stbtt.pack_context" },
		// { "stbtt_aligned_quad", "stbtt.aligned_quad" },
		// { "stbtt_fontinfo", "stbtt.fontinfo" },
		// { "stbtt_pack_range", "stbtt.pack_range" },
		// { "stbtt_packedchar", "stbtt.packedchar" },
		{ "stbtt_GetFontOffsetForIndex", "stbtt.GetFontOffsetForIndex" },

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
	os.write_entire_file(IMGUI_PATH + "out/imgui_gen.odin", converter_context.result.buf[:])

	str.builder_reset(&converter_context.result)
	write_shim(&converter_context)
	os.write_entire_file(IMGUI_PATH + "out/shim.odin", converter_context.result.buf[:])
}


process_dx11_backend :: proc()
{
	input_map : map[string]Input

	tokenize_file(&input_map, "imgui.h")
	tokenize_file(&input_map, "backends/imgui_impl_dx11.h", "imgui_impl_dx11.h")
	tokenize_file(&input_map, "backends/imgui_impl_dx11.cpp", "imgui_impl_dx11.cpp")
	
	{
		//tokenize_file(&input_map, "imconfig.h")
		input_map["imconfig.h"] = { {}, false}
	}

	{
		toks : [dynamic]Token
		tokenize(&toks, `
			//
			// shim
			//
			#define int int
			#define bool bool
			//
			// win32
			//
			#include "win32_type_shim.cpp"
			//
			// D3D11
			//
			#include "d3d11_type_shim.cpp"
			//
			// impl
			//
			#include "imgui_impl_dx11.cpp"
		`, "init_shim.cpp")
		input_map["init_shim.cpp"] = { toks[:], false }
	}
	{
		toks : [dynamic]Token
		tokenize(&toks, #load(IMGUI_PATH + "/win32_type_shim.cpp"), "win32_type_shim.cpp")
		input_map["win32_type_shim.cpp"] = { toks[:], false }
	}
	{
		toks : [dynamic]Token
		tokenize(&toks, #load(IMGUI_PATH + "/d3d11_type_shim.cpp"), "d3d11_type_shim.cpp")
		input_map["d3d11_type_shim.cpp"] = { toks[:], false }
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
		{ "INT_MIN", "min(i32)" },
		{ "UINT_MAX", "max(u32)" },
		{ "UINT_MIN", "min(u32)" },
		{ "LLONG_MAX", "max(i64)" },
		{ "LLONG_MIN", "min(i64)" },
		{ "ULLONG_MAX", "max(u64)" },
		{ "FLT_MAX", "max(f32)" },
		{ "FLT_MIN", "min(f32)" },
		{ "DBL_MAX", "max(f64)" },
		{ "DBL_MIN", "min(f64)" },
		{ "CP_UTF8", "win32.CP_UTF8" },
		{ "FILENAME_MAX", "win32.FILENAME_MAX" },
		{ "CF_UNICODETEXT", "win32.CF_UNICODETEXT" },
		{ "GMEM_MOVEABLE", "win32.GMEM_MOVEABLE" },
		{ "SW_SHOWDEFAULT", "win32.SW_SHOWDEFAULT" },
		{ "CFS_FORCE_POSITION", "win32.CFS_FORCE_POSITION" },
		{ "CFS_CANDIDATEPOS", "win32.CFS_CANDIDATEPOS" },

		// { "stbrp_rect", "stbrp.rect" },
		// { "stbrp_coord", "stbrp.coord" },
		// { "stbrp_context", "stbrp.context" },

		// { "stbtt_pack_context", "stbtt.pack_context" },
		// { "stbtt_aligned_quad", "stbtt.aligned_quad" },
		// { "stbtt_fontinfo", "stbtt.fontinfo" },
		// { "stbtt_pack_range", "stbtt.pack_range" },
		// { "stbtt_packedchar", "stbtt.packedchar" },
		{ "stbtt_GetFontOffsetForIndex", "stbtt.GetFontOffsetForIndex" },

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
	os.write_entire_file(IMGUI_PATH + "out/backends/dx11/backend.odin", converter_context.result.buf[:])
}

process_win32_backend :: proc()
{
	input_map : map[string]Input

	tokenize_file(&input_map, "imgui.h")
	tokenize_file(&input_map, "backends/imgui_impl_win32.h", "imgui_impl_win32.h")
	tokenize_file(&input_map, "backends/imgui_impl_win32.cpp", "imgui_impl_win32.cpp")
	
	{
		//tokenize_file(&input_map, "imconfig.h")
		input_map["imconfig.h"] = { {}, false}
	}

	{
		toks : [dynamic]Token
		tokenize(&toks, `
			//
			// shim
			//
			#define int int
			#define bool bool
			//
			// win32
			//
			#include "win32_type_shim.cpp"
			//
			// impl
			//
			#include "imgui_impl_win32.cpp"
		`, "init_shim.cpp")
		input_map["init_shim.cpp"] = { toks[:], false }
	}
	{
		toks : [dynamic]Token
		tokenize(&toks, #load(IMGUI_PATH + "/win32_type_shim.cpp"), "win32_type_shim.cpp")
		input_map["win32_type_shim.cpp"] = { toks[:], false }
	}

	ignored_identifiers := []string {
		"IM_MSVC_RUNTIME_CHECKS_OFF",
		"IM_MSVC_RUNTIME_CHECKS_RESTORE",
		"IMGUI_API",
		"IMGUI_CDECL",
		"WINAPI",
		"CALLBACK",
		"IMGUI_IMPL_API",
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
		{ "INT_MIN", "min(i32)" },
		{ "UINT_MAX", "max(u32)" },
		{ "UINT_MIN", "min(u32)" },
		{ "LLONG_MAX", "max(i64)" },
		{ "LLONG_MIN", "min(i64)" },
		{ "ULLONG_MAX", "max(u64)" },
		{ "FLT_MAX", "max(f32)" },
		{ "FLT_MIN", "min(f32)" },
		{ "DBL_MAX", "max(f64)" },
		{ "DBL_MIN", "min(f64)" },
		{ "CP_UTF8", "win32.CP_UTF8" },
		{ "FILENAME_MAX", "win32.FILENAME_MAX" },
		{ "CF_UNICODETEXT", "win32.CF_UNICODETEXT" },
		{ "GMEM_MOVEABLE", "win32.GMEM_MOVEABLE" },
		{ "SW_SHOWDEFAULT", "win32.SW_SHOWDEFAULT" },
		{ "CFS_FORCE_POSITION", "win32.CFS_FORCE_POSITION" },
		{ "CFS_CANDIDATEPOS", "win32.CFS_CANDIDATEPOS" },

		// { "stbrp_rect", "stbrp.rect" },
		// { "stbrp_coord", "stbrp.coord" },
		// { "stbrp_context", "stbrp.context" },

		// { "stbtt_pack_context", "stbtt.pack_context" },
		// { "stbtt_aligned_quad", "stbtt.aligned_quad" },
		// { "stbtt_fontinfo", "stbtt.fontinfo" },
		// { "stbtt_pack_range", "stbtt.pack_range" },
		// { "stbtt_packedchar", "stbtt.packedchar" },
		{ "stbtt_GetFontOffsetForIndex", "stbtt.GetFontOffsetForIndex" },

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
	os.write_entire_file(IMGUI_PATH + "out/backends/win32/backend.odin", converter_context.result.buf[:])
}