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


last :: #force_inline proc "contextless" (arr : []$T) -> ^T
{
	return &arr[len(arr) - 1]
}

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
	formatters[typeid_of(AstError)] = fmt_ast_err_a
	formatters[typeid_of(Token)] = fmt_token_a
	formatters[typeid_of(SourceLocation)] = fmt_location_a
	formatters[typeid_of(AstNodeIndex)] = fmt_astindex_a
	formatters[typeid_of(AstNode)] = fmt_astnode_a
	formatters[typeid_of(TokenRange)] = fmt_token_range_a
	formatters[typeid_of(NameContextIndex)] = fmt_name_ctx_idx_a

	fmt.set_user_formatters(&formatters)
}
