package test

A1047 :: struct {
	a : i32, b : i32,
}

A1047_init :: proc(this : ^A1047) { this.a = 2 }

B1047 :: struct {
	c : A1047,
}

B1047_init :: proc(this : ^B1047) { init(&this.c) }