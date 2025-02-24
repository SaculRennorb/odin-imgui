package program

import "core:mem"
import "base:runtime"
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

append_return_index :: proc(arr : ^[dynamic]$T, v : T) -> (idx : AstNodeIndex)
{
	idx = AstNodeIndex(len(arr))
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


formatters : map[typeid]fmt.User_Formatter
@(init)
_set_user_formatters :: proc()
{
	formatters[typeid_of(AstError)] = fmt_token_a
	formatters[typeid_of(SourceLocation)] = fmt_location_a

	fmt.set_user_formatters(&formatters)
}
