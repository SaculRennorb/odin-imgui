package test

A1308 :: struct($T : typeid) {
	t : T,
}

A1308_get :: proc(this : ^A1308($T)) -> ^T { return this.t }

D1308 :: struct {
	d : i32,
}

B1308 :: struct {
	b : D1308,
}

C1308 :: struct {
	a : A1308(B1308),
}

C1308_fn :: proc(this : ^C1308) { get(&this.a).b.d = 0 }
