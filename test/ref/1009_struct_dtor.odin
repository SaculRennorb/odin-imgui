package test

A1009 :: struct {
	a : i32,
}

A1009_deinit :: proc(this : ^A1009)
{
	this.a = 0
}