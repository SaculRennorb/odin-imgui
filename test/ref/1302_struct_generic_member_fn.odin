package test

A1302 :: struct(T : typeid) {
	t : T,
}

A1302_swap :: proc(this : ^A1302($T), o : A1302(T)) { a : T = o.t }
