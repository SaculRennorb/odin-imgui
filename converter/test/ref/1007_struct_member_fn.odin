package test

A07 :: struct {
	a : i32,
}

A07_B :: proc(this : ^A07) -> i32
{
	b : i32 = 4
	return this.a + b
}