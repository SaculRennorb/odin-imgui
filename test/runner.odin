package test_program

import "core:fmt"
import path "core:path/filepath"
import "core:os"
import str "core:strings"
import converter "../"
import "core:testing"
import "core:thread"
import "base:runtime"
import "core:log"
import "core:time"

SEQUENTIAL :: #config(sequential, false)

BASEDIR :: "test"

@(test)
test :: proc(t : ^testing.T)
{
	dir_in, derr1 := os.open(BASEDIR+"/in")
	assert(derr1 == nil)
	files_in, ferr1 := os.read_dir(dir_in, 0)
	assert(ferr1 == nil)

	//testing.set_fail_timeout(t, 5 * time.Second)

	test_ctx := context

	test_ctx.assertion_failure_proc = proc(prefix, message : string, loc := #caller_location) -> ! {
		current_thread := transmute(^thread.Thread) context.user_ptr
		t  := transmute(^testing.T) current_thread.user_args[0]
		fi := transmute(^os.File_Info) current_thread.user_args[1]
		log.errorf("[%v]: Failed [%v]: %v", fi.name, prefix, message, location = loc)
		thread.terminate(current_thread, 1)
		unreachable()
	}

	a := os.args
	if len(os.args) > 1 {
		for &file in files_in {
			if str.starts_with(file.name, os.args[1]) {
				tr := thread.create(thread_proc)
				test_ctx.user_ptr = tr
				tr.init_context = test_ctx
				tr.user_args[0] = t
				tr.user_args[1] = &file
				thread.start(tr)

				thread.join_multiple(tr)
				return
			}
		}
		panic(fmt.tprintf("Failed to match '%v' to any test file in '%v'.", os.args[1], BASEDIR))
	}

	threads : [dynamic]^thread.Thread

	for &file in files_in {
		if str.contains(file.name, ".disabled") {
			log.warn("Disabled", location = { file_path = file.name })
			continue
		}

		tr := thread.create(thread_proc)
		test_ctx.user_ptr = tr
		tr.init_context = test_ctx
		tr.user_args[0] = t
		tr.user_args[1] = &file
		thread.start(tr)

		when !SEQUENTIAL {
			append(&threads, tr)
		}
		else {
			thread.join_multiple(tr)
		}
	}

	when !SEQUENTIAL {
		thread.join_multiple(..threads[:])
	}
}

thread_proc :: proc(current_thread : ^thread.Thread)
{
	t    := transmute(^testing.T) current_thread.user_args[0]
	file := transmute(^os.File_Info) current_thread.user_args[1]

	test_proc(t, file)
}

test_proc :: proc(t : ^testing.T, file : ^os.File_Info) {
	defer runtime.default_temp_allocator_destroy(transmute(^runtime.Default_Temp_Allocator) context.temp_allocator.data)

	loc := runtime.Source_Code_Location {
		file_path = file.name,
		column = 0,
		line = 0,
	}

	inputs : []os.File_Info

	if !file.is_dir {
		inputs = { file^ }
	}
	else {
		// use whole directory of files as test input
		dir, err1 := os.open(file.fullpath)
		assert(err1 == nil)

		err : os.Error
		inputs, err = os.read_dir(dir, 0)
		assert(err == nil)
	}

	input_map : map[string]converter.Input
	preprocessed : [dynamic]converter.Token
	ast  : [dynamic]converter.AstNode
	result : str.Builder

	ref, err2 := os.read_entire_file(fmt.tprintf(BASEDIR+"/ref/%v.odin", path.stem(file.name)))
	assert(err2, "Missing ref file?", loc)

	for _, stream in input_map { delete(stream.tokens) }
	clear(&input_map)
	for file in inputs {
		loc.file_path = file.name

		loc.procedure = "os.read_entire_file"
		content, err1 := os.read_entire_file(file.fullpath)
		assert(err1, loc = loc)

		toks : [dynamic]converter.Token
		loc.procedure = "converter.tokenize"
		converter.tokenize(&toks, cast(string) content, file.name)

		input_map[file.name] = { toks[:], false }
	}

	loc.file_path = file.name

	initial_file_name := str.ends_with(file.name, ".cpp") ? file.name : str.concatenate({ file.name, ".cpp" }, context.temp_allocator)

	removed_ifs := []converter.PreProcRemoveIfData {
		{ "REMOVED_IF", false },
	}

	clear(&preprocessed)
	loc.procedure = "converter.preprocess"
	converter.preprocess(&{ result = &preprocessed, inputs = input_map, removed_ifs = removed_ifs }, initial_file_name)

	clear(&ast)
	loc.procedure = "converter.ast_parse_filescope_sequence"
	ast_context : converter.AstContext = { ast = &ast }
	root_sequence := converter.ast_parse_filescope_sequence(&ast_context, preprocessed[:])

	clear(&result.buf)
	loc.procedure = "converter.convert_and_format"
	converter_context : converter.ConverterContext = { result = result, ast = ast, type_heap = ast_context.type_heap, root_sequence = root_sequence[:] }
	converter.convert_and_format(&converter_context, {})

	os.write_entire_file(fmt.tprintf(BASEDIR+"/out/%v.odin", path.stem(file.name)), converter_context.result.buf[:])

	loc.procedure = "test.validate"

	if(str.to_string(converter_context.result) == string(ref)) {
		loc.procedure = ""
		log.info("OK", location = loc)
	}
	else {
		log.errorf("expected\n---\n%v\n---\n\ngot\n---\n%v\n---", string(ref), str.to_string(converter_context.result), location=loc)
	}
}
