package test

A1307 :: struct($T : typeid) {
	t : T,
}

B1307 :: struct {
	a : A1307(^i32),
}

B1307_fn :: proc(this : ^B1307) { this.a.t = 0 }

B1307_fn2 :: proc(this : ^B1307) { this.a.t = 0 }
