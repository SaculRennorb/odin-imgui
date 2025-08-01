package program

import "core:mem"
import "base:runtime"
import "base:intrinsics"
import "core:fmt"

//bug in the compiler to sub multiptr
ptr_msub :: #force_inline proc "contextless"(e, s : [^]$T) -> int
{
	return mem.ptr_sub(transmute(^T)e, transmute(^T)s)
}

str_from_se :: proc(s, e : [^]u8) -> string
{
	return transmute(string) s[:ptr_msub(e, s)]
}

slice_from_se :: #force_inline proc "contextless"(s, e : [^]$T) -> []T
{
	return s[:ptr_msub(e, s)]
}

remove_unordered :: #force_inline proc "contextless" (array : ^[]$T, index : int)
{
	raw := transmute(^runtime.Raw_Slice) array
	if len(array) > 1 {
		array[index] = array[len(array) - 1]
	}
	raw.len -= 1
}

append_return_index :: proc(arr : ^[dynamic]$T, v : T) -> (idx : int)
{
	idx = len(arr)
	append(arr, v)
	return
}

append_return_ptr :: proc(arr : ^[dynamic]$T, v : T) -> (added : ^T)
{
	idx := len(arr)
	append(arr, v)
	return &arr[idx]
}

make_one :: #force_inline proc(e : $E, alloc := context.allocator) -> (arr : [dynamic]E)
{
	arr = make([dynamic]E, 1, alloc)
	arr[0] = e
	return
}

is_variant :: #force_inline proc "contextless" (expr : $U, $V : typeid) -> bool where intrinsics.type_is_variant_of(U, V)
{
	_, ok := expr.(V)
	return ok
}

map_clone :: proc(m : $M/map[$K]$V, allocator := context.allocator) -> M
{
	clone := make_map_cap(M, cap(m), allocator)
	for k, v in m { clone[k] = v }
	return clone
}


last :: proc { last_slice, last_array }
last_slice :: #force_inline proc "contextless" (arr : []$T)        -> ^T { return &arr[len(arr) - 1] }
last_array :: #force_inline proc "contextless" (arr : [dynamic]$T) -> ^T { return &arr[len(arr) - 1] }


last_or_nil :: proc { last_or_nil_slice, last_or_nil_array }
last_or_nil_slice :: #force_inline proc "contextless" (arr : []$T)        -> T { return len(arr) != 0 ? arr[len(arr) - 1] : {} }
last_or_nil_array :: #force_inline proc "contextless" (arr : [dynamic]$T) -> T { return len(arr) != 0 ? arr[len(arr) - 1] : {} }

first_or_nil :: proc { first_or_nil_slice, first_or_nil_array }
first_or_nil_slice :: #force_inline proc "contextless" (arr : []$T)        -> T { return len(arr) != 0 ? arr[0] : {} }
first_or_nil_array :: #force_inline proc "contextless" (arr : [dynamic]$T) -> T { return len(arr) != 0 ? arr[0] : {} }

all :: #force_inline proc "contextless" ($E : typeid) -> E
{
	return transmute(E) cast(intrinsics.type_bit_set_underlying_type(E)) ((1 << (uint(max(intrinsics.type_bit_set_elem_type(E))) + 1)) - 1)
}

assert_eq :: proc(a, b : $T, ax := #caller_expression(a), bx := #caller_expression(b), loc := #caller_location) where intrinsics.type_is_comparable(T)
{
	if a != b {
		panic(fmt.tprintf("Expected %v == %v, but was %v == %v.\n", ax, bx, a, b), loc)
	}
}


formatters : map[typeid]fmt.User_Formatter
@(init)
_set_user_formatters :: proc()
{
	formatters[typeid_of(Maybe(AstErrorFrame))] = fmt_ast_err_a
	formatters[typeid_of(AstErrorFrame)] = fmt_ast_erri_a
	formatters[typeid_of(Token)] = fmt_token_a
	formatters[typeid_of(SourceLocation)] = fmt_location_a
	formatters[typeid_of(AstNodeIndex)] = fmt_astindex_a
	formatters[typeid_of(AstNode)] = fmt_astnode_a
	formatters[typeid_of(TokenRange)] = fmt_token_range_a
	formatters[typeid_of(AstTypeIndex)] = fmt_asttypeidx_a

	fmt.set_user_formatters(&formatters)
}


import win32 "core:sys/windows"
import str "core:strings"
import "winternal"

@(init)
install_exception_handler :: proc()
{
	win32.AddVectoredExceptionHandler(1, proc "system" (ExceptionInfo: ^win32.EXCEPTION_POINTERS) -> win32.LONG {
		if ExceptionInfo.ExceptionRecord.ExceptionCode != win32.EXCEPTION_STACK_OVERFLOW { return win32.EXCEPTION_CONTINUE_SEARCH }

		context_ := win32.CONTEXT { ContextFlags = win32.WOW64_CONTEXT_CONTROL }
		win32.GetThreadContext(win32.GetCurrentThread(), &context_)
		tib := winternal.NtCurrentTeb().Tib
		stack_size := transmute(uintptr) tib.StackBase - transmute(uintptr) tib.StackLimit
		stack_left := transmute(uintptr) context_.Rsp - transmute(uintptr) tib.StackLimit

		std_out := win32.GetStdHandle(win32.STD_OUTPUT_HANDLE)
		if std_out == win32.INVALID_HANDLE { return win32.EXCEPTION_CONTINUE_SEARCH }

		@(static) stack_mem : [512]u8
		context = {
			temp_allocator = mem.small_stack_allocator(&mem.Small_Stack{ data = stack_mem[:] })
		}

		fmt.eprintf("Stack overflow, %v Bytes left of %v KB.\n", stack_left, stack_size / 1024)

		when false {
		
		process := win32.GetCurrentProcess()
		thread := win32.GetCurrentThread()

		if !win32.SymInitialize(process, nil, win32.TRUE) {
			fmt.eprint("Failed to initialize symbol resolver system.\n")
			// continue anyway
		}
		
		frame := winternal.STACKFRAME64 {
			AddrPC = {
				Offset = context_.Rip,
				Mode = .AddrModeFlat,
			},
			AddrStack = {
				Offset = context_.Rsp,
				Mode = .AddrModeFlat,
			},
			AddrFrame = {
				Offset = context_.Rbp,
				Mode = .AddrModeFlat,
			},
		}

		displacement : win32.DWORD64

		NAME_LEN :: 128
		_s, err := mem.alloc(size_of(win32.SYMBOL_INFOW) + NAME_LEN * size_of(win32.WCHAR), align_of(win32.SYMBOL_INFOW), context.temp_allocator)
		if err != nil {
			fmt.eprint("Failed to alloc frame symbol storage.\n")
			return win32.EXCEPTION_CONTINUE_SEARCH
		}
		symbol := cast(^win32.SYMBOL_INFOW)_s
		symbol.SizeOfStruct = size_of(win32.SYMBOL_INFOW)
		symbol.MaxNameLen = NAME_LEN

		fmt.eprint("Stack Trace\tPC                 Stack              Frame\n\tName\n")

		for f in 0..<100 {
			if !winternal.StackWalk64(winternal.IMAGE_FILE_MACHINE_AMD64, process, thread, &frame, &context_,
				nil,
				winternal.SymFunctionTableAccess64,
				winternal.SymGetModuleBase64,
				nil,
			) {
				break
			}

			fmt.eprintf("Frame [%v]:\t0x%016x 0x%016x 0x%016x\n\t", f, frame.AddrPC.Offset, frame.AddrStack.Offset, frame.AddrFrame.Offset)
			
			if !win32.SymFromAddrW(process, frame.AddrPC.Offset, &displacement, symbol) {
				err := win32.GetLastError()
				fmt.eprintf("Failed to get symbol at this address: error %v\n", err)
				continue 
			}

			wname := win32.wstring(&symbol.Name[0])[:symbol.NameLen]
			name, err := win32.utf16_to_utf8(wname, context.temp_allocator)
			if err != nil {
				fmt.eprintln("Failed to convert name to utf8\n")
			}
			else {
				fmt.eprintln(name)
			}
		}

		}

		return win32.EXCEPTION_CONTINUE_SEARCH
	})
}