package test

A1303 :: struct($T : typeid) {
	s : i32,
}

A1303_init :: proc(this : ^A1303($T), s : ^A1303(T))
{
}

A1303_swap :: proc(this : ^A1303($T), r : A1303(T)) { a : i32 = r.s }
