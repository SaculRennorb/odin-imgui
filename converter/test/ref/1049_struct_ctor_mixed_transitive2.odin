package test

A1049 :: struct {
	a : i32, b : i32,
}

A1049_init :: proc(this : ^A1049) { this.a = 2 }

B1049 :: struct {
	c : A1049,
	d : i32,
}

B1049_init :: proc(this : ^B1049)
{
	init(&this.c)
	this.d = 3
}