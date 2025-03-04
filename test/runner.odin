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

SEQUENTIAL :: #config(sequential, false)
 
@(test)
test :: proc(t : ^testing.T)
{
	BASEDIR :: "test"

	dir_in, derr1 := os.open(BASEDIR+"/in")
	assert(derr1 == nil)
	files_in, ferr1 := os.read_dir(dir_in, 0)
	assert(ferr1 == nil)

	context.user_ptr = t

	context.assertion_failure_proc = proc(prefix, message : string, loc := #caller_location) -> ! {
		t := transmute(^testing.T) context.user_ptr
		fi := transmute(^os.File_Info) context.user_index
		log.errorf("[%v]: Failed [%v]: %v", fi.name, prefix, message, location = loc)
		runtime.trap()
	}

	a := os.args
	if len(os.args) > 1 {
		for &file in files_in {
			if str.starts_with(file.name, os.args[1]) {
				context.user_index = transmute(int) &file
				thread_proc()
				return
			}
		}
		panic(fmt.tprintf("Failed to match '%v' to any test file in '%v'.", os.args[1], BASEDIR))
	}

	threads : [dynamic]^thread.Thread

	for &file in files_in {
		context.user_index = transmute(int) &file

		when !SEQUENTIAL {
			ctx := context
			tr := thread.create_and_start(thread_proc, ctx)
			append(&threads, tr)
		}
		else {
			thread_proc()
		}
	}

	thread_proc :: proc() {
		when !SEQUENTIAL {
			defer runtime.default_temp_allocator_destroy(transmute(^runtime.Default_Temp_Allocator) context.temp_allocator.data)
		}

		
		t := transmute(^testing.T) context.user_ptr
		file := transmute(^os.File_Info) context.user_index

		loc := runtime.Source_Code_Location {
			file_path = file.name,
			column = 0,
			line = 0,
		}


		toks : [dynamic]converter.Token
		ast  : [dynamic]converter.AstNode
		input_map : map[string][]converter.AstNode
		preprocessed : [dynamic][]converter.AstNode
		folded : [dynamic]converter.AstNode
		result : str.Builder
		

		loc.procedure = "os.read_entire_file"
		content, err1 := os.read_entire_file(file.fullpath)
		assert(err1, loc = loc)
		ref, err2 := os.read_entire_file(fmt.tprintf(BASEDIR+"/ref/%v.odin", path.stem(file.name)))
		assert(err2, "Missing ref file?", loc)

		clear(&toks)
		loc.procedure = "converter.tokenize"
		log.debug("tokenizing ... ", location = loc)
		converter.tokenize(&toks, cast(string) content, file.name)

		clear(&ast)
		loc.procedure = "converter.parse_ast_filescope_sequence"
		log.debug(len(toks), "tokens, building ast ... ", location = loc)
		converter.parse_ast_filescope_sequence(&ast, toks[:])

		clear(&input_map)
		input_map["prim"] = ast[:]
		
		clear(&preprocessed)
		loc.procedure = "converter.preprocess"
		log.debug(len(ast), "ast nodes, preprocessing ... ", location = loc)
		converter.preprocess(&preprocessed, input_map, "prim")

		clear(&folded)
		converter.merge_ast(&folded, preprocessed[:]);

		loc.procedure = "converter.convert_and_format"
		log.debug(len(folded), "ast nodes, converting ... ", location = loc)
		converter.convert_and_format(&result, folded[:])

		os.write_entire_file(fmt.tprintf(BASEDIR+"/out/%v.odin", path.stem(file.name)), result.buf[:])

		loc.procedure = "test.validate"

		if(str.to_string(result) == string(ref)) {
			loc.procedure = ""
			log.info("OK", location = loc)
		}
		else {
			log.errorf("expected\n---\n%v\n---\n\ngot\n---\n%v\n---", string(ref), str.to_string(result), location=loc)
		}
	}

	when !SEQUENTIAL {
		thread.join_multiple(..threads[:])
	}
}