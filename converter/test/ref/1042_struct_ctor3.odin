package test

A1042 :: struct {
	a : i32, b : i32,
}

A1042_init :: proc(this : ^A1042, _a : i32, _b : i32) { }

B1042 :: struct {
	a : A1042,
}

B1042_init :: proc(this : ^B1042) { init(&this.a, 1, 2) }
