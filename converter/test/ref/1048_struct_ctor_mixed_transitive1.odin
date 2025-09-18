package test

A1048 :: struct {
	a : i32, b : i32,
}

A1048_init :: proc(this : ^A1048) { this.a = 2 }

B1048 :: struct {
	c : A1048,
	d : i32,
}

B1048_init :: proc(this : ^B1048)
{
	init(&this.c)
	this.d = 2
}