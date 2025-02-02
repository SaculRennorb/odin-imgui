package program

import      "core:os"
import      "core:fmt"
import str  "core:strings"
import      "core:strconv"
import regx "core:text/regex"
import path "core:path/filepath"
import      "base:runtime"
import      "base:builtin"
import      "core:math"


input_root : string

is_single_file := true
all_inplace_constructors : [dynamic]string
all_destructors : [dynamic]string

main :: proc()
{
	args := os.args
	if len(args) > 1 {
		
		stat, err := os.stat(args[1], context.temp_allocator)
		if err != nil {
			fmt.eprintf("Failed to stat target file/dir '%v': %v\n", args[1], err);
			os.exit(1)
		}

		if stat.is_dir {
			input_root = args[1]
			is_single_file = false
		}
		else {
			input_root = path.dir(args[1])
			preprocess_file(args[1])
			process_file(args[1])
			return;
		}
	}
	else {
		_input_root, err := path.abs("in");
		assert(err, "failed to get abs")
		input_root = _input_root
		is_single_file = false
	}

	path.walk(input_root, file_callback, cast(rawptr) preprocess_file)
	path.walk(input_root, file_callback, cast(rawptr) process_file)

	if len(all_inplace_constructors) > 0 || len(all_destructors) > 0 {
		fmt.eprintln("Generating ctors / dtors file")
		b := str.builder_make(context.temp_allocator)
		str.write_string(&b, "package imgui\n\n")
		append_ctors_dtors(&b)
		text := str.to_string(b)
		write_err := os.write_entire_file_or_err("out/ctors_dtors.odin", transmute([]u8) text)
		if write_err != nil {
			fmt.eprintf("Failed to write ctors/dtors file '%v': %v.\n", "out/ctors_dtors.odin", write_err)
			return 
		}
	}
}

file_callback :: proc(info: os.File_Info, in_err: os.Error, user_data: rawptr) -> (err: os.Error, skip_dir: bool)
{
	err = in_err;

	if info.name == "freetype"  do skip_dir = true;
	if info.is_dir  do return;

	processing_fn := cast(proc(string)) user_data

	if str.ends_with(info.fullpath, ".h") || str.ends_with(info.fullpath, ".cpp") {
		processing_fn(info.fullpath)
	}

	return
}

preprocess_file :: proc(in_path : string)
{
	fmt.eprintf("Preprocessing '%v' ...\n", in_path);

	text, read_err := os.read_entire_file_from_filename_or_err(in_path, context.temp_allocator)
	if read_err != nil {
		fmt.eprintf("Failed to read file '%v': %v.\n", in_path, read_err)
		return 
	}

	do_the_preprocessing(string(text));
}

process_file :: proc(in_path : string)
{
	rel_path, err := path.rel(input_root, in_path, context.temp_allocator);
	fmt.eprintf("Processing '%v' ...\n", in_path);
	assert(err == nil, fmt.tprintf("failed to find relative path for base '%v', path: '%v': %v", input_root, in_path, err));

	out_path, _ := path.abs(fmt.tprintf("out/%v.odin", rel_path));

	text, read_err := os.read_entire_file_from_filename_or_err(in_path, context.temp_allocator)
	if read_err != nil {
		fmt.eprintf("Failed to read file '%v': %v.\n", in_path, read_err)
		return 
	}

	processed_text := do_the_processing(string(text));
	//free_all(context.temp_allocator)

	current_dir, _ := path.abs(".");
	dir_to_make := path.dir(out_path);
	for dir_to_make != current_dir {
		os.make_directory(dir_to_make)
		dir_to_make = path.dir(dir_to_make)
	}

	if is_single_file && (len(all_inplace_constructors) > 0 || len(all_destructors) > 0) {
		fmt.eprintln("appending ctors / dtors to file... ")
		b := str.builder_make(context.temp_allocator)
		append_ctors_dtors(&b)
	}

	write_err := os.write_entire_file_or_err(out_path, transmute([]u8) processed_text)
	if write_err != nil {
		fmt.eprintf("Failed to write file '%v': %v.\n", out_path, write_err)
		return 
	}
}

append_ctors_dtors :: proc(b : ^str.Builder)
{
	if len(all_inplace_constructors) > 0 {
		str.write_string(b, `
//
// All Inplace Constructors
//

// default proc that gets called as the "empty constructor" for poly procs that cannot know if the type actually has a constructor
// zeros the memory 
__empty_ctor :: #force_inline proc(a : any) {
	info := type_info_of(a.id)
	bytes := slice.bytes_from_ptr(a.data, info.size)
	slice.fill(bytes, 0)
}

__inplace_constructors :: proc {
`)
		for ctor in all_inplace_constructors {
			fmt.sbprintf(b, "  %v,\n", ctor)
		}
		str.write_string(b, "  __empty_ctor,\n}\n")
	}
	if len(all_destructors) > 0 {
		str.write_string(b, `
//
// All Destructors
//

// default proc that gets called as the "empty destructor" for poly procs that cannot know if the type actually has a destructor
__empty_dtor :: #force_inline proc(_ : any) {  }

__destructors :: proc {
`)
		for ctor in all_destructors {
			fmt.sbprintf(b, "  %v,\n", ctor)
		}
		str.write_string(b, "  __empty_dtor,\n}\n")
	}
}

ForwardDeclaredFunction :: struct {
	namespace : string,
	fn_name : string,
	default_args : []string,
	comment : string,
}

declared_functions : map[string]ForwardDeclaredFunction
inside_namespace : string
do_the_preprocessing :: proc(file_content : string)
{
	capture := regx.preallocate_capture(context.temp_allocator)
	inner_capture = regx.preallocate_capture(context.temp_allocator)

	_remaining_line_data := file_content
	line_loop: for raw_line in str.split_lines_after_iterator(&_remaining_line_data) {
		line := raw_line

		indentation_len : int = 0
		for ; indentation_len < len(line) && line[indentation_len] == ' '; indentation_len += 1 { }
		if indentation_len > 0 {
			line = line[indentation_len:]
		}

		comment : string
		if comment_index := str.index(line, "//"); comment_index > 0 {
			for(comment_index > 1 && line[comment_index - 1] == ' ') do comment_index -= 1
			comment = line[comment_index:]
			line = line[:comment_index]
		}
		else if len(line) > 0 && line[len(line) - 1] == '\n' {
			line = line[:len(line) - 1]
		}

		if str.starts_with(line, "IMGUI_API ") {
			line = line[len("IMGUI_API "):]
		}
		if str.starts_with(line, "static ") {
			line = line[len("static "):]
		}


		if str.starts_with(line, "namespace") {
			inside_namespace = str.clone(line[len("namespace"):])
			if len(inside_namespace) > 0 && inside_namespace[0] == ' '  do inside_namespace = inside_namespace[1:]
		}
		else if indentation_len == 0 && line == "}" {
			inside_namespace = {}
		}
		else {
			if groups, ok := regx.match(rx_function_forward, line, &capture); ok && groups == 4 {
				fn_name := capture.groups[2]
				raw_args := capture.groups[3]

				raw_args, _ = str.remove_all(raw_args, "struct ", context.temp_allocator)
				raw_args, _ = str.remove_all(raw_args, "const ", context.temp_allocator)

				arg_default_values : [dynamic]string
				// might overshoot a bit:   a, b = A(2, 3)
				comma_count := str.count(raw_args, ",")
				if comma_count > 0  do comma_count += 1
				reserve(&arg_default_values, comma_count)

				reg_itterate_all(raw_args, rx_function_args_with_assign, 2, proc(c : ^regx.Capture, captures : int, arg_default_values : rawptr) {
					arg_default_values := cast(^[dynamic]string) arg_default_values

					if captures == 3 {
						append(arg_default_values, transform_default_value(c.groups[1], c.groups[3]))
					}
					else {
						append(arg_default_values, string{})
					}
				}, &inner_capture, cast(rawptr) &arg_default_values)

				stable_fn_name := str.clone(fn_name);
				declared_functions[stable_fn_name] = ForwardDeclaredFunction {
					namespace = inside_namespace,
					default_args = arg_default_values[:],
					fn_name = stable_fn_name,
					comment = str.clone(str.trim_left_space(comment))
				}
				//fmt.eprintln(inside_namespace, fn_name, arg_default_values, comment)
			}
		}
	}
}

transform_default_value :: proc(type : string, default : string) -> string
{
	switch default {
		case "NULL": return "nil"
		case "ImVec2(0, 0)": return "{}"
		case "0": if type == "int" || str.contains(type, "signed") || str.contains(type, "short") || str.contains(type, "long") {
			return default
		}
		else {
			return "{}" // flags / enums 
		}
		case "FLT_MAX": return "math.F32_MAX"
		case "FLT_MIN": return "math.F32_MIN"
		case: {
			if default[0] == '"' {
				return default
			}
			else if captures, ok := regx.match(rx_floats, default, &inner_capture); ok && captures == 2 {
				return inner_capture.groups[1]
			}
			else {
				return default
			}
		}
	}
}


PoundfIfLogic :: struct {
	condition : string,
	inverted : bool,
}

PoundfIfStackEl :: struct {
	using logic : PoundfIfLogic,
	was_else : bool
}

PoundfIfGuard :: struct {
	logic : PoundfIfLogic,
	active : bool,
}

inner_capture : regx.Capture
inner_builder : str.Builder
inside_struct := false
inside_enum : string
inside_flags_enum : bool
poundif_stack : [dynamic]PoundfIfStackEl
ignoring_poundif : PoundfIfGuard
do_the_processing :: proc(file_content : string) -> string
{
	clear(&poundif_stack)
	ignoring_poundif = {}
	inside_flags_enum = false
	inside_enum = {}
	inside_struct = false

	capture := regx.preallocate_capture(context.temp_allocator)
	inner_capture = regx.preallocate_capture(context.temp_allocator)
	_builder := str.builder_make_len_cap(0, len(file_content), context.temp_allocator)
	b := &_builder

	r_builder : str.Builder
	combined_enum_members : [dynamic]string

	str.write_string(b, "package imgui\n\n")

	// trivial per line transforms
	_remaining_line_data := file_content
	line_loop: for raw_line in str.split_lines_after_iterator(&_remaining_line_data) {
		line := raw_line

		indentation_len : int = 0
		for ; indentation_len < len(line) && line[indentation_len] == ' '; indentation_len += 1 { }
		if indentation_len > 0 {
			line = line[indentation_len:]
		}

		comment : string
		if comment_index := str.index(line, "//"); comment_index > 0 {
			for(comment_index > 1 && line[comment_index - 1] == ' ') do comment_index -= 1
			comment = line[comment_index:]
			line = line[:comment_index]
		}
		else if len(line) > 0 && line[len(line) - 1] == '\n' {
			line = line[:len(line) - 1]
		}

		line_was_modified := false

		if str.starts_with(line, "#") {
			stripped_poundifs := [?]PoundfIfLogic {
				{ condition = "IMGUI_DISABLE_OBSOLETE_FUNCTIONS", inverted = true },
				{ condition = "IMGUI_USER_CONFIG" },
				{ condition = "IMGUI_API", inverted = true },
				{ condition = "IMGUI_IMPL_API", inverted = true },
				{ condition = "IM_ASSERT", inverted = true },
				{ condition = "IMGUI_DISABLE_METRICS_WINDOW" },
				{ condition = "IMGUI_INCLUDE_IMGUI_USER_H" },
				{ condition = "defined(__clang__)" },
				{ condition = "defined(__GNUC__)" },
				{ condition = "defined(__GNUC__)" },
				{ condition = "IM_VEC2_CLASS_EXTRA" },
				{ condition = "IM_VEC4_CLASS_EXTRA" },
				{ condition = "IMGUI_DEFINE_MATH_OPERATORS" },
				{ condition = "IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT" },
				{ condition = "IMGUI_DISABLE_FORMAT_STRING_FUNCTIONS" },
				{ condition = "IMGUI_DISABLE_MATH_FUNCTIONS" },
			}

			not_poundif := false

			// #if* processing first, might exclude other stuff
			if str.starts_with(line, "#if ") {
				ifdef := PoundfIfStackEl{ condition = line[len("#if "):], inverted = false }
				append(&poundif_stack, ifdef)

				if !ignoring_poundif.active {
					for stripped in stripped_poundifs {
						if ifdef.condition == stripped.condition {
							ignoring_poundif.logic = ifdef.logic
							if ifdef.inverted == stripped.inverted {
								ignoring_poundif.active = true
							}
							continue line_loop;
						}
					}
				}

				if !ignoring_poundif.active {
					fmt.sbprintf(b, "when %v {{", ifdef.condition)
					line_was_modified = true
				}
			}
			else if str.starts_with(line, "#ifdef ") {
				ifdef := PoundfIfStackEl{ condition = line[len("#ifdef "):], inverted = false }
				append(&poundif_stack, ifdef)

				if !ignoring_poundif.active {
					for stripped in stripped_poundifs {
						if ifdef.condition == stripped.condition {
							ignoring_poundif.logic = ifdef.logic
							if ifdef.inverted == stripped.inverted {
								ignoring_poundif.active = true
							}
							continue line_loop;
						}
					}
				}

				if !ignoring_poundif.active {
					fmt.sbprintf(b, "when %v {{", ifdef.condition)
					line_was_modified = true
				}
			}
			else if str.starts_with(line, "#ifndef ") {
				ifdef := PoundfIfStackEl{ condition = line[len("#ifndef "):], inverted = true }
				append(&poundif_stack, ifdef)

				if !ignoring_poundif.active {
					for stripped in stripped_poundifs {
						if ifdef.condition == stripped.condition {
							ignoring_poundif.logic = ifdef.logic
							if ifdef.inverted == stripped.inverted {
								ignoring_poundif.active = true
							}
							continue line_loop;
						}
					}
				}
				
				if !ignoring_poundif.active {
					fmt.sbprintf(b, "when !(%v) {{", ifdef.condition)
					line_was_modified = true
				}
			}
			else if str.starts_with(line, "#else") {
				latest_poundif := &poundif_stack[len(poundif_stack) - 1]

				remove_else := false
				if latest_poundif.logic == ignoring_poundif.logic {
					// left ignore block
					remove_else = true
					ignoring_poundif.active = false
				}
				latest_poundif.inverted = !latest_poundif.inverted

				for stripped in stripped_poundifs {
					if latest_poundif.logic == stripped {
						ignoring_poundif.logic = latest_poundif.logic
						ignoring_poundif.active = true
						continue line_loop;
					}
				}

				if remove_else   do continue line_loop;

				if !ignoring_poundif.active {
					str.write_string(b, "} else {")
					line_was_modified = true
				}
			}
			else if str.starts_with(line, "#elif") {
				latest_poundif := &poundif_stack[len(poundif_stack) - 1]

				remove_else := false
				if latest_poundif.logic == ignoring_poundif.logic {
					// left ignore block
					remove_else = true
					ignoring_poundif = {}
				}
				latest_poundif.inverted = !latest_poundif.inverted

				new_ifdef := PoundfIfStackEl{ condition = line[len("#elif "):], inverted = false, was_else = true }
				append(&poundif_stack, new_ifdef)

				for stripped in stripped_poundifs {
					if new_ifdef.condition == stripped.condition {
						ignoring_poundif.logic = new_ifdef.logic
						if new_ifdef.inverted == stripped.inverted {
							ignoring_poundif.active = true
						}
						continue line_loop;
					}
				}

				if remove_else {
					if latest_poundif.was_else {
						//fmt.sbprintf(b, "#elif %v", new_ifdef.condition)
						fmt.sbprintf(b, "}} else when %v {{", new_ifdef.condition)
					}
					else {
						//fmt.sbprintf(b, "#if %v", new_ifdef.condition)
						fmt.sbprintf(b, "when %v {{", new_ifdef.condition)
					}
					line_was_modified = true
				}
				else if !ignoring_poundif.active {
					fmt.sbprintf(b, "}} else when %v {{", new_ifdef.condition)
					line_was_modified = true
				}
			}
			else if str.starts_with(line, "#endif") {
				latest_poundif := &poundif_stack[len(poundif_stack) - 1]
				pop(&poundif_stack)

				if latest_poundif.condition == ignoring_poundif.logic.condition {
					// left ignore block
					ignoring_poundif = {}
					continue line_loop;
				}

				// no need to recheck ignore block, as we would already have been ignoring the parent block as a whole if that was ignored

				if !ignoring_poundif.active {
					str.write_string(b, "}")
					line_was_modified = true
				}
			}
			else {
				if ignoring_poundif.active  do continue line_loop;

				if str.starts_with(line, "#pragma") {
					pragma := line[len("#pragma "):]
	
					if pragma == "once" do continue;
					else if str.starts_with(pragma, "warning") do continue;
					else if str.starts_with(pragma, "clang diagnostic") do continue;
					else if str.starts_with(pragma, "GCC diagnostic") do continue;
				}
				else if str.starts_with(line, "#define") {
					define := line[len("#define "):]
	
					removed_defines := [?]string {
						"IM_ASSERT", "IM_MSVC_WARNING_SUPPRESS",
						"IM_MSVC_RUNTIME_CHECKS_OFF", "IM_MSVC_RUNTIME_CHECKS_RESTORE", // TODO could maybe use those but for now they are removed
						"IM_LIKELY", "IM_UNLIKELY", // unused in the codebase, replace with intrinsics.expect if the time comes 
						"IMGUI_CDECL", "IMGUI_API", "IMGUI_IMPL_API",
						"IM_FMTARGS", "IM_FMTLIST",
						"IM_ARRAYSIZE", // replaced with len
						"IM_DEBUG_BREAK()", // replaced with runtime.debug_trap()
						"IM_ROUND", // replaced with math.round
						"IM_TRUNC", // replaced with math.trunc
						"IM_MEMALIGN", // replaced with mem.align_backward
						"IM_STATIC_ASSERT(", // inlined #assert
					}
					for removed_define in removed_defines {
						if str.starts_with(define, removed_define) do continue line_loop;
					}
	
					if groups, ok := regx.match(rx_trivial_define, line, &capture); ok && groups == 2 {
						if indentation_len > 0 do str.write_string(b, raw_line[:indentation_len])
						fmt.sbprintf(b, "%v :: true", capture.groups[1]); // default enabled defines
						line_was_modified = true;
					}
					else if groups, ok := regx.match(rx_string_define, line, &capture); ok && groups == 3 {
						if indentation_len > 0 do str.write_string(b, raw_line[:indentation_len])
						fmt.sbprintf(b, "%v :: %v", capture.groups[1], capture.groups[2]); // string defines
						line_was_modified = true;
					}
					else if groups, ok := regx.match(rx_number_define, line, &capture); ok && groups == 3 {
						if indentation_len > 0 do str.write_string(b, raw_line[:indentation_len])
						fmt.sbprintf(b, "%v :: %v", capture.groups[1], capture.groups[2]); // number defines
						line_was_modified = true;
					}
					else if groups, ok := regx.match(rx_redefine, line, &capture); ok && groups == 3 {
						if indentation_len > 0 do str.write_string(b, raw_line[:indentation_len])
						fmt.sbprintf(b, "%v :: %v", capture.groups[1], capture.groups[2]); // number defines
						line_was_modified = true;
					}
				}
				else if str.starts_with(line, "#include") {
					continue; // remove all #include s
				}

				not_poundif = true
			}

			if !not_poundif && ignoring_poundif.active  do continue line_loop;
		}
		else if(str.starts_with(line, "//")) {
			if ignoring_poundif.active  do continue line_loop;

			comment := line[len("//"):]

			if groups, ok := regx.match(rx_trivial_define, comment, &capture); ok && groups == 2 {
				if indentation_len > 0 do str.write_string(b, raw_line[:indentation_len])
				fmt.sbprintf(b, "%v :: false", capture.groups[1]); // default disabled defined
				line_was_modified = true;
			}
		}
		else {
			// "normal" line processing 
			if ignoring_poundif.active  do continue line_loop;

			if line == "};" {
				str.write_string(b, raw_line);

				for compound in combined_enum_members {
					str.write_string(b, compound); // moved compound literals
				}
				clear(&combined_enum_members)

				inside_enum = {}
				inside_struct = false
				inside_flags_enum = false

				continue line_loop
			}
			else {
				lines_to_remove := [?]string {
					"IM_MSVC_RUNTIME_CHECKS_OFF",
					"IM_MSVC_RUNTIME_CHECKS_RESTORE",
				}

				for to_remove in lines_to_remove {
					if line == to_remove   do continue line_loop;
				}
				
				simple_replaces := [?]string {
					// from            // to
					"IM_STATIC_ASSERT", "#assert",
					"IM_ARRAYSIZE", "len",
					"void*", "rawptr",
					"IM_ASSERT(0);", "assert(false)",
					"unsigned char", "u8",
					"signed char", "i8",
					"unsigned short", "u16",
					"signed short", "i16",
					"unsigned int", "u32",
					"signed int", "i32",
					"unsigned long long", "u64",
					"signed long long", "i64",
					"IM_DEBUG_BREAK()", "runtime.debug_trap()",
					"ImIsPowerOfTwo", "math.is_power_of_two",
					"__APPLE__", "ODIN_OS == .Darwin",
					"memset(this, 0, size_of(*this))", "this^ = {}",
					"'\\0'", "nil",
					"\\0", "0x00",
					`" IM_PRId64 "`, "v",
					`" IM_PRIu64 "`, "v",
					`" IM_PRIX64 "`, "x",
					"++;", " += 1;",
					"--;", " -= 1;",
					"default:", "case:",
				}
				
				last_change_applied : bool
				#no_bounds_check for i :=  0; i < len(simple_replaces); i += 2 {
					line, last_change_applied = str.replace_all(line, simple_replaces[i], simple_replaces[i + 1], context.temp_allocator)
					line_was_modified |= last_change_applied
				}

				// this is expensive, but i didnt want to do proper tokenization
				line, last_change_applied = reg_replace_all(line, rx_words, 1, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, _ : rawptr) -> RegxMatchSkipBehaviour {
					replace_words := [?]string {
						/// these are all after the general replace for "unsigned short" etc so they dont get mixed
						"NULL"    , "nil",
						"sizeof"  , "size_of",
						
						"ImU8"    , "u8",
						"uint8_t" , "u8",
						"ImS8"    , "i8",
						"int8_t"  , "i8",
						"char"    , "u8",
						
						"ImU16"   , "u16",
						"uint16_t", "u16",

						"ImS16"   , "u16",
						"int16_t" , "i16",
						"short"   , "i16",
						
						"ImU32"   , "u32",
						"uint32_t", "u32",
						"ImS32"   , "i32",
						"int32_t" , "i32",
						"int"     , "i32", // order is important. int -> i32 before size_t -> int
						
						"ImU64"   , "u64",
						"uint64_t", "u64",
						"ImS64"   , "i64",
						"int64_t" , "i64",

						"float"   , "f32",
						"double"  , "f64",

						"size_t"  , "int",
						"while"   , "for",
						"ImRsqrt" , "linalg.inverse_sqrt",

						"IM_ROUND", "math.round",
						"IM_TRUNC", "math.trunc",
						"IM_MEMALIGN", "mem.align_backward",
						"FLT_MAX", "math.F32_MAX",
						"FLT_MIN", "math.F32_MIN",
						"DBL_MAX", "math.F64_MAX",
						"DBL_MIN", "math.F64_MIN",
					}
					#no_bounds_check for i :=  0; i < len(replace_words); i += 2 {
						if replace_words[i] == c.groups[1] {
							str.write_string(b, replace_words[i + 1])
							return .Match
						}
					}
					return .SkipMatch
				}, &capture, &r_builder)
				line_was_modified |= last_change_applied



				simple_removes := [?]string {
					"ImGui::",
					"IMGUI_API ",
				}
				
				for remove in simple_removes {
					line, last_change_applied = str.remove_all(line, remove, context.temp_allocator)
					line_was_modified |= last_change_applied
				}

				line, last_change_applied = reg_replace_all(line, rx_floats, 1, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, _ : rawptr) -> RegxMatchSkipBehaviour { str.write_string(b, c.groups[1]); return .Match }, &capture, &r_builder)
				line_was_modified |= last_change_applied

				line, last_change_applied = reg_replace_all(line, rx_IM_FMTARGS, 0, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, _ : rawptr) -> RegxMatchSkipBehaviour { return .Match }, &capture, &r_builder)
				line_was_modified |= last_change_applied

				if !line_was_modified && inside_enum != {} && str.starts_with(line, inside_enum) {
					inside_enum := inside_enum
					line = line[len(inside_enum):]
					if line[0] == '_' {
						line = line[1:]
						inside_enum = str.concatenate([]string{ inside_enum, "_" }, context.temp_allocator)
					}

					if str.contains(line, inside_enum) {
						line, _ = str.remove_all(line, inside_enum, context.temp_allocator)
					}

					if '0' <= line[0] && line[0] <= '9' {
						line, _ = reg_replace_all(line, rx_numbers, 1, proc(b : ^str.Builder, c : ^regx.Capture, captures : int, data : rawptr) -> RegxMatchSkipBehaviour {
							fmt.sbprintf(b, "_%v", c.groups[1]);
							for i := captures; i > 1; i -= 1 {
								fmt.sbprintf(b, ", _%v", c.groups[i]);
							}
							return .Match;
						}, &capture, &r_builder)
					}

					if len(line) >= len("None") && line[:len("None")] == "None" && (line[len("None")] == ' ' || line[len("None")] == '=') {
						comment = fmt.tprintf("// [removed] -> nil: %v%v\n", line, str.trim_right(comment, "\n"))
						line = ""
					}
					else if line == "COUNT" || line == "COUNT," {
						line = "_COUNT,"
					}
					else if inside_flags_enum {
						match : bool
						line, match = reg_replace(line, rx_const_bitshift, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour {
							// enums for bitsets have their values be the bit indices 
							fmt.sbprintf(b, "%v", c.groups[2]);
							return .Match
						}, &capture, &r_builder)

						if !match {
							// not immediate bitshift. store for later to create constant outside enum

							comment = fmt.tprintf("// [moved] %v%v\n", line, str.trim_right(comment, "\n"))

							if line[len(line) - 1] == ','  do  line =  line[:len(line) - 1]

							replaced, _ := reg_replace(line, rx_generic_assign, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour {
								args, _ := reg_replace(c.groups[2], rx_generic_assign, 1, proc(b : ^str.Builder, c : ^regx.Capture, captures : int, data : rawptr) -> RegxMatchSkipBehaviour {
									fmt.sbprintf(b, ".%v", c.groups[1]);
									for i := captures; i > 1; i -= 1 {
										fmt.sbprintf(b, ", _%v", c.groups[i]);
									}
									return .Match
								}, &inner_capture, &inner_builder);
								
								fmt.sbprintf(b, "%v%v :: {{ %v }}\n", inside_enum, c.groups[1], args);
								return .Match
							}, &capture, &r_builder)

							replaced, _ = str.replace_all(replaced, "|", ",", context.temp_allocator)

							replaced, _ = reg_replace(replaced, rx_generic_assign, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour {
								fmt.sbprintf(b, "%v%v :: {{ %v }}\n", inside_enum, c.groups[1], c.groups[2]);
								return .Match
							}, &capture, &r_builder)
							append(&combined_enum_members, str.clone(replaced, context.temp_allocator))

							line = ""
						}
					}
					
					line_was_modified = true
					last_change_applied = true
				}

				// strip of static, but only for globals and functions, not for variables inside functions -> indentation check
				if indentation_len == 0 && str.starts_with(line, "static ") {
					line = line[len("static "):]
					line_was_modified = true
				}

				line, last_change_applied = reg_replace_all(line, rx_assert_with_text, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "assert(%v, %v);", c.groups[1], c.groups[2]); return .Match }, &capture, &r_builder)
				line_was_modified |= last_change_applied

				line, last_change_applied = reg_replace_all(line, rx_assert, 1, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "assert(%v);", c.groups[1]); return .Match }, &capture, &r_builder)
				line_was_modified |= last_change_applied

				if !last_change_applied {
					// typedef int ImGuiDataAuthority; -> ImGuiDataAuthority :: int
					if groups, ok := regx.match(rx_typedef, line, &capture); ok && groups == 3 {
						source := capture.groups[1]
						dest := capture.groups[2]

						if dest == "i8" || dest == "u8" ||
							dest == "i16" || dest == "u16" ||
							dest == "i32" || dest == "u32" ||
							dest == "u32" || dest == "u64" ||
							str.contains(comment, fmt.tprintf(" -> enum %v_", dest)) {
							// TODO preserve type for underlying enum ?
							continue line_loop; // strip flag type declarations since we just use proper enums 
						}

						if is_ptr_type(source)  do line = fmt.tprintf("%v :: ^%v", dest, source[:len(source) - 1]);
						else                    do line = fmt.tprintf("%v :: %v", dest, source);

						line_was_modified = true;
						last_change_applied = true;
					}
				}

				if !last_change_applied {
					// typedef int ImGuiDataAuthority; -> ImGuiDataAuthority :: int
					if groups, ok := regx.match(rx_typedef_functionptr, line, &capture); ok && groups == 4 {
						return_type := capture.groups[1]
						name := capture.groups[2]
						raw_args := capture.groups[3]

						raw_args, _ = str.remove_all(raw_args, "const ") // dont care about const qualifiers for function args
						args, _ := reg_replace_all(raw_args, rx_function_args, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour {
							fmt.sbprintf(b, "%v : ", c.groups[2])
							transform_type(b, c.groups[1])
							return .Match
						}, &inner_capture, &inner_builder)

						if is_ptr_type(return_type) {
							line = fmt.tprintf("%v :: #type proc(%v) -> ^%v", name, args, return_type[:len(return_type) - 1])
						}
						else if return_type == "void" {
							line = fmt.tprintf("%v :: #type proc(%v)", name, args)
						}
						else {
							line = fmt.tprintf("%v :: #type proc(%v) -> %v", name, args, return_type)
						}


						line_was_modified = true;
						last_change_applied = true;
					}
				}

				if !last_change_applied {
					line, last_change_applied = reg_replace_all(line, rx_struct, 1, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "%v :: struct", c.groups[1]); return .Match }, &capture, &r_builder)
					line_was_modified |= last_change_applied
					if last_change_applied  do inside_struct = true;
				}

				if !last_change_applied {
					if captures, ok := regx.match(rx_enum, line, &capture); ok && captures >= 2 {
						inside_enum = capture.groups[1]
						name := capture.groups[1]
						type := captures == 3 ? capture.groups[2] : "u32" // c default is int -> 32bits

						if str.ends_with(name, "Flags_") {
							line = fmt.tprintf("%v :: bit_set[%v; %v]\n%v :: enum", name[:len(name) - 1], name[:len(name) - 2], type, name[:len(name) - 2]);
							inside_flags_enum = true
						}
						else {
							line = fmt.tprintf("%v :: enum %v", name, type);
						}

						last_change_applied = true
						line_was_modified = true
					}
				}

				if !last_change_applied {
					if captures, ok := regx.match(rx_enum_forward, line, &capture); ok && captures == 3 {
						// remove forward declarations of enums
						continue line_loop;
					}
				}

				if !last_change_applied {
					// ImGuiContext& g = *ctx; -> g := ctx
					line, last_change_applied = reg_replace_all(line, rx_ptr_deref_into_ref, 1, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "%v := ", c.groups[1]); return .Match }, &capture, &r_builder)
					line_was_modified |= last_change_applied
				}

				if !last_change_applied {
					// ImGuiDockContext* dc = &ctx->DockContext; -> dc := &ctx->DockContext
					// ImGuiDockContext dc = ctx->DockContext; -> dc := ctx->DockContext
					line, last_change_applied = reg_replace_all(line, rx_assign, 1, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "%v :=", c.groups[1]); return .Match }, &capture, &r_builder)
					line_was_modified |= last_change_applied
				}

				if !last_change_applied && !inside_struct {
					// ImVec2 color_button_sz(GetFontSize(), GetFontSize()); -> color_button_sz := ImVec2(GetFontSize(), GetFontSize())
					line, last_change_applied = reg_replace_all(line, rx_assign_im_struct, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "%v := %v(", c.groups[2], c.groups[1]); return .Match }, &capture, &r_builder)
					line_was_modified |= last_change_applied
				}

				declaration: if groups, ok := regx.match(rx_declare, line, &capture); ok && groups == 3 {
					// ImGuiDockContext dc; -> dc : ImGuiDockContext
					// ImGuiDockContext* dc; -> dc : ^ImGuiDockContext
					// struct a; -> remove forward declaration of structs
					type := capture.groups[1]
					name := capture.groups[2]

					if type == "struct"  do continue line_loop;
					if type == "return"  do break declaration;

					str.builder_reset(&inner_builder)
					transform_type(&inner_builder, type)
					type = str.to_string(inner_builder)

					if inside_struct do line = fmt.tprintf("%v : %v,", name, type);
					else             do line = fmt.tprintf("%v : %v", name, type);

					line_was_modified = true;
					last_change_applied = true;
				}

				if !last_change_applied {
					// ImGuiDockContext dc; -> dc : ImGuiDockContext
					// ImGuiDockContext* dc; -> dc : ^ImGuiDockContext
					line, last_change_applied = reg_replace_all(line, rx_declare, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour {
						if c.groups[1] == "return" {
							return .SkipMatch
						}

						type := str.clone(c.groups[1], context.temp_allocator)

						fmt.sbprintf(b, "%v : ", c.groups[2]);
						transform_type(b, type)

						if inside_struct  do str.write_byte(b, ',')

						return .Match
					}, &capture, &r_builder)
					line_was_modified |= last_change_applied
				}

				if !last_change_applied {
					// ImGuiDockContext dc; -> dc : ImGuiDockContext
					// ImGuiDockContext* dc; -> dc : ^ImGuiDockContext
					line, last_change_applied = reg_replace_all(line, rx_declare_array, 3, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour {
						if c.groups[1] == "return" {
							return .SkipMatch
						}

						type := str.clone(c.groups[1], context.temp_allocator)
						index := str.clone(c.groups[3], context.temp_allocator)

						fmt.sbprintf(b, "%v : [%v]", c.groups[2], index);
						transform_type(b, type)

						if inside_struct  do str.write_byte(b, ',')

						return .Match
					}, &capture, &r_builder)
					line_was_modified |= last_change_applied
				}

				if !last_change_applied {
					// int* A(int b, int c) -> A :: proc(b : int, c : int)
					// int* C::A(int b, int c) -> A :: proc(this : ^C, b : int, c : int)
					// A::A(int b, int c) -> init_A :: proc(this : ^A, b : int, c : int)
					// A::~A() -> deinit_A :: proc(this : ^A)
					line, last_change_applied = reg_replace(line, rx_function, 3, proc(b : ^str.Builder, c : ^regx.Capture, captures : int, data : rawptr) -> RegxMatchSkipBehaviour {
						raw_args, parent_type, function_name, return_type : string
						is_init, is_deinit : bool
						if captures == 4 {
							return_type   = c.groups[1]
							parent_type   = c.groups[2]
							parent_type = parent_type[:len(parent_type) - 2] // strip :: at the end
							parent_type, _ = str.replace_all(parent_type, "::", "_", context.temp_allocator)
							function_name = c.groups[3]
							raw_args      = c.groups[4]
						}
						else {
							if str.ends_with(c.groups[1], "::") {
								return_type   = "void"
								parent_type   = c.groups[1][:len(c.groups[1]) - 2]
								function_name = c.groups[2]
								raw_args      = c.groups[3]
								
								if function_name[0] == '~' {
									is_deinit = true
									function_name = function_name[1:]
									assert(parent_type == function_name);

									function_name = fmt.tprintf("deinit_%v", function_name)
									append(&all_inplace_constructors, function_name)
								}
								else {
									is_init = true
									assert(parent_type == function_name);

									function_name = fmt.tprintf("init_%v", function_name)
									append(&all_destructors, function_name)
								}
							}
							else {
								return_type   = c.groups[1]
								function_name = c.groups[2]
								raw_args      = c.groups[3]
							}
						}
						
						if return_type == "else"  do return .SkipMatch;

						return_type = str.clone(return_type, context.temp_allocator)
						function_name = str.clone(function_name, context.temp_allocator)

						did_copy_args : bool
						raw_args, did_copy_args = str.remove_all(raw_args, "const " , context.temp_allocator) // dont care about const qualifiers for function args
						raw_args, did_copy_args = str.remove_all(raw_args, "struct ", context.temp_allocator)

						forward_declared_data := declared_functions[function_name]
						if forward_declared_data.comment != {} {
							if !did_copy_args  do raw_args = str.clone(raw_args, context.temp_allocator)
							parent_type = str.clone(parent_type, context.temp_allocator)
							
							str.write_string(b, "// [forward declared comment]:\n")
							str.write_string(b, forward_declared_data.comment)
						}

						arg_defaults := forward_declared_data.default_args[:]

						args, _ := reg_replace_all(raw_args, rx_function_args, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, defaults : rawptr) -> RegxMatchSkipBehaviour {
							defaults := cast(^[]string) defaults;
							
							fmt.sbprintf(b, "%v : ", c.groups[2])
							transform_type(b, c.groups[1])
							if len(defaults) > 0 {
								if defaults[0] != {}  do fmt.sbprintf(b, " = %v", defaults[0])
								defaults^ = defaults[1:]
							}
							
							return .Match
						}, &inner_capture, &inner_builder, cast(rawptr) &arg_defaults)

						if captures == 4 || is_init || is_deinit {
							if len(args) > 0  do args = fmt.tprintf("this : ^%v, %v", parent_type, args)
							else              do args = fmt.tprintf("this : ^%v", parent_type)
						}

						fmt.sbprintf(b, "%v :: proc(%v)", function_name, args)
						if return_type != "void" {
							str.write_string(b, " -> ")
							transform_type(b, return_type)
						}
						
						return .Match
					}, &capture, &r_builder)
					line_was_modified |= last_change_applied
				}

				if !last_change_applied {
					// *dc = ...; -> dc^ = ...
					line, last_change_applied = reg_replace_all(line, rx_ptr_write, 1, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "%v^ =", c.groups[1]); return .Match }, &capture, &r_builder)
					line_was_modified |= last_change_applied
				}

				//strip brackets around for loop
				if captures, ok := regx.match(rx_for_loop, line, &capture); ok && captures == 2 {
					line = fmt.tprintf("for %v", capture.groups[1])
					last_change_applied = true;
					line_was_modified = true;
				}

				// dc->a -> dc.a
				line, last_change_applied = reg_replace_all(line, rx_arrow_deref, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "%v.%v", c.groups[1], c.groups[2]); return .Match }, &capture, &r_builder)
				line_was_modified |= last_change_applied



				// ImVec2(0, 1) ->ImVec2{0, 1}
				line, last_change_applied = reg_replace_all(line, rx_im_vec_init, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "ImVec%v{{%v}}", c.groups[1], c.groups[2]); return .Match }, &capture, &r_builder)
				line_was_modified |= last_change_applied

				// (int)a -> cast(int) a
				line, last_change_applied = reg_replace_all(line, rx_primitive_cast, 2, proc(b : ^str.Builder, c : ^regx.Capture, _ : int, data : rawptr) -> RegxMatchSkipBehaviour { fmt.sbprintf(b, "cast(%v) %v", c.groups[1], c.groups[2]); return .Match }, &capture, &r_builder)
				line_was_modified |= last_change_applied

				if line_was_modified {
					if indentation_len > 0 do str.write_string(b, raw_line[:indentation_len])
					str.write_string(b, line)
				}
			}
		}

		if line_was_modified {
			if comment != {} {
				str.write_string(b, comment)
			}
			else {
				str.write_byte(b, '\n')
			}
		}
		else {
			str.write_string(b, raw_line)
		}
	}
	

	return str.to_string(_builder)
}


transform_type :: proc(b : ^str.Builder, type : string) {
	if is_ptr_type(type) {
		str.write_byte(b, '^')
		transform_type(b, type[:len(type)-1])
	}
	else if is_ref_type(type) {
		if str.starts_with(type, "ImVec") {
			// demote imvec refrences to by value calls
			str.write_string(b, type[:len(type)-1])
		}
		else {
			str.write_byte(b, '^')
			transform_type(b, type[:len(type)-1])
		}
	}
	else {
		transform_value_type(b, type)
	}
}

transform_value_type :: proc(b : ^str.Builder, type : string) {
	if str.starts_with(type, "ImVector<") && str.ends_with(type, ">") {
		str.write_string(b, "[dynamic]")
		transform_type(b, type[len("ImVector<"):len(type) - 1])
	}
	else {
		str.write_string(b, type)
	}
}



trim_space_right :: proc(b : ^str.Builder)
{
	raw := transmute(runtime.Raw_Dynamic_Array) b.buf
	for(b.buf[raw.len - 1] == ' ') do raw.len -= 1
}

is_ptr_type :: proc(type : string) -> bool {
	return len(type) > 1 && type[len(type) - 1] == '*'
}
is_ref_type :: proc(type : string) -> bool {
	return len(type) > 1 && type[len(type) - 1] == '&'
}

RegxMatchSkipBehaviour :: enum {
	SkipByte,
	SkipMatch,
	Match,
}

ReplaceProc :: proc(result_builder : ^str.Builder, capture : ^regx.Capture, captures : int, data : rawptr) -> RegxMatchSkipBehaviour
reg_replace_all :: proc(line : string, regex : regx.Regular_Expression, group_count : int, replace_proc : ReplaceProc, c : ^regx.Capture, b : ^str.Builder, data : rawptr = nil) -> (line_out : string, processed : bool)
{
	str.builder_reset(b)

	next_start := 0
	remaining_search := line
	line_was_modified := false
	for true {
		groups, ok := regx.match(regex, remaining_search, c)
		if !ok || groups < 1 + group_count  do break;

		if len(b.buf) == 0 {
			if cap(b.buf) < len(line) {
				if cap(b.buf) == 0  do str.builder_init_len_cap(b, 0, len(line))
				else                do str.builder_grow(b, len(line))
			}			
		}

		if c.pos[0][0] > 0 {
			str.write_string(b, remaining_search[:c.pos[0][0]])
		}
		did_replace := replace_proc(b, c, groups - 1, data)
		next_start = c.pos[0][1]
		switch did_replace {
			case .SkipByte:
				str.write_byte(b, c.groups[0][0])
				next_start = c.pos[0][0] + 1

			case .SkipMatch:
				str.write_string(b, c.groups[0])
				next_start = c.pos[0][1]
			
			case .Match:
				next_start = c.pos[0][1]
				line_was_modified = true
		}


		remaining_search = remaining_search[next_start:]
		if len(remaining_search) == 0  do break;
	}

	if line_was_modified {
		if len(remaining_search) > 0 do  str.write_string(b, remaining_search)
		line_out = str.to_string(b^)
		processed = true;
	}
	else {
		line_out = line
	}

	return
}


ItterateProc :: proc(capture : ^regx.Capture, captures : int, data : rawptr)
reg_itterate_all :: proc(line : string, regex : regx.Regular_Expression, group_count : int, match_proc : ItterateProc, c : ^regx.Capture, data : rawptr)
{
	next_start := 0
	remaining_search := line
	for true {
		groups, ok := regx.match(regex, remaining_search, c)
		if !ok || groups < 1 + group_count  do break;

		match_proc(c, groups - 1, data)
		next_start = c.pos[0][1]

		remaining_search = remaining_search[next_start:]
		if len(remaining_search) == 0  do break;
	}
}

reg_replace :: proc(line : string, regex : regx.Regular_Expression, group_count : int, replace_proc : ReplaceProc, c : ^regx.Capture, b : ^str.Builder, data : rawptr = nil) -> (line_out : string, processed : bool)
{
	str.builder_reset(b)

	remaining_search := line
	line_was_modified := false
	for true {
		groups, ok := regx.match(regex, remaining_search, c)
		if !ok || groups < 1 + group_count  do break;

		if len(b.buf) == 0 {
			if cap(b.buf) < len(line) {
				if cap(b.buf) == 0  do str.builder_init_len_cap(b, 0, len(line))
				else                do str.builder_grow(b, len(line))
			}			
		}

		if c.pos[0][0] > 0 {
			str.write_string(b, remaining_search[:c.pos[0][0]])
		}
		did_replace := replace_proc(b, c, groups - 1, data)
		if did_replace == .Match {
			remaining_search = remaining_search[c.pos[0][1]:]
			line_was_modified = true
			break;
		}
		if (regex.flags & {.Global} == nil)    do break

		if did_replace == .SkipByte {
			str.write_byte(b, c.groups[0][0])
			remaining_search = remaining_search[c.pos[0][0] + 1:]
		}
		else if did_replace == .SkipMatch {
			str.write_string(b, c.groups[0])
			remaining_search = remaining_search[c.pos[0][1]:]
		}

		if len(remaining_search) == 0  do break;
	}

	if line_was_modified {
		if len(remaining_search) > 0 do  str.write_string(b, remaining_search)
		line_out = str.to_string(b^)
		processed = true;
	}
	else {
		line_out = line
	}

	return
}


RX_ANY_NUMBER :: `[\-.0-9]+f?`
RX_TYPE :: `[\w*&<>]+`

rx_trivial_define := regex(`^\#define\s+(\w+)$`)
rx_string_define := regex(`^\#define\s+(\w+)\s+("[^"]*")$`)
rx_number_define := regex(`^\#define\s+(\w+)\s+([\d.]+f?)$`)
rx_redefine := regex(`^\#define\s+(\w+)\s+(\w+)$`)
rx_typedef := regex(`^typedef\s+(.+?)\s+(\w+);$`)
rx_typedef_functionptr := regex(`^typedef\s+([\w*]+?)\s+\(\*(\w+)\)\s*\((.+)\);$`)
rx_assert_with_text := regex(`IM_ASSERT\((.+?)\s*&&\s*(".*")\);`, { .Global })
rx_assert := regex(`IM_ASSERT\((.+?)\);`, { .Global })
RX_FUNCTION_MODIFIERS :: `(?:\s*(?:`+RX_IM_FMTARGS+`|const))*`
rx_function := regex(`^(?:(?:const\s+)?([\w*]+)\s+)?((?:\w+::)+)?(~?\w+)\s*\((.*)\)`+RX_FUNCTION_MODIFIERS+`$`)
rx_function_forward := regex(`^(?:const\s+)?([\w*]+)\s+(\w+)\s*\((.*?)\)`+RX_FUNCTION_MODIFIERS+`;$`)
RX_FUNCTION_ARGS :: `(`+RX_TYPE+`)\s+(\w+)`
rx_function_args := regex(RX_FUNCTION_ARGS, { .Global })
rx_function_args_with_assign := regex(RX_FUNCTION_ARGS+`(?:\s+=\s+(-?[\w.]+(?:\(.*?\))?|".*?"))?`, { .Global })
rx_struct := regex(`^struct (\w+)$`)
rx_enum := regex(`^enum (\w+)\s*(?::\s*(\w+))?$`)
rx_enum_forward := regex(`^enum\s+(\w+)\s*:\s*(\w+);$`)
rx_ptr_deref_into_ref := regex(`^\w+&\s+(\w+)\s*=\s*\*`)
rx_assign := regex(`^(?:const\s+)?\w+\*?\s+(\w+)\s*=`)
rx_assign_im_struct := regex(`^(?:const\s+)?(Im\w+)\s+(\w+)\(`)
rx_declare := regex(`^(?:const\s+)?(`+RX_TYPE+`)\s+(\w+(\s*,\s*\w+)*);`)
rx_declare_array := regex(`^(?:const\s+)?(`+RX_TYPE+`)\s+(\w+)\s*\[(.+)\]\s*;`)
rx_ptr_write := regex(`^\*(\w+)\s*=`)
rx_arrow_deref := regex(`(\w+)->(\w+)`, { .Global })
rx_im_vec_init := regex(`ImVec(\d)\((.+?)\)`, { .Global })
rx_const_bitshift := regex(`(\d+)\s*<<\s*(\d+)`, { .Global })
rx_generic_assign := regex(`^\s*(.*?)\s*=\s*(.*?)\s*$`)
rx_numbers := regex(`(\d+)`, { .Global })
rx_floats := regex(`(\d*\.\d+)f`, { .Global })
rx_words := regex(`(\w+)`, { .Global })
RX_IM_FMTARGS :: `IM_FMT(?:ARGS|LIST)\(\d+\)`
rx_IM_FMTARGS := regex(RX_IM_FMTARGS, { .Global })
rx_for_loop := regex(`^for\s*\((.*)\)$`)
rx_primitive_cast := regex(`\((int|[iuf](?:8|16|32|64))\)\s*(\w+)`, { .Global })

regex :: proc(pattern : string, flags : regx.Flags = {}) -> regx.Regular_Expression
{
	fmt.eprintf("Compiling regex '%v' ...\n", pattern)
	expr, err := regx.create(pattern, flags)
	assert(err == nil, fmt.tprintf("failed to compile regex '%v': %v", pattern, err))
	return expr
}



/*

replace short ifs with if do
(if\s*\(.*\))$\n\s+(.{1,25});$
$1   do $2


for i32 (\w+) = 


const u8\* (\w+)\s=


static (\w+) (\w+) =
@(static) $2 : $1 =


^(?<w> *)((?:else\s+)?if[^\/\n]+\))\s*(\/\/.*)?$\n(\k<w>    [^i {][^f].*)\s*$
$1$2 {\n$3\n$1}\n

\(([\w\.]+[fF]lags) & \w+_(\w+[^_)])\) == 0
(.$2 not_in $1)


\(([\w\.]+[fF]lags) & \w+_(\w+[^_)])\)
(.$2 in $1)

([\w.]+)\.Size 
len($1) 

([\w.]+)\.Size;
len($1);

when 0 -> when false
when 1 -> when true

*/

