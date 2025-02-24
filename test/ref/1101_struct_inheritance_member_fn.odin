package test

A11 :: struct {
	a : i32,
}

B11 :: struct {
	using _base_A11 : A11,
}

B11_C :: proc(this : ^B11) -> i32
{
	return this.a
}