package test

A1305 :: struct(T : typeid, T2 : typeid) {
	t : T,
}

B1305 :: struct {
	a : A1305(^i32, ^^i32),
}
