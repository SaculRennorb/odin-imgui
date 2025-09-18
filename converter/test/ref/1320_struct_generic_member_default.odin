package test

A1320 :: struct($T : typeid, $L : i32 = 1) {
	t : [L]T,
}

B1320 :: struct {
	a : A1320(^i32),
	b : A1320(^i32, 2),
}

B1320_fn :: proc(this : ^B1320) { this.a.t[0] = 0 }

B1320_fn2 :: proc(this : ^B1320) { this.b.t[0] = 0 }
