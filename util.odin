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
	formatters[typeid_of(NameContextIndex)] = fmt_name_ctx_idx_a
	formatters[typeid_of(AstTypeIndex)] = fmt_asttypeidx_a

	fmt.set_user_formatters(&formatters)
}

PersistenceKind :: enum uint {
	Temporary = 0,
	Persistent = 1,
}

SplitIndex :: bit_field uint {
	index : uint | size_of(uint) * 8 - 1,
	persistence : PersistenceKind | 1,
}
